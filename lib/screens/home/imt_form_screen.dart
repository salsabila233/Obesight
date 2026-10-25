import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/imt_calculator_service.dart';
import 'imt_result_screen.dart';

class ImtFormScreen extends StatefulWidget {
  final UserModel? user;
  final double? initialWeight;
  final double? initialHeight;
  final String? initialGender;
  final int? initialAge;

  const ImtFormScreen({
    super.key,
    this.user,
    this.initialWeight,
    this.initialHeight,
    this.initialGender,
    this.initialAge,
  });

  @override
  State<ImtFormScreen> createState() => _ImtFormScreenState();
}

class _ImtFormScreenState extends State<ImtFormScreen> {
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  late final TextEditingController _ageController;

  String _selectedGender = 'Laki-laki';
  String? _errorMessage;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    final userId = widget.user?.id ?? 'usr_001';
    final userBmi = AuthService().getUserBmi(userId);

    final initialW = widget.initialWeight ?? (userBmi['weight'] as num?)?.toDouble() ?? 68.0;
    final initialH = widget.initialHeight ?? (userBmi['height'] as num?)?.toDouble() ?? 170.0;
    final initialG = widget.initialGender ?? (userBmi['gender'] as String?) ?? 'Laki-laki';
    final initialA = widget.initialAge ?? (userBmi['age'] as num?)?.toInt() ?? 21;

    _weightController = TextEditingController(
      text: initialW % 1 == 0 ? initialW.toInt().toString() : initialW.toString(),
    );
    _heightController = TextEditingController(
      text: initialH % 1 == 0 ? initialH.toInt().toString() : initialH.toString(),
    );
    _ageController = TextEditingController(text: initialA.toString());
    _selectedGender = initialG;
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _onCalculatePressed() async {
    final w = ImtCalculatorService.parseDecimal(_weightController.text);
    final h = ImtCalculatorService.parseDecimal(_heightController.text);
    final a = int.tryParse(_ageController.text.trim()) ?? 21;

    final weightError = ImtCalculatorService.validateWeight(w);
    if (weightError != null) {
      setState(() {
        _errorMessage = weightError;
      });
      return;
    }

    final heightError = ImtCalculatorService.validateHeight(h);
    if (heightError != null) {
      setState(() {
        _errorMessage = heightError;
      });
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    if (_isNavigating) return;
    _isNavigating = true;

    final rawBmi = ImtCalculatorService.calculateBmi(weight: w, height: h) ?? 23.5;
    final roundedBmi = ImtCalculatorService.roundBmi(rawBmi);
    final classification = ImtCalculatorService.classifyBmi(roundedBmi);
    final category = classification['category']!;
    final risk = classification['risk']!;
    final userId = widget.user?.id ?? AuthService().currentUser?.id ?? 'usr_001';

    // Update AuthService state
    AuthService().updateUserBmi(
      userId: userId,
      bmi: roundedBmi,
      category: category,
      risk: risk,
      weight: w,
      height: h,
      gender: _selectedGender,
      age: a,
    );

    // Langsung navigasi ke ImtResultScreen dalam 1 kali tekan tombol
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ImtResultScreen(
          bmi: roundedBmi,
          weight: w!,
          height: h!,
          gender: _selectedGender,
          age: a,
          category: category,
          risk: risk,
        ),
      ),
    );

    if (mounted) {
      setState(() {
        _isNavigating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerColor = isDark ? const Color(0xFF1E293B) : const Color(0xFF489874);
    final primaryGreen = isDark ? const Color(0xFF58AF86) : const Color(0xFF489874);
    final appBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF4F8F6);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textHeading = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: headerColor,
      appBar: AppBar(
        backgroundColor: headerColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Hitung IMT',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: appBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Card Pengantar (Bersih, elegan, tanpa latar kusam)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hitung Indeks Massa Tubuhmu',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: textHeading,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Ketahui status berat badan dan risiko kesehatan berdasarkan tinggi dan berat badanmu.',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: textSub,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Image.asset(
                        'assets/images/bmi_illustration.png',
                        width: 90,
                        height: 90,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Icon(
                          Icons.assessment_rounded,
                          size: 64,
                          color: primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // BAGIAN DATA FISIK PENGGUNA
                Text(
                  'Data Fisik Pengguna',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textHeading,
                  ),
                ),
                          const SizedBox(height: 16),

                          // 1. Usia Card
                          _PhysicalDataCard(
                            label: 'Usia',
                            unit: 'Tahun',
                            icon: Icons.calendar_today_outlined,
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 14),

                          // 2. Gender Selector
                          _GenderSelector(
                            selectedGender: _selectedGender,
                            onChanged: (gender) {
                              setState(() => _selectedGender = gender);
                            },
                            isDark: isDark,
                          ),
                          const SizedBox(height: 14),

                          // 3. Tinggi Badan Card
                          _PhysicalDataCard(
                            label: 'Tinggi Badan',
                            unit: 'cm',
                            icon: Icons.height_rounded,
                            controller: _heightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            isDark: isDark,
                          ),
                          const SizedBox(height: 14),

                          // 4. Berat Badan Card
                          _PhysicalDataCard(
                            label: 'Berat Badan',
                            unit: 'kg',
                            icon: Icons.scale_rounded,
                            controller: _weightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            isDark: isDark,
                          ),
                          const SizedBox(height: 18),

                          // Error message if any
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFECACA)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFFDC2626)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // CARD: Catatan Penting
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: cardBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Image.asset(
                                  'assets/bmi_magnifying_glass.png',
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) => Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE8F5EE),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.info_outline_rounded, color: primaryGreen, size: 24),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Catatan Penting',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: textHeading,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'IMT dihitung berdasarkan rumus berat badan (kg) dibagi tinggi badan (m) kuadrat. Pastikan data yang dimasukkan akurat.',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: textSub,
                                          height: 1.45,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // TOMBOL: Hitung IMT / Simpan Perubahan
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4E8F73),
                                foregroundColor: Colors.white,
                                elevation: 3,
                                shadowColor: const Color(0xFF4E8F73).withValues(alpha: 0.35),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(26), // Pill shape
                                ),
                              ),
                              onPressed: _onCalculatePressed,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Hitung IMT',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Icon(Icons.arrow_forward_rounded, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
          }

// ==========================================
// REUSABLE SUB-WIDGET: Physical Data Card
// ==========================================
class _PhysicalDataCard extends StatelessWidget {
  final String label;
  final String unit;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool isDark;

  const _PhysicalDataCard({
    required this.label,
    required this.unit,
    required this.icon,
    required this.controller,
    required this.keyboardType,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final primaryGreen = isDark ? const Color(0xFF58AF86) : const Color(0xFF3B8E67);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris Atas: Icon kecil hijau outline + label
          Row(
            children: [
              Icon(icon, size: 17, color: primaryGreen),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Baris Bawah: Row dengan MainAxisAlignment.spaceBetween
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Kiri: Angka input
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  cursorColor: primaryGreen,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Kanan: Satuan dalam pill badge abu-abu muda
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  unit,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================
// REUSABLE SUB-WIDGET: Gender Selector
// ==========================================
class _GenderSelector extends StatelessWidget {
  final String selectedGender;
  final ValueChanged<String> onChanged;
  final bool isDark;

  const _GenderSelector({
    required this.selectedGender,
    required this.onChanged,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jenis Kelamin',
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildGenderOption(
                label: 'Laki-laki',
                icon: Icons.male_rounded,
                isSelected: selectedGender.toLowerCase().contains('laki'),
                onTap: () => onChanged('Laki-laki'),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildGenderOption(
                label: 'Perempuan',
                icon: Icons.female_rounded,
                isSelected: selectedGender.toLowerCase().contains('perempuan'),
                onTap: () => onChanged('Perempuan'),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final primaryGreen = isDark ? const Color(0xFF58AF86) : const Color(0xFF3B8E67);
    final activeBg = isDark ? const Color(0xFF1E3A2F) : const Color(0xFFEFF8F3);
    final inactiveBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final inactiveBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final activeText = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF1E5B3E);
    final inactiveText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF334155);
    final greyIconColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? primaryGreen : inactiveBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: greyIconColor,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? activeText : inactiveText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
