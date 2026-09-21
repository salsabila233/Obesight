import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../auth/login_screen.dart';
import 'health_article_list_screen.dart';
import 'health_article_detail_screen.dart';

class UserHomeScreen extends StatefulWidget {
  final UserModel user;

  const UserHomeScreen({
    super.key,
    required this.user,
  });

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _selectedTabIndex = 0; // 0: Home, 1: Stats, 2: Settings
  bool _isLoadingBiodata = true;
  late bool _isBiodataComplete;
  late String _currentUserName;
  late double _currentBmi;
  late String _currentBmiCategory;
  late String _currentObesityRisk;

  @override
  void initState() {
    super.initState();
    _currentUserName = widget.user.name;
    _isBiodataComplete = widget.user.isBiodataComplete || AuthService().isBiodataCompleted(widget.user.id);
    
    final bmiInfo = AuthService().getUserBmi(widget.user.id);
    _currentBmi = (bmiInfo['bmi'] as num?)?.toDouble() ?? widget.user.bmiScore;
    _currentBmiCategory = (bmiInfo['category'] as String?) ?? widget.user.bmiCategory;
    _currentObesityRisk = (bmiInfo['risk'] as String?) ?? widget.user.obesityRisk;

    // Brief check (300ms) to ensure smooth anti-flicker loading
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isLoadingBiodata = false;
        });
      }
    });
  }

  Color _getBmiStatusColor(double bmi) {
    if (bmi < 18.5) return const Color(0xFF0284C7);
    if (bmi <= 22.9) return const Color(0xFF16A34A);
    if (bmi <= 24.9) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  Map<String, String> _classifyBmi(double bmi) {
    if (bmi < 18.5) {
      return {'category': 'Kurus (Kekurangan Berat)', 'risk': 'Rendah'};
    } else if (bmi <= 22.9) {
      return {'category': 'Normal (Berat Ideal)', 'risk': 'Rendah'};
    } else if (bmi <= 24.9) {
      return {'category': 'Kelebihan Berat Badan', 'risk': 'Sedang'};
    } else {
      return {'category': 'Obesitas', 'risk': 'Tinggi'};
    }
  }

  String get _userFirstName {
    final name = _currentUserName.trim();
    if (name.isEmpty) return 'Zahra';
    return name.split(' ').first;
  }

  void _handleLogout(BuildContext context) {
    AuthService().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showProfileModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: const Color(0xFF4EA07E),
                      child: Text(
                        _userFirstName.isNotEmpty ? _userFirstName[0].toUpperCase() : 'Z',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.user.name,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            widget.user.email,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded, color: Color(0xFF334155)),
                  title: Text(
                    'Lengkapi Biodata',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showBiodataModal();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
                  title: Text(
                    'Keluar Akun',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _handleLogout(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showScreeningModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.bottom: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5EE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'SKRINING KESEHATAN',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF36785A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Deteksi Risiko Obesitas',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Jawab pertanyaan berikut untuk menilai pola hidup dan tingkat risiko obesitas Anda.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildQuestionItem('1. Frekuensi konsumsi makanan cepat saji atau minuman manis?', [
                    'Jarang (1-2x per bulan)',
                    'Kadang-kadang (1-2x per minggu)',
                    'Sering (>3x per minggu)',
                  ]),
                  _buildQuestionItem('2. Durasi aktivitas fisik / olahraga dalam seminggu?', [
                    'Lebih dari 150 menit / minggu',
                    'Kurang dari 150 menit / minggu',
                    'Hampir tidak pernah olahraga',
                  ]),
                  _buildQuestionItem('3. Rata-rata jam tidur malam?', [
                    'Cukup (7 - 8 jam)',
                    'Kurang (<6 jam)',
                  ]),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00874A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Hasil Skrining: Risiko Rendah. Pola hidup Anda sudah baik!',
                            style: GoogleFonts.poppins(),
                          ),
                          backgroundColor: const Color(0xFF16A34A),
                        ),
                      );
                    },
                    child: Text(
                      'Lihat Hasil Skrining',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuestionItem(String question, List<String> options) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          ...options.map((opt) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    const Icon(Icons.radio_button_checked, size: 16, color: Color(0xFF36785A)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        opt,
                        style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF475569)),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  void _showBmiCalculatorModal() {
    final heightController = TextEditingController(text: '165');
    final weightController = TextEditingController(text: '58');
    double calculatedBmi = _currentBmi;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final classification = _classifyBmi(calculatedBmi);
            final statusColor = _getBmiStatusColor(calculatedBmi);

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Kalkulator IMT',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: heightController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Tinggi Badan (cm)',
                            labelStyle: GoogleFonts.poppins(fontSize: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: weightController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Berat Badan (kg)',
                            labelStyle: GoogleFonts.poppins(fontSize: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          calculatedBmi.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                        Text(
                          classification['category']!,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Risiko Obesitas: ${classification['risk']!}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF374151),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00874A),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final h = double.tryParse(heightController.text) ?? 165;
                      final w = double.tryParse(weightController.text) ?? 58;
                      final hM = h / 100;
                      final newBmi = double.parse((w / (hM * hM)).toStringAsFixed(1));
                      final c = _classifyBmi(newBmi);
                      final cat = c['category']!;
                      final risk = c['risk']!;

                      setModalState(() {
                        calculatedBmi = newBmi;
                      });

                      AuthService().updateUserBmi(
                        userId: widget.user.id,
                        bmi: newBmi,
                        category: cat.contains('Normal') ? 'Normal' : (cat.contains('Kurus') ? 'Kurus' : (cat.contains('Kelebihan') ? 'Overweight' : 'Obesitas')),
                        risk: risk,
                      );

                      setState(() {
                        _currentBmi = newBmi;
                        _currentBmiCategory = cat.contains('Normal') ? 'Normal' : (cat.contains('Kurus') ? 'Kurus' : (cat.contains('Kelebihan') ? 'Overweight' : 'Obesitas'));
                        _currentObesityRisk = risk;
                      });
                    },
                    child: Text(
                      'Hitung Ulang & Terapkan',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showBiodataModal() {
    final nameCtrl = TextEditingController(text: _currentUserName);
    final ageCtrl = TextEditingController(text: '22');
    final heightCtrl = TextEditingController(text: '165');
    final weightCtrl = TextEditingController(text: '58');
    String selectedGender = 'Perempuan';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Lengkapi Biodata Anda',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded, size: 22),
                          color: const Color(0xFF64748B),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nama Lengkap',
                        labelStyle: GoogleFonts.poppins(fontSize: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: ageCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Usia (Tahun)',
                              labelStyle: GoogleFonts.poppins(fontSize: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedGender,
                            decoration: InputDecoration(
                              labelText: 'Jenis Kelamin',
                              labelStyle: GoogleFonts.poppins(fontSize: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Perempuan', child: Text('Perempuan')),
                              DropdownMenuItem(value: 'Laki-laki', child: Text('Laki-laki')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() => selectedGender = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: heightCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Tinggi (cm)',
                              labelStyle: GoogleFonts.poppins(fontSize: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: weightCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Berat (kg)',
                              labelStyle: GoogleFonts.poppins(fontSize: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00874A),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        final updatedName = nameCtrl.text.trim();
                        AuthService().updateBiodataStatus(
                          userId: widget.user.id,
                          isComplete: true,
                          name: updatedName.isNotEmpty ? updatedName : widget.user.name,
                        );
                        setState(() {
                          _isBiodataComplete = true;
                          if (updatedName.isNotEmpty) {
                            _currentUserName = updatedName;
                          }
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Biodata berhasil diperbarui!', style: GoogleFonts.poppins()),
                            backgroundColor: const Color(0xFF16A34A),
                          ),
                        );
                      },
                      child: Text('Simpan Perubahan', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showArticleDetail(String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollCtrl) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollCtrl,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.bottom: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '⏱️ 3 Menit Baca • Ditinjau Tim Medis ObeSight',
                    style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    content,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      height: 1.6,
                      color: const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6F9),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Main Content Area
            Column(
              children: [
                // 2. Header Top Bar
                _buildHeaderTopBar(),

                // Scrollable Body
                Expanded(
                  child: IndexedStack(
                    index: _selectedTabIndex,
                    children: [
                      _buildHomeTab(),
                      _buildStatsTab(),
                      _buildSettingsTab(),
                    ],
                  ),
                ),
              ],
            ),

            // 7. Floating Custom Bottom Navigation Bar
            Positioned(
              left: 20,
              right: 20,
              bottom: 16,
              child: _buildFloatingBottomNav(),
            ),
          ],
        ),
      ),
    );
  }

  // 2. Header Top Bar
  Widget _buildHeaderTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo ObeSight
          Row(
            children: [
              Image.asset('assets/logo.png', width: 32, height: 32),
              const SizedBox(width: 8),
              Text(
                'ObeSight',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF36785A),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),

          // Profile Avatar Icon Button
          GestureDetector(
            onTap: _showProfileModal,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2D6A4F), width: 2),
                color: Colors.white,
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 24,
                color: Color(0xFF2D6A4F),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Main Home Tab Content with Subtle Ambient Health Decorations
  Widget _buildHomeTab() {
    return Stack(
      children: [
        // Subtle Ambient Minimalist Health Decorations
        Positioned.fill(
          child: IgnorePointer(
            child: Stack(
              children: [
                // Soft botanical leaf in top right
                Positioned(
                  top: 12,
                  right: 18,
                  child: Opacity(
                    opacity: 0.05,
                    child: Icon(
                      Icons.eco_rounded,
                      size: 96,
                      color: const Color(0xFF368260),
                    ),
                  ),
                ),
                // Soft heartbeat pulse wave accent
                Positioned(
                  top: 310,
                  left: -15,
                  child: Opacity(
                    opacity: 0.045,
                    child: Icon(
                      Icons.monitor_heart_outlined,
                      size: 110,
                      color: const Color(0xFF2D6A4F),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Scrollable Home Content
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // 1. Greeting Section
          _buildGreetingSection(),

          const SizedBox(height: 16),

          // 2. Banner Skrining Obesitas
          _buildScreeningSection(),

          const SizedBox(height: 12),

          // 3. Conditional Card Lengkapi Biodata (Tampil jika belum lengkap)
          _buildReminderCard(),

          // 4. Baris Menu Ikon (Skrining Obesitas, Kalkulator IMT, Progress, Riwayat Skrining)
          _buildMenuIconsRow(),

          const SizedBox(height: 20),

          // 5. Section Status Kesehatan (IMT & Risiko Obesitas)
          _buildHealthStatusCard(),

          const SizedBox(height: 22),

          // 6. Section Artikel Kesehatan (Horizontal Scroll Bar)
          _buildArticlesSection(),

          // Space for floating bottom nav
          const SizedBox(height: 90),
        ],
      ),
    ));
  }

  // 1. Greeting Section
  Widget _buildGreetingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Halo, $_userFirstName! 👋',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Langkah kecil hari ini, berdampak besar untuk kesehatanmu :)',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  // 2. Section Banner Skrining Obesitas
  Widget _buildScreeningSection() {
    return GestureDetector(
      onTap: _showScreeningModal,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4EA07D), Color(0xFF368260)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF368260).withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Skrining Risiko\nObesitas',
                    style: GoogleFonts.poppins(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kenali tingkat risiko obesitas berdasarka pola hidupmu.',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Illustration container matching the design art
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 20,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFF368260),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...List.generate(3, (i) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.check_rounded, size: 8, color: Color(0xFF16A34A)),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Container(
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFCBD5E1),
                                    borderRadius: BorderRadius.circular(1.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Color(0xFF368260),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. Conditional Reminder Card: Lengkapi Biodata
  Widget _buildReminderCard() {
    if (_isLoadingBiodata) {
      return const SizedBox(height: 4);
    }

    if (_isBiodataComplete) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: _showBiodataModal,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF4F1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF00874A).withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFF4EA07E),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Lengkapi biodata kamu dulu agar hasil skrining lebih akurat dan sesuai dengan kondisi kamu.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF334155),
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF1E293B),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 4. Baris Menu Ikon (4 Kolom)
  Widget _buildMenuIconsRow() {
    final items = [
      {
        'title': 'Skrining\nObesitas',
        'icon': Icons.search_rounded,
        'action': _showScreeningModal,
      },
      {
        'title': 'Kalkulator\nIMT',
        'icon': Icons.calculate_outlined,
        'action': _showBmiCalculatorModal,
      },
      {
        'title': 'Progress',
        'icon': Icons.history_rounded,
        'action': () {
          setState(() {
            _selectedTabIndex = 1;
          });
        },
      },
      {
        'title': 'Riwayat\nSkrining',
        'icon': Icons.monitor_heart_outlined,
        'action': () {
          setState(() {
            _selectedTabIndex = 1;
          });
        },
      },
    ];

    return Row(
      children: items.map((item) {
        return Expanded(
          child: GestureDetector(
            onTap: item['action'] as VoidCallback,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE2F1E8),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF368260).withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item['icon'] as IconData,
                    size: 28,
                    color: const Color(0xFF2E6B4F),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['title'] as String,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E4534),
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // 5. Section Status Kesehatan
  Widget _buildHealthStatusCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status Kesehatan',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              children: [
                // Kolom IMT
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5EE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.calculate_outlined,
                          color: Color(0xFF2E6B4F),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'IMT',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            _currentBmi.toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                              height: 1.15,
                            ),
                          ),
                          Text(
                            _currentBmiCategory,
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: _getBmiStatusColor(_currentBmi),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Divider vertikal
                Container(
                  width: 1,
                  height: 48,
                  color: const Color(0xFFE2E8F0),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                ),
                // Kolom Risiko Obesitas
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5EE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.directions_walk_rounded,
                          color: Color(0xFF2E6B4F),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Risiko Obesitas',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _currentObesityRisk,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _getBmiStatusColor(_currentBmi),
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
        ],
      ),
    );
  }

  // 6. Section Artikel Kesehatan (Horizontal Scroll Bar)
  Widget _buildArticlesSection() {
    final articles = [
      {
        'title': '5 Pola Makan Sehat Cegah Obesitas',
        'color': const Color(0xFF7E96AC),
        'icon': Icons.restaurant_menu_rounded,
        'content':
            'Menerapkan pola makan sehat merupakan fondasi utama dalam mencegah obesitas: perbanyak serat sayuran, batasi gula-garam-lemak (GGL), sarapan bergizi, minum 2 liter air, dan mindful eating.',
      },
      {
        'title': 'Porsi Piring Gizi Seimbang Kemenkes',
        'color': const Color(0xFFE5BD87),
        'icon': Icons.pie_chart_outline_rounded,
        'content':
            'Konsep Isi Piringku Kemenkes: 1/3 makanan pokok karbohidrat, 1/3 aneka ragam sayuran, 1/6 lauk pauk protein, dan 1/6 buah-buahan segar.',
      },
      {
        'title': 'Isi Piringku: Pedoman Sehari-hari',
        'color': const Color(0xFF58B29C),
        'icon': Icons.eco_outlined,
        'content':
            'Keseimbangan nutrisi makro dan mikro sehari-hari membantu mengoptimalkan metabolisme dan menjaga berat badan tetap stabil.',
      },
      {
        'title': 'Aktivitas Fisik Ringan Pembakar Kalori',
        'color': const Color(0xFF818CF8),
        'icon': Icons.directions_run_rounded,
        'content':
            'Jalan kaki 30 menit per hari membakar hingga 200 kalori. Kombinasikan naik tangga dan peregangan berkala.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Artikel Kesehatan',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const HealthArticleListScreen(),
                  ),
                );
              },
              child: Row(
                children: [
                  Text(
                    'Selengkapnya',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF36785A),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF36785A)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Horizontal ListView / SingleChildScrollView
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: articles.map((art) {
              return GestureDetector(
                onTap: () => _showArticleDetail(art['title'] as String, art['content'] as String),
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 80,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: art['color'] as Color,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: Center(
                          child: Icon(
                            art['icon'] as IconData,
                            size: 34,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              art['title'] as String,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F172A),
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2F1E8),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Edukasi',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF2E6B4F),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // 7. Custom Floating Bottom Navigation Bar
  Widget _buildFloatingBottomNav() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF489874),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E6B4F).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Tab 0: Home
          _buildNavItem(
            index: 0,
            icon: Icons.home_rounded,
            activeIcon: Icons.home_rounded,
          ),

          // Tab 1: Stats
          _buildNavItem(
            index: 1,
            icon: Icons.bar_chart_rounded,
            activeIcon: Icons.bar_chart_rounded,
          ),

          // Tab 2: Settings
          _buildNavItem(
            index: 2,
            icon: Icons.settings_rounded,
            activeIcon: Icons.settings_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
  }) {
    final isActive = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isActive ? 44 : 36,
        height: isActive ? 38 : 36,
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withValues(alpha: 0.28) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          isActive ? activeIcon : icon,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }

  // Tab 1: Stats
  Widget _buildStatsTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistik & Analisis',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Grafik dan riwayat skrining berkala Anda.',
            style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Indeks Massa Tubuh (BMI)',
                  style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 4),
                Text(
                  '21.4 kg/m²',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF36785A),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Status: Berat Badan Normal / Ideal',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tab 2: Settings
  Widget _buildSettingsTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pengaturan',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kelola akun dan preferensi aplikasi.',
            style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            tileColor: Colors.white,
            leading: const Icon(Icons.person_outline_rounded, color: Color(0xFF36785A)),
            title: Text(
              'Profil & Biodata',
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text('Edit tinggi, berat & usia', style: GoogleFonts.poppins(fontSize: 11.5)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _showBiodataModal,
          ),
          const SizedBox(height: 12),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            tileColor: Colors.white,
            leading: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
            title: Text(
              'Keluar dari Akun',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFDC2626),
              ),
            ),
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }
}
