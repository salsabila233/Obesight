import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import 'skrining_models.dart';
import 'skrining_result_screen.dart';

class SkriningWizardScreen extends StatefulWidget {
  final UserModel? user;

  const SkriningWizardScreen({
    super.key,
    this.user,
  });

  @override
  State<SkriningWizardScreen> createState() => _SkriningWizardScreenState();
}

class _SkriningWizardScreenState extends State<SkriningWizardScreen> {
  int _currentStep = 0; // 0 to 4 -> Langkah 1 to 5
  late final SkriningData _data;

  // Controllers for Step 1
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;

  static const Color primaryGreen = Color(0xFF4A8B6C); // Medical soft green
  static const Color activeGreen = Color(0xFF36785A);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color cardBorder = Color(0xFFCBD5E1);

  @override
  void initState() {
    super.initState();
    final userId = widget.user?.id ?? AuthService().currentUser?.id ?? 'usr_001';
    final userBmi = AuthService().getUserBmi(userId);

    final initialAge = (userBmi['age'] as num?)?.toInt() ?? 23;
    final initialHeight = (userBmi['height'] as num?)?.toDouble() ?? 165.0;
    final initialWeight = (userBmi['weight'] as num?)?.toDouble() ?? 72.0;
    final initialGender = (userBmi['gender'] as String?) ?? 'Perempuan';

    _data = SkriningData(
      gender: initialGender,
      age: initialAge,
      height: initialHeight,
      weight: initialWeight,
    );

    _ageController = TextEditingController(text: initialAge.toString());
    _heightController = TextEditingController(
      text: initialHeight % 1 == 0 ? initialHeight.toInt().toString() : initialHeight.toString(),
    );
    _weightController = TextEditingController(
      text: initialWeight % 1 == 0 ? initialWeight.toInt().toString() : initialWeight.toString(),
    );

    // Listen to changes for reactive validation
    _ageController.addListener(_onFieldChanged);
    _heightController.addListener(_onFieldChanged);
    _weightController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    setState(() {
      _data.age = int.tryParse(_ageController.text);
      _data.height = double.tryParse(_heightController.text.replaceAll(',', '.'));
      _data.weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
    });
  }

  @override
  void dispose() {
    _ageController.removeListener(_onFieldChanged);
    _heightController.removeListener(_onFieldChanged);
    _weightController.removeListener(_onFieldChanged);
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  bool get _isCurrentStepValid {
    switch (_currentStep) {
      case 0: // Step 1: Data Diri
        return _data.gender != null &&
            _data.gender!.isNotEmpty &&
            _data.age != null &&
            _data.age! > 0 &&
            _data.height != null &&
            _data.height! > 0 &&
            _data.weight != null &&
            _data.weight! > 0;
      case 1: // Step 2: Riwayat Keluarga & Pola Makan
        return _data.familyHistory != null &&
            _data.highCalorieFood != null &&
            _data.vegetableIntake != null &&
            _data.mainMealFrequency != null;
      case 2: // Step 3: Kebiasaan & Gaya Hidup
        return _data.snackFrequency != null &&
            _data.smoking != null &&
            _data.waterIntake != null &&
            _data.monitorCalories != null;
      case 3: // Step 4: Aktifitas Fisik
        return _data.physicalActivity != null &&
            _data.screenTime != null;
      case 4: // Step 5: Konsumsi Alkohol dan Transportasi
        return _data.alcohol != null &&
            _data.transportation != null;
      default:
        return false;
    }
  }

  void _onNextPressed() {
    if (!_isCurrentStepValid) return;

    if (_currentStep < 4) {
      setState(() {
        _currentStep++;
      });
    } else {
      _finishScreening();
    }
  }

  void _finishScreening() {
    // Save updated BMI and risk profile to AuthService
    final userId = widget.user?.id ?? AuthService().currentUser?.id ?? 'usr_001';
    final calculatedBmi = _data.bmi;
    final category = _data.categoryTitle.replaceAll('\n', ' ');
    final risk = _data.riskTitle;

    AuthService().updateUserBmi(
      userId: userId,
      bmi: calculatedBmi,
      category: category,
      risk: risk,
      weight: _data.weight,
      height: _data.height,
      gender: _data.gender,
      age: _data.age,
    );

    AuthService().updateBiodataStatus(
      userId: userId,
      isComplete: true,
    );

    // Navigate to Hasil Skrining
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SkriningResultScreen(
          data: _data,
          user: widget.user,
        ),
      ),
    );
  }

  void _onBackPressed() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 30),
          onPressed: _onBackPressed,
        ),
        title: Text(
          'Skrining Obesitas',
          style: GoogleFonts.poppins(
            fontSize: 16.5,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // STEPPER INDICATOR HEADER
            _buildStepperHeader(),

            // SCROLLABLE FORM QUESTIONS
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step Title & Subtitle
                    _buildStepHeaderTitle(),
                    const SizedBox(height: 14),

                    // Dynamic Step Content
                    if (_currentStep == 0) _buildStep1DataDiri(),
                    if (_currentStep == 1) _buildStep2RiwayatPolaMakan(),
                    if (_currentStep == 2) _buildStep3KebiasaanGayaHidup(),
                    if (_currentStep == 3) _buildStep4AktifitasFisik(),
                    if (_currentStep == 4) _buildStep5AlkoholTransportasi(),

                    const SizedBox(height: 24),

                    // VALIDATED ACTION BUTTON ("Berikutnya ->" / "Lihat Hasil ->")
                    _buildActionButton(),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. STEPPER INDICATOR (Langkah X dari 5 & 1-5 Circles)
  Widget _buildStepperHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        children: [
          Text(
            'Langkah ${_currentStep + 1} dari 5',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final isCompletedOrActive = index <= _currentStep;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompletedOrActive ? activeGreen : const Color(0xFFE2E8F0),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: isCompletedOrActive ? FontWeight.w600 : FontWeight.w500,
                    color: isCompletedOrActive ? Colors.white : const Color(0xFF94A3B8),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // 2. STEP HEADER TITLE & SUBTITLE
  Widget _buildStepHeaderTitle() {
    String title = '';
    const subtitle = 'Lengkapi data berikut';

    switch (_currentStep) {
      case 0:
        title = 'Data Diri';
        break;
      case 1:
        title = 'Riwayat Keluarga & Pola Makan';
        break;
      case 2:
        title = 'Kebiasaan & Gaya Hidup';
        break;
      case 3:
        title = 'Aktifitas Fisik';
        break;
      case 4:
        title = 'Konsumsi Alkohol dan Transportasi';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: textMuted,
          ),
        ),
      ],
    );
  }

  // =================== STEP 1: DATA DIRI ===================
  Widget _buildStep1DataDiri() {
    return Column(
      children: [
        // Question: Jenis Kelamin
        _buildQuestionCard(
          title: 'Jenis Kelamin',
          child: Row(
            children: [
              _buildRoundRadio(
                label: 'Laki-laki',
                isSelected: _data.gender == 'Laki-laki',
                onTap: () => setState(() => _data.gender = 'Laki-laki'),
              ),
              const SizedBox(width: 32),
              _buildRoundRadio(
                label: 'Perempuan',
                isSelected: _data.gender == 'Perempuan',
                onTap: () => setState(() => _data.gender = 'Perempuan'),
              ),
            ],
          ),
        ),

        // Question: Usia
        _buildQuestionCard(
          title: 'Usia',
          child: Row(
            children: [
              _buildNumberInputField(
                controller: _ageController,
                hintText: '23',
                maxWidth: 90,
              ),
              const SizedBox(width: 12),
              Text(
                'Tahun',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textDark,
                ),
              ),
            ],
          ),
        ),

        // Question: Tinggi Badan
        _buildQuestionCard(
          title: 'Tinggi Badan',
          child: Row(
            children: [
              _buildNumberInputField(
                controller: _heightController,
                hintText: '165',
                maxWidth: 90,
              ),
              const SizedBox(width: 12),
              Text(
                'cm',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textDark,
                ),
              ),
            ],
          ),
        ),

        // Question: Berat Badan
        _buildQuestionCard(
          title: 'Berat Badan',
          child: Row(
            children: [
              _buildNumberInputField(
                controller: _weightController,
                hintText: '72',
                maxWidth: 90,
              ),
              const SizedBox(width: 12),
              Text(
                'Kg',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =================== STEP 2: RIWAYAT KELUARGA & POLA MAKAN ===================
  Widget _buildStep2RiwayatPolaMakan() {
    return Column(
      children: [
        _buildQuestionCard(
          title: 'Apakah ada anggota keluarga yang mengalami kelebihan berat badan atau obesitas?',
          child: Row(
            children: [
              _buildRoundRadio(
                label: 'Ya',
                isSelected: _data.familyHistory == 'Ya',
                onTap: () => setState(() => _data.familyHistory = 'Ya'),
              ),
              const SizedBox(width: 32),
              _buildRoundRadio(
                label: 'Tidak',
                isSelected: _data.familyHistory == 'Tidak',
                onTap: () => setState(() => _data.familyHistory = 'Tidak'),
              ),
            ],
          ),
        ),
        _buildQuestionCard(
          title: 'Apakah anda sering mengonsumsi makanan berkalori tinggi?',
          child: Row(
            children: [
              _buildRoundRadio(
                label: 'Ya',
                isSelected: _data.highCalorieFood == 'Ya',
                onTap: () => setState(() => _data.highCalorieFood = 'Ya'),
              ),
              const SizedBox(width: 32),
              _buildRoundRadio(
                label: 'Tidak',
                isSelected: _data.highCalorieFood == 'Tidak',
                onTap: () => setState(() => _data.highCalorieFood = 'Tidak'),
              ),
            ],
          ),
        ),
        _buildQuestionCard(
          title: 'Seberapa sering Anda mengonsumsi sayuran dalam sehari?',
          child: Wrap(
            spacing: 20,
            runSpacing: 10,
            children: [
              _buildRoundRadio(
                label: 'Jarang',
                isSelected: _data.vegetableIntake == 'Jarang',
                onTap: () => setState(() => _data.vegetableIntake = 'Jarang'),
              ),
              _buildRoundRadio(
                label: 'Kadang-kadang',
                isSelected: _data.vegetableIntake == 'Kadang-kadang',
                onTap: () => setState(() => _data.vegetableIntake = 'Kadang-kadang'),
              ),
              _buildRoundRadio(
                label: 'Sering',
                isSelected: _data.vegetableIntake == 'Sering',
                onTap: () => setState(() => _data.vegetableIntake = 'Sering'),
              ),
            ],
          ),
        ),
        _buildQuestionCard(
          title: 'Berapa kali Anda mengonsumsi makanan utama dalam sehari?',
          child: Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              _buildRoundRadio(
                label: '1 kali',
                isSelected: _data.mainMealFrequency == '1 kali',
                onTap: () => setState(() => _data.mainMealFrequency = '1 kali'),
              ),
              _buildRoundRadio(
                label: '2 kali',
                isSelected: _data.mainMealFrequency == '2 kali',
                onTap: () => setState(() => _data.mainMealFrequency = '2 kali'),
              ),
              _buildRoundRadio(
                label: '3 kali',
                isSelected: _data.mainMealFrequency == '3 kali',
                onTap: () => setState(() => _data.mainMealFrequency = '3 kali'),
              ),
              _buildRoundRadio(
                label: '4 kali atau lebih',
                isSelected: _data.mainMealFrequency == '4 kali atau lebih',
                onTap: () => setState(() => _data.mainMealFrequency = '4 kali atau lebih'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =================== STEP 3: KEBIASAAN & GAYA HIDUP ===================
  Widget _buildStep3KebiasaanGayaHidup() {
    return Column(
      children: [
        _buildQuestionCard(
          title: 'Seberapa sering Anda mengonsumsi camilan di antara waktu makan?',
          child: Wrap(
            spacing: 14,
            runSpacing: 10,
            children: [
              _buildRoundRadio(
                label: 'Tidak pernah',
                isSelected: _data.snackFrequency == 'Tidak pernah',
                onTap: () => setState(() => _data.snackFrequency = 'Tidak pernah'),
              ),
              _buildRoundRadio(
                label: 'Kadang-kadang',
                isSelected: _data.snackFrequency == 'Kadang-kadang',
                onTap: () => setState(() => _data.snackFrequency = 'Kadang-kadang'),
              ),
              _buildRoundRadio(
                label: 'Sering',
                isSelected: _data.snackFrequency == 'Sering',
                onTap: () => setState(() => _data.snackFrequency = 'Sering'),
              ),
              _buildRoundRadio(
                label: 'Selalu',
                isSelected: _data.snackFrequency == 'Selalu',
                onTap: () => setState(() => _data.snackFrequency = 'Selalu'),
              ),
            ],
          ),
        ),
        _buildQuestionCard(
          title: 'Apakah Anda merokok?',
          child: Row(
            children: [
              _buildRoundRadio(
                label: 'Ya',
                isSelected: _data.smoking == 'Ya',
                onTap: () => setState(() => _data.smoking = 'Ya'),
              ),
              const SizedBox(width: 32),
              _buildRoundRadio(
                label: 'Tidak',
                isSelected: _data.smoking == 'Tidak',
                onTap: () => setState(() => _data.smoking = 'Tidak'),
              ),
            ],
          ),
        ),
        _buildQuestionCard(
          title: 'Berapa banyak air putih yang Anda konsumsi setiap hari?',
          child: Wrap(
            spacing: 20,
            runSpacing: 10,
            children: [
              _buildRoundRadio(
                label: '<1 Liter',
                isSelected: _data.waterIntake == '<1 Liter',
                onTap: () => setState(() => _data.waterIntake = '<1 Liter'),
              ),
              _buildRoundRadio(
                label: '1-2 Liter',
                isSelected: _data.waterIntake == '1-2 Liter',
                onTap: () => setState(() => _data.waterIntake = '1-2 Liter'),
              ),
              _buildRoundRadio(
                label: '>2 Liter',
                isSelected: _data.waterIntake == '>2 Liter',
                onTap: () => setState(() => _data.waterIntake = '>2 Liter'),
              ),
            ],
          ),
        ),
        _buildQuestionCard(
          title: 'Apakah Anda memantau jumlah kalori yang dikonsumsi?',
          child: Row(
            children: [
              _buildRoundRadio(
                label: 'Ya',
                isSelected: _data.monitorCalories == 'Ya',
                onTap: () => setState(() => _data.monitorCalories = 'Ya'),
              ),
              const SizedBox(width: 32),
              _buildRoundRadio(
                label: 'Tidak',
                isSelected: _data.monitorCalories == 'Tidak',
                onTap: () => setState(() => _data.monitorCalories = 'Tidak'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =================== STEP 4: AKTIFITAS FISIK ===================
  Widget _buildStep4AktifitasFisik() {
    return Column(
      children: [
        _buildQuestionCard(
          title: 'Seberapa sering Anda melakukan aktivitas fisik dalam seminggu?',
          child: Wrap(
            spacing: 14,
            runSpacing: 10,
            children: [
              _buildRoundRadio(
                label: 'Tidak pernah',
                isSelected: _data.physicalActivity == 'Tidak pernah',
                onTap: () => setState(() => _data.physicalActivity = 'Tidak pernah'),
              ),
              _buildRoundRadio(
                label: 'Kadang-kadang',
                isSelected: _data.physicalActivity == 'Kadang-kadang',
                onTap: () => setState(() => _data.physicalActivity = 'Kadang-kadang'),
              ),
              _buildRoundRadio(
                label: 'Sering',
                isSelected: _data.physicalActivity == 'Sering',
                onTap: () => setState(() => _data.physicalActivity = 'Sering'),
              ),
              _buildRoundRadio(
                label: 'Selalu',
                isSelected: _data.physicalActivity == 'Selalu',
                onTap: () => setState(() => _data.physicalActivity = 'Selalu'),
              ),
            ],
          ),
        ),
        _buildQuestionCard(
          title: 'Berapa lama Anda menggunakan perangkat seperti HP, komputer, laptop atau TV dalam sehari?',
          child: Wrap(
            spacing: 20,
            runSpacing: 10,
            children: [
              _buildRoundRadio(
                label: '<1 Jam',
                isSelected: _data.screenTime == '<1 Jam',
                onTap: () => setState(() => _data.screenTime = '<1 Jam'),
              ),
              _buildRoundRadio(
                label: '1-2 Jam',
                isSelected: _data.screenTime == '1-2 Jam',
                onTap: () => setState(() => _data.screenTime = '1-2 Jam'),
              ),
              _buildRoundRadio(
                label: '>2 Jam',
                isSelected: _data.screenTime == '>2 Jam',
                onTap: () => setState(() => _data.screenTime = '>2 Jam'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =================== STEP 5: ALKOHOL & TRANSPORTASI ===================
  Widget _buildStep5AlkoholTransportasi() {
    return Column(
      children: [
        _buildQuestionCard(
          title: 'Seberapa sering Anda mengonsumsi minuman beralkohol?',
          child: Wrap(
            spacing: 14,
            runSpacing: 10,
            children: [
              _buildRoundRadio(
                label: 'Tidak pernah',
                isSelected: _data.alcohol == 'Tidak pernah',
                onTap: () => setState(() => _data.alcohol = 'Tidak pernah'),
              ),
              _buildRoundRadio(
                label: 'Kadang-kadang',
                isSelected: _data.alcohol == 'Kadang-kadang',
                onTap: () => setState(() => _data.alcohol = 'Kadang-kadang'),
              ),
              _buildRoundRadio(
                label: 'Sering',
                isSelected: _data.alcohol == 'Sering',
                onTap: () => setState(() => _data.alcohol = 'Sering'),
              ),
              _buildRoundRadio(
                label: 'Selalu',
                isSelected: _data.alcohol == 'Selalu',
                onTap: () => setState(() => _data.alcohol = 'Selalu'),
              ),
            ],
          ),
        ),
        _buildQuestionCard(
          title: 'Apa transportasi yang paling sering Anda gunakan untuk bepergian?',
          child: Wrap(
            spacing: 18,
            runSpacing: 12,
            children: [
              _buildRoundRadio(
                label: 'Jalan kaki',
                isSelected: _data.transportation == 'Jalan kaki',
                onTap: () => setState(() => _data.transportation = 'Jalan kaki'),
              ),
              _buildRoundRadio(
                label: 'Sepeda',
                isSelected: _data.transportation == 'Sepeda',
                onTap: () => setState(() => _data.transportation = 'Sepeda'),
              ),
              _buildRoundRadio(
                label: 'Motor',
                isSelected: _data.transportation == 'Motor',
                onTap: () => setState(() => _data.transportation = 'Motor'),
              ),
              _buildRoundRadio(
                label: 'Mobil',
                isSelected: _data.transportation == 'Mobil',
                onTap: () => setState(() => _data.transportation = 'Mobil'),
              ),
              _buildRoundRadio(
                label: 'Transportasi\numum',
                isSelected: _data.transportation == 'Transportasi umum',
                onTap: () => setState(() => _data.transportation = 'Transportasi umum'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =================== COMMON QUESTION CARD ===================
  Widget _buildQuestionCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: textDark,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  // =================== CUSTOM ROUND RADIO (CHECKLIST) ===================
  Widget _buildRoundRadio({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Custom Circle
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? activeGreen : const Color(0xFF94A3B8),
                  width: isSelected ? 2 : 1.5,
                ),
                color: Colors.white,
              ),
              alignment: Alignment.center,
              child: isSelected
                  ? Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: activeGreen,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                color: textDark,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =================== NUMBER INPUT FIELD ===================
  Widget _buildNumberInputField({
    required TextEditingController controller,
    required String hintText,
    double maxWidth = 90,
  }) {
    return Container(
      width: maxWidth,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cardBorder, width: 1.0),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*[\,\.]?\d*')),
        ],
        style: GoogleFonts.poppins(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(
            fontSize: 13,
            color: const Color(0xFFCBD5E1),
          ),
        ),
      ),
    );
  }

  // =================== ACTION BUTTON ===================
  Widget _buildActionButton() {
    final isValid = _isCurrentStepValid;
    final isLastStep = _currentStep == 4;
    final buttonText = isLastStep ? 'Lihat Hasil' : 'Berikutnya';

    return Center(
      child: ElevatedButton(
        onPressed: isValid ? _onNextPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          disabledBackgroundColor: const Color(0xFFD1D5DB),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              buttonText,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
