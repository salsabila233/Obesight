import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../services/nutrition_service.dart';
import 'physical_activity_screen.dart';
import 'rest_recommendation_screen.dart';
import 'nutrition_recommendation_screen.dart';
import 'nutrition_detail_screen.dart';

class ProgressScreen extends StatelessWidget {
  final UserModel user;

  const ProgressScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NutritionService.instance,
      builder: (context, _) {
        final currentFood = NutritionService.instance.myFood;
        final currentDrink = NutritionService.instance.myDrink;

        return Scaffold(
          backgroundColor: const Color(0xFFF3F6F8),
          appBar: AppBar(
            backgroundColor: const Color(0xFF36785A),
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
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Motivation Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE6F7F0), Color(0xFFD4F1E4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFC4ECDA)),
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
                                color: const Color(0xFF36785A).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'TARGET HARI INI',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF23533E),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tetap Semangat, Capai Berat Ideal!',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF112A1F),
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Konsistensi dan langkah kecil harian adalah kunci keberhasilan gaya hidup sehat.',
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                color: const Color(0xFF375347),
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
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.directions_run_rounded,
                            size: 64,
                            color: Color(0xFF36785A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // 2. Quick Cards Grid (Makananku & Minumanku) - Terhubung ke NutritionService
                Row(
                  children: [
                    // Makananku
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => NutritionDetailScreen(item: currentFood),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF5EB),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFFFE7D4)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Foto Besar Makananku
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  height: 95,
                                  width: double.infinity,
                                  color: const Color(0xFFFEF3C7),
                                  child: Image.asset(
                                    currentFood['thumbImg'] as String? ?? 'assets/progress/nutrition/food_oatmeal.png',
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
                                              color: const Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                        const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: Color(0xFF94A3B8)),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      currentFood['title'] as String? ?? 'Oatmeal + Pisang + Almond',
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
                              builder: (_) => NutritionDetailScreen(item: currentDrink),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEFBEA),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFFDF5CF)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Foto Besar Minumanku
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  height: 95,
                                  width: double.infinity,
                                  color: const Color(0xFFE0F2FE),
                                  child: Image.asset(
                                    currentDrink['thumbImg'] as String? ?? 'assets/progress/nutrition/drink_infused_lemon.png',
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
                                              color: const Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                        const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: Color(0xFF94A3B8)),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      currentDrink['title'] as String? ?? 'Infused Water Lemon',
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
                ),

                const SizedBox(height: 22),

                // 3. Section Pantau Kesehatanmu
                Text(
                  'Pantau Kesehatanmu',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),

                // Feature 1: Makanan & Minuman (NAVIGASI AKTIF!)
                _buildFeatureTile(
                  iconImg: 'assets/progress/clean/icon_salad.png',
                  iconFallback: Icons.eco_outlined,
                  iconBg: const Color(0xFFE2F1E8),
                  iconColor: const Color(0xFF36785A),
                  title: 'Makanan & Minuman',
                  desc: 'Pantau asupan nutrisi seimbang dan kalori harianmu.',
                  isHighlighted: true,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NutritionRecommendationScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Feature 2: Aktivitas Fisik (NAVIGASI AKTIF!)
                _buildFeatureTile(
                  iconImg: 'assets/progress/clean/icon_shoe.png',
                  iconFallback: Icons.directions_run_rounded,
                  iconBg: const Color(0xFFE0F2FE),
                  iconColor: const Color(0xFF0284C7),
                  title: 'Aktivitas Fisik',
                  desc: 'Panduan olahraga, durasi & rekomendasi aktivitas fisik harian.',
                  isHighlighted: true,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PhysicalActivityScreen()),
                    );
                  },
                ),
                const SizedBox(height: 10),

            // Feature 3: Waktu Istirahat
            _buildFeatureTile(
              iconImg: 'assets/progress/clean/icon_bed.png',
              iconFallback: Icons.bedtime_outlined,
              iconBg: const Color(0xFFF3E8FF),
              iconColor: const Color(0xFF7E22CE),
              title: 'Waktu Istirahat',
              desc: 'Cek kualitas tidur 7-8 jam dan durasi istirahatmu.',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RestRecommendationScreen()),
                );
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  },
);
}

  Widget _buildFeatureTile({
    required String iconImg,
    required IconData iconFallback,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String desc,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isHighlighted ? const Color(0xFF36785A).withValues(alpha: 0.4) : const Color(0xFFE2E8F0),
          width: isHighlighted ? 1.3 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isHighlighted ? const Color(0xFF36785A).withValues(alpha: 0.08) : const Color(0xFF0F172A).withValues(alpha: 0.03),
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
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        desc,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: const Color(0xFF64748B),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isHighlighted ? const Color(0xFF36785A) : const Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
