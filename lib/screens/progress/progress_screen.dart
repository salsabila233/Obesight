import 'dart:math' as math;
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
  int _selectedChartType = 0; // 0: Kurva Tren Dinamis, 1: Batang Kapsul Modern

  @override
  void initState() {
    super.initState();
    // Sinkronisasi riwayat skrining pengguna untuk menentukan siklus 1 bulan
    ScreeningHistoryService.instance
        .loadHistory(widget.user.id, widget.user.email)
        .then((_) {
      if (mounted) {
        ProgressTrackingService.instance
            .syncWithUserScreening(widget.user.id, widget.user.email);
      }
    });
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
                // 1. JADWAL SKRINING ULANG (Waktunya 1 bulan setelah skrining pertama)
                _buildNextScreeningCard(progressService, isDark),

                const SizedBox(height: 20),

                // 2. GRAFIK EVALUASI CAPAIAN PROGRES 1 BULAN (4 MINGGU)
                // Hanya berisi Makanan & Minuman dan Aktivitas Fisik (Waktu tidur tidak masuk grafik)
                _buildEvaluationProgressChartCard(
                    progressService, isDark, textPrimary),

                const SizedBox(height: 26),

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
          // Header Row: Icon + Judul + Countdown Badge
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
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                    Text(
                      service.formattedNextScreeningDate,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF36785A),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: service.daysUntilNextScreening <= 3
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF36785A),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${service.daysUntilNextScreening} Hari Lagi',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: service.daysUntilNextScreening <= 3
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF36785A),
                      ),
                    ),
                  ],
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
                    'Jadwal skrining ulang dijadwalkan tepat 1 bulan (30 hari) setelah skrining pertama (${service.formattedStartDate}) untuk mengevaluasi efektivitas latihan fisik dan asupan nutrisi Anda.',
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

          // Action Buttons
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
                  label: const Text('Riwayat Skrining'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textDark,
                    side: BorderSide(
                      color: isDark
                          ? const Color(0xFF475569)
                          : const Color(0xFFCBD5E1),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
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
                  onPressed: () async {
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
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Skrining Ulang'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF36785A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
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
  // 2. GRAFIK EVALUASI CAPAIAN PROGRES 1 BULAN
  // Menggambarkan progres yang sudah dicentang (Makanan & Minuman + Aktivitas Fisik)
  // Durasi 1 bulan / 4 minggu
  // Desain visual yang sangat menarik, estetik, dan interaktif
  // ==========================================
  Widget _buildEvaluationProgressChartCard(
    ProgressTrackingService service,
    bool isDark,
    Color textPrimary,
  ) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder =
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textMuted =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final overallPct = service.overallPercentage;
    final nutritionPct = service.nutritionPercentage;
    final activityPct = service.activityPercentage;
    final weeklySummaries = service.getWeeklySummaries();

    const nutritionColor = Color(0xFF10B981); // Emerald
    const activityColor = Color(0xFF0284C7); // Sky Blue

    // Status motivasi dinamis berdasarkan persentase
    String milestoneTitle;
    String milestoneDesc;
    IconData milestoneIcon;
    Color milestoneColor;

    if (overallPct >= 0.8) {
      milestoneTitle = 'Performa Sangat Luar Biasa!';
      milestoneDesc =
          'Target 1 bulan hampir tercapai dengan konsistensi prima.';
      milestoneIcon = Icons.emoji_events_rounded;
      milestoneColor = const Color(0xFFF59E0B);
    } else if (overallPct >= 0.5) {
      milestoneTitle = 'Konsistensi Sangat Baik!';
      milestoneDesc =
          'Lebih dari separuh target 1 bulan telah berhasil Anda tuntaskan.';
      milestoneIcon = Icons.local_fire_department_rounded;
      milestoneColor = const Color(0xFFEA580C);
    } else if (overallPct >= 0.2) {
      milestoneTitle = 'Terus Bergerak Maju!';
      milestoneDesc =
          'Langkah awal yang hebat, teruskan ceklis menu & olahraga harianmu.';
      milestoneIcon = Icons.trending_up_rounded;
      milestoneColor = const Color(0xFF10B981);
    } else {
      milestoneTitle = 'Mulai Capai Target 1 Bulan!';
      milestoneDesc =
          'Ceklis menu sehat & latihan fisik hari ini untuk mulai mengisi progres.';
      milestoneIcon = Icons.eco_rounded;
      milestoneColor = const Color(0xFF36785A);
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: cardBorder, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF36785A)
                .withValues(alpha: isDark ? 0.25 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    ProgressCompletedDetailScreen(user: widget.user),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ----------------------------------------------------
                // Header: Judul, Periode 1 Bulan (4 Minggu), dan Tag Action
                // ----------------------------------------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Evaluasi Capaian 1 Bulan',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isDark
                                        ? [
                                            const Color(0xFF163326),
                                            const Color(0xFF0F241A)
                                          ]
                                        : [
                                            const Color(0xFFE2F6ED),
                                            const Color(0xFFD3EFE1)
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF36785A)
                                        .withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Text(
                                  '4 Minggu',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF36785A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.date_range_rounded,
                                size: 14,
                                color: Color(0xFF36785A),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  'Periode: ${service.formattedDateRange}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF36785A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Action Pill: Lihat Detail
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.touch_app_rounded,
                            size: 14,
                            color: isDark
                                ? const Color(0xFF6EE7B7)
                                : const Color(0xFF36785A),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Lihat Detail',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFF6EE7B7)
                                  : const Color(0xFF36785A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // ----------------------------------------------------
                // HERO SECTION: DUAL ACTIVITY RING + ILUSTRASI BERKILAU
                // ----------------------------------------------------
                _buildHeroVisualSection(
                  service: service,
                  overallPct: overallPct,
                  nutritionPct: nutritionPct,
                  activityPct: activityPct,
                  milestoneTitle: milestoneTitle,
                  milestoneDesc: milestoneDesc,
                  milestoneIcon: milestoneIcon,
                  milestoneColor: milestoneColor,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),

                const SizedBox(height: 20),

                // ----------------------------------------------------
                // GRAFIK FREKUENSI 4 MINGGU (DENGAN TABS KURVA / KAPSUL)
                // ----------------------------------------------------
                _buildInteractiveChartContainer(
                  weeklySummaries: weeklySummaries,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  nutritionColor: nutritionColor,
                  activityColor: activityColor,
                ),

                const SizedBox(height: 18),

                // ----------------------------------------------------
                // 2 PILAR METRIC CARDS (Makanan & Minuman vs Aktivitas Fisik)
                // ----------------------------------------------------
                _buildPillarCard(
                  iconImg: 'assets/progress/clean/icon_salad.png',
                  iconFallback: Icons.eco_rounded,
                  title: 'Makanan & Minuman',
                  subtitle:
                      '${service.nutritionCompletedCount} dari ${service.nutritionTargetCount} menu dikonsumsi',
                  percentage: nutritionPct,
                  percentageColor: nutritionColor,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
                const SizedBox(height: 10),

                _buildPillarCard(
                  iconImg: 'assets/progress/clean/icon_shoe.png',
                  iconFallback: Icons.directions_run_rounded,
                  title: 'Aktivitas Fisik',
                  subtitle:
                      '${service.activityCompletedCount} dari ${service.activityTargetCount} sesi selesai',
                  percentage: activityPct,
                  percentageColor: activityColor,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),

                const SizedBox(height: 16),

                // ----------------------------------------------------
                // INTERACTIVE BANNER: KETUK UNTUK LIHAT RINCIAN CENTANG
                // ----------------------------------------------------
                _buildInteractiveHintBanner(service, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // HERO VISUAL: DUAL ACTIVITY RING + MASCOT ART
  // ==========================================
  Widget _buildHeroVisualSection({
    required ProgressTrackingService service,
    required double overallPct,
    required double nutritionPct,
    required double activityPct,
    required String milestoneTitle,
    required String milestoneDesc,
    required IconData milestoneIcon,
    required Color milestoneColor,
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
  }) {
    final overallInt = (overallPct * 100).toInt();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF0F172A),
                  const Color(0xFF132A1F),
                  const Color(0xFF0F202B),
                ]
              : [
                  const Color(0xFFF0FDF4),
                  const Color(0xFFE6F7EF),
                  const Color(0xFFF0F9FF),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFC7EEDB),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981)
                .withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. Dual Concentric Activity Rings
          SizedBox(
            width: 110,
            height: 110,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(110, 110),
                  painter: DualCircularProgressPainter(
                    nutritionProgress: nutritionPct,
                    activityProgress: activityPct,
                    isDark: isDark,
                  ),
                ),
                // Center Badge Disk
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$overallInt%',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Selesai',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF36785A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // 2. Motivational Text & Target Chip
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(milestoneIcon, size: 16, color: milestoneColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        milestoneTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  milestoneDesc,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: textMuted,
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFD1EAE0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: isDark ? 0.2 : 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 13,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${service.totalCompletedActions} dari ${service.totalTargetActions} Target Tercapai',
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF36785A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),

          // 3. Mascot Illustration with Aura Halo & Badge
          _buildMascotIllustration(isDark),
        ],
      ),
    );
  }

  // ==========================================
  // MASCOT ILLUSTRATION FRAME DENGAN HALO AURA
  // ==========================================
  Widget _buildMascotIllustration(bool isDark) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Background Glow Halo Orb
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: isDark
                  ? [
                      const Color(0xFF235B42).withValues(alpha: 0.5),
                      const Color(0xFF0F172A).withValues(alpha: 0.05),
                    ]
                  : [
                      const Color(0xFFD1FAE5),
                      const Color(0xFFE6F7EF).withValues(alpha: 0.1),
                    ],
            ),
          ),
        ),

        // Mascot Character Image
        Image.asset(
          'assets/progress/clean/character_woman.png',
          height: 82,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              const SizedBox.shrink(),
        ),

        // Floating Achievement Pill Tag
        Positioned(
          top: -2,
          right: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, size: 10, color: Colors.white),
                const SizedBox(width: 2),
                Text(
                  '30 Hari',
                  style: GoogleFonts.poppins(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // INTERACTIVE CHART CONTAINER DENGAN SWITCHER TABS
  // ==========================================
  Widget _buildInteractiveChartContainer({
    required List<WeeklyProgressSummary> weeklySummaries,
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
    required Color nutritionColor,
    required Color activityColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar: Title + Segmented Switcher Tabs (Kurva Tren vs Batang Kapsul)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Grafik Frekuensi 4 Minggu',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              // Segmented Toggle
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSegmentTab(
                      index: 0,
                      label: 'Kurva Tren',
                      icon: Icons.show_chart_rounded,
                      isSelected: _selectedChartType == 0,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 3),
                    _buildSegmentTab(
                      index: 1,
                      label: 'Batang Kapsul',
                      icon: Icons.bar_chart_rounded,
                      isSelected: _selectedChartType == 1,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Legend Bar: Makanan & Minuman vs Aktivitas Fisik
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildLegendDot(nutritionColor, '🥗 Makanan & Minuman', isDark),
              const SizedBox(width: 12),
              _buildLegendDot(activityColor, '🏃 Aktivitas Fisik', isDark),
            ],
          ),

          const SizedBox(height: 14),

          // Render Chosen Chart View
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _selectedChartType == 0
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: _buildCurvedWaveChartView(
              weeklySummaries: weeklySummaries,
              isDark: isDark,
              textPrimary: textPrimary,
              textMuted: textMuted,
              nutritionColor: nutritionColor,
              activityColor: activityColor,
            ),
            secondChild: _buildCapsuleBarChartView(
              weeklySummaries: weeklySummaries,
              isDark: isDark,
              textPrimary: textPrimary,
              textMuted: textMuted,
              nutritionColor: nutritionColor,
              activityColor: activityColor,
            ),
          ),
        ],
      ),
    );
  }

  // Segment Tab Helper
  Widget _buildSegmentTab({
    required int index,
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedChartType = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF36785A) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected
                  ? (isDark ? Colors.white : const Color(0xFF36785A))
                  : (isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF36785A))
                    : (isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // VIEW 1: GRAFIK KURVA TREN HALUS (SMOOTH SPLINE WAVE)
  // ==========================================
  Widget _buildCurvedWaveChartView({
    required List<WeeklyProgressSummary> weeklySummaries,
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
    required Color nutritionColor,
    required Color activityColor,
  }) {
    return Column(
      children: [
        // Custom Wave Spline Canvas
        SizedBox(
          width: double.infinity,
          height: 140,
          child: CustomPaint(
            size: const Size(double.infinity, 140),
            painter: CurvedWaveChartPainter(
              weeklySummaries: weeklySummaries,
              nutritionColor: nutritionColor,
              activityColor: activityColor,
              isDark: isDark,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // 4 Columns for Week Badges (M1, M2, M3, M4) & Date Range
        Padding(
          padding: const EdgeInsets.only(left: 28, right: 14),
          child: Row(
            children: weeklySummaries.map((w) {
              final pctInt = (w.percentage * 100).toInt();

              return Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: pctInt > 0
                            ? const Color(0xFF36785A)
                                .withValues(alpha: isDark ? 0.25 : 0.12)
                            : (isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$pctInt%',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: pctInt > 0
                              ? const Color(0xFF36785A)
                              : (isDark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF94A3B8)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      w.label,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      w.dateRangeText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // VIEW 2: GRAFIK BATANG KAPSUL MODERN
  // ==========================================
  Widget _buildCapsuleBarChartView({
    required List<WeeklyProgressSummary> weeklySummaries,
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
    required Color nutritionColor,
    required Color activityColor,
  }) {
    return Column(
      children: [
        Stack(
          children: [
            // Background Guide Lines (100%, 50%, 0%)
            Positioned.fill(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                      height: 1,
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFE2E8F0)),
                  Container(
                      height: 1,
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFE2E8F0)),
                  Container(
                      height: 1,
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFCBD5E1)),
                ],
              ),
            ),

            // 4 Columns for Week 1 to Week 4
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weeklySummaries.map((w) {
                return Expanded(
                  child: _buildSculptedWeekBarColumn(
                    w,
                    isDark,
                    textPrimary,
                    textMuted,
                    nutritionColor,
                    activityColor,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSculptedWeekBarColumn(
    WeeklyProgressSummary w,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color nutritionColor,
    Color activityColor,
  ) {
    final pct = w.percentage;
    final pctInt = (pct * 100).toInt();

    // Tinggi batang kapsul side-by-side (max 78px)
    const double maxH = 78.0;
    final double nH = math.max(6.0, (w.nutritionPercentage * maxH));
    final double aH = math.max(6.0, (w.activityPercentage * maxH));

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Floating Pill persentase di atas batang
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: pctInt > 0
                ? const Color(0xFF36785A)
                    .withValues(alpha: isDark ? 0.25 : 0.12)
                : (isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: pctInt > 0
                  ? const Color(0xFF36785A)
                      .withValues(alpha: isDark ? 0.4 : 0.2)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (pctInt == 100) ...[
                const Icon(Icons.star_rounded,
                    size: 10, color: Color(0xFFF59E0B)),
                const SizedBox(width: 2),
              ],
              Text(
                '$pctInt%',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: pctInt > 0
                      ? const Color(0xFF36785A)
                      : (isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Track container dengan 2 batang kapsul paralel berkilau
        Container(
          height: 86,
          width: 36,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          alignment: Alignment.bottomCenter,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEBF1ED),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFDCE8E0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Batang 1: Makanan & Minuman (Emerald Mint Capsule)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: nH,
                width: 11,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      nutritionColor.withValues(alpha: 0.85),
                      const Color(0xFF34D399),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: nutritionColor.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
              // Batang 2: Aktivitas Fisik (Ocean Sky Capsule)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: aH,
                width: 11,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      activityColor.withValues(alpha: 0.85),
                      const Color(0xFF38BDF8),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: activityColor.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Label Minggu & Rentang Tanggal
        Text(
          w.label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        Text(
          w.dateRangeText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 9,
            color: textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendDot(Color color, String text, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // METRIC PILLAR CARDS DENGAN GLOWING PROGRESS
  // ==========================================
  Widget _buildPillarCard({
    required String iconImg,
    required IconData iconFallback,
    required String title,
    required String subtitle,
    required double percentage,
    required Color percentageColor,
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
  }) {
    final pctInt = (percentage * 100).toInt();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: percentageColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  iconImg,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(iconFallback, size: 20, color: percentageColor),
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
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: percentageColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: percentageColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  '$pctInt% Selesai',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: percentageColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Glowing Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 8,
              width: double.infinity,
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              child: Row(
                children: [
                  Flexible(
                    flex: pctInt.clamp(1, 100),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            percentageColor.withValues(alpha: 0.8),
                            percentageColor,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: percentageColor.withValues(alpha: 0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Flexible(
                    flex: (100 - pctInt).clamp(0, 100),
                    child: Container(color: Colors.transparent),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // INTERACTIVE HINT BANNER
  // ==========================================
  Widget _buildInteractiveHintBanner(
      ProgressTrackingService service, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1B2A22), const Color(0xFF15222E)]
              : [const Color(0xFFE8F5EF), const Color(0xFFE3F2FD)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFB8E2CE),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF36785A)
                .withValues(alpha: isDark ? 0.15 : 0.05),
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
              color: const Color(0xFF36785A).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.checklist_rounded,
              size: 18,
              color: Color(0xFF36785A),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ketuk grafik untuk rincian progres yang sudah dilakukan',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFF6EE7B7)
                        : const Color(0xFF1E4A37),
                  ),
                ),
                Text(
                  '${service.totalCompletedActions} item terselesaikan selama 30 hari ini',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              color: Color(0xFF36785A),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              size: 13,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. FEATURE TILE BUILDER (Card-card yang sudah ada)
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
    final descColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

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
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        desc,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: descColor,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
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

/// CustomPainter untuk menggambar Dual Activity Rings (Lingkaran Cincin Progres Ganda)
/// Outer Ring: 🥗 Makanan & Minuman (Emerald Gradient)
/// Inner Ring: 🏃 Aktivitas Fisik (Sky Blue Gradient)
class DualCircularProgressPainter extends CustomPainter {
  final double nutritionProgress; // 0.0 .. 1.0
  final double activityProgress; // 0.0 .. 1.0
  final bool isDark;

  DualCircularProgressPainter({
    required this.nutritionProgress,
    required this.activityProgress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - 8;
    final innerRadius = outerRadius - 13;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 1. Outer Track (Nutrition)
    trackPaint.strokeWidth = 8.5;
    trackPaint.color =
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    canvas.drawCircle(center, outerRadius, trackPaint);

    // 2. Inner Track (Activity)
    trackPaint.strokeWidth = 8.5;
    trackPaint.color =
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    canvas.drawCircle(center, innerRadius, trackPaint);

    // 3. Outer Arc (Nutrition - Emerald Green Gradient)
    if (nutritionProgress > 0) {
      final nutritionPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 8.5
        ..shader = const SweepGradient(
          colors: [Color(0xFF34D399), Color(0xFF059669)],
          startAngle: -math.pi / 2,
          endAngle: 3 * math.pi / 2,
        ).createShader(Rect.fromCircle(center: center, radius: outerRadius));

      final sweepAngle =
          (2 * math.pi * nutritionProgress).clamp(0.02, 2 * math.pi);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius),
        -math.pi / 2,
        sweepAngle,
        false,
        nutritionPaint,
      );
    }

    // 4. Inner Arc (Activity - Sky Blue Gradient)
    if (activityProgress > 0) {
      final activityPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 8.5
        ..shader = const SweepGradient(
          colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
          startAngle: -math.pi / 2,
          endAngle: 3 * math.pi / 2,
        ).createShader(Rect.fromCircle(center: center, radius: innerRadius));

      final sweepAngle =
          (2 * math.pi * activityProgress).clamp(0.02, 2 * math.pi);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: innerRadius),
        -math.pi / 2,
        sweepAngle,
        false,
        activityPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DualCircularProgressPainter oldDelegate) {
    return oldDelegate.nutritionProgress != nutritionProgress ||
        oldDelegate.activityProgress != activityProgress ||
        oldDelegate.isDark != isDark;
  }
}

