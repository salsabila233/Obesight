import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/screening_history_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/screening_history_service.dart';
import '../settings/settings_screen.dart';
import '../skrining/skrining_landing_screen.dart';
import '../skrining/skrining_result_screen.dart';

class ScreeningHistoryScreen extends StatefulWidget {
  final UserModel? user;

  const ScreeningHistoryScreen({
    super.key,
    this.user,
  });

  @override
  State<ScreeningHistoryScreen> createState() => _ScreeningHistoryScreenState();
}

class _ScreeningHistoryScreenState extends State<ScreeningHistoryScreen> {
  late String _userId;

  UserModel get _effectiveUser {
    return widget.user ??
        AuthService().currentUser ??
        UserModel(
          id: 'usr_guest',
          name: 'Pengguna ObeSight',
          email: '',
          username: 'user',
          role: UserRole.user,
        );
  }

  @override
  void initState() {
    super.initState();
    final effective = _effectiveUser;
    _userId = ScreeningHistoryService.instance.resolveUserKey(effective.id, effective.email);

    // Muat riwayat tersimpan spesifik untuk akun pengguna saat ini
    ScreeningHistoryService.instance.loadHistory(_userId);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryGreen = isDark ? const Color(0xFF1E293B) : const Color(0xFF489874);
    final sheetBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: primaryGreen,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Riwayat Skrining',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: ScreeningHistoryService.instance,
        builder: (context, _) {
          final items = ScreeningHistoryService.instance.getHistory(_userId);
          final totalCount = ScreeningHistoryService.instance.getTotalCount(_userId);
          final highRiskCount = ScreeningHistoryService.instance.getHighRiskCount(_userId);
          final mediumRiskCount = ScreeningHistoryService.instance.getMediumRiskCount(_userId);
          final lowRiskCount = ScreeningHistoryService.instance.getLowRiskCount(_userId);

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: sheetBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==========================================
                    // 1. SEKSI RINGKASAN (4 KARTU STATISTIK)
                    // (0 Semua jika akun belum pernah skrining)
                    // ==========================================
                    Text(
                      'Ringkasan',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        // Card 1: Total Skrining
                        Expanded(
                          child: _buildSummaryCard(
                            count: totalCount,
                            label: 'Total Skrining',
                            bgColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFFBEAF4),
                            borderColor: isDark ? const Color(0xFF334155) : const Color(0xFFF5D6EB),
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Card 2: Risiko Tinggi
                        Expanded(
                          child: _buildSummaryCard(
                            count: highRiskCount,
                            label: 'Risiko Tinggi',
                            bgColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFFDEAEB),
                            borderColor: isDark ? const Color(0xFF334155) : const Color(0xFFFCD4D7),
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Card 3: Risiko Sedang
                        Expanded(
                          child: _buildSummaryCard(
                            count: mediumRiskCount,
                            label: 'Risiko Sedang',
                            bgColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFFEF8E3),
                            borderColor: isDark ? const Color(0xFF334155) : const Color(0xFFFDEEBB),
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Card 4: Risiko Rendah
                        Expanded(
                          child: _buildSummaryCard(
                            count: lowRiskCount,
                            label: 'Risiko Rendah',
                            bgColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFEAF1FB),
                            borderColor: isDark ? const Color(0xFF334155) : const Color(0xFFD2E3F8),
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // ==========================================
                    // 2. BANNER MOTIVASI (SPARKLE BADGE)
                    // ==========================================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEDF7F2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFD3EFE0),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFD8F1E4),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              color: isDark ? const Color(0xFF58AF86) : const Color(0xFF2E6B4F),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Terus pertahankan kebiasaan baikmu! Perkembangan kecil setiap hari membawa perubahan besar untuk kesehatanmu.',
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF2E6B4F),
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ==========================================
                    // 3. SEKSI DAFTAR RIWAYAT (TIMELINE CARDS)
                    // ==========================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Daftar Riwayat',
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        if (items.isNotEmpty)
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SkriningLandingScreen(user: _effectiveUser),
                                ),
                              ).then((_) {
                                if (mounted) {
                                  ScreeningHistoryService.instance.loadHistory(_userId);
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_circle_outline_rounded,
                                    size: 16,
                                    color: isDark ? const Color(0xFF58AF86) : const Color(0xFF489874),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Skrining Baru',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFF58AF86) : const Color(0xFF489874),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    if (items.isEmpty)
                      _buildEmptyState(context, isDark, textPrimary, textSecondary)
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final isFirst = index == 0;
                          final isLast = index == items.length - 1;
                          final screeningNumber = items.length - index;

                          return _buildTimelineRow(
                            context: context,
                            item: item,
                            screeningNumber: screeningNumber,
                            isFirst: isFirst,
                            isLast: isLast,
                            isDark: isDark,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          );
                        },
                      ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),

      // ==========================================
      // 4. FLOATING BOTTOM NAVIGATION BAR
      // ==========================================
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: _buildFloatingBottomNav(isDark),
        ),
      ),
    );
  }

  /// Kartu Ringkasan Statistik Horizontal
  Widget _buildSummaryCard({
    required int count,
    required String label,
    required Color bgColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$count',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textSecondary,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }

  /// Baris Timeline yang menghubungkan garis vertikal dengan dot berwarna dan kartu hasil
  Widget _buildTimelineRow({
    required BuildContext context,
    required ScreeningHistoryItem item,
    required int screeningNumber,
    required bool isFirst,
    required bool isLast,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFEAEAEA);
    final dateBoxBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final dateBoxBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Indikator Garis Vertikal & Titik Dot Berwarna
          SizedBox(
            width: 22,
            child: Column(
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    width: 2,
                    color: isFirst ? Colors.transparent : const Color(0xFFCBD5E1),
                  ),
                ),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: item.dotColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: isDark ? const Color(0xFF0F172A) : Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: item.dotColor.withValues(alpha: 0.35),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : const Color(0xFFCBD5E1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Kartu Riwayat
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    // Navigasi ke halaman hasil skrining yang pernah dilakukan
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SkriningResultScreen(
                          data: item.skriningData,
                          user: _effectiveUser,
                          isFromHistory: true,
                        ),
                      ),
                    ).then((_) {
                      if (mounted) {
                        ScreeningHistoryService.instance.loadHistory(_userId);
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        // Kotak Tanggal di Kiri
                        Container(
                          width: 54,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: dateBoxBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: dateBoxBorder),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item.day,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.monthYear,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary,
                                  height: 1.15,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Informasi IMT & Kategori
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Skrining #$screeningNumber',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? const Color(0xFF58AF86) : const Color(0xFF2E6B4F),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'IMT',
                                style: GoogleFonts.poppins(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: textSecondary,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    item.formattedBmi,
                                    style: GoogleFonts.poppins(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: item.riskBg,
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: Text(
                                      item.risk,
                                      style: GoogleFonts.poppins(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: item.riskColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Kategori',
                                style: GoogleFonts.poppins(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: textSecondary,
                                ),
                              ),
                              Text(
                                item.category,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Panah Chevron Kanan
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF94A3B8),
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tampilan Kosong jika akun belum pernah melakukan skrining (0 semua)
  Widget _buildEmptyState(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF489874).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_outlined,
              color: Color(0xFF489874),
              size: 38,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Belum Ada Riwayat Skrining',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Akun ini belum pernah melakukan skrining obesitas.\nLakukan skrining pertamamu untuk mulai memantau perkembangan kesehatan.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow_rounded, size: 20),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF489874),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SkriningLandingScreen(user: _effectiveUser),
                ),
              ).then((_) {
                if (mounted) {
                  ScreeningHistoryService.instance.loadHistory(_userId);
                }
              });
            },
            label: Text(
              'Mulai Skrining Sekarang',
              style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// Custom Floating Bottom Navigation Bar (Home, Analytics/Chart [Active], Settings)
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
          // Tab 0: Home (Kembali ke Beranda)
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.home_rounded,
                color: isDark ? const Color(0xFF94A3B8) : Colors.white.withValues(alpha: 0.8),
                size: 24,
              ),
            ),
          ),

          // Tab 1: Stats / Bar Chart (Aktif pada Halaman Riwayat Skrining)
          Container(
            width: 44,
            height: 38,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : Colors.white.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.bar_chart_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),

          // Tab 2: Settings (Pengaturan)
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(user: _effectiveUser),
                ),
              );
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.settings_rounded,
                color: isDark ? const Color(0xFF94A3B8) : Colors.white.withValues(alpha: 0.8),
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
