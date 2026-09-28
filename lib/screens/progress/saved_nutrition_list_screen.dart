import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/nutrition_service.dart';
import 'nutrition_detail_screen.dart';
import 'nutrition_recommendation_screen.dart';

class SavedNutritionListScreen extends StatelessWidget {
  final bool isFood;

  const SavedNutritionListScreen({
    super.key,
    required this.isFood,
  });

  @override
  Widget build(BuildContext context) {
    final title = isFood ? 'Makananku' : 'Minumanku';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF36785A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 17.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: NutritionService.instance,
        builder: (context, _) {
          final items = isFood
              ? NutritionService.instance.myFoods
              : NutritionService.instance.myDrinks;

          if (items.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            physics: const BouncingScrollPhysics(),
            children: [
              // Header Summary Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isFood ? const Color(0xFFFFF7ED) : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isFood ? const Color(0xFFFFEDD5) : const Color(0xFFBAE6FD),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isFood ? Icons.restaurant_rounded : Icons.local_drink_rounded,
                      color: isFood ? const Color(0xFFEA580C) : const Color(0xFF0284C7),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Total ${items.length} ${isFood ? 'menu makanan' : 'menu minuman'} tersimpan di daftar Anda',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isFood ? const Color(0xFF9A3412) : const Color(0xFF0369A1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Items List
              ...items.map((item) => _buildItemCard(context, item)),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: isFood ? const Color(0xFFFFF7ED) : const Color(0xFFE0F2FE),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFood ? Icons.restaurant_menu_rounded : Icons.local_drink_rounded,
                size: 46,
                color: isFood ? const Color(0xFFEA580C) : const Color(0xFF0284C7),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isFood ? 'Belum Ada Makananku' : 'Belum Ada Minumanku',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFood
                  ? 'Anda belum menambahkan menu ke daftar Makananku. Yuk, jelajahi rekomendasi dan simpan menu pilihan Anda!'
                  : 'Anda belum menambahkan menu ke daftar Minumanku. Yuk, jelajahi rekomendasi dan simpan menu pilihan Anda!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => NutritionRecommendationScreen(
                      initialFilter:
                          isFood ? NutritionFilter.food : NutritionFilter.drink,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.search_rounded, size: 18),
              label: Text(
                isFood ? 'Lihat Rekomendasi Makanan' : 'Lihat Rekomendasi Minuman',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF36785A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, Map<String, dynamic> item) {
    final title = item['title'] as String? ?? 'Menu';
    final category = item['category'] as String? ?? '';
    final calories = item['calories'] as String? ?? '';
    final thumbImg = item['thumbImg'] as String? ?? '';
    final categoryIcon = item['categoryIcon'] as IconData? ?? Icons.star_rounded;
    final categoryBg = item['categoryBg'] as Color? ?? const Color(0xFFFFF7ED);
    final categoryText = item['categoryText'] as Color? ?? const Color(0xFFEA580C);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => NutritionDetailScreen(item: item),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Foto Kiri Rounded
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 84,
                    height: 84,
                    color: const Color(0xFFF1F5F9),
                    child: Image.asset(
                      thumbImg,
                      width: 84,
                      height: 84,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: isFood ? const Color(0xFFFEF3C7) : const Color(0xFFE0F2FE),
                        child: Icon(
                          isFood ? Icons.restaurant_rounded : Icons.local_drink_rounded,
                          size: 32,
                          color: isFood ? const Color(0xFFD97706) : const Color(0xFF0284C7),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Info Tengah
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Category Tag
                      if (category.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: categoryBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(categoryIcon, size: 11, color: categoryText),
                              const SizedBox(width: 4),
                              Text(
                                category,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: categoryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                      ],

                      // Title
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                          height: 1.3,
                        ),
                      ),

                      if (calories.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department_rounded,
                              size: 13,
                              color: Color(0xFFEA580C),
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                calories,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Arrow Indicator
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
