import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/article_model.dart';
import '../../models/user_model.dart';
import '../../services/article_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../admin/admin_change_password_sheet.dart';
import '../article/health_article_detail_screen.dart';
import '../auth/login_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  final UserModel user;

  const AdminHomeScreen({
    super.key,
    required this.user,
  });

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;
  final _authService = AuthService();
  final _articleService = ArticleService();

  late UserModel _currentUser;

  // Search & Filters for Tabs
  String _userSearchQuery = '';
  String _selectedRoleFilter = 'Semua';
  String _articleSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _refreshProfile();
  }

  Future<void> _refreshProfile() async {
    final updated = await _authService.fetchUserProfile(widget.user.id);
    if (updated != null && mounted) {
      setState(() {
        _currentUser = updated;
      });
    }
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Konfirmasi Keluar',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari sesi Administrator?',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(color: const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _authService.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Keluar',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _switchTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = AppColors.adminGreen;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF7FAF8),
      extendBody: true,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF7FAF8),
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            Image.asset(
              'assets/logo.png',
              width: 36,
              height: 36,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5EE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.eco_rounded, color: Color(0xFF267352), size: 20),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ObeSight',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF132F23),
                      letterSpacing: -0.3,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ADMIN CONSOLE',
                        style: GoogleFonts.poppins(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF64748B),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF267352).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'PANEL ADMINISTRATOR',
                            style: GoogleFonts.poppins(
                              fontSize: 7,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF267352),
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Circular Profile Icon Button (NO notification icon!)
          GestureDetector(
            onTap: () => _switchTab(4), // Go to Profile/Settings tab
            child: Container(
              margin: const EdgeInsets.only(right: 20),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5EE),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _currentIndex == 4 ? const Color(0xFF267352) : const Color(0xFFC7E2D5),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Color(0xFF267352),
                size: 22,
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildBerandaTab(isDark, primaryColor),
          _buildPenggunaTab(isDark, primaryColor),
          _buildArtikelTab(isDark, primaryColor),
          _buildLaporanTab(isDark, primaryColor),
          _buildPengaturanTab(isDark, primaryColor),
        ],
      ),
      bottomNavigationBar: _buildCapsuleBottomNav(isDark),
    );
  }

  // ===========================================================================
  // TAB 0: BERANDA ADMIN (Berdasarkan Gambar Referensi ObeSight)
  // ===========================================================================
  Widget _buildBerandaTab(bool isDark, Color primaryColor) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Greeting Section (Text on Left, Health Dashboard Illustration on Right)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Beranda',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F1E36),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Selamat datang, Admin! 👋',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F1E36),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Kelola dan pantau aktivitas ObeSight dalam satu tempat.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentUser.name,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF267352),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildHealthDashboardIllustration(isDark),
            ],
          ),

          const SizedBox(height: 16),

          // 2. Status Sistem Banner (Gradient Green Card)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF246B4D), Color(0xFF388E6B)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF246B4D).withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sistem berjalan dengan baik',
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Semua layanan dalam kondisi normal.',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. Statistik: Total Pengguna (Emerald) & Total Artikel (White) from Firestore
          Row(
            children: [
              // Total Pengguna Card (Emerald Green Card)
              Expanded(
                child: StreamBuilder<int>(
                  stream: _authService.getTotalUsersCountStream(),
                  initialData: 125,
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 125;
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF22674A), Color(0xFF2E805C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF22674A).withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            right: -6,
                            bottom: -6,
                            child: Icon(
                              Icons.people_alt_rounded,
                              size: 52,
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.people_alt_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Total Pengguna',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'Total Pasien',
                                          style: GoogleFonts.poppins(
                                            fontSize: 9,
                                            color: Colors.white.withValues(alpha: 0.75),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '$count',
                                style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '↑ 12%',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF22674A),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '+12 pengguna bulan ini',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(width: 14),

              // Total Artikel Card (Clean White Card)
              Expanded(
                child: StreamBuilder<int>(
                  stream: _authService.getTotalArticlesCountStream(),
                  initialData: 24,
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 24;
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            right: -6,
                            bottom: -6,
                            child: Icon(
                              Icons.article_rounded,
                              size: 52,
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.05),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.article_rounded,
                                      color: Color(0xFF2563EB),
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Total Artikel',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : const Color(0xFF0F1E36),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '$count',
                                style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF0F1E36),
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '↑ 8%',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF16A34A),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '18 dipublikasikan',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 4. Statistik Pengguna (7-day Activity Chart & New Users Summary)
          _buildUserStatsSection(isDark),

          const SizedBox(height: 18),

          // 5. Aktivitas Terbaru (Administrative Activity List)
          _buildRecentActivitiesSection(isDark),
        ],
      ),
    );
  }

  // Health Dashboard Illustration with stylized leaves and chart window
  Widget _buildHealthDashboardIllustration(bool isDark) {
    return SizedBox(
      width: 125,
      height: 105,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFD4EFE1).withValues(alpha: isDark ? 0.2 : 0.6),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 2,
            top: 6,
            child: Transform.rotate(
              angle: -0.3,
              child: Container(
                width: 22,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF88CCA9).withValues(alpha: 0.7),
                  borderRadius: const BorderRadius.all(Radius.elliptical(22, 44)),
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            bottom: 10,
            child: Transform.rotate(
              angle: 0.4,
              child: Container(
                width: 26,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF4FA87F).withValues(alpha: 0.8),
                  borderRadius: const BorderRadius.all(Radius.elliptical(26, 50)),
                ),
              ),
            ),
          ),
          Positioned(
            right: 4,
            top: 8,
            child: Container(
              width: 96,
              height: 78,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFD5E7DD),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 5, height: 5, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle)),
                      const SizedBox(width: 3),
                      Container(width: 5, height: 5, decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle)),
                      const SizedBox(width: 3),
                      Container(width: 5, height: 5, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                      const Spacer(),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(color: Color(0xFFD1FAE5), shape: BoxShape.circle),
                        child: const Icon(Icons.person, size: 7, color: Color(0xFF10B981)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 46,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(width: 8, height: 16, decoration: BoxDecoration(color: const Color(0xFFBCE3CE), borderRadius: BorderRadius.circular(2))),
                      Container(width: 8, height: 26, decoration: BoxDecoration(color: const Color(0xFF76C49B), borderRadius: BorderRadius.circular(2))),
                      Container(width: 8, height: 38, decoration: BoxDecoration(color: const Color(0xFF267352), borderRadius: BorderRadius.circular(2))),
                      Container(width: 8, height: 20, decoration: BoxDecoration(color: const Color(0xFF9BD4B7), borderRadius: BorderRadius.circular(2))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Statistik Pengguna Widget (7-day Activity Chart & New Users Summary)
  Widget _buildUserStatsSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5EE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.bar_chart_rounded,
                        color: Color(0xFF267352),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Statistik Pengguna',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F1E36),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '7 hari terakhir',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Left: 7-day Bar Chart with Y-axis markers
              Expanded(
                flex: 66,
                child: Column(
                  children: [
                    SizedBox(
                      height: 110,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('20', style: GoogleFonts.poppins(fontSize: 8.5, color: const Color(0xFF94A3B8))),
                                Text('15', style: GoogleFonts.poppins(fontSize: 8.5, color: const Color(0xFF94A3B8))),
                                Text('10', style: GoogleFonts.poppins(fontSize: 8.5, color: const Color(0xFF94A3B8))),
                                Text('5', style: GoogleFonts.poppins(fontSize: 8.5, color: const Color(0xFF94A3B8))),
                                Text('0', style: GoogleFonts.poppins(fontSize: 8.5, color: const Color(0xFF94A3B8))),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildChartBar('Sen', 6, 20, false),
                                _buildChartBar('Sel', 10, 20, false),
                                _buildChartBar('Rab', 8, 20, false),
                                _buildChartBar('Kam', 14, 20, false),
                                _buildChartBar('Jum', 11, 20, false),
                                _buildChartBar('Sab', 19, 20, true),
                                _buildChartBar('Min', 15, 20, false),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Right: New User Summary Box
              Expanded(
                flex: 34,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDCFCE7)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFDCFCE7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_add_alt_1_rounded,
                          color: Color(0xFF16A34A),
                          size: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '28',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F1E36),
                          height: 1.1,
                        ),
                      ),
                      Text(
                        'Pengguna baru',
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '↑ 17%',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'dibanding minggu lalu',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              color: const Color(0xFF64748B),
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
        ],
      ),
    );
  }

  Widget _buildChartBar(String day, double value, double maxValue, bool isHighlight) {
    final heightRatio = (value / maxValue).clamp(0.05, 1.0);
    const barHeight = 84.0;

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 10,
            height: barHeight * heightRatio,
            decoration: BoxDecoration(
              color: isHighlight ? const Color(0xFF267352) : const Color(0xFF86CCA9),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              day,
              style: GoogleFonts.poppins(
                fontSize: 9.0,
                color: const Color(0xFF64748B),
                fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 5. Aktivitas Terbaru Widget (Administrative Activities List from real Firestore data)
  Widget _buildRecentActivitiesSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5EE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.access_time_rounded,
                        color: Color(0xFF267352),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Aktivitas Terbaru',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F1E36),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _switchTab(1), // Go to Pengguna tab
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Lihat semua',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF267352),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Color(0xFF267352),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          StreamBuilder<List<UserModel>>(
            stream: _authService.getAllUsersStream(),
            builder: (context, userSnap) {
              return StreamBuilder<List<ArticleModel>>(
                stream: _articleService.getArticlesStream(),
                builder: (context, artSnap) {
                  final users = userSnap.data ?? [];
                  final articles = artSnap.data ?? [];

                  final firstUser = users.isNotEmpty ? users.first.name : 'Siti Aulia';
                  final secondUser = users.length > 1 ? users[1].name : 'Rizky';
                  final firstArt = articles.isNotEmpty ? articles.first.title : '5 pola makan seimbang untuk tubuh sehat';
                  final secondArt = articles.length > 1 ? articles[1].title : 'Tips menjaga pola makan sehat';

                  return Column(
                    children: [
                      _buildActivityTile(
                        icon: Icons.person_rounded,
                        iconBg: const Color(0xFFE8F5EE),
                        iconColor: const Color(0xFF16A34A),
                        title: 'Pengguna baru terdaftar',
                        subtitle: '$firstUser telah membuat akun',
                        time: '2 jam lalu',
                        isDark: isDark,
                        onTap: () => _switchTab(1),
                      ),
                      const SizedBox(height: 10),
                      _buildActivityTile(
                        icon: Icons.article_rounded,
                        iconBg: const Color(0xFFEFF6FF),
                        iconColor: const Color(0xFF2563EB),
                        title: 'Artikel baru dipublikasikan',
                        subtitle: firstArt,
                        time: '5 jam lalu',
                        isDark: isDark,
                        onTap: () => _switchTab(2),
                      ),
                      const SizedBox(height: 10),
                      _buildActivityTile(
                        icon: Icons.manage_accounts_rounded,
                        iconBg: const Color(0xFFCCFBF1),
                        iconColor: const Color(0xFF0D9488),
                        title: 'Data pengguna diperbarui',
                        subtitle: '$secondUser mengubah data profil',
                        time: '1 hari lalu',
                        isDark: isDark,
                        onTap: () => _switchTab(1),
                      ),
                      const SizedBox(height: 10),
                      _buildActivityTile(
                        icon: Icons.edit_note_rounded,
                        iconBg: const Color(0xFFFEF3C7),
                        iconColor: const Color(0xFFD97706),
                        title: 'Artikel diperbarui',
                        subtitle: secondArt,
                        time: '1 hari lalu',
                        isDark: isDark,
                        onTap: () => _switchTab(2),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F1E36),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                time,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 7. Capsule Bottom Navigation (Navigasi Hijau Berbentuk Kapsul dengan 5 Menu)
  Widget _buildCapsuleBottomNav(bool isDark) {
    const activeColor = Color(0xFF388E6B);
    const capsuleBg = Color(0xFF246B4D);

    final items = [
      {'icon': Icons.home_rounded, 'inactiveIcon': Icons.home_outlined, 'label': 'Beranda'},
      {'icon': Icons.people_alt_rounded, 'inactiveIcon': Icons.people_alt_outlined, 'label': 'Pengguna'},
      {'icon': Icons.article_rounded, 'inactiveIcon': Icons.article_outlined, 'label': 'Artikel'},
      {'icon': Icons.bar_chart_rounded, 'inactiveIcon': Icons.bar_chart_outlined, 'label': 'Laporan'},
      {'icon': Icons.settings_rounded, 'inactiveIcon': Icons.settings_outlined, 'label': 'Pengaturan'},
    ];

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: capsuleBg,
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: capsuleBg.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final isSelected = _currentIndex == index;
            final item = items[index];
            final icon = (isSelected ? item['icon'] : item['inactiveIcon']) as IconData;
            final label = item['label'] as String;

            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _switchTab(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSelected ? activeColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.75),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 1: PENGGUNA (User Management with Real-time Firestore Stream & Details)
  // ===========================================================================
  Widget _buildPenggunaTab(bool isDark, Color primaryColor) {
    return StreamBuilder<List<UserModel>>(
      stream: _authService.getAllUsersStream(),
      builder: (context, snapshot) {
        final users = snapshot.data ?? [];

        // Apply local filtering
        final filteredUsers = users.where((u) {
          final matchesQuery = _userSearchQuery.isEmpty ||
              u.name.toLowerCase().contains(_userSearchQuery.toLowerCase()) ||
              u.email.toLowerCase().contains(_userSearchQuery.toLowerCase());

          if (!matchesQuery) return false;

          if (_selectedRoleFilter == 'Admin') {
            return u.isAdmin;
          } else if (_selectedRoleFilter == 'Pengguna') {
            return !u.isAdmin;
          }
          return true;
        }).toList();

        return Column(
          children: [
            // Header Search & Filters
            Container(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kelola Pengguna',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Daftar akun dan hak akses pengguna ObeSight',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Search TextField
                  TextField(
                    onChanged: (val) => setState(() => _userSearchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Cari nama atau email...',
                      hintStyle: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Role Filter Chips
                  Row(
                    children: [
                      _buildFilterChip('Semua', primaryColor, isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip('Pengguna', primaryColor, isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip('Admin', primaryColor, isDark),
                    ],
                  ),
                ],
              ),
            ),

            // User List View
            Expanded(
              child: filteredUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 48, color: const Color(0xFF94A3B8)),
                          const SizedBox(height: 12),
                          Text(
                            'Tidak ada pengguna yang cocok',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                      itemCount: filteredUsers.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        return _buildUserTile(user, isDark, primaryColor);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String label, Color primaryColor, bool isDark) {
    final isSelected = _selectedRoleFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedRoleFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTile(UserModel user, bool isDark, Color primaryColor) {
    return Material(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: user.isAdmin
              ? primaryColor.withValues(alpha: 0.15)
              : const Color(0xFF3B82F6).withValues(alpha: 0.15),
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: user.isAdmin ? primaryColor : const Color(0xFF2563EB),
            ),
          ),
        ),
        title: Text(
          user.name,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              user.email,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: user.isAdmin
                ? primaryColor.withValues(alpha: 0.12)
                : const Color(0xFF3B82F6).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            user.isAdmin ? 'Admin' : 'Pengguna',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: user.isAdmin ? primaryColor : const Color(0xFF2563EB),
            ),
          ),
        ),
        onTap: () => _showUserDetailModal(user, isDark, primaryColor),
      ),
    ));
  }

  void _showUserDetailModal(UserModel user, bool isDark, Color primaryColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: primaryColor.withValues(alpha: 0.15),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        user.email,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            _buildDetailRow('ID Pengguna', user.id, isDark),
            _buildDetailRow('Hak Akses', user.isAdmin ? 'Administrator' : 'Pengguna Biasa', isDark),
            _buildDetailRow('Jenis Kelamin', user.gender ?? 'Belum diisi', isDark),
            _buildDetailRow('Nomor Telepon', (user.phone != null && user.phone!.isNotEmpty) ? user.phone! : 'Belum diisi', isDark),
            _buildDetailRow('Skor IMT', '${user.bmiScore.toStringAsFixed(1)} (${user.bmiCategory})', isDark),
            _buildDetailRow('Risiko Obesitas', user.obesityRisk, isDark),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Tutup',
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: ARTIKEL (Health Articles Management from Firestore)
  // ===========================================================================
  Widget _buildArtikelTab(bool isDark, Color primaryColor) {
    return StreamBuilder<List<ArticleModel>>(
      stream: _articleService.getArticlesStream(),
      builder: (context, snapshot) {
        final articles = snapshot.data ?? [];

        final filteredArticles = articles.where((a) {
          if (_articleSearchQuery.isEmpty) return true;
          return a.title.toLowerCase().contains(_articleSearchQuery.toLowerCase()) ||
              a.category.toLowerCase().contains(_articleSearchQuery.toLowerCase());
        }).toList();

        return Column(
          children: [
            Container(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Artikel Edukasi Kesehatan',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kelola publikasi dan materi gizi seimbang ObeSight',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (val) => setState(() => _articleSearchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Cari judul artikel atau topik...',
                      hintStyle: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filteredArticles.isEmpty
                  ? Center(
                      child: Text(
                        'Belum ada artikel ditemukan.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                      itemCount: filteredArticles.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final article = filteredArticles[index];
                        return _buildArticleCard(article, isDark, primaryColor);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildArticleCard(ArticleModel article, bool isDark, Color primaryColor) {
    return Material(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(article.icon, color: primaryColor),
          ),
          title: Text(
            article.title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                article.snippet,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      article.category,
                      style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: primaryColor),
                    ),
                  ),
                  Text(
                    article.readTime,
                    style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ],
          ),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF94A3B8)),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => HealthArticleDetailScreen(article: article),
              ),
            );
          },
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 3: LAPORAN (Reports & Health Analytics)
  // ===========================================================================
  Widget _buildLaporanTab(bool isDark, Color primaryColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Laporan & Analitik',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ringkasan data skrining dan demografi kesehatan pengguna',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),

          // Overview Grid
          Row(
            children: [
              Expanded(
                child: _buildReportMetric(
                  title: 'Akurasi Skrining',
                  value: '94.8%',
                  subtitle: 'Random Forest v2',
                  icon: Icons.biotech_rounded,
                  color: const Color(0xFF7C3AED),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildReportMetric(
                  title: 'Kepatuhan Tidur',
                  value: '82%',
                  subtitle: 'Rata-rata 7.2 jam',
                  icon: Icons.nightlight_rounded,
                  color: const Color(0xFF2563EB),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildReportMetric(
                  title: 'Aktivitas Fisik',
                  value: '1.240 kkal',
                  subtitle: 'Target tercapai',
                  icon: Icons.fitness_center_rounded,
                  color: const Color(0xFFF59E0B),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildReportMetric(
                  title: 'Gizi Seimbang',
                  value: '88%',
                  subtitle: 'Checklist piringku',
                  icon: Icons.restaurant_rounded,
                  color: primaryColor,
                  isDark: isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // BMI Distribution Breakdown
          Text(
            'Distribusi Kategori IMT Pengguna',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          _buildBmiBar('Normal (18.5 - 22.9)', 0.58, '58%', const Color(0xFF10B981), isDark),
          const SizedBox(height: 10),
          _buildBmiBar('Kelebihan Berat Badan (23.0 - 24.9)', 0.24, '24%', const Color(0xFFF59E0B), isDark),
          const SizedBox(height: 10),
          _buildBmiBar('Obesitas I (25.0 - 29.9)', 0.12, '12%', const Color(0xFFEF4444), isDark),
          const SizedBox(height: 10),
          _buildBmiBar('Obesitas II (≥ 30.0)', 0.06, '6%', const Color(0xFF991B1B), isDark),
        ],
      ),
    );
  }

  Widget _buildReportMetric({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBmiBar(String label, double ratio, String percent, Color barColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ),
              Text(
                percent,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: barColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 4: PENGATURAN DAN PROFIL ADMIN (Read-Only Email & Verifikasi Sandi)
  // ===========================================================================
  Widget _buildPengaturanTab(bool isDark, Color primaryColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFF3E9674), const Color(0xFF2C6348)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'ADMINISTRATOR SISTEM',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _currentUser.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _currentUser.email,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section 1: Informasi Akun (Email READ-ONLY)
          Text(
            'Informasi Akun',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),

          // Read-only Email Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lock_rounded,
                      size: 16,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Email Administrator (Read-Only)',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _currentUser.email,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF64748B).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'TETAP',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Alamat email administrator bersifat tetap dan tidak dapat diubah demi keamanan dan integritas audit sistem.',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Section 2: Keamanan Akun (Fitur Ubah Kata Sandi)
          Text(
            'Keamanan & Kata Sandi',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),

          // Ubah Kata Sandi Action Tile
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                final success = await AdminChangePasswordSheet.show(
                  context,
                  adminEmail: _currentUser.email,
                );
                if (success == true && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Kata sandi administrator berhasil diperbarui.',
                              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.key_rounded, color: primaryColor, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ubah Kata Sandi',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Wajib verifikasi kata sandi lama via Firebase Auth',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
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
          ),

          const SizedBox(height: 20),

          // Section 3: Pengaturan Tampilan & Sistem
          Text(
            'Preferensi Sistem',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),

          // Dark Mode Toggle
          ValueListenableBuilder<ThemeMode>(
            valueListenable: AppTheme.themeModeNotifier,
            builder: (context, currentMode, _) {
              final isDarkModeActive = currentMode == ThemeMode.dark;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isDarkModeActive ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                          color: isDarkModeActive ? const Color(0xFFF59E0B) : primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Mode Gelap',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: isDarkModeActive,
                      activeThumbColor: primaryColor,
                      activeTrackColor: primaryColor.withValues(alpha: 0.5),
                      onChanged: (val) {
                        AppTheme.setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                      },
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Logout Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _handleLogout(context),
              icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
              label: Text(
                'Keluar dari Sesi Administrator',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
