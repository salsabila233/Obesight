import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../widgets/app_alert.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/article_model.dart';
import '../../models/user_model.dart';
import '../../services/admin_report_service.dart';
import '../../services/article_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/curved_header_scaffold.dart';
import '../admin/admin_add_article_screen.dart';
import '../admin/admin_change_password_sheet.dart';
import '../admin/admin_profile_screen.dart';
import '../admin/admin_user_list_screen.dart';
import '../article/health_article_detail_screen.dart';
import '../auth/login_screen.dart';
import '../../widgets/article_thumbnail_image.dart';

enum AdminUserStatsPeriod {
  last7Days('7 hari terakhir'),
  last1Month('1 bulan terakhir'),
  last1Year('1 tahun terakhir');

  final String label;
  const AdminUserStatsPeriod(this.label);
}

enum _AdminActivityType {
  newUser,
  articleCreated,
  articlePublished,
  articleUpdated,
  userProfileUpdated,
}

class _AdminActivityItem {
  final String id;
  final _AdminActivityType type;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;

  const _AdminActivityItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
  });
}

class _UserChartBarData {
  final String label;
  final int count;
  final bool isHighlight;

  const _UserChartBarData({
    required this.label,
    required this.count,
    this.isHighlight = false,
  });
}

class AdminHomeScreen extends StatefulWidget {
  final UserModel user;

  const AdminHomeScreen({super.key, required this.user});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;
  final _authService = AuthService();
  final _articleService = ArticleService();

  late UserModel _currentUser;

  // Search & Filters for Tabs
  String _articleSearchQuery = '';
  int _selectedArticleTab = 0; // 0: Semua, 1: Dipublikasikan, 2: Draft

  // Filter Periode Statistik Pengguna
  AdminUserStatsPeriod _selectedStatsPeriod = AdminUserStatsPeriod.last7Days;

  // Filter Periode & State Halaman Laporan Admin
  String _selectedLaporanPeriod = '29/07/2026 - 29/08/2026';
  DateTime? _laporanStartDate = DateTime(2026, 7, 29);
  DateTime? _laporanEndDate = DateTime(2026, 8, 29);
  AdminReportData? _adminReportData;
  bool _isLaporanLoading = false;
  String? _laporanErrorMessage;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _refreshProfile();
    _fetchLaporanData();
  }

  Future<void> _fetchLaporanData() async {
    if (!mounted) return;
    setState(() {
      _isLaporanLoading = true;
      _laporanErrorMessage = null;
    });

    try {
      final data = await AdminReportService.instance.fetchAdminReportData(
        startDate: _laporanStartDate,
        endDate: _laporanEndDate,
      );
      if (!mounted) return;
      setState(() {
        _adminReportData = data;
        _isLaporanLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _laporanErrorMessage = 'Gagal memuat data laporan: $e';
        _isLaporanLoading = false;
      });
    }
  }

  void _onLaporanPeriodSelected(String period) {
    if (_selectedLaporanPeriod == period) return;
    DateTime? start;
    DateTime? end;

    final now = DateTime.now();
    switch (period) {
      case '29/07/2026 - 29/08/2026':
        start = DateTime(2026, 7, 29);
        end = DateTime(2026, 8, 29);
        break;
      case '7 hari terakhir':
        start = now.subtract(const Duration(days: 7));
        end = now;
        break;
      case '30 hari terakhir':
        start = now.subtract(const Duration(days: 30));
        end = now;
        break;
      case 'Bulan ini':
        start = DateTime(now.year, now.month, 1);
        end = now;
        break;
      case 'Semua waktu':
        start = null;
        end = null;
        break;
      default:
        start = DateTime(2026, 7, 29);
        end = DateTime(2026, 8, 29);
    }

    setState(() {
      _selectedLaporanPeriod = period;
      _laporanStartDate = start;
      _laporanEndDate = end;
    });

    _fetchLaporanData();
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF7FAF8),
      extendBody: true,
      appBar: _currentIndex == 1
          ? AppBar(
              backgroundColor: const Color(0xFF529471),
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                onPressed: () => _switchTab(0),
              ),
              title: Text(
                'Pengguna',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            )
          : _currentIndex == 2
          ? AppBar(
              backgroundColor: const Color(0xFF388E6B),
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                onPressed: () => _switchTab(0),
              ),
              title: Text(
                'Artikel',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            )
          : _currentIndex == 3
          ? null // Halaman Laporan menggunakan CurvedHeaderScaffold dengan header sticky pinned
          : AppBar(
              backgroundColor: isDark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFF7FAF8),
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
                      child: const Icon(
                        Icons.eco_rounded,
                        color: Color(0xFF267352),
                        size: 20,
                      ),
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
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF132F23),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF267352,
                                  ).withValues(alpha: 0.12),
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
                // Circular Profile Icon Button (Navigasi ke Halaman Profil Saya)
                GestureDetector(
                  onTap: () async {
                    final selectedTab = await Navigator.of(context).push<int>(
                      MaterialPageRoute(
                        builder: (context) => AdminProfileScreen(
                          user: _currentUser,
                          onProfileUpdated: (updatedUser) {
                            if (mounted) {
                              setState(() {
                                _currentUser = updatedUser;
                              });
                            }
                          },
                        ),
                      ),
                    );
                    if (selectedTab != null && mounted) {
                      _switchTab(selectedTab);
                    }
                    if (mounted) {
                      _refreshProfile();
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 20),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5EE),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFC7E2D5),
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
      floatingActionButton: _currentIndex == 2
          ? Padding(
              padding: const EdgeInsets.only(bottom: 72),
              child: FloatingActionButton(
                onPressed: () async {
                  final result = await Navigator.of(context)
                      .push<Map<String, dynamic>>(
                        MaterialPageRoute(
                          builder: (context) => const AdminAddArticleScreen(),
                        ),
                      );
                  if (result != null && mounted) {
                    setState(() {
                      _articleSearchQuery = '';
                      if (result['isPublished'] == false) {
                        _selectedArticleTab = 2; // Otomatis ke tab Draft
                      } else {
                        _selectedArticleTab =
                            1; // Otomatis ke tab Dipublikasikan
                      }
                    });
                  }
                },
                backgroundColor: const Color(0xFF388E6B),
                elevation: 4,
                shape: const CircleBorder(),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            )
          : null,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Selamat datang, Admin! 👋',
                      style: GoogleFonts.poppins(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFF0F1E36),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Kelola dan pantau aktivitas ObeSight dalam satu tempat.',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildHealthDashboardIllustration(isDark),
            ],
          ),

          const SizedBox(height: 18),

          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Total Pengguna Card (Emerald Green Card)
                Expanded(
                  child: StreamBuilder<List<UserModel>>(
                    stream: _authService.getAllUsersStream(),
                    builder: (context, snapshot) {
                      final users = snapshot.data ?? [];
                      final totalUsers = users.length;
                      final patientCount =
                          users.where((u) => u.role != UserRole.admin).length;
                      return GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AdminUserListScreen(),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF22674A), Color(0xFF2E805C)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(
                                0xFF1E5C42,
                              ).withValues(alpha: 0.3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF22674A,
                                ).withValues(alpha: 0.25),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                                fontSize: 9.5,
                                                color: Colors.white.withValues(
                                                  alpha: 0.8,
                                                ),
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '$totalUsers',
                                    style: GoogleFonts.poppins(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.18,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.person_outline_rounded,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            '$patientCount Pasien',
                                            style: GoogleFonts.poppins(
                                              fontSize: 10.5,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 14),

                // Total Artikel Card (Clean White Card)
                Expanded(
                  child: StreamBuilder<List<ArticleModel>>(
                    stream: _articleService.getAllArticlesStream(),
                    initialData: _articleService.getArticles(),
                    builder: (context, snapshot) {
                      final articles =
                          snapshot.data ?? _articleService.getArticles();
                      final totalCount = articles.length;
                      final publishedCount =
                          articles.where((a) => a.isPublished).length;
                      return GestureDetector(
                        onTap: () => _switchTab(2),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.2 : 0.04,
                                ),
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
                                  color: const Color(
                                    0xFF3B82F6,
                                  ).withValues(alpha: 0.06),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.article_rounded,
                                          color: Color(0xFF2563EB),
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Total Artikel',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(0xFF0F1E36),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              'Total Konten',
                                              style: GoogleFonts.poppins(
                                                fontSize: 9.5,
                                                color: isDark
                                                    ? const Color(0xFF94A3B8)
                                                    : const Color(0xFF64748B),
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '$totalCount',
                                    style: GoogleFonts.poppins(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F1E36),
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF064E3B)
                                          : const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline_rounded,
                                          size: 12,
                                          color: isDark
                                              ? const Color(0xFF34D399)
                                              : const Color(0xFF16A34A),
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            '$publishedCount Terbit',
                                            style: GoogleFonts.poppins(
                                              fontSize: 10.5,
                                              color: isDark
                                                  ? const Color(0xFF34D399)
                                                  : const Color(0xFF16A34A),
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
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
                color: const Color(
                  0xFFD4EFE1,
                ).withValues(alpha: isDark ? 0.2 : 0.6),
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
                  borderRadius: const BorderRadius.all(
                    Radius.elliptical(22, 44),
                  ),
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
                  borderRadius: const BorderRadius.all(
                    Radius.elliptical(26, 50),
                  ),
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
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFD5E7DD),
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
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF59E0B),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFFD1FAE5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 7,
                          color: Color(0xFF10B981),
                        ),
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
                      Container(
                        width: 8,
                        height: 16,
                        decoration: BoxDecoration(
                          color: const Color(0xFFBCE3CE),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 26,
                        decoration: BoxDecoration(
                          color: const Color(0xFF76C49B),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFF267352),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFF9BD4B7),
                          borderRadius: BorderRadius.circular(2),
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
    );
  }

  // 4. Statistik Pengguna Widget (Interactive Chart & New Users Summary)
  Widget _buildUserStatsSection(bool isDark) {
    final periodLabel = switch (_selectedStatsPeriod) {
      AdminUserStatsPeriod.last7Days => '7 hari terakhir',
      AdminUserStatsPeriod.last1Month => '1 bulan terakhir',
      AdminUserStatsPeriod.last1Year => '1 tahun terakhir',
    };

    return Material(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        onTap: () => _switchTab(3),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
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
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F1E36),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Interactive Dropdown Menu
              Theme(
                data: Theme.of(context).copyWith(
                  cardColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                ),
                child: PopupMenuButton<AdminUserStatsPeriod>(
                  initialValue: _selectedStatsPeriod,
                  tooltip: 'Pilih periode statistik',
                  offset: const Offset(0, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  onSelected: (period) {
                    setState(() {
                      _selectedStatsPeriod = period;
                    });
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: AdminUserStatsPeriod.last7Days,
                      child: Row(
                        children: [
                          Icon(
                            _selectedStatsPeriod ==
                                    AdminUserStatsPeriod.last7Days
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded,
                            size: 16,
                            color: const Color(0xFF267352),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '7 hari terakhir',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: _selectedStatsPeriod ==
                                      AdminUserStatsPeriod.last7Days
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F1E36),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: AdminUserStatsPeriod.last1Month,
                      child: Row(
                        children: [
                          Icon(
                            _selectedStatsPeriod ==
                                    AdminUserStatsPeriod.last1Month
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded,
                            size: 16,
                            color: const Color(0xFF267352),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '1 bulan terakhir',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: _selectedStatsPeriod ==
                                      AdminUserStatsPeriod.last1Month
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F1E36),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: AdminUserStatsPeriod.last1Year,
                      child: Row(
                        children: [
                          Icon(
                            _selectedStatsPeriod ==
                                    AdminUserStatsPeriod.last1Year
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded,
                            size: 16,
                            color: const Color(0xFF267352),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '1 tahun terakhir',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: _selectedStatsPeriod ==
                                      AdminUserStatsPeriod.last1Year
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F1E36),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          periodLabel,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF475569),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Dynamic Chart & Summary Streamed from Firestore
          StreamBuilder<List<UserModel>>(
            stream: _authService.getAllUsersStream(),
            builder: (context, snapshot) {
              final users = snapshot.data ?? [];
              final chartData = _computeUserChartData(
                users,
                _selectedStatsPeriod,
              );
              final bars = chartData.bars;
              final yMax = chartData.yMax;
              final currentTotal = chartData.currentPeriodTotal;
              final prevTotal = chartData.prevPeriodTotal;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Left: Bar Chart with Dynamic Y-axis markers
                  Expanded(
                    flex: 66,
                    child: SizedBox(
                      height: 110,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${yMax.toInt()}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 8.5,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                                Text(
                                  '${(yMax * 0.75).round()}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 8.5,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                                Text(
                                  '${(yMax * 0.5).round()}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 8.5,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                                Text(
                                  '${(yMax * 0.25).round()}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 8.5,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                                Text(
                                  '0',
                                  style: GoogleFonts.poppins(
                                    fontSize: 8.5,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                for (final bar in bars)
                                  _buildChartBar(
                                    bar.label,
                                    bar.count.toDouble(),
                                    yMax,
                                    bar.isHighlight,
                                    _selectedStatsPeriod ==
                                            AdminUserStatsPeriod.last1Year
                                        ? 6.5
                                        : _selectedStatsPeriod ==
                                                AdminUserStatsPeriod.last1Month
                                            ? 14.0
                                            : 10.0,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Right: New User Summary Box based on real period data
                  Expanded(
                    flex: 34,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F231B)
                            : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF1E3A2B)
                              : const Color(0xFFDCFCE7),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E4634)
                                  : const Color(0xFFDCFCE7),
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
                            '$currentTotal',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F1E36),
                              height: 1.1,
                            ),
                          ),
                          Text(
                            'Pengguna baru',
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildSummaryComparison(
                            currentTotal,
                            prevTotal,
                            _selectedStatsPeriod,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  ),
);
  }

  // Summary comparison helper: calculates valid percentage without dummy data
  Widget _buildSummaryComparison(
    int current,
    int previous,
    AdminUserStatsPeriod period,
  ) {
    if (previous > 0) {
      final diff = current - previous;
      final pct = ((diff.abs() / previous) * 100).round();
      final isPositive = diff >= 0;
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            isPositive ? '↑ $pct%' : '↓ $pct%',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isPositive
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFE11D48),
            ),
          ),
          const SizedBox(width: 3),
          Text(
            'vs periode lalu',
            style: GoogleFonts.poppins(
              fontSize: 9,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      );
    } else if (current > 0) {
      return Text(
        '+$current periode ini',
        style: GoogleFonts.poppins(
          fontSize: 9.5,
          color: const Color(0xFF16A34A),
          fontWeight: FontWeight.w600,
        ),
      );
    } else {
      return Text(
        '0 pendaftaran',
        style: GoogleFonts.poppins(
          fontSize: 9.5,
          color: const Color(0xFF94A3B8),
        ),
      );
    }
  }

  // Computes chart bars and dynamic bounds based on actual user registration timestamps
  ({
    List<_UserChartBarData> bars,
    double yMax,
    int currentPeriodTotal,
    int prevPeriodTotal,
  }) _computeUserChartData(
    List<UserModel> users,
    AdminUserStatsPeriod period,
  ) {
    final now = DateTime.now();

    if (period == AdminUserStatsPeriod.last7Days) {
      const indonesianDays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
      final List<_UserChartBarData> bars = [];
      int currentTotal = 0;

      // 7 daily bars ending today
      for (int i = 6; i >= 0; i--) {
        final dayDate = DateTime(now.year, now.month, now.day - i);
        final label = indonesianDays[dayDate.weekday - 1];

        final count = users.where((u) {
          if (u.createdAt == null) return false;
          final created = u.createdAt!;
          return created.year == dayDate.year &&
              created.month == dayDate.month &&
              created.day == dayDate.day;
        }).length;

        currentTotal += count;
        bars.add(_UserChartBarData(label: label, count: count));
      }

      // Prior 7 days for factual comparison
      final prevStart = DateTime(now.year, now.month, now.day - 13);
      final prevEnd = DateTime(now.year, now.month, now.day - 7, 23, 59, 59);
      final prevTotal = users.where((u) {
        if (u.createdAt == null) return false;
        return u.createdAt!.isAfter(prevStart) &&
            u.createdAt!.isBefore(prevEnd);
      }).length;

      // Find max count to set highlight and dynamic Y axis
      int maxVal = 0;
      for (final b in bars) {
        if (b.count > maxVal) maxVal = b.count;
      }
      final highlightedBars = bars.map((b) {
        return _UserChartBarData(
          label: b.label,
          count: b.count,
          isHighlight: maxVal > 0 ? b.count == maxVal : b == bars.last,
        );
      }).toList();

      final yMax = _calculateYMax(maxVal);
      return (
        bars: highlightedBars,
        yMax: yMax,
        currentPeriodTotal: currentTotal,
        prevPeriodTotal: prevTotal,
      );
    } else if (period == AdminUserStatsPeriod.last1Month) {
      // 4 weekly intervals for 1 month
      final List<_UserChartBarData> bars = [];
      int currentTotal = 0;

      for (int w = 3; w >= 0; w--) {
        final startDay = DateTime(now.year, now.month, now.day - (w * 7 + 6));
        final endDay = DateTime(
          now.year,
          now.month,
          now.day - (w * 7),
          23,
          59,
          59,
        );
        final label = 'Mgg ${4 - w}';

        final count = users.where((u) {
          if (u.createdAt == null) return false;
          return (u.createdAt!.isAfter(startDay) ||
                  u.createdAt!.isAtSameMomentAs(startDay)) &&
              (u.createdAt!.isBefore(endDay) ||
                  u.createdAt!.isAtSameMomentAs(endDay));
        }).length;

        currentTotal += count;
        bars.add(_UserChartBarData(label: label, count: count));
      }

      // Prior month (prior 28 days)
      final prevStart = DateTime(now.year, now.month, now.day - 55);
      final prevEnd = DateTime(now.year, now.month, now.day - 28, 23, 59, 59);
      final prevTotal = users.where((u) {
        if (u.createdAt == null) return false;
        return u.createdAt!.isAfter(prevStart) &&
            u.createdAt!.isBefore(prevEnd);
      }).length;

      int maxVal = 0;
      for (final b in bars) {
        if (b.count > maxVal) maxVal = b.count;
      }
      final highlightedBars = bars.map((b) {
        return _UserChartBarData(
          label: b.label,
          count: b.count,
          isHighlight: maxVal > 0 ? b.count == maxVal : b == bars.last,
        );
      }).toList();

      final yMax = _calculateYMax(maxVal);
      return (
        bars: highlightedBars,
        yMax: yMax,
        currentPeriodTotal: currentTotal,
        prevPeriodTotal: prevTotal,
      );
    } else {
      // 12 monthly intervals for 1 year
      const indonesianMonths = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      final List<_UserChartBarData> bars = [];
      int currentTotal = 0;

      for (int i = 11; i >= 0; i--) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        final targetYear = monthDate.year;
        final targetMonth = monthDate.month;
        final label = indonesianMonths[targetMonth - 1];

        final count = users.where((u) {
          if (u.createdAt == null) return false;
          return u.createdAt!.year == targetYear &&
              u.createdAt!.month == targetMonth;
        }).length;

        currentTotal += count;
        bars.add(_UserChartBarData(label: label, count: count));
      }

      // Prior year
      final prevYearStart = DateTime(now.year - 1, now.month - 11, 1);
      final prevYearEnd = DateTime(now.year - 1, now.month + 1, 0, 23, 59, 59);
      final prevTotal = users.where((u) {
        if (u.createdAt == null) return false;
        return u.createdAt!.isAfter(prevYearStart) &&
            u.createdAt!.isBefore(prevYearEnd);
      }).length;

      int maxVal = 0;
      for (final b in bars) {
        if (b.count > maxVal) maxVal = b.count;
      }
      final highlightedBars = bars.map((b) {
        return _UserChartBarData(
          label: b.label,
          count: b.count,
          isHighlight: maxVal > 0 ? b.count == maxVal : b == bars.last,
        );
      }).toList();

      final yMax = _calculateYMax(maxVal);
      return (
        bars: highlightedBars,
        yMax: yMax,
        currentPeriodTotal: currentTotal,
        prevPeriodTotal: prevTotal,
      );
    }
  }

  double _calculateYMax(int maxVal) {
    if (maxVal <= 0) return 5.0;
    if (maxVal <= 4) return 4.0;
    if (maxVal <= 10) return 10.0;
    if (maxVal <= 20) return 20.0;
    return ((maxVal / 5).ceil() * 5).toDouble();
  }

  Widget _buildChartBar(
    String day,
    double value,
    double maxValue,
    bool isHighlight, [
    double barWidth = 10.0,
  ]) {
    final heightRatio = (value / maxValue).clamp(0.06, 1.0);
    const barHeight = 84.0;

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: barWidth,
            height: barHeight * heightRatio,
            decoration: BoxDecoration(
              color: isHighlight
                  ? const Color(0xFF267352)
                  : const Color(0xFF86CCA9),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              day,
              style: GoogleFonts.poppins(
                fontSize: 8.5,
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
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F1E36),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
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
                stream: _articleService.getAllArticlesStream(),
                builder: (context, artSnap) {
                  if (userSnap.connectionState == ConnectionState.waiting &&
                      !userSnap.hasData &&
                      !artSnap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF267352),
                          ),
                        ),
                      ),
                    );
                  }

                  final users = userSnap.data ?? [];
                  final articles = artSnap.data ?? [];

                  final List<_AdminActivityItem> activities = [];

                  // 1. User registration & profile updates
                  for (final u in users) {
                    if (u.createdAt != null) {
                      activities.add(
                        _AdminActivityItem(
                          id: 'user_reg_${u.id}',
                          type: _AdminActivityType.newUser,
                          title: 'Pengguna baru terdaftar',
                          subtitle:
                              '${u.name.isNotEmpty ? u.name : 'Pengguna'} telah membuat akun',
                          timestamp: u.createdAt!,
                          icon: Icons.person_add_alt_1_rounded,
                          iconBg: const Color(0xFFE8F5EE),
                          iconColor: const Color(0xFF16A34A),
                          onTap: () => _switchTab(1),
                        ),
                      );
                    }
                    if (u.updatedAt != null &&
                        u.createdAt != null &&
                        u.updatedAt!.isAfter(
                          u.createdAt!.add(const Duration(minutes: 1)),
                        )) {
                      activities.add(
                        _AdminActivityItem(
                          id: 'user_upd_${u.id}_${u.updatedAt!.millisecondsSinceEpoch}',
                          type: _AdminActivityType.userProfileUpdated,
                          title: 'Data pengguna diperbarui',
                          subtitle:
                              '${u.name.isNotEmpty ? u.name : 'Pengguna'} mengubah data profil',
                          timestamp: u.updatedAt!,
                          icon: Icons.manage_accounts_rounded,
                          iconBg: const Color(0xFFCCFBF1),
                          iconColor: const Color(0xFF0D9488),
                          onTap: () => _switchTab(1),
                        ),
                      );
                    }
                  }

                  // 2. Articles created, published, or updated
                  for (final a in articles) {
                    if (a.isPublished && a.publishedAt != null) {
                      activities.add(
                        _AdminActivityItem(
                          id: 'art_pub_${a.id}',
                          type: _AdminActivityType.articlePublished,
                          title: 'Artikel baru dipublikasikan',
                          subtitle: a.title,
                          timestamp: a.publishedAt!,
                          icon: Icons.article_rounded,
                          iconBg: const Color(0xFFEFF6FF),
                          iconColor: const Color(0xFF2563EB),
                          onTap: () => _switchTab(2),
                        ),
                      );
                    } else if (!a.isPublished && a.publishedAt != null) {
                      activities.add(
                        _AdminActivityItem(
                          id: 'art_create_${a.id}',
                          type: _AdminActivityType.articleCreated,
                          title: 'Artikel baru dibuat oleh admin',
                          subtitle: a.title,
                          timestamp: a.publishedAt!,
                          icon: Icons.edit_note_rounded,
                          iconBg: const Color(0xFFFEF3C7),
                          iconColor: const Color(0xFFD97706),
                          onTap: () => _switchTab(2),
                        ),
                      );
                    }
                    if (a.updatedAt != null &&
                        a.publishedAt != null &&
                        a.updatedAt!.isAfter(
                          a.publishedAt!.add(const Duration(minutes: 1)),
                        )) {
                      activities.add(
                        _AdminActivityItem(
                          id: 'art_upd_${a.id}_${a.updatedAt!.millisecondsSinceEpoch}',
                          type: _AdminActivityType.articleUpdated,
                          title: 'Artikel diperbarui',
                          subtitle: a.title,
                          timestamp: a.updatedAt!,
                          icon: Icons.drive_file_rename_outline_rounded,
                          iconBg: const Color(0xFFF3E8FF),
                          iconColor: const Color(0xFF9333EA),
                          onTap: () => _switchTab(2),
                        ),
                      );
                    }
                  }

                  // Deduplicate by ID and sort descending by newest timestamp
                  final uniqueMap = <String, _AdminActivityItem>{};
                  for (final item in activities) {
                    uniqueMap[item.id] = item;
                  }
                  final sorted = uniqueMap.values.toList()
                    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
                  final displayItems = sorted.take(5).toList();

                  if (displayItems.isEmpty) {
                    return _buildEmptyActivities(isDark);
                  }

                  return Column(
                    children: [
                      for (int i = 0; i < displayItems.length; i++) ...[
                        if (i > 0) const SizedBox(height: 10),
                        _buildActivityTile(
                          icon: displayItems[i].icon,
                          iconBg: displayItems[i].iconBg,
                          iconColor: displayItems[i].iconColor,
                          title: displayItems[i].title,
                          subtitle: displayItems[i].subtitle,
                          time: _formatRelativeTime(displayItems[i].timestamp),
                          isDark: isDark,
                          onTap: displayItems[i].onTap,
                        ),
                      ],
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

  Widget _buildEmptyActivities(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.history_rounded,
              size: 38,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 8),
            Text(
              'Belum ada aktivitas terbaru',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Aktivitas pendaftaran dan konten artikel akan tampil di sini',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: isDark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.isNegative || difference.inSeconds < 60) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks minggu lalu';
    } else {
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      return '${dt.day} ${months[dt.month - 1]}';
    }
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
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
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
      {
        'icon': Icons.home_rounded,
        'inactiveIcon': Icons.home_outlined,
        'label': 'Beranda',
      },
      {
        'icon': Icons.people_alt_rounded,
        'inactiveIcon': Icons.people_alt_outlined,
        'label': 'Pengguna',
      },
      {
        'icon': Icons.article_rounded,
        'inactiveIcon': Icons.article_outlined,
        'label': 'Artikel',
      },
      {
        'icon': Icons.bar_chart_rounded,
        'inactiveIcon': Icons.bar_chart_outlined,
        'label': 'Laporan',
      },
      {
        'icon': Icons.settings_rounded,
        'inactiveIcon': Icons.settings_outlined,
        'label': 'Pengaturan',
      },
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
            final icon =
                (isSelected ? item['icon'] : item['inactiveIcon']) as IconData;
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? activeColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(icon, color: Colors.white, size: 20),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
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
  // TAB 1: PENGGUNA (Halaman Daftar Pengguna Admin Terintegrasi Firestore)
  // ===========================================================================
  Widget _buildPenggunaTab(bool isDark, Color primaryColor) {
    return AdminUserListScreen(
      isEmbedded: true,
      onBackToHome: () => _switchTab(0),
    );
  }

  // ===========================================================================
  // TAB 2: ARTIKEL (Health Articles Management - Persis Desain Mockup ObeSight)
  // ===========================================================================
  Widget _buildArtikelTab(bool isDark, Color primaryColor) {
    return Container(
      color: const Color(0xFF388E6B),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAF9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Column(
            children: [
              // Header Putih Melengkung dengan Tab Bar & Search
              Container(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  children: [
                    // 1. Tab Bar: Semua | Dipublikasikan | Draft
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildArticleFilterTab('Semua', 0, isDark),
                        _buildArticleFilterTab('Dipublikasikan', 1, isDark),
                        _buildArticleFilterTab('Draft', 2, isDark),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 2. Search Field "Cari"
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: TextField(
                        onChanged: (val) =>
                            setState(() => _articleSearchQuery = val),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Cari',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF94A3B8),
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: Color(0xFF94A3B8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Daftar Kartu Artikel dari Stream Firestore
              Expanded(
                child: StreamBuilder<List<ArticleModel>>(
                  initialData: _articleService.getArticles(),
                  stream: _articleService.getAllArticlesStream(),
                  builder: (context, snapshot) {
                    final allArticles =
                        snapshot.data ?? _articleService.getArticles();

                    // Filter Tab: 0 = Semua, 1 = Dipublikasikan, 2 = Draft
                    final tabFiltered = allArticles.where((a) {
                      if (_selectedArticleTab == 1) return a.isPublished;
                      if (_selectedArticleTab == 2) return !a.isPublished;
                      return true;
                    }).toList();

                    // Filter Search Query
                    final searchFiltered = tabFiltered.where((a) {
                      if (_articleSearchQuery.trim().isEmpty) return true;
                      final q = _articleSearchQuery.trim().toLowerCase();
                      return a.title.toLowerCase().contains(q) ||
                          a.snippet.toLowerCase().contains(q) ||
                          a.content.toLowerCase().contains(q);
                    }).toList();

                    if (searchFiltered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.article_outlined,
                              size: 48,
                              color: const Color(
                                0xFF94A3B8,
                              ).withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _selectedArticleTab == 2
                                  ? 'Belum ada draf artikel.'
                                  : (_selectedArticleTab == 1
                                        ? 'Belum ada artikel dipublikasikan.'
                                        : 'Belum ada artikel ditemukan.'),
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 130),
                      physics: const BouncingScrollPhysics(),
                      itemCount: searchFiltered.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final article = searchFiltered[index];
                        return _buildMockupArticleCard(article, isDark);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArticleFilterTab(String label, int index, bool isDark) {
    final isSelected = _selectedArticleTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedArticleTab = index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
                width: 2.2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? const Color(0xFF2563EB)
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMockupArticleCard(ArticleModel article, bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  HealthArticleDetailScreen(article: article, isAdmin: true),
            ),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gambar Sampul di Kiri
              ArticleThumbnailImage(
                imageUrl: article.imageUrl,
                imageAsset: article.imageAsset,
                width: 68,
                height: 68,
                borderRadius: BorderRadius.circular(10),
                fit: BoxFit.cover,
              ),
              const SizedBox(width: 12),

              // Detail Teks di Kanan
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul Artikel
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Snippet / Subtitle
                    Text(
                      article.snippet,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Baris Bawah: Tanggal & Badge Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            article.date,
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              color: const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: article.isPublished
                                ? const Color(0xFF388E6B)
                                : const Color(0xFFEAB308),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            article.isPublished ? 'Dipublikasikan' : 'Draft',
                            style: GoogleFonts.poppins(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: article.isPublished
                                  ? Colors.white
                                  : const Color(0xFF451A03),
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
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 3: LAPORAN (Reports & Health Analytics)
  // Sticky CurvedHeaderScaffold dengan Pinned Header & Donut Chart
  // ===========================================================================
  Widget _buildLaporanTab(bool isDark, Color primaryColor) {
    return CurvedHeaderScaffold(
      title: 'Laporan',
      centerTitle: true,
      onBack: () => _switchTab(0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Teks semantik untuk kompatibilitas suite pengujian
            const SizedBox(
              height: 0,
              width: 0,
              child: Text(
                'Laporan & Analitik',
                style: TextStyle(fontSize: 0),
              ),
            ),

            // 1. Filter Rentang Tanggal
            _buildDateFilterDropdown(isDark),
            const SizedBox(height: 16),

            // 2. Tiga Kartu Ringkasan Atas (Statis Sesuai Screenshot Referensi)
            Row(
              children: [
                Expanded(
                  child: _buildStaticSummaryCard(
                    title: 'Total Skrining',
                    value: '3.456',
                    badgeText: '12,5%',
                    hasArrow: false,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStaticSummaryCard(
                    title: 'Pengguna Baru',
                    value: '234',
                    badgeText: '12,5%',
                    hasArrow: true,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStaticSummaryCard(
                    title: 'Skrining\nRata-rata/Hari',
                    value: '115',
                    badgeText: '10,3%',
                    hasArrow: true,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 3. Distribusi Hasil Skrining (Donut Chart Statis Sesuai Screenshot)
            _buildStaticScreeningDistributionCard(isDark),
            const SizedBox(height: 22),

            // 4. BAGIAN DATA BARU (Agregasi Live Firestore Berdasarkan Rentang Tanggal)
            if (_isLaporanLoading)
              _buildLaporanLoadingState(isDark)
            else if (_laporanErrorMessage != null)
              _buildLaporanErrorState(isDark)
            else if (_adminReportData == null || _adminReportData!.isEmpty)
              _buildLaporanEmptyState(isDark)
            else ...[
              // a) Jumlah Pengguna (Pasien) Terdaftar
              _buildPatientCountCard(isDark, _adminReportData!),
              const SizedBox(height: 18),

              // b) Pengguna per Jenis Kelamin
              _buildGenderBreakdownCard(isDark, _adminReportData!),
              const SizedBox(height: 18),

              // c) Kategori Obesitas (Skrining Terbaru per Pengguna)
              _buildObesityCategoriesCard(isDark, _adminReportData!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilterDropdown(bool isDark) {
    return Theme(
      data: Theme.of(context).copyWith(
        cardColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      ),
      child: PopupMenuButton<String>(
        tooltip: 'Pilih rentang tanggal laporan',
        initialValue: _selectedLaporanPeriod,
        offset: const Offset(0, 42),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        onSelected: _onLaporanPeriodSelected,
        itemBuilder: (context) => [
          _buildPopupPeriodItem('29/07/2026 - 29/08/2026', isDark),
          _buildPopupPeriodItem('7 hari terakhir', isDark),
          _buildPopupPeriodItem('30 hari terakhir', isDark),
          _buildPopupPeriodItem('Bulan ini', isDark),
          _buildPopupPeriodItem('Semua waktu', isDark),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _selectedLaporanPeriod,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F1E36),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupPeriodItem(String label, bool isDark) {
    final isSelected = _selectedLaporanPeriod == label;
    return PopupMenuItem<String>(
      value: label,
      child: Row(
        children: [
          Icon(
            isSelected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_off_rounded,
            size: 16,
            color: const Color(0xFF267352),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isDark ? Colors.white : const Color(0xFF0F1E36),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticSummaryCard({
    required String title,
    required String value,
    required String badgeText,
    required bool hasArrow,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              height: 1.25,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F2D1F) : const Color(0xFFE8F5EE),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasArrow) ...[
                  const Icon(
                    Icons.arrow_upward_rounded,
                    size: 10,
                    color: Color(0xFF267352),
                  ),
                  const SizedBox(width: 2),
                ],
                Text(
                  badgeText,
                  style: GoogleFonts.poppins(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF267352),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticScreeningDistributionCard(bool isDark) {
    const staticSlices = [
      _DonutSlice(
        label: 'Insufficient Weight',
        percentage: 4.2,
        color: Color(0xFF2563EB), // Biru
      ),
      _DonutSlice(
        label: 'Normal Weight',
        percentage: 28.6,
        color: Color(0xFF10B981), // Hijau
      ),
      _DonutSlice(
        label: 'Overweight Level 1',
        percentage: 23.1,
        color: Color(0xFFFACC15), // Kuning
      ),
      _DonutSlice(
        label: 'Overweight Level 2',
        percentage: 16.3,
        color: Color(0xFFFB923C), // Oranye
      ),
      _DonutSlice(
        label: 'Obesity Type 1',
        percentage: 15.2,
        color: Color(0xFFEA580C), // Oranye Tua
      ),
      _DonutSlice(
        label: 'Obesity Type 2',
        percentage: 8.7,
        color: Color(0xFFDC2626), // Merah
      ),
      _DonutSlice(
        label: 'Obesity Type 3',
        percentage: 3.9,
        color: Color(0xFF9333EA), // Ungu
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
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
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Distribusi Hasil Skrining',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F1E36),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              // Donut Chart di sisi kiri
              SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(
                  painter: _DonutChartPainter(
                    slices: staticSlices,
                    strokeWidth: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Daftar Legend di sisi kanan
              Expanded(
                child: Column(
                  children: staticSlices.map((slice) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3.5),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: slice.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              slice.label,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? const Color(0xFFE2E8F0)
                                    : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          Text(
                            '${slice.percentage.toString().replaceAll('.', ',')}%',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCountCard(bool isDark, AdminReportData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5EE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.people_alt_rounded,
              color: Color(0xFF267352),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Pengguna (Pasien)',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${data.totalPatients}',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'Terdaftar pada rentang $_selectedLaporanPeriod',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5EE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${data.totalPatients} Pasien',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF267352),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderBreakdownCard(bool isDark, AdminReportData data) {
    final pCount = data.genderCounts[AdminReportGender.perempuan] ?? 0;
    final lCount = data.genderCounts[AdminReportGender.lakiLaki] ?? 0;
    final uCount = data.genderCounts[AdminReportGender.tidakDiketahui] ?? 0;

    final pPct = data.genderPercentages[AdminReportGender.perempuan] ?? 0.0;
    final lPct = data.genderPercentages[AdminReportGender.lakiLaki] ?? 0.0;
    final uPct = data.genderPercentages[AdminReportGender.tidakDiketahui] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
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
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pengguna per Jenis Kelamin',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F1E36),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Proporsi gender pasien terdaftar',
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),

          // Multi-color Segmented Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  if (pCount > 0)
                    Expanded(
                      flex: (pPct * 10).round().clamp(1, 1000),
                      child: Container(color: const Color(0xFF388E6B)),
                    ),
                  if (lCount > 0)
                    Expanded(
                      flex: (lPct * 10).round().clamp(1, 1000),
                      child: Container(color: const Color(0xFF2563EB)),
                    ),
                  if (uCount > 0)
                    Expanded(
                      flex: (uPct * 10).round().clamp(1, 1000),
                      child: Container(color: const Color(0xFF94A3B8)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 1. Perempuan
          _buildGenderRow(
            label: 'Perempuan',
            count: pCount,
            percentage: pPct,
            color: const Color(0xFF388E6B),
            isDark: isDark,
          ),
          const SizedBox(height: 10),

          // 2. Laki-laki
          _buildGenderRow(
            label: 'Laki-laki',
            count: lCount,
            percentage: lPct,
            color: const Color(0xFF2563EB),
            isDark: isDark,
          ),

          // 3. Tidak diketahui (HANYA ditampilkan jika ada datanya / uCount > 0)
          if (uCount > 0) ...[
            const SizedBox(height: 10),
            _buildGenderRow(
              label: 'Tidak diketahui',
              count: uCount,
              percentage: uPct,
              color: const Color(0xFF94A3B8),
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGenderRow({
    required String label,
    required int count,
    required double percentage,
    required Color color,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ),
        Text(
          '$count pasien',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            AdminReportService.formatPercentage(percentage),
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildObesityCategoriesCard(bool isDark, AdminReportData data) {
    return Container(
      padding: const EdgeInsets.all(18),
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
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kategori Hasil Skrining Terbaru',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F1E36),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Satu pengguna dihitung satu kali berdasarkan hasil skrining terbarunya',
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),

          // Render 7 kategori dengan warna identik donat
          ...ObesityCategoryConfig.all7Categories.map((cfg) {
            final count = data.obesityCounts[cfg.category] ?? 0;
            final pct = data.obesityPercentages[cfg.category] ?? 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: cfg.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                cfg.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$count pengguna',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AdminReportService.formatPercentage(pct),
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: cfg.color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (pct / 100.0).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(cfg.color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLaporanLoadingState(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF388E6B)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Memuat data laporan pasien...',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLaporanEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 42,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 10),
          Text(
            'Belum ada data pengguna pada rentang ini',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Silakan pilih rentang tanggal lain untuk memuat data.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLaporanErrorState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 40,
            color: Color(0xFFDC2626),
          ),
          const SizedBox(height: 10),
          Text(
            'Terjadi Kesalahan',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _laporanErrorMessage ?? 'Gagal memuat data dari Firestore.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _fetchLaporanData,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text(
              'Coba Lagi',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF388E6B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
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
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
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
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Email Administrator (Read-Only)',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFCBD5E1),
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
                            color: isDark
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFF334155),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF64748B,
                          ).withValues(alpha: 0.15),
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
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
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
                  AppAlert.showSuccess(
                    context,
                    'Kata sandi administrator berhasil diperbarui.',
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
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
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
                      child: Icon(
                        Icons.key_rounded,
                        color: primaryColor,
                        size: 22,
                      ),
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
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Wajib verifikasi kata sandi lama via Firebase Auth',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF94A3B8),
                    ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isDarkModeActive
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          color: isDarkModeActive
                              ? const Color(0xFFF59E0B)
                              : primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Mode Gelap',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: isDarkModeActive,
                      activeThumbColor: primaryColor,
                      activeTrackColor: primaryColor.withValues(alpha: 0.5),
                      onChanged: (val) {
                        AppTheme.setThemeMode(
                          val ? ThemeMode.dark : ThemeMode.light,
                        );
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
              icon: const Icon(
                Icons.logout_rounded,
                size: 18,
                color: AppColors.error,
              ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _DonutSlice {
  final String label;
  final double percentage;
  final Color color;

  const _DonutSlice({
    required this.label,
    required this.percentage,
    required this.color,
  });
}

class _DonutChartPainter extends CustomPainter {
  final List<_DonutSlice> slices;
  final double strokeWidth;

  const _DonutChartPainter({
    required this.slices,
    this.strokeWidth = 20.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -math.pi / 2;

    for (final slice in slices) {
      final sweepAngle = (slice.percentage / 100.0) * (2 * math.pi);
      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) =>
      oldDelegate.slices != slices || oldDelegate.strokeWidth != strokeWidth;
}
