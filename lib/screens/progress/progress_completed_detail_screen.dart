import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../services/nutrition_checklist_service.dart';
import '../../services/physical_activity_service.dart';
import '../../services/progress_tracking_service.dart';
import 'nutrition_recommendation_screen.dart';
import 'physical_activity_screen.dart';

class ProgressCompletedDetailScreen extends StatefulWidget {
  final UserModel? user;

  const ProgressCompletedDetailScreen({super.key, this.user});

  @override
  State<ProgressCompletedDetailScreen> createState() =>
      _ProgressCompletedDetailScreenState();
}

class _ProgressCompletedDetailScreenState
    extends State<ProgressCompletedDetailScreen> {
  // 0: Semua, 1: Makanan & Minuman, 2: Aktivitas Fisik
  int _categoryFilterIndex = 0;
  // 0: Semua Minggu, 1: Minggu 1, 2: Minggu 2, 3: Minggu 3, 4: Minggu 4
  int _selectedWeekFilter = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final bgScreen = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgScreen,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Progres yang sudah dilakukan',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            height: 1,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          ProgressTrackingService.instance,
          NutritionChecklistService.instance,
          PhysicalActivityService.instance,
        ]),
        builder: (context, _) {
          final service = ProgressTrackingService.instance;
          final allCompletedItems = service.getAllCompletedItems();

          // Terapkan filter kategori
          List<CompletedChecklistItem> filteredItems = allCompletedItems;
          if (_categoryFilterIndex == 1) {
            filteredItems =
                filteredItems.where((it) => it.type == 'nutrition').toList();
          } else if (_categoryFilterIndex == 2) {
            filteredItems =
                filteredItems.where((it) => it.type == 'activity').toList();
          }

          // Terapkan filter minggu
          if (_selectedWeekFilter > 0) {
            filteredItems = filteredItems
                .where((it) => it.weekNumber == _selectedWeekFilter)
                .toList();
          }

          final nutritionDone = service.nutritionCompletedCount;
          final activityDone = service.activityCompletedCount;
          final totalDone = service.totalCompletedActions;
          final overallPct = (service.overallPercentage * 100).toInt();

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Banner Periode Evaluasi 1 Bulan
                _buildPeriodBanner(service, isDark),

                const SizedBox(height: 14),

                // 2. Kartu Ringkasan Capaian
                _buildSummaryStatsCard(
                  totalDone: totalDone,
                  nutritionDone: nutritionDone,
                  activityDone: activityDone,
                  overallPct: overallPct,
                  service: service,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),

                const SizedBox(height: 18),

                // 3. Tab Filter Kategori (Semua, Makanan & Minuman, Aktivitas Fisik)
                _buildCategoryFilterTabs(
                  totalCount: allCompletedItems.length,
                  nutritionCount: nutritionDone,
                  activityCount: activityDone,
                  isDark: isDark,
                ),

                const SizedBox(height: 12),

                // 4. Tab Filter Minggu (Semua Minggu, M1, M2, M3, M4)
                _buildWeekFilterPills(isDark),

                const SizedBox(height: 16),

                // 5. Header Daftar Item
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Daftar Target Selesai (${filteredItems.length})',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      _selectedWeekFilter == 0
                          ? '1 Bulan Penuh'
                          : 'Minggu ke-$_selectedWeekFilter',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF36785A),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 6. Daftar Item atau Empty State
                if (filteredItems.isEmpty)
                  _buildEmptyState(isDark, textPrimary, textSecondary)
                else
                  ...filteredItems.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildCompletedItemCard(
                        item,
                        isDark,
                        textPrimary,
                        textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // 1. BANNER PERIODE EVALUASI 1 BULAN
  // ==========================================
  Widget _buildPeriodBanner(ProgressTrackingService service, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE6F4ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFBCE3D0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFF36785A).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.date_range_rounded,
              color: Color(0xFF36785A),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Periode Evaluasi 1 Bulan (4 Minggu)',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF112A1F),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  service.formattedDateRange,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF36785A),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF36785A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '4 Minggu',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. KARTU RINGKASAN CAPAIAN
  // ==========================================
  Widget _buildSummaryStatsCard({
    required int totalDone,
    required int nutritionDone,
    required int activityDone,
    required int overallPct,
    required ProgressTrackingService service,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
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
              Text(
                'Ringkasan Capaian Selesai',
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF36785A), Color(0xFF489874)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$overallPct% Capaian 1 Bulan',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Pillar 1: Makanan & Minuman
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF166534) : const Color(0xFFBBF7D0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.eco_rounded,
                            size: 16,
                            color: Color(0xFF16A34A),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Makanan & Minum',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$nutritionDone Menu',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                      Text(
                        'dari ${service.nutritionTargetCount} target 1 bln',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Pillar 2: Aktivitas Fisik
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF0369A1) : const Color(0xFFBAE6FD),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.directions_run_rounded,
                            size: 16,
                            color: Color(0xFF0284C7),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Aktivitas Fisik',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$activityDone Sesi',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0284C7),
                        ),
                      ),
                      Text(
                        'dari ${service.activityTargetCount} target 1 bln',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: textSecondary,
                        ),
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

  // ==========================================
  // 3. TAB FILTER KATEGORI (Semua, Makanan, Aktivitas)
  // ==========================================
  Widget _buildCategoryFilterTabs({
    required int totalCount,
    required int nutritionCount,
    required int activityCount,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _buildCategoryTabItem(
            title: 'Semua ($totalCount)',
            index: 0,
            icon: Icons.done_all_rounded,
            isDark: isDark,
          ),
          _buildCategoryTabItem(
            title: '🥗 Makanan ($nutritionCount)',
            index: 1,
            icon: Icons.eco_rounded,
            isDark: isDark,
          ),
          _buildCategoryTabItem(
            title: '🏃 Aktivitas ($activityCount)',
            index: 2,
            icon: Icons.directions_run_rounded,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabItem({
    required String title,
    required int index,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = _categoryFilterIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _categoryFilterIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF36785A)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF36785A).withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 4. TAB FILTER MINGGU (Semua Minggu, M1, M2, M3, M4)
  // ==========================================
  Widget _buildWeekFilterPills(bool isDark) {
    final weeks = [
      {'label': 'Semua Minggu', 'week': 0},
      {'label': 'Minggu 1', 'week': 1},
      {'label': 'Minggu 2', 'week': 2},
      {'label': 'Minggu 3', 'week': 3},
      {'label': 'Minggu 4', 'week': 4},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: weeks.map((w) {
          final weekVal = w['week'] as int;
          final isSelected = _selectedWeekFilter == weekVal;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedWeekFilter = weekVal),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? const Color(0xFF58AF86) : const Color(0xFF36785A))
                      : (isDark ? const Color(0xFF1E293B) : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? (isDark ? const Color(0xFF58AF86) : const Color(0xFF36785A))
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                  ),
                ),
                child: Text(
                  w['label'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==========================================
  // 5. ITEM CARD YANG DICENTANG
  // ==========================================
  Widget _buildCompletedItemCard(
    CompletedChecklistItem item,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final isNutrition = item.type == 'nutrition';
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final badgeColor = isNutrition ? const Color(0xFF16A34A) : const Color(0xFF0284C7);
    final badgeBg = isNutrition
        ? const Color(0xFF16A34A).withValues(alpha: 0.12)
        : const Color(0xFF0284C7).withValues(alpha: 0.12);

    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final formattedItemDate =
        '${item.date.day} ${months[item.date.month - 1]} ${item.date.year}';

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail / Icon
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: item.thumb != null && item.thumb!.isNotEmpty
                      ? Image.asset(
                          item.thumb!,
                          width: 58,
                          height: 58,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildFallbackIcon(isNutrition, isDark),
                        )
                      : _buildFallbackIcon(isNutrition, isDark),
                ),
                Positioned(
                  top: 3,
                  left: 3,
                  child: Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: const BoxDecoration(
                      color: Color(0xFF16A34A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges Row: SubCategory + Week Badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.subCategory,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: badgeColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          'Minggu ${item.weekNumber}',
                          style: GoogleFonts.poppins(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Title
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Detail Desc
                  Text(
                    item.detailDesc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Footer info: Calories + Duration/Portion + Date
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildMiniBadge(
                        Icons.local_fire_department_rounded,
                        item.caloriesText,
                        const Color(0xFFEA580C),
                        isDark,
                      ),
                      _buildMiniBadge(
                        isNutrition
                            ? Icons.scale_rounded
                            : Icons.timer_outlined,
                        item.portionOrDuration,
                        badgeColor,
                        isDark,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 11,
                            color: textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formattedItemDate,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackIcon(bool isNutrition, bool isDark) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: isNutrition
            ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFE2F1E8))
            : (isDark ? const Color(0xFF0C4A6E) : const Color(0xFFE0F2FE)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        isNutrition ? Icons.eco_rounded : Icons.directions_run_rounded,
        color: isNutrition ? const Color(0xFF16A34A) : const Color(0xFF0284C7),
        size: 28,
      ),
    );
  }

  Widget _buildMiniBadge(
      IconData icon, String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 6. EMPTY STATE (JIKA BELUM ADA CENTANGAN)
  // ==========================================
  Widget _buildEmptyState(
      bool isDark, Color textPrimary, Color textSecondary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF36785A).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.checklist_rtl_rounded,
              color: Color(0xFF36785A),
              size: 44,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Target yang Dicentang',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Anda belum menandai menu makanan & minuman atau menyelesaikan sesi aktivitas fisik pada filter periode ini.\nYuk mulai gaya hidup sehat dan centang target harianmu!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            const NutritionRecommendationScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.eco_rounded, size: 16),
                  label: const Text('Menu Nutrisi'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF16A34A),
                    side: const BorderSide(color: Color(0xFF16A34A)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PhysicalActivityScreen(
                          user: widget.user,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.directions_run_rounded, size: 16),
                  label: const Text('Aktivitas Fisik'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
}
