import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/nutrition_service.dart';
import '../../services/progress_tracking_service.dart';
import '../profile/complete_profile_screen.dart';
import '../skrining/skrining_landing_screen.dart';
import 'night_sleep_detail_screen.dart';
import 'nutrition_recommendation_screen.dart';
import 'physical_activity_screen.dart';
import 'saved_nutrition_list_screen.dart';
import 'screening_history_screen.dart';

class ProgressScreen extends StatefulWidget {
  final UserModel user;

  const ProgressScreen({super.key, required this.user});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _selectedFilterIndex = 0; // 0: Semua, 1: Latihan, 2: Pola Makan, 3: Waktu Tidur

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F6F8);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);

    return ListenableBuilder(
      listenable: Listenable.merge([
        NutritionService.instance,
        ProgressTrackingService.instance,
      ]),
      builder: (context, _) {
        final currentFood = NutritionService.instance.myFood;
        final currentDrink = NutritionService.instance.myDrink;
        final progressService = ProgressTrackingService.instance;

        return Scaffold(
          backgroundColor: scaffoldBg,
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF36785A),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Progress',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            // Gambar jam/riwayat skrining di pojok kanan atas telah dihapus sesuai permintaan
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Motivation Banner Card
                _buildMotivationCard(isDark),

                const SizedBox(height: 18),

                // 2. Banner Jadwal Skrining Ulang Berdasarkan Hasil Rekomendasi
                _buildNextScreeningCard(progressService, isDark),

                const SizedBox(height: 18),

                // 3. GRAFIK EVALUASI CAPAIAN PROGRES RENTANG WAKTU
                _buildEvaluationProgressChartCard(progressService, isDark, textPrimary),

                const SizedBox(height: 20),

                // 4. Quick Cards Grid (Makananku & Minumanku)
                _buildQuickNutritionGrid(currentFood, currentDrink, isDark, textPrimary),

                const SizedBox(height: 22),

                // 5. Section Pantau Kesehatanmu
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
                  iconBg: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2F1E8),
                  iconColor: isDark ? const Color(0xFF58AF86) : const Color(0xFF36785A),
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
                  iconBg: isDark ? const Color(0xFF0F172A) : const Color(0xFFE0F2FE),
                  iconColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                  title: 'Aktivitas Fisik',
                  desc: 'Panduan olahraga, durasi & rekomendasi aktivitas fisik harian.',
                  isHighlighted: true,
                  borderColor: isDark
                      ? const Color(0xFF38BDF8).withValues(alpha: 0.5)
                      : const Color(0xFFBAE6FD),
                  isDark: isDark,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PhysicalActivityScreen()),
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Feature 3: Waktu Tidur
                _buildFeatureTile(
                  iconImg: 'assets/progress/clean/icon_bed.png',
                  iconFallback: Icons.nightlight_round,
                  iconBg: isDark ? const Color(0xFF0F172A) : const Color(0xFFE8F4EE),
                  iconColor: isDark ? const Color(0xFF34D399) : const Color(0xFF235B42),
                  title: 'Waktu Tidur',
                  desc: 'Pantau durasi tidur malam dan kualitas istirahatmu.',
                  isHighlighted: true,
                  borderColor: isDark
                      ? const Color(0xFF34D399).withValues(alpha: 0.5)
                      : const Color(0xFFA5D6C1),
                  isDark: isDark,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NightSleepDetailScreen()),
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
  // 1. MOTIVATION CARD
  // ==========================================
  Widget _buildMotivationCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF1B382B)]
              : [const Color(0xFFE6F7F0), const Color(0xFFD4F1E4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFC4ECDA),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF36785A).withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFF36785A).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'TARGET HARI INI',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF23533E),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tetap Semangat, Capai Berat Ideal!',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF112A1F),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Konsistensi dan langkah kecil harian adalah kunci keberhasilan gaya hidup sehat.',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF375347),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: Image.asset(
              'assets/progress/clean/character_woman.png',
              height: 110,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.directions_run_rounded,
                size: 64,
                color: isDark ? const Color(0xFF58AF86) : const Color(0xFF36785A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. JADWAL SKRINING ULANG CARD
  // ==========================================
  Widget _buildNextScreeningCard(ProgressTrackingService service, bool isDark) {
    final primaryColor = const Color(0xFF36785A);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFD0EAE0);
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

          // Detail Deskripsi Rekomendasi Skrining
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF6FAF8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, size: 17, color: Color(0xFF36785A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Berdasarkan hasil skrining kategori ${service.category} (IMT ${service.bmi.toStringAsFixed(1)}), skrining berkala disarankan setiap ${service.category.contains('Normal') ? '30 hari' : '14 hari'} untuk mengevaluasi efektivitas latihan, nutrisi, dan pola istirahat.',
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
                      MaterialPageRoute(builder: (_) => const ScreeningHistoryScreen()),
                    );
                  },
                  icon: const Icon(Icons.history_rounded, size: 16),
                  label: const Text('Riwayat Skrining'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textDark,
                    side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    textStyle: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final isComplete = await AuthService().checkProfileGating(widget.user.id);
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    textStyle: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600),
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
  // 3. GRAFIK & EVALUASI CAPAIAN PROGRES RENTANG WAKTU
  // ==========================================
  Widget _buildEvaluationProgressChartCard(
    ProgressTrackingService service,
    bool isDark,
    Color textPrimary,
  ) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final exercisePct = service.getCategoryPercentage('Latihan');
    final nutritionPct = service.getCategoryPercentage('Pola Makan');
    final sleepPct = service.getCategoryPercentage('Waktu Tidur');
    final overallPct = service.overallPercentage;

    final exerciseColor = const Color(0xFF10B981); // Emerald
    final nutritionColor = const Color(0xFFF59E0B); // Amber
    final sleepColor = const Color(0xFF8B5CF6); // Purple

    // Filter goals
    List<RecommendationProgressGoal> displayGoals = service.goals;
    if (_selectedFilterIndex == 1) {
      displayGoals = service.getGoalsByCategory('Latihan');
    } else if (_selectedFilterIndex == 2) {
      displayGoals = service.getGoalsByCategory('Pola Makan');
    } else if (_selectedFilterIndex == 3) {
      displayGoals = service.getGoalsByCategory('Waktu Tidur');
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Judul & Rentang Waktu Periode
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Evaluasi Capaian Rekomendasi',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.date_range_rounded, size: 14, color: Color(0xFF36785A)),
                        const SizedBox(width: 4),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF36785A), Color(0xFF489874)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF36785A).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      '${(overallPct * 100).toInt()}%',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'Selesai',
                      style: GoogleFonts.poppins(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // GRAFIK BATANG KOMPARASI (Sudah Dilakukan vs Belum Dilakukan)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ringkasan Bar Status Keseluruhan
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Total Target Dilakukan',
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${service.totalCompletedActions} dari ${service.totalTargetActions} Target Tercapai',
                        textAlign: TextAlign.end,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF36785A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Multi-Segment Progress Bar Keseluruhan
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 12,
                    width: double.infinity,
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    child: Row(
                      children: [
                        Flexible(
                          flex: (overallPct * 100).toInt(),
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF36785A), Color(0xFF489874)],
                              ),
                            ),
                          ),
                        ),
                        Flexible(
                          flex: ((1.0 - overallPct) * 100).toInt(),
                          child: Container(color: Colors.transparent),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Grafik 3 Pilar: Latihan, Pola Makan, Waktu Tidur
                _buildPillarProgressBar(
                  label: '🏃 Latihan Fisik',
                  doneText: '${(exercisePct * 100).toInt()}% Selesai',
                  remainingText: '${((1.0 - exercisePct) * 100).toInt()}% Belum',
                  percentage: exercisePct,
                  color: exerciseColor,
                  isDark: isDark,
                ),
                const SizedBox(height: 10),

                _buildPillarProgressBar(
                  label: '🥗 Pola Makan & Nutrisi',
                  doneText: '${(nutritionPct * 100).toInt()}% Selesai',
                  remainingText: '${((1.0 - nutritionPct) * 100).toInt()}% Belum',
                  percentage: nutritionPct,
                  color: nutritionColor,
                  isDark: isDark,
                ),
                const SizedBox(height: 10),

                _buildPillarProgressBar(
                  label: '🌙 Waktu Tidur & Istirahat',
                  doneText: '${(sleepPct * 100).toInt()}% Selesai',
                  remainingText: '${((1.0 - sleepPct) * 100).toInt()}% Belum',
                  percentage: sleepPct,
                  color: sleepColor,
                  isDark: isDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // FILTER TABS CHECKLIST REKOMENDASI
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterPill('Semua Target (${service.goals.length})', 0, const Color(0xFF36785A), isDark),
                const SizedBox(width: 8),
                _buildFilterPill('🏃 Latihan', 1, exerciseColor, isDark),
                const SizedBox(width: 8),
                _buildFilterPill('🥗 Pola Makan', 2, nutritionColor, isDark),
                const SizedBox(width: 8),
                _buildFilterPill('🌙 Waktu Tidur', 3, sleepColor, isDark),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // LIST CHECKLIST RINCIAN TARGET PROGRES
          ...displayGoals.map((goal) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildGoalDetailCard(goal, isDark, textPrimary, textMuted),
              )),
        ],
      ),
    );
  }

  Widget _buildPillarProgressBar({
    required String label,
    required String doneText,
    required String remainingText,
    required double percentage,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  doneText,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  ' • $remainingText',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 8,
            width: double.infinity,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            child: Row(
              children: [
                Flexible(
                  flex: (percentage * 100).toInt().clamp(1, 100),
                  child: Container(color: color),
                ),
                Flexible(
                  flex: ((1.0 - percentage) * 100).toInt().clamp(0, 100),
                  child: Container(color: Colors.transparent),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalDetailCard(
    RecommendationProgressGoal goal,
    bool isDark,
    Color textPrimary,
    Color textMuted,
  ) {
    Color badgeColor;
    if (goal.category == 'Latihan') {
      badgeColor = const Color(0xFF10B981);
    } else if (goal.category == 'Pola Makan') {
      badgeColor = const Color(0xFFF59E0B);
    } else {
      badgeColor = const Color(0xFF8B5CF6);
    }

    final isComplete = goal.isFullyCompleted;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isComplete
              ? const Color(0xFF36785A).withValues(alpha: isDark ? 0.4 : 0.3)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isComplete
                      ? const Color(0xFF36785A).withValues(alpha: 0.15)
                      : badgeColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isComplete ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: isComplete ? const Color(0xFF36785A) : badgeColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      goal.targetDesc,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isComplete
                      ? const Color(0xFF36785A).withValues(alpha: 0.12)
                      : const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isComplete
                      ? 'Selesai'
                      : '${goal.completedCount}/${goal.totalTargetCount} ${goal.unit}',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isComplete ? const Color(0xFF36785A) : const Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: goal.percentage,
              minHeight: 5,
              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(isComplete ? const Color(0xFF36785A) : badgeColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String label, int index, Color activeColor, bool isDark) {
    final isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilterIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 4. QUICK NUTRITION GRID (Makananku & Minumanku)
  // ==========================================
  Widget _buildQuickNutritionGrid(
    Map<String, dynamic>? currentFood,
    Map<String, dynamic>? currentDrink,
    bool isDark,
    Color textPrimary,
  ) {
    return Row(
      children: [
        // Makananku
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SavedNutritionListScreen(isFood: true),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFF5EB),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFFFE7D4),
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 95,
                      width: double.infinity,
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFEF3C7),
                      child: Image.asset(
                        currentFood?['thumbImg'] as String? ?? 'assets/progress/nutrition/food_oatmeal.png',
                        width: double.infinity,
                        height: 95,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(Icons.restaurant, size: 36, color: Color(0xFFD97706)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Makananku',
                                style: GoogleFonts.poppins(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: Color(0xFF94A3B8)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentFood != null
                              ? (currentFood['title'] as String? ?? 'Oatmeal + Pisang + Almond')
                              : 'Belum ada menu',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Minumanku
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SavedNutritionListScreen(isFood: false),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFEFBEA),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFFDF5CF),
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 95,
                      width: double.infinity,
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE0F2FE),
                      child: Image.asset(
                        currentDrink?['thumbImg'] as String? ?? 'assets/progress/nutrition/drink_infused_lemon.png',
                        width: double.infinity,
                        height: 95,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(Icons.local_drink, size: 36, color: Color(0xFF0284C7)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Minumanku',
                                style: GoogleFonts.poppins(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: Color(0xFF94A3B8)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentDrink != null
                              ? (currentDrink['title'] as String? ?? 'Infused Water Lemon')
                              : 'Belum ada menu',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0284C7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 5. FEATURE TILE BUILDER
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
            ? (isHighlighted ? const Color(0xFF58AF86).withValues(alpha: 0.5) : const Color(0xFF334155))
            : (isHighlighted ? const Color(0xFF36785A).withValues(alpha: 0.4) : const Color(0xFFE2E8F0)));
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
                    errorBuilder: (context, error, stackTrace) => Icon(iconFallback, color: iconColor, size: 22),
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
                      ? (isDark ? const Color(0xFF58AF86) : const Color(0xFF36785A))
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
