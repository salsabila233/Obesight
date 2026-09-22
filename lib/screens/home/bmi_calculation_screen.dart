import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import 'bmi_result_screen.dart';

class BmiCalculationScreen extends StatefulWidget {
  final UserModel? user;
  final double? initialWeight;
  final double? initialHeight;
  final String? initialGender;
  final int? initialAge;

  const BmiCalculationScreen({
    super.key,
    this.user,
    this.initialWeight,
    this.initialHeight,
    this.initialGender,
    this.initialAge,
  });

  @override
  State<BmiCalculationScreen> createState() => _BmiCalculationScreenState();
}

class _BmiCalculationScreenState extends State<BmiCalculationScreen> {
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  late final TextEditingController _ageController;

  String _selectedGender = 'Perempuan';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final userId = widget.user?.id ?? 'usr_001';
    final userBmi = AuthService().getUserBmi(userId);

    final initialW = widget.initialWeight ?? (userBmi['weight'] as num?)?.toDouble() ?? 58.0;
    final initialH = widget.initialHeight ?? (userBmi['height'] as num?)?.toDouble() ?? 165.0;
    final initialG = widget.initialGender ?? (userBmi['gender'] as String?) ?? 'Perempuan';
    final initialA = widget.initialAge ?? (userBmi['age'] as num?)?.toInt() ?? 22;

    _weightController = TextEditingController(text: initialW % 1 == 0 ? initialW.toInt().toString() : initialW.toString());
    _heightController = TextEditingController(text: initialH % 1 == 0 ? initialH.toInt().toString() : initialH.toString());
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
    } else if (bmi <= 22.9) {
      return {'category': 'Normal', 'risk': 'Rendah'};
    } else if (bmi <= 24.9) {
      return {'category': 'Kelebihan Berat Badan', 'risk': 'Sedang'};
    } else {
      return {'category': 'Obesitas', 'risk': 'Tinggi'};
    }
  }

  void _onSavePressed() {
    final w = _parsedWeight;
    final h = _parsedHeight;
    final a = _parsedAge;

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

    final currentBmi = _calculateBmi() ?? 22.8;
    final roundedBmi = double.parse(currentBmi.toStringAsFixed(1));
    final classification = _classifyBmi(roundedBmi);
    final category = classification['category']!;
    final risk = classification['risk']!;
    final userId = widget.user?.id ?? AuthService().currentUser?.id ?? 'usr_001';

    // Update AuthService state immediately
    AuthService().updateUserBmi(
      userId: userId,
      bmi: roundedBmi,
      category: category,
      risk: risk,
      weight: w,
      height: h,
      gender: _selectedGender,
      age: a ?? 22,
    );

    // Directly navigate to BmiResultScreen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BmiResultScreen(
          bmi: roundedBmi,
          weight: w,
          height: h,
          gender: _selectedGender,
          age: a ?? 22,
          category: category,
          risk: risk,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF489874),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Perhitungan IMT',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // B. AREA INFORMASI (Top Banner dengan Visual Kanan)
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE6F7F0), Color(0xFFD4F1E4)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFC4ECDA)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x12489874),
                            blurRadius: 14,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 65,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hitung Indeks Massa\nTubuhmu',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF112A1F),
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Ketahui status berat badan dan risiko kesehatan berdasarkan tinggi dan berat badanmu.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: const Color(0xFF375347),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 35,
                            child: Container(
                              height: 84,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2F6EC),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Image.asset(
                                    'assets/illustration_woman.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => const Icon(
                                      Icons.health_and_safety_rounded,
                                      size: 42,
                                      color: Color(0xFF489874),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Error banner if any
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
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
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFFB91C1C),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Section Title: Input Data
                    Text(
                      'Data Fisik Pengguna',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // D. PILIHAN / OPTION (Jenis Kelamin)
                    Text(
                      'Jenis Kelamin',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildGenderCard(
                            gender: 'Laki-laki',
                            icon: Icons.male_rounded,
                            isSelected: _selectedGender == 'Laki-laki',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildGenderCard(
                            gender: 'Perempuan',
                            icon: Icons.female_rounded,
                            isSelected: _selectedGender == 'Perempuan',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // C. INPUT DATA (Berat Badan & Tinggi Badan Cards)
                    _buildInputCard(
                      label: 'Berat Badan',
                      controller: _weightController,
                      suffixText: 'kg',
                      hintText: 'Contoh: 60',
                      icon: Icons.monitor_weight_outlined,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*[\,\.]?\d*')),
                      ],
                    ),
                    const SizedBox(height: 14),

                    _buildInputCard(
                      label: 'Tinggi Badan',
                      controller: _heightController,
                      suffixText: 'cm',
                      hintText: 'Contoh: 165',
                      icon: Icons.height_rounded,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*[\,\.]?\d*')),
                      ],
                    ),
                    const SizedBox(height: 14),

                    _buildInputCard(
                      label: 'Usia',
                      controller: _ageController,
                      suffixText: 'Tahun',
                      hintText: 'Contoh: 22',
                      icon: Icons.cake_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                    const SizedBox(height: 20),

                    // E. CARD INFORMASI IMT
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6F2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF489874).withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE2F1E8),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.info_outline_rounded,
                              color: Color(0xFF36785A),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Catatan Penting',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1E3A2F),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'IMT dihitung berdasarkan rumus berat badan (kg) dibagi kuadrat tinggi badan (m²). Pastikan data yang Anda masukkan akurat.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: const Color(0xFF475569),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // F. BUTTON (Simpan Perubahan)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF489874),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _onSavePressed,
                  child: Text(
                    'Simpan Perubahan',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderCard({
    required String gender,
    required IconData icon,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = gender;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5EE) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF489874) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.6 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF489874).withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 19,
              color: isSelected ? const Color(0xFF2E6B4F) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                gender,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? const Color(0xFF2E6B4F) : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard({
    required String label,
    required TextEditingController controller,
    required String suffixText,
    required String hintText,
    required IconData icon,
    required TextInputType keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF489874)),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475569),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  onChanged: (_) {
                    if (_errorMessage != null) {
                      setState(() {
                        _errorMessage = null;
                      });
                    }
                  },
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: hintText,
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF94A3B8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  suffixText,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569),
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
