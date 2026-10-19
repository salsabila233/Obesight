import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/nutrition_checklist_service.dart';
import '../../services/physical_activity_service.dart';
import '../../services/progress_tracking_service.dart';
import '../../services/screening_history_service.dart';
import '../../widgets/progress_page_scaffold.dart';
import '../profile/complete_profile_screen.dart';
import '../skrining/skrining_landing_screen.dart';
import 'night_sleep_detail_screen.dart';
import 'nutrition_recommendation_screen.dart';
import 'physical_activity_screen.dart';
import 'progress_completed_detail_screen.dart';
import 'screening_history_screen.dart';

class ProgressScreen extends StatefulWidget {
  final UserModel user;

  const ProgressScreen({super.key, required this.user});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  @override
  void initState() {
    super.initState();
    // Sinkronisasi awal dengan cache memori jika data riwayat sudah ada
    ProgressTrackingService.instance
        .syncWithUserScreening(widget.user.id, widget.user.email);
    PhysicalActivityService.instance.syncAllSessionsFromFirestore();

    // Sinkronisasi riwayat skrining pengguna dari storage/Firestore
    ScreeningHistoryService.instance
        .loadHistory(widget.user.id, widget.user.email)
        .then((_) {
      if (mounted) {
        ProgressTrackingService.instance
            .syncWithUserScreening(widget.user.id, widget.user.email);
        PhysicalActivityService.instance.syncAllSessionsFromFirestore();
      }
    });
  }

  Future<void> _openScreeningFlow() async {
    final isComplete =
        await AuthService().checkProfileGating(widget.user.id);
    if (!mounted) return;
    if (!isComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lengkapi data diri terlebih dahulu sebelum melakukan skrining.',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: const Color(0xFFD97706),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CompleteProfileScreen(
            user: widget.user,
            isGatedFlow: true,
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SkriningLandingScreen(user: widget.user),
      ),
    );
  }

  void _openCompletedDetail() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProgressCompletedDetailScreen(user: widget.user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);

    return ListenableBuilder(
      listenable: Listenable.merge([
        ProgressTrackingService.instance,
        NutritionChecklistService.instance,
        PhysicalActivityService.instance,
        ScreeningHistoryService.instance,
      ]),
      builder: (context, _) {
        final progressService = ProgressTrackingService.instance;

        return ProgressPageScaffold(
          title: 'Progress',
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. JADWAL SKRINING ULANG (Hanya muncul jika sudah pernah skrining)
                // Kalo belum pernah skrining ya nggak ada, jika sudah baru akan muncul skrining ulang tgl berapa
                if (progressService.hasActiveScreening) ...[
                  _buildNextScreeningCard(progressService, isDark),
                  const SizedBox(height: 20),
                ],

                // 2. GRAFIK & EVALUASI CAPAIAN PROGRES 1 BULAN (4 MINGGU)
                _buildEvaluationProgressChartCard(
                    progressService, isDark, textPrimary),

                const SizedBox(height: 24),

                // 3. CARD-CARD PANTAU KESEHATANMU (Makanan & Minuman, Aktivitas Fisik, Waktu Tidur)
                Text(
                  'Pantau Kesehatanmu',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // Feature 1: Makanan & Minuman
                _buildFeatureTile(
                  iconImg: 'assets/progress/clean/icon_salad.png',
                  iconFallback: Icons.eco_outlined,
                  iconBg: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFE2F1E8),
                  iconColor: isDark
                      ? const Color(0xFF58AF86)
                      : const Color(0xFF36785A),
                  title: 'Makanan & Minuman',
                  desc: 'Pantau asupan nutrisi seimbang dan kalori harianmu.',
                  isHighlighted: true,
                  borderColor: isDark
                      ? const Color(0xFF58AF86).withValues(alpha: 0.5)
                      : const Color(0xFF36785A).withValues(alpha: 0.4),
                  isDark: isDark,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NutritionRecommendationScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Feature 2: Aktivitas Fisik
                _buildFeatureTile(
                  iconImg: 'assets/progress/clean/icon_shoe.png',
                  iconFallback: Icons.directions_run_rounded,
                  iconBg: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFE0F2FE),
                  iconColor: isDark
                      ? const Color(0xFF38BDF8)
                      : const Color(0xFF0284C7),
                  title: 'Aktivitas Fisik',
                  desc:
                      'Panduan olahraga, durasi & rekomendasi aktivitas fisik harian.',
                  isHighlighted: true,
                  borderColor: isDark
                      ? const Color(0xFF38BDF8).withValues(alpha: 0.5)
                      : const Color(0xFFBAE6FD),
                  isDark: isDark,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            PhysicalActivityScreen(user: widget.user),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Feature 3: Waktu Tidur
                _buildFeatureTile(
                  iconImg: 'assets/progress/clean/icon_bed.png',
                  iconFallback: Icons.nightlight_round,
                  iconBg: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFE8F4EE),
                  iconColor: isDark
                      ? const Color(0xFF34D399)
                      : const Color(0xFF235B42),
                  title: 'Waktu Tidur',
                  desc: 'Pantau durasi tidur malam dan kualitas istirahatmu.',
                  isHighlighted: true,
                  borderColor: isDark
                      ? const Color(0xFF34D399).withValues(alpha: 0.5)
                      : const Color(0xFFA5D6C1),
                  isDark: isDark,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NightSleepDetailScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 28),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // 1. JADWAL SKRINING ULANG CARD
  // Waktunya satu bulan setelah skrining pertama
  // ==========================================
  Widget _buildNextScreeningCard(ProgressTrackingService service, bool isDark) {
    final primaryColor = const Color(0xFF36785A);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder =
        isDark ? const Color(0xFF334155) : const Color(0xFFD0EAE0);
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cardBorder, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Icon + Judul + Countdown Badge (Anti-overflow)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF36785A).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Color(0xFF36785A),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jadwal Skrining Ulang',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                    Text(
                      service.formattedNextScreeningDate,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF36785A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: service.daysUntilNextScreening <= 3
                        ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                        : const Color(0xFF36785A).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: service.daysUntilNextScreening <= 3
                          ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                          : const Color(0xFF36785A).withValues(alpha: 0.3),
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 13,
                          color: service.daysUntilNextScreening <= 3
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF36785A),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${service.daysUntilNextScreening} Hari Lagi',
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: service.daysUntilNextScreening <= 3
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF36785A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Detail Deskripsi Rekomendasi Skrining Ulang 1 Bulan
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF6FAF8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 17,
                  color: Color(0xFF36785A),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Jadwal skrining ulang dijadwalkan tepat 1 bulan (30 hari) setelah skrining terakhir (${service.formattedStartDate}) untuk mengevaluasi efektivitas latihan fisik dan asupan nutrisi Anda.',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: textMuted,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Action Buttons (Anti-overflow menggunakan FittedBox)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ScreeningHistoryScreen(user: widget.user),
                      ),
                    );
                  },
                  icon: const Icon(Icons.history_rounded, size: 16),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Riwayat Skrining'),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textDark,
                    side: BorderSide(
                      color: isDark
                          ? const Color(0xFF475569)
                          : const Color(0xFFCBD5E1),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openScreeningFlow,
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Skrining Ulang'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF36785A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ==========================================
  // 2. GRAFIK CAPAIAN PROGRES 1 BULAN (HANYA MEMUAT GRAFIK)
  // Menampilkan grafik capaian mingguan yang terhubung langsung dengan siklus progres skrining
  // Menghapus tulisan capaian target ideal, nutrisi, aktivitas fisik, dan status
  // Card hanya memuat grafiknya saja
  // Jika belum ada progres (atau belum ada skrining), grafik ditampilkan kosong sesuai hasil skrining
  // ==========================================
  Widget _buildEvaluationProgressChartCard(
    ProgressTrackingService service,
    bool isDark,
    Color textPrimary,
  ) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder =
        isDark ? const Color(0xFF334155) : const Color(0xFFE9F3ED);
    final textMuted =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final weeklySummaries = service.getWeeklySummaries();
    final totalCompleted = service.totalCompletedActions;
    final hasActiveScreening = service.hasActiveScreening;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color:
                const Color(0xFF1E293B).withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _openCompletedDetail,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card: Judul Grafik, Periode Siklus Skrining & Navigasi Panah
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Grafik Capaian Mingguan',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hasActiveScreening
                                ? 'Periode: ${service.formattedDateRange}'
                                : 'Belum Ada Siklus Skrining',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (totalCompleted > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF36785A)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF36785A),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '$totalCompleted Selesai',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF36785A),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF334155).withValues(alpha: 0.5)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          hasActiveScreening ? '0 Selesai' : 'Kosong',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: textMuted,
                          ),
                        ),
                      ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: Color(0xFF94A3B8),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                Divider(
                  height: 1,
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFF1F5F9),
                ),
                const SizedBox(height: 16),

                // Jika belum ada progres (0 selesai) atau belum ada skrining, tampilkan grafik kosong
                if (!hasActiveScreening || totalCompleted == 0)
                  _buildEmptyChartView(
                      hasActiveScreening, isDark, textPrimary, textMuted)
                else
                  // Batang-batang Grafik Mingguan (M1, M2, M3, M4)
                  _buildWeeklyBarsRow(
                      weeklySummaries, isDark, textPrimary, textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAMPILAN GRAFIK KOSONG (Kalo progres belum ada / belum skrining)
  // ==========================================
  Widget _buildEmptyChartView(
    bool hasActiveScreening,
    bool isDark,
    Color textPrimary,
    Color textMuted,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F172A).withValues(alpha: 0.35)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155).withValues(alpha: 0.5)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFEEF2F6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bar_chart_rounded,
              size: 24,
              color: textMuted.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Grafik Kosong',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasActiveScreening
                ? 'Belum ada progres pada siklus skrining ini.\nGrafik akan otomatis terisi saat kamu mencatat checklist makanan dan aktivitas fisik.'
                : 'Belum ada riwayat skrining aktif.\nLakukan skrining terlebih dahulu agar target dan progres grafik kamu dapat dipantau sesuai hasil skrining.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: textMuted,
              height: 1.45,
            ),
          ),
          if (!hasActiveScreening) ...[
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _openScreeningFlow,
              icon: const Icon(Icons.play_arrow_rounded, size: 16),
              label: const Text('Mulai Skrining Sekarang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF36785A),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    vertical: 8, horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // GRAFIK BATANG MINGGUAN (BEBAS OVERFLOW & MENYATU)
  // ==========================================
  Widget _buildWeeklyBarsRow(
    List<WeeklyProgressSummary> summaries,
    bool isDark,
    Color textPrimary,
    Color textMuted,
  ) {
    return SizedBox(
      height: 140, // Ruang leluasa (140px) mencegah bottom overflow
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: summaries.map((w) {
          final pct = w.percentage;
          final hasData = w.totalCompleted > 0;
          final barH = hasData ? (16.0 + (pct * 44.0).clamp(0.0, 44.0)) : 0.0;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 16,
                      child: Center(
                        child: Text(
                          hasData ? '${w.totalCompleted}' : '0',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: hasData
                                ? const Color(0xFF36785A)
                                : textMuted.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Track + Batang Vertikal Kapsul Rounded
                    Container(
                      width: 26,
                      height: 64,
                      alignment: Alignment.bottomCenter,
                      decoration: BoxDecoration(
                        color: hasData
                            ? (isDark
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFF1F5F9))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: hasData
                          ? AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 24,
                              height: barH,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF36785A),
                                    Color(0xFF265C45)
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF36785A)
                                        .withValues(alpha: 0.25),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            )
                          : Container(
                              width: 14,
                              height: 3,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFCBD5E1),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'M${w.weekNumber}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: hasData
                            ? const Color(0xFF36785A)
                            : textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      w.dateRangeText,
                      maxLines: 1,
                      style: GoogleFonts.poppins(
                        fontSize: 8.5,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==========================================
  // 3. FEATURE TILE BUILDER (Card-card modul)
  // ==========================================
  Widget _buildFeatureTile({
    required String iconImg,
    required IconData iconFallback,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String desc,
    required VoidCallback onTap,
    bool isHighlighted = false,
    bool isDark = false,
    Color? borderColor,
  }) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = borderColor ??
        (isDark
            ? (isHighlighted
                ? const Color(0xFF58AF86).withValues(alpha: 0.5)
                : const Color(0xFF334155))
            : (isHighlighted
                ? const Color(0xFF36785A).withValues(alpha: 0.4)
                : const Color(0xFFE2E8F0)));
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final descColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: cardBorder,
          width: isHighlighted || borderColor != null ? 1.3 : 1.0,
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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset(
                    iconImg,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(iconFallback, color: iconColor, size: 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        desc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: descColor,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isHighlighted
                      ? (isDark
                          ? const Color(0xFF58AF86)
                          : const Color(0xFF36785A))
                      : const Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
