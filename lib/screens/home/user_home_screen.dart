import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/article_service.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/complete_profile_screen.dart';
import '../settings/settings_screen.dart';
import '../progress/progress_screen.dart';
import '../progress/screening_history_screen.dart';
import '../article/health_article_list_screen.dart';
import '../article/health_article_detail_screen.dart';
import 'imt_form_screen.dart';
import '../skrining/skrining_landing_screen.dart';

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

    // Listen to real-time profile updates across screens
    AuthService().profileUpdateNotifier.addListener(_syncUserData);

    // Brief check (300ms) to ensure smooth anti-flicker loading
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isLoadingBiodata = false;
        });
      }
    });
  }

  @override
  void dispose() {
    AuthService().profileUpdateNotifier.removeListener(_syncUserData);
    super.dispose();
  }

  void _syncUserData() {
    final profile = AuthService().getUserProfile(widget.user.id);
    final bmiInfo = AuthService().getUserBmi(widget.user.id);
    if (mounted) {
      setState(() {
        _currentUserName = profile['name'] ?? widget.user.name;
        _currentBmi = (bmiInfo['bmi'] as num?)?.toDouble() ?? _currentBmi;
        _currentBmiCategory = (bmiInfo['category'] as String?) ?? _currentBmiCategory;
        _currentObesityRisk = (bmiInfo['risk'] as String?) ?? _currentObesityRisk;
        _isBiodataComplete = AuthService().isBiodataCompleted(widget.user.id);
      });
    }
  }

  Color _getBmiStatusColor(double bmi) {
    if (bmi < 18.5) return const Color(0xFF0284C7);
    if (bmi <= 22.9) return const Color(0xFF16A34A);
    if (bmi <= 24.9) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
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

  Future<void> _showScreeningModal() async {
    // BAGIAN 4: Sistem Penjagaan (Gating) Skrining
    // Pengguna TIDAK BOLEH mengakses Skrining sebelum Tanggal Lahir, Jenis Kelamin, dan Nomor Telepon lengkap
    final isGatedComplete = await AuthService().checkProfileGating(widget.user.id);

    if (!isGatedComplete) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lengkapi data diri (Tanggal Lahir, Jenis Kelamin, Nomor Telepon) terlebih dahulu sebelum mengakses skrining.',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: const Color(0xFFD97706),
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Redirect otomatis ke Halaman "Lengkapi Profil"
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CompleteProfileScreen(
            user: widget.user,
            isGatedFlow: true,
          ),
        ),
      );
      if (mounted) {
        _syncUserData();
      }
      return;
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SkriningLandingScreen(user: widget.user),
      ),
    ).then((_) {
      if (mounted) {
        _syncUserData();
      }
    });
  }

  void _openBmiCalculationScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ImtFormScreen(user: widget.user),
      ),
    );
    if (mounted) {
      final bmiInfo = AuthService().getUserBmi(widget.user.id);
      setState(() {
        _currentBmi = (bmiInfo['bmi'] as num?)?.toDouble() ?? _currentBmi;
        _currentBmiCategory = (bmiInfo['category'] as String?) ?? _currentBmiCategory;
        _currentObesityRisk = (bmiInfo['risk'] as String?) ?? _currentObesityRisk;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF2F6F9),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Main Content Area
            Column(
              children: [
                // 2. Header Top Bar
                _buildHeaderTopBar(isDark),

                // Scrollable Body
                Expanded(
                  child: IndexedStack(
                    index: _selectedTabIndex,
                    children: [
                      _buildHomeTab(isDark),
                      _buildStatsTab(isDark),
                      _buildSettingsTab(isDark),
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
              child: _buildFloatingBottomNav(isDark),
            ),
          ],
        ),
      ),
    );
  }

  // Real-time Header Avatar Widget (BAGIAN 3)
  Widget _buildHeaderAvatar() {
    final profile = AuthService().getUserProfile(widget.user.id);
    final photoPath = profile['photo_path'];
    final isRemoved = profile['avatar'] == 'removed';

    if (!isRemoved && photoPath != null && photoPath.isNotEmpty) {
      if (photoPath.startsWith('http://') || photoPath.startsWith('https://')) {
        return Image.network(
          photoPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.person_rounded,
            size: 22,
            color: Color(0xFF2D6A4F),
          ),
        );
      }
      final file = File(photoPath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.person_rounded,
            size: 22,
            color: Color(0xFF2D6A4F),
          ),
        );
      }
    }

    if (isRemoved) {
      return const Icon(
        Icons.person_rounded,
        size: 22,
        color: Color(0xFF2D6A4F),
      );
    }

    return Image.asset(
      profile['avatar'] ?? 'assets/avatar_zahra.png',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const Icon(
        Icons.person_rounded,
        size: 22,
        color: Color(0xFF2D6A4F),
      ),
    );
  }

  // 2. Header Top Bar with real-time avatar and dark mode
  Widget _buildHeaderTopBar(bool isDark) {
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
                  color: isDark ? const Color(0xFF58AF86) : const Color(0xFF36785A),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),

          // Profile Avatar Icon Button - Synchronized in real-time
          GestureDetector(
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(user: widget.user),
                ),
              );
              _syncUserData();
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2D6A4F), width: 2),
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
              ),
              child: ClipOval(
                child: _buildHeaderAvatar(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Main Home Tab Content with Subtle Ambient Health Decorations
  Widget _buildHomeTab(bool isDark) {
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
                    opacity: isDark ? 0.08 : 0.05,
                    child: Icon(
                      Icons.eco_rounded,
                      size: 96,
                      color: isDark ? const Color(0xFF58AF86) : const Color(0xFF368260),
                    ),
                  ),
                ),
                // Soft heartbeat pulse wave accent
                Positioned(
                  top: 310,
                  left: -15,
                  child: Opacity(
                    opacity: isDark ? 0.07 : 0.045,
                    child: Icon(
                      Icons.monitor_heart_outlined,
                      size: 110,
                      color: isDark ? const Color(0xFF58AF86) : const Color(0xFF2D6A4F),
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
              _buildGreetingSection(isDark),

              const SizedBox(height: 16),

              // 2. Banner Skrining Obesitas
              _buildScreeningSection(),

              const SizedBox(height: 12),

              // 3. Conditional Card Lengkapi Biodata (Tampil jika belum lengkap)
              _buildReminderCard(isDark),

              // 4. Baris Menu Ikon (Skrining Obesitas, Kalkulator IMT, Progress, Riwayat Skrining)
              _buildMenuIconsRow(isDark),

              const SizedBox(height: 20),

              // 5. Section Status Kesehatan (IMT & Risiko Obesitas)
              _buildHealthStatusCard(isDark),

              const SizedBox(height: 22),

              // 6. Section Artikel Kesehatan (Horizontal Scroll Bar)
              _buildArticlesSection(isDark),

              const SizedBox(height: 90),
            ],
          ),
        ),
      ],
    );
  }

  // 1. Greeting Section
  Widget _buildGreetingSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Halo, $_userFirstName! 👋',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Langkah kecil hari ini, berdampak besar untuk kesehatanmu :)',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  // 2. Section Banner Skrining Obesitas (Tampilan Visual / Banner Informasi)
  Widget _buildScreeningSection() {
    return Container(
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
                  'Kenali tingkat risiko obesitas berdasarkan pola hidupmu.',
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
    );
  }

  // 3. Conditional Reminder Card: Lengkapi Biodata
  Widget _buildReminderCard(bool isDark) {
    if (_isLoadingBiodata) {
      return const SizedBox(height: 4);
    }

    if (_isBiodataComplete) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CompleteProfileScreen(
                user: widget.user,
                isGatedFlow: false,
              ),
            ),
          );
          _syncUserData();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF4F1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFF00874A).withValues(alpha: 0.1),
            ),
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
                    color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 4. Baris Menu Ikon (4 Kolom)
  Widget _buildMenuIconsRow(bool isDark) {
    final items = [
      {
        'title': 'Skrining\nObesitas',
        'icon': Icons.manage_search_rounded,
        'action': _showScreeningModal,
      },
      {
        'title': 'Kalkulator\nIMT',
        'icon': Icons.calculate_rounded,
        'action': _openBmiCalculationScreen,
      },
      {
        'title': 'Progress',
        'icon': Icons.trending_up_rounded,
        'action': () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProgressScreen(user: widget.user),
            ),
          );
        },
      },
      {
        'title': 'Riwayat\nSkrining',
        'icon': Icons.medical_information_rounded,
        'action': () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ScreeningHistoryScreen(),
            ),
          );
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
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2F1E8),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFF368260).withValues(alpha: 0.1),
                ),
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
                    color: isDark ? const Color(0xFF58AF86) : const Color(0xFF2E6B4F),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: Text(
                      item['title'] as String,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1E4534),
                        height: 1.2,
                      ),
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

  // 5. Section Status Kesehatan (Tampilan Informasi)
  Widget _buildHealthStatusCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
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
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Kolom IMT (dengan Expanded dan constraints aman)
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE8F5EE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.calculate_outlined,
                            color: isDark ? const Color(0xFF58AF86) : const Color(0xFF2E6B4F),
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'IMT',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                _currentBmi.toStringAsFixed(1),
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  height: 1.15,
                                ),
                              ),
                              Text(
                                _currentBmiCategory,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _getBmiStatusColor(_currentBmi),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Divider vertikal yang fleksibel
                  Container(
                    width: 1,
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  // Kolom Risiko Obesitas
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE8F5EE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.directions_walk_rounded,
                            color: isDark ? const Color(0xFF58AF86) : const Color(0xFF2E6B4F),
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Risiko Obesitas',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _currentObesityRisk,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
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
          ),
        ],
      ),
    );
  }

  // 6. Section Artikel Kesehatan (Horizontal Scroll Bar)
  Widget _buildArticlesSection(bool isDark) {
    final articles = ArticleService().getArticles();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Artikel Kesehatan',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const HealthArticleListScreen(),
                  ),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Selengkapnya',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF58AF86) : const Color(0xFF36785A),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: isDark ? const Color(0xFF58AF86) : const Color(0xFF36785A),
                  ),
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
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => HealthArticleDetailScreen(article: art),
                    ),
                  );
                },
                child: Container(
                  width: 156,
                  height: 182,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
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
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: SizedBox(
                          height: 95,
                          width: double.infinity,
                          child: Image.asset(
                            art.imageAsset,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: art.headerColor.withValues(alpha: 0.15),
                              child: Center(
                                child: Icon(art.icon, size: 36, color: art.headerColor),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                art.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  height: 1.3,
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF94A3B8)),
                                  const SizedBox(width: 4),
                                  Text(
                                    art.readTime,
                                    style: GoogleFonts.poppins(
                                      fontSize: 9.5,
                                      color: const Color(0xFF94A3B8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
  Widget _buildFloatingBottomNav(bool isDark) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFF489874),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : const Color(0xFF2E6B4F).withValues(alpha: 0.35),
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
            isDark: isDark,
          ),

          // Tab 1: Stats
          _buildNavItem(
            index: 1,
            icon: Icons.bar_chart_rounded,
            activeIcon: Icons.bar_chart_rounded,
            isDark: isDark,
          ),

          // Tab 2: Settings
          _buildNavItem(
            index: 2,
            icon: Icons.settings_rounded,
            activeIcon: Icons.settings_rounded,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required bool isDark,
  }) {
    final isActive = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 1) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProgressScreen(user: widget.user),
            ),
          );
        } else if (index == 2) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SettingsScreen(user: widget.user),
            ),
          );
        } else {
          setState(() {
            _selectedTabIndex = 0;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isActive ? 44 : 36,
        height: isActive ? 38 : 36,
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? const Color(0xFF334155) : Colors.white.withValues(alpha: 0.28))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          isActive ? activeIcon : icon,
          color: isDark
              ? (isActive ? const Color(0xFF58AF86) : const Color(0xFF94A3B8))
              : Colors.white,
          size: 22,
        ),
      ),
    );
  }

  // Tab 1: Stats
  Widget _buildStatsTab(bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistik & Analisis',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Grafik dan riwayat skrining berkala Anda.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Indeks Massa Tubuh (BMI)',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_currentBmi.toStringAsFixed(1)} kg/m²',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFF58AF86) : const Color(0xFF36785A),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Status: $_currentBmiCategory',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getBmiStatusColor(_currentBmi),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ProgressScreen(user: widget.user)),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                      : [const Color(0xFFE6F7F0), const Color(0xFFD4F1E4)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFC4ECDA),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFF36785A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.directions_run_rounded,
                      color: isDark ? const Color(0xFF58AF86) : Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pantau Progres & Aktivitas',
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF112A1F),
                          ),
                        ),
                        Text(
                          'Rekomendasi 5 aktivitas fisik harian',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF375347),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark ? const Color(0xFF58AF86) : const Color(0xFF36785A),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ScreeningHistoryScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.monitor_heart_rounded, color: Color(0xFFD97706), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lihat Riwayat Skrining',
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Linimasa hasil skrining risiko & IMT berkala',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tab 2: Settings
  Widget _buildSettingsTab(bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pengaturan',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kelola akun dan preferensi aplikasi.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            tileColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            leading: Icon(
              Icons.settings_outlined,
              color: isDark ? const Color(0xFF58AF86) : const Color(0xFF36785A),
            ),
            title: Text(
              'Pengaturan Lengkap',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            subtitle: Text(
              'Keamanan, sandi, email & info aplikasi',
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => SettingsScreen(user: widget.user)),
              );
            },
          ),
          const SizedBox(height: 12),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            tileColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            leading: Icon(
              Icons.person_outline_rounded,
              color: isDark ? const Color(0xFF58AF86) : const Color(0xFF36785A),
            ),
            title: Text(
              'Profil & Biodata',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            subtitle: Text(
              'Edit data pribadi & status biodata',
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ProfileScreen(user: widget.user)),
              );
              _syncUserData();
            },
          ),
          const SizedBox(height: 12),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            tileColor: isDark ? const Color(0xFF1E293B) : Colors.white,
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
