import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/bmi_save_confirmation_dialog.dart';
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

  double? get _parsedWeight => double.tryParse(_weightController.text.replaceAll(',', '.'));
  double? get _parsedHeight => double.tryParse(_heightController.text.replaceAll(',', '.'));
  int? get _parsedAge => int.tryParse(_ageController.text);

  double? _calculateBmi() {
    final w = _parsedWeight;
    final h = _parsedHeight;
    if (w == null || h == null || w <= 0 || h <= 0) return null;
    final hMeters = h / 100.0;
    return w / (hMeters * hMeters);
  }

  Map<String, String> _classifyBmi(double bmi) {
    if (bmi < 18.5) {
      return {'category': 'Kurus', 'risk': 'Rendah'};
    } else if (bmi <= 24.9) {
      return {'category': 'Normal', 'risk': 'Rendah'};
    } else if (bmi <= 29.9) {
      return {'category': 'Gemuk', 'risk': 'Sedang'};
    } else {
      return {'category': 'Obesitas', 'risk': 'Tinggi'};
    }
  }

  void _onCalculatePressed() {
    final w = _parsedWeight;
    final h = _parsedHeight;

    if (w == null || w < 20 || w > 350) {
      setState(() {
        _errorMessage = 'Harap masukkan berat badan yang valid (20 - 350 kg)';
      });
      return;
    }

    if (h == null || h < 50 || h > 260) {
      setState(() {
        _errorMessage = 'Harap masukkan tinggi badan yang valid (50 - 260 cm)';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    // Show Confirmation Modal Dialog
    BmiSaveConfirmationDialog.show(
      context,
      onConfirm: () {
        final a = _parsedAge ?? 21;
        final currentBmi = _calculateBmi() ?? 23.5;
        final roundedBmi = double.parse(currentBmi.toStringAsFixed(1));
        final classification = _classifyBmi(roundedBmi);
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

        // Navigate to ImtResultScreen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ImtResultScreen(
              bmi: roundedBmi,
              weight: w,
              height: h,
              gender: _selectedGender,
              age: a,
              category: category,
              risk: risk,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryGreen = isDark ? const Color(0xFF58AF86) : const Color(0xFF4E8F73);
    final appBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F9F7);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textHeading = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: appBg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF4E8F73),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Hitung Indeks Masa Tubuh (IMT)',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HERO CARD
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFD6F0E3),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 16, 16, 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hitung Indeks Massa Tubuhmu',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
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
                                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Image.asset(
                            'assets/bmi_hero_hands.png',
                            width: 100,
                            height: 100,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => Icon(
                              Icons.assessment_rounded,
                              size: 72,
                              color: primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // SECTION: Data Fisik Pengguna
                          Text(
                            'Data Fisik Pengguna',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
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
                            isDropdownStyle: true,
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
                  ],
                ),
              ),
            ),
          ],
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
  final bool isDropdownStyle;
  final bool isDark;

  const _PhysicalDataCard({
    required this.label,
    required this.unit,
    required this.icon,
    required this.controller,
    required this.keyboardType,
    this.isDropdownStyle = false,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final primaryGreen = isDark ? const Color(0xFF58AF86) : const Color(0xFF4E8F73);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final labelColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris Atas: Icon kecil hijau outline + label
          Row(
            children: [
              Icon(icon, size: 16, color: primaryGreen),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Baris Bawah: Row dengan MainAxisAlignment.spaceBetween
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Kiri: Angka besar bold
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),

              // Kanan: Satuan hijau bold
              if (isDropdownStyle)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      unit,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.keyboard_arrow_down_rounded, color: primaryGreen, size: 20),
                  ],
                )
              else
                Text(
                  unit,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: primaryGreen,
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
    final primaryGreen = isDark ? const Color(0xFF58AF86) : const Color(0xFF4E8F73);
    final labelColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.wc_rounded, size: 16, color: primaryGreen),
            const SizedBox(width: 8),
            Text(
              'Jenis Kelamin',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: labelColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildGenderOption(
                label: 'Laki-laki',
                symbol: '♂',
                symbolColor: const Color(0xFF00BBA7),
                isSelected: selectedGender.toLowerCase().contains('laki'),
                onTap: () => onChanged('Laki-laki'),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildGenderOption(
                label: 'Perempuan',
                symbol: '♀',
                symbolColor: const Color(0xFFD946EF),
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
    required String symbol,
    required Color symbolColor,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final primaryGreen = isDark ? const Color(0xFF58AF86) : const Color(0xFF4E8F73);
    final activeBg = isDark ? const Color(0xFF1E3A2F) : const Color(0xFFF0FAF5);
    final inactiveBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final inactiveBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final activeText = isDark ? const Color(0xFF6EE7B7) : primaryGreen;
    final inactiveText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryGreen : inactiveBorder,
            width: isSelected ? 1.6 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              symbol,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: symbolColor,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? activeText : inactiveText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
