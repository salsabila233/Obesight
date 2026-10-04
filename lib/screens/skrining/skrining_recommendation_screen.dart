import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../progress/progress_screen.dart';
import 'skrining_models.dart';
import 'skrining_recommendation_rules.dart';

class SkriningRecommendationScreen extends StatelessWidget {
  final SkriningData data;
  final UserModel? user;
  final String? customCategory; // Opsional jika ingin meng-override kategori klasifikasi

  const SkriningRecommendationScreen({
    super.key,
    required this.data,
    this.user,
    this.customCategory,
  });

  static const Color primaryGreen = Color(0xFF4A8B6C); // Medical soft green
  static const Color darkGreen = Color(0xFF36785A);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color cardBorder = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    final currentUser = user ?? AuthService().currentUser ?? AuthService.defaultUserAccount;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryGreen = isDark ? const Color(0xFF58AF86) : const Color(0xFF4A8B6C); // Medical soft green
    final textDark = isDark ? Colors.white : const Color(0xFF1E293B);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final scaffoldBg = isDark ? const Color(0xFF0F172A) : Colors.white;

    // 1. Ambil kategori hasil klasifikasi algoritma/model skrining
    final String activeCategory = customCategory ?? data.classificationCategory;

    // 2. Baca aturan rekomendasi resmi (PAPDI & KMK Kemenkes No. HK.01.07-MENKES-509-2025)
    final CategoryRecommendation rec = SkriningRecommendationRules.getRecommendationByCategory(activeCategory);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left_rounded, color: textDark, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Rekomendasi',
          style: GoogleFonts.poppins(
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Big Title
                    Text(
                      'Rekomendasi Untuk Anda',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Subtitle
                    Text(
                      'Yuk, mulai langkah kecil untuk hidup lebih sehat!\nBerikut rekomendasi yang sesuai dengan Anda.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: textMuted,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Kategori & Target Klinis Badge Card (PAPDI & KMK Kemenkes 2025)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: cardBorder, width: 1.1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(activeCategory).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.assignment_turned_in_rounded,
                              size: 18,
                              color: _getCategoryColor(activeCategory),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: RichText(
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        text: TextSpan(
                                          text: 'Hasil: ',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: textMuted,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: rec.categoryDisplayName,
                                              style: GoogleFonts.poppins(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: _getCategoryColor(activeCategory),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      rec.imtRange,
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Target: ${rec.clinicalGoal}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w400,
                                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // CARD 1: Perbaiki Pola Makan (Terapi Nutrisi Medis)
                    _buildRecommendationCard(
                      title: 'Perbaiki Pola Makan',
                      titleColor: const Color(0xFF2E7D5B),
                      iconWidget: _buildFoodIllustration(),
                      points: rec.foodRecommendations,
                    ),

                    const SizedBox(height: 14),

                    // CARD 2: Tingkatkan Aktivitas Fisik (Latihan Fisik & Olahraga)
                    _buildRecommendationCard(
                      title: 'Tingkatkan Aktivitas Fisik',
                      titleColor: const Color(0xFF2563EB),
                      iconWidget: _buildActivityIllustration(),
                      points: rec.physicalActivityRecommendations,
                    ),

                    const SizedBox(height: 14),

                    // CARD 3: Hidrasi
                    _buildRecommendationCard(
                      title: 'Hidrasi',
                      titleColor: const Color(0xFF0284C7),
                      iconWidget: _buildHydrationIllustration(),
                      points: rec.hydrationRecommendations,
                    ),

                    const SizedBox(height: 14),

                    // CARD 4: Istirahat yang cukup
                    _buildRecommendationCard(
                      title: 'Istirahat yang cukup',
                      titleColor: const Color(0xFF8B5CF6),
                      iconWidget: _buildRestIllustration(),
                      points: rec.restAndBehaviorRecommendations,
                    ),

                    const SizedBox(height: 16),

                    // COMMITMENT BANNER (Durasi Intervensi Klinis)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFA7F3D0),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF10B981),
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              rec.evaluationPeriod,
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: isDark ? const Color(0xFF58AF86) : const Color(0xFF065F46),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ACTION BUTTON: LANJUTKAN SEBAGAI PROGRES
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => _showSaveProgressDialog(context, currentUser, rec),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Lanjutkan sebagai progres',
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                          ],
                        ),
                      ),
                    ),

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

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Normal':
        return const Color(0xFF16A34A);
      case 'Overweight':
        return const Color(0xFFD97706);
      case 'Obesitas I':
        return const Color(0xFFEA580C);
      case 'Obesitas II':
        return const Color(0xFFDC2626);
      case 'Obesitas III':
        return const Color(0xFF991B1B);
      case 'Underweight':
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFFD97706);
    }
  }

  void _showSaveProgressDialog(BuildContext context, UserModel currentUser, CategoryRecommendation rec) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Icon: Clipboard with checkmark & question mark badge
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D5B),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2E7D5B).withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Clip board shape header
                          Positioned(
                            top: 10,
                            child: Container(
                              width: 22,
                              height: 6,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4A8B6C),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          // Checkmark
                          const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                        ],
                      ),
                    ),
                    // Small Yellow Question Badge at bottom right
                    Positioned(
                      bottom: -4,
                      right: -4,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBBF24),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '?',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Question Text
                Text(
                  'Apakah Anda ingin melanjutkan\nrekomendasi sebagai progres?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: textDark,
                    height: 1.35,
                  ),
                ),

                const SizedBox(height: 22),

                // Two Action Buttons: "Tidak" & "YA"
                Row(
                  children: [
                    // Tidak Button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF94A3B8), width: 1.2),
                          foregroundColor: textDark,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Tidak',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textDark,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // YA Button (Hijau)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Dismiss dialog
                          Navigator.of(dialogContext).pop();

                          // Show top success banner / notification
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Rekomendasi berhasil dilanjutkan sebagai progres!',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: const Color(0xFF2E7D5B),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                              duration: const Duration(seconds: 2),
                            ),
                          );

                          // Navigate to ProgressScreen
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ProgressScreen(user: currentUser),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D5B),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'YA',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
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
      },
    );
  }

  // =================== CARD BUILDER ===================
  Widget _buildRecommendationCard({
    required String title,
    required Color titleColor,
    required Widget iconWidget,
    required List<String> points,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Title centered
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 10),

          // Content Row: Left Icon/Illustration, Right Bullet Points
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Icon Container
              SizedBox(
                width: 68,
                child: Center(child: iconWidget),
              ),
              const SizedBox(width: 10),

              // Right Bullet Points
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: points.map((point) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: textDark,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              point,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: textDark,
                                height: 1.35,
                              ),
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

  // =================== ILLUSTRATION WIDGETS ===================
  Widget _buildFoodIllustration() {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFBBF7D0), width: 1.2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.rice_bowl_rounded,
            size: 32,
            color: const Color(0xFF2E7D5B).withValues(alpha: 0.9),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Icon(
              Icons.eco_rounded,
              size: 14,
              color: const Color(0xFF16A34A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityIllustration() {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
      ),
      child: const Center(
        child: Icon(
          Icons.directions_run_rounded,
          size: 34,
          color: Color(0xFF2563EB),
        ),
      ),
    );
  }

  Widget _buildHydrationIllustration() {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFBAE6FD), width: 1.2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.local_drink_rounded,
            size: 30,
            color: const Color(0xFF0284C7).withValues(alpha: 0.85),
          ),
          Positioned(
            bottom: 15,
            child: Icon(
              Icons.water_drop_rounded,
              size: 14,
              color: const Color(0xFF0284C7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestIllustration() {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFFFAF5FF),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE9D5FF), width: 1.2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.bed_rounded,
            size: 32,
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.9),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Icon(
              Icons.nightlight_round,
              size: 13,
              color: const Color(0xFF7C3AED),
            ),
          ),
        ],
      ),
    );
  }
}
