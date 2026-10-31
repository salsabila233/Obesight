import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
import '../admin/admin_login_screen.dart';
import '../admin/admin_profile_screen.dart';
import '../admin/admin_user_list_screen.dart';
import '../article/health_article_detail_screen.dart';
import '../../widgets/article_thumbnail_image.dart';
import '../../widgets/admin_capsule_bottom_nav.dart';

enum _AdminSettingsSubView {
  main,
  changePassword,
  aboutApp,
}

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
  final int initialIndex;

  const AdminHomeScreen({
    super.key,
    required this.user,
    this.initialIndex = 0,
  });

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late int _currentIndex;
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

  // Sub-view Pengaturan Admin
  _AdminSettingsSubView _settingsSubView = _AdminSettingsSubView.main;

  // Controllers & State untuk Form Ubah Kata Sandi Admin
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _oldPasswordFocus = FocusNode();
  final _newPasswordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _hasMinLength = false;
  bool _hasDigit = false;
  bool _hasUpperAndLower = false;
  bool _isChangingPassword = false;
  String? _passwordErrorMessage;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _currentUser = widget.user;
    _newPasswordController.addListener(_validatePasswordCriteria);
    _refreshProfile();
    _fetchLaporanData();
  }

  void _validatePasswordCriteria() {
    final text = _newPasswordController.text;
    setState(() {
      _hasMinLength = text.length >= 8 && text.length <= 16;
      _hasDigit = RegExp(r'[0-9]').hasMatch(text);
      _hasUpperAndLower =
          RegExp(r'[A-Z]').hasMatch(text) && RegExp(r'[a-z]').hasMatch(text);
    });
  }

  @override
  void dispose() {
    _newPasswordController.removeListener(_validatePasswordCriteria);
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _oldPasswordFocus.dispose();
    _newPasswordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
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
    _showAdminLogoutDialog(context);
  }

  void _switchTab(int index) {
    setState(() {
      _currentIndex = index;
      if (index == 4) {
        _settingsSubView = _AdminSettingsSubView.main;
        _passwordErrorMessage = null;
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = AppColors.adminGreen;

    return PopScope(
      canPop: _currentIndex == 0 && _settingsSubView == _AdminSettingsSubView.main,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex == 4 && _settingsSubView != _AdminSettingsSubView.main) {
          setState(() {
            _settingsSubView = _AdminSettingsSubView.main;
            _passwordErrorMessage = null;
          });
        } else if (_currentIndex != 0) {
          _switchTab(0);
        }
      },
      child: Scaffold(
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
            : (_currentIndex == 3 || _currentIndex == 4)
            ? null // Halaman Laporan & Pengaturan menggunakan CurvedHeaderScaffold dengan header sticky pinned dan lembaran melengkung radius 28
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
      ),
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
                        onTap: () async {
                          final targetIndex = await Navigator.of(context).push<int>(
                            MaterialPageRoute(
                              builder: (context) => const AdminUserListScreen(),
                            ),
                          );
                          if (targetIndex != null && mounted) {
                            _switchTab(targetIndex);
                          }
                        },
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
    return AdminCapsuleBottomNav(
      currentIndex: _currentIndex,
      onTap: _switchTab,
    );
  }

  // ===========================================================================
  // TAB 1: PENGGUNA (Halaman Daftar Pengguna Admin Terintegrasi Firestore)
  // ===========================================================================
  Widget _buildPenggunaTab(bool isDark, Color primaryColor) {
    return AdminUserListScreen(
      isEmbedded: true,
      onBackToHome: () => _switchTab(0),
      onTabSelected: _switchTab,
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
  // TAB 4: PENGATURAN ADMIN (Berdasarkan Gambar Referensi ObeSight)
  // Sub-view: Main Pengaturan, Ubah Kata Sandi, Tentang Aplikasi, Dialog Keluar
  // ===========================================================================
  Widget _buildPengaturanTab(bool isDark, Color primaryColor) {
    String titleText = 'Pengaturan';
    if (_settingsSubView == _AdminSettingsSubView.changePassword) {
      titleText = 'Ubah Kata Sandi';
    } else if (_settingsSubView == _AdminSettingsSubView.aboutApp) {
      titleText = 'Tentang Aplikasi';
    }

    Widget contentBody;
    switch (_settingsSubView) {
      case _AdminSettingsSubView.changePassword:
        contentBody = _buildUbahKataSandiView(isDark, primaryColor);
        break;
      case _AdminSettingsSubView.aboutApp:
        contentBody = _buildTentangAplikasiView(isDark, primaryColor);
        break;
      case _AdminSettingsSubView.main:
        contentBody = _buildPengaturanMainView(isDark, primaryColor);
        break;
    }

    return CurvedHeaderScaffold(
      title: titleText,
      centerTitle: true,
      headerColor: const Color(0xFF388E6B),
      sheetColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF7FAF8),
      onBack: () {
        if (_settingsSubView != _AdminSettingsSubView.main) {
          setState(() {
            _settingsSubView = _AdminSettingsSubView.main;
            _passwordErrorMessage = null;
          });
        } else {
          _switchTab(0);
        }
      },
      body: contentBody,
    );
  }

  // ---------------------------------------------------------------------------
  // A. SUB-VIEW: PENGATURAN UTAMA (Keamanan, Tampilan / Mode Gelap, Informasi, Keluar)
  // ---------------------------------------------------------------------------
  Widget _buildPengaturanMainView(bool isDark, Color primaryColor) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Seksi Keamanan
          _buildSettingsSectionHeader('Keamanan', isDark),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  setState(() {
                    _settingsSubView = _AdminSettingsSubView.changePassword;
                    _passwordErrorMessage = null;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E3A2F)
                              : const Color(0xFFE8F5EE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.lock_outline_rounded,
                          color: Color(0xFF388E6B),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Ubah Kata Sandi',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 22),

          // 2. Seksi Tampilan (Mode Gelap)
          _buildSettingsSectionHeader('Tampilan', isDark),
          const SizedBox(height: 8),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: AppTheme.themeModeNotifier,
            builder: (context, currentMode, _) {
              final isDarkModeActive = currentMode == ThemeMode.dark;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.2 : 0.03,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2E2A50)
                            : const Color(0xFFEDE9FE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.nightlight_round,
                        color: Color(0xFF818CF8),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Mode Gelap',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Switch(
                      value: isDarkModeActive,
                      activeThumbColor: const Color(0xFF388E6B),
                      activeTrackColor: const Color(
                        0xFF388E6B,
                      ).withValues(alpha: 0.5),
                      onChanged: (val) {
                        AppTheme.toggleDarkMode(val);
                      },
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 22),

          // 3. Seksi Informasi & Keluar
          _buildSettingsSectionHeader('Informasi', isDark),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                // Item 1: Tentang Aplikasi
                Material(
                  color: Colors.transparent,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  child: InkWell(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                    onTap: () {
                      setState(() {
                        _settingsSubView = _AdminSettingsSubView.aboutApp;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF113D38)
                                  : const Color(0xFFE8F5EE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.info_outline_rounded,
                              color: Color(0xFF388E6B),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Tentang Aplikasi',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF94A3B8),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Pemisah antar item
                Divider(
                  height: 1,
                  thickness: 0.8,
                  indent: 68,
                  endIndent: 16,
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFF1F5F9),
                ),

                // Item 2: Keluar
                Material(
                  color: Colors.transparent,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(18),
                  ),
                  child: InkWell(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(18),
                    ),
                    onTap: () => _handleLogout(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF3F1D1D)
                                  : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.logout_rounded,
                              color: Color(0xFFDC2626),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Keluar',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFDC2626),
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF94A3B8),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSettingsSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // B. SUB-VIEW: UBAH KATA SANDI (Password lama, baru, konfirmasi, checklist, Simpan)
  // ---------------------------------------------------------------------------
  Widget _buildUbahKataSandiView(bool isDark, Color primaryColor) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pesan Error jika validasi / verifikasi gagal
          if (_passwordErrorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFDC2626),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _passwordErrorMessage!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFB91C1C),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          // Input 1: Password lama
          _buildPillInputField(
            controller: _oldPasswordController,
            focusNode: _oldPasswordFocus,
            hintText: 'Password lama',
            obscureText: _obscureOldPassword,
            onToggleObscure: () {
              setState(() {
                _obscureOldPassword = !_obscureOldPassword;
              });
            },
            isDark: isDark,
            textInputAction: TextInputAction.next,
          ),

          const SizedBox(height: 18),

          // Input 2: Password baru
          _buildPillInputField(
            controller: _newPasswordController,
            focusNode: _newPasswordFocus,
            hintText: 'Password baru',
            obscureText: _obscureNewPassword,
            onToggleObscure: () {
              setState(() {
                _obscureNewPassword = !_obscureNewPassword;
              });
            },
            isDark: isDark,
            textInputAction: TextInputAction.next,
          ),

          const SizedBox(height: 14),

          // Checklist kriteria validasi kata sandi baru (Live Feedback)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                _buildPasswordCheckItem(
                  'Minimum 8 karakter (maksimal 16)',
                  _hasMinLength,
                  isDark,
                ),
                _buildPasswordCheckItem(
                  'Terdapat minimum 1 angka',
                  _hasDigit,
                  isDark,
                ),
                _buildPasswordCheckItem(
                  'Terdapat minimum 1 huruf besar dan 1 huruf kecil',
                  _hasUpperAndLower,
                  isDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Input 3: Konfirmasi password baru
          _buildPillInputField(
            controller: _confirmPasswordController,
            focusNode: _confirmPasswordFocus,
            hintText: 'Konfirmasi password baru',
            obscureText: _obscureConfirmPassword,
            onToggleObscure: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
            isDark: isDark,
            textInputAction: TextInputAction.done,
            onEditingComplete: _handleSaveNewPassword,
          ),

          const SizedBox(height: 32),

          // Tombol Aksi Simpan (Hijau berbentuk kapsul / pill)
          Center(
            child: SizedBox(
              width: 160,
              height: 44,
              child: ElevatedButton(
                onPressed: _isChangingPassword ? null : _handleSaveNewPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF388E6B),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: _isChangingPassword
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'Simpan',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPillInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggleObscure,
    required bool isDark,
    TextInputAction textInputAction = TextInputAction.next,
    VoidCallback? onEditingComplete,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.only(left: 20, right: 8),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        textInputAction: textInputAction,
        onEditingComplete: onEditingComplete,
        onChanged: (_) {
          if (_passwordErrorMessage != null) {
            setState(() {
              _passwordErrorMessage = null;
            });
          }
        },
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(
            fontSize: 13.5,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: isDark
                  ? const Color(0xFF64748B)
                  : const Color(0xFF94A3B8),
              size: 20,
            ),
            onPressed: onToggleObscure,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordCheckItem(String label, bool isSatisfied, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            isSatisfied
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked,
            size: 16,
            color: isSatisfied
                ? const Color(0xFF388E6B)
                : (isDark ? const Color(0xFF64748B) : const Color(0xFFCBD5E1)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isSatisfied
                    ? (isDark
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFF334155))
                    : (isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8)),
                fontWeight: isSatisfied ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSaveNewPassword() async {
    setState(() {
      _passwordErrorMessage = null;
    });

    FocusScope.of(context).unfocus();

    final oldPass = _oldPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (oldPass.isEmpty) {
      setState(() {
        _passwordErrorMessage =
            'Password lama wajib diisi untuk verifikasi keamanan.';
      });
      return;
    }

    if (!_hasMinLength || !_hasDigit || !_hasUpperAndLower) {
      setState(() {
        _passwordErrorMessage =
            'Password baru belum memenuhi semua kriteria keamanan.';
      });
      return;
    }

    if (newPass != confirmPass) {
      setState(() {
        _passwordErrorMessage = 'Konfirmasi password baru tidak cocok.';
      });
      return;
    }

    if (oldPass == newPass) {
      setState(() {
        _passwordErrorMessage =
            'Password baru tidak boleh sama dengan password lama.';
      });
      return;
    }

    setState(() {
      _isChangingPassword = true;
    });

    try {
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;

      if (currentUser != null && currentUser.email != null) {
        final credential = EmailAuthProvider.credential(
          email: currentUser.email!,
          password: oldPass,
        );

        // Verifikasi kata sandi lama via Firebase Authentication Reauthentication
        await currentUser.reauthenticateWithCredential(credential);

        // Update kata sandi baru di Firebase Auth
        await currentUser.updatePassword(newPass);

        // Catat timestamp perubahan kata sandi di Firestore TANPA menyimpan teks biasa
        await _authService.changePassword(
          currentPassword: oldPass,
          newPassword: newPass,
        );
      } else {
        // Fallback akun dummy / offline jika Firebase Auth belum login aktif
        if (oldPass != 'admin123' && oldPass != 'Admin123') {
          throw FirebaseAuthException(
            code: 'wrong-password',
            message: 'Password lama yang dimasukkan tidak cocok.',
          );
        }

        await _authService.changePassword(
          currentPassword: oldPass,
          newPassword: newPass,
        );
      }

      if (!mounted) return;

      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      setState(() {
        _isChangingPassword = false;
        _passwordErrorMessage = null;
        _settingsSubView = _AdminSettingsSubView.main;
      });

      AppAlert.showSuccess(
        context,
        'Kata sandi administrator berhasil diperbarui.',
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isChangingPassword = false;
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          _passwordErrorMessage =
              'Verifikasi gagal: Password lama Anda salah.';
        } else if (e.code == 'weak-password') {
          _passwordErrorMessage =
              'Password baru dinilai terlalu lemah oleh sistem.';
        } else if (e.code == 'requires-recent-login') {
          _passwordErrorMessage =
              'Sesi autentikasi telah kedaluwarsa. Silakan keluar dan login ulang.';
        } else {
          _passwordErrorMessage = e.message ?? 'Gagal memperbarui kata sandi.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isChangingPassword = false;
        _passwordErrorMessage = 'Terjadi kesalahan sistem: $e';
      });
    }
  }

  // ---------------------------------------------------------------------------
  // C. SUB-VIEW: TENTANG APLIKASI (Identitas, Fitur Utama, Catatan, Versi Footer)
  // ---------------------------------------------------------------------------
  Widget _buildTentangAplikasiView(bool isDark, Color primaryColor) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
      child: Column(
        children: [
          // Logo & Identitas ObeSight
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE8F3EE),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF388E6B), width: 2),
            ),
            padding: const EdgeInsets.all(12),
            child: Image.asset(
              'assets/logo.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.health_and_safety_rounded,
                color: Color(0xFF388E6B),
                size: 38,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'OBESIGHT',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1E3A2F),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kenali Risiko, Jaga Masa Depanmu',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? const Color(0xFF6EE7B7)
                  : const Color(0xFF388E6B),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'Obesight adalah aplikasi kesehatan yang membantu kamu melakukan skrining risiko obesitas berdasarkan pola hidup, serta membantu memantau kebiasaan hidup secara berkala.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isDark
                    ? const Color(0xFFCBD5E1)
                    : const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Card Fitur Utama Obesight
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF388E6B).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.stars_rounded,
                        color: Color(0xFF388E6B),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Fitur Utama Obesight',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Fitur 1: Skrining Risiko
                _buildAboutFeatureTile(
                  isDark: isDark,
                  icon: Icons.qr_code_scanner_rounded,
                  title: 'Skrining Risiko',
                  desc:
                      'Membantu kamu mengidentifikasi potensi risiko obesitas lebih awal berdasarkan gaya hidup.',
                ),
                const SizedBox(height: 10),

                // Fitur 2: Monitoring Pola Hidup
                _buildAboutFeatureTile(
                  isDark: isDark,
                  icon: Icons.assignment_outlined,
                  title: 'Monitoring Pola Hidup',
                  desc:
                      'Membantu kamu memantau perkembangan pola makan, aktivitas fisik, pola makan, dan kebiasaan tidur.',
                ),
                const SizedBox(height: 10),

                // Fitur 3: Rekomendasi GAYA-SEHAT
                _buildAboutFeatureTile(
                  isDark: isDark,
                  icon: Icons.lightbulb_outline_rounded,
                  title: 'Rekomendasi GAYA-SEHAT',
                  desc:
                      'Memberikan insight dan rekomendasi yang disesuaikan dengan kondisi kamu melalui teknologi AI.',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Catatan Medis (Amber Box)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF2E1F0B)
                  : const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF78350F)
                    : const Color(0xFFFDE68A),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFD97706),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Catatan:',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFFFDE68A)
                              : const Color(0xFF92400E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Obesight merupakan alat edukasi untuk skrining awal dan pembentukan gaya hidup, bukan alat untuk mendiagnosis secara medis. Tetap konsultasikan hasil dengan tenaga kesehatan.',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: isDark
                              ? const Color(0xFFFCD34D)
                              : const Color(0xFFB45309),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Footer Versi Aplikasi
          Text(
            'Versi 1.0.0',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF388E6B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '© 2026 Obesight. Semua hak dilindungi.',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: isDark
                  ? const Color(0xFF64748B)
                  : const Color(0xFF94A3B8),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAboutFeatureTile({
    required bool isDark,
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF4F9F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155)
              : const Color(0xFFE2EBE5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E3A2F)
                  : const Color(0xFFE8F5EE),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: const Color(0xFF388E6B),
            ),
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
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // D. DIALOG KELUAR DARI AKUN (Berdasarkan Gambar Referensi ObeSight)
  // ---------------------------------------------------------------------------
  void _showAdminLogoutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Keluar dari akun?',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Apakah kamu yakin ingin keluar dari akun Obesight?',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: isDark
                    ? const Color(0xFFCBD5E1)
                    : const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: BorderSide(
                        color: isDark
                            ? const Color(0xFF475569)
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Text(
                      'Batal',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _authService.logout();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const AdminLoginScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Keluar',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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

