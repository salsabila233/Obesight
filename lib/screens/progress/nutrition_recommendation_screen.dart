import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/nutrition_meal_model.dart';
import '../../services/auth_service.dart';
import '../../services/calorie_target_service.dart';
import '../../services/meal_plan_service.dart';
import '../../services/nutrition_checklist_service.dart';
import '../../widgets/progress_page_scaffold.dart';
import 'nutrition_detail_screen.dart';

enum NutritionFilter {
  all,
  food,
  drink,
}

class NutritionRecommendationScreen extends StatefulWidget {
  final NutritionFilter initialFilter;

  const NutritionRecommendationScreen({
    super.key,
    this.initialFilter = NutritionFilter.all,
  });

  @override
  State<NutritionRecommendationScreen> createState() =>
      _NutritionRecommendationScreenState();
}

class _NutritionRecommendationScreenState
    extends State<NutritionRecommendationScreen> with WidgetsBindingObserver {
  late NutritionFilter _currentFilter;

  // Date Scroller state (21 days: -7 to +13)
  late final ScrollController _dateScrollController;
  final int _todayOffset = 7;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentFilter = widget.initialFilter;

    // Inisialisasi tanggal terpilih ke Hari Ini (dinormalisasi tahun-bulan-hari)
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _dateScrollController = ScrollController();

    // Auto-scroll date scroller agar hari ini di tengah
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_dateScrollController.hasClients) {
        final scrollPosition = (_todayOffset * 64.0) - 120.0;
        _dateScrollController.animateTo(
          scrollPosition.clamp(0.0, _dateScrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });

    // Sinkronisasi bila ada pembaruan profil / hasil skrining baru
    AuthService().profileUpdateNotifier.addListener(_onProfileUpdated);

    // Sinkronkan catatan yang ada ke Cloud Firestore di latar belakang
    NutritionChecklistService.instance.syncAllToFirestore();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AuthService().profileUpdateNotifier.removeListener(_onProfileUpdated);
    _dateScrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _onProfileUpdated() {
    if (mounted) {
      setState(() {});
    }
  }

  String get _headerTitle {
    switch (_currentFilter) {
      case NutritionFilter.food:
        return 'Rekomendasi Makanan';
      case NutritionFilter.drink:
        return 'Rekomendasi Minuman';
      case NutritionFilter.all:
        return 'Rekomendasi Makanan & Minuman';
    }
  }

  void _openDetail(NutritionMealModel item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NutritionDetailScreen(item: item.toMap()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ambil tanggal hari ini secara real-time dari DateTime.now() saat render
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);

    // Kategori IMT pengguna yang sama dengan tampilan di Beranda "Status Kesehatan"
    final rawCategory = CalorieTargetService.getLatestScreeningCategoryRaw();
    final calorieGroup = CalorieTargetService.resolveGroup(rawCategory);
    final groupDisplayName = CalorieTargetService.getGroupDisplayName(calorieGroup);
    final targetCalories = CalorieTargetService.getDailyCalorieTarget(calorieGroup);

    return ListenableBuilder(
      listenable: NutritionChecklistService.instance,
      builder: (context, _) {
        final selectedDateKey = NutritionChecklistService.instance.formatDateKey(_selectedDate);
        final bool isSelectedDateToday = (_selectedDate.year == today.year &&
            _selectedDate.month == today.month &&
            _selectedDate.day == today.day);

        // Menu deterministik 1 hari (5 item: Sarapan, Siang, Malam, Cemilan, Minuman)
        final dailyMeals = MealPlanService.getDailyPlanForDate(
          date: _selectedDate,
          group: calorieGroup,
        );

        // Filter tampilan (Semua, Makanan, Minuman)
        final filteredMeals = dailyMeals.where((m) {
          switch (_currentFilter) {
            case NutritionFilter.food:
              return m.type == 'food';
            case NutritionFilter.drink:
              return m.type == 'drink';
            case NutritionFilter.all:
              return true;
          }
        }).toList();

        // Hitung selesai pada filter aktif
        final completedIds = NutritionChecklistService.instance.getCompletedForDate(selectedDateKey);
        final completedInFilter = filteredMeals.where((m) => completedIds.contains(m.id)).length;
        final totalInFilter = filteredMeals.length;

        // Hitung kalori terkonsumsi seluruh menu hari itu
        final consumedCalories = NutritionChecklistService.instance.getConsumedCaloriesForDate(
          selectedDateKey,
          dailyMeals,
        );

        final calorieProgress = (targetCalories > 0)
            ? (consumedCalories / targetCalories).clamp(0.0, 1.0)
            : 0.0;

        return ProgressPageScaffold(
          title: _headerTitle,
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Horizontal Real-Time Date Scroller (21 days: -7 to +13)
                SizedBox(
                  height: 74,
                  child: ListView.builder(
                    controller: _dateScrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: 21,
                    itemBuilder: (context, index) {
                      final itemOffset = index - _todayOffset;
                      final date = today.add(Duration(days: itemOffset));
                      final isSelected = (_selectedDate.year == date.year &&
                          _selectedDate.month == date.month &&
                          _selectedDate.day == date.day);
                      final isPast = date.isBefore(today);
                      final isCurrentDay = (date.year == today.year &&
                          date.month == today.month &&
                          date.day == today.day);

                      final dayName = isCurrentDay ? 'Hari ini' : dayNames[date.weekday % 7];
                      final dateStr = '${date.day}/${date.month}/${date.year.toString().substring(2)}';

                      Color bgColor;
                      Color textColor;
                      Color subTextColor;
                      Border border;

                      if (isSelected) {
                        bgColor = isDark ? const Color(0xFF58AF86) : const Color(0xFF36785A);
                        textColor = Colors.white;
                        subTextColor = Colors.white.withValues(alpha: 0.9);
                        border = Border.all(color: bgColor, width: 1.5);
                      } else if (isPast) {
                        bgColor = const Color(0xFFEF4444);
                        textColor = Colors.white;
                        subTextColor = Colors.white.withValues(alpha: 0.85);
                        border = Border.all(color: const Color(0xFFDC2626));
                      } else if (isCurrentDay) {
                        bgColor = isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5);
                        textColor = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46);
                        subTextColor = isDark ? const Color(0xFFA7F3D0) : const Color(0xFF047857);
                        border = Border.all(color: const Color(0xFF10B981), width: 1.5);
                      } else {
                        bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
                        textColor = isDark ? Colors.white : const Color(0xFF0F172A);
                        subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
                        border = Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));
                      }

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDate = date;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 58,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(16),
                            border: border,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF36785A).withValues(alpha: 0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    )
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    )
                                  ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dayName,
                                style: GoogleFonts.poppins(
                                  fontSize: isCurrentDay ? 9.5 : 11,
                                  fontWeight: isCurrentDay || isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: subTextColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dateStr,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 18),

                // 2. Ringkasan Kalori Harian & Kategori Skrining
                _buildCalorieSummaryBanner(
                  isDark: isDark,
                  groupDisplayName: groupDisplayName,
                  targetCalories: targetCalories,
                  consumedCalories: consumedCalories,
                  progress: calorieProgress,
                ),

                const SizedBox(height: 18),

                // 3. Filter Tabs (Semua, Makanan, Minuman)
                _buildFilterTabs(isDark),

                const SizedBox(height: 16),

                // 4. Section Header dengan Counter "X/Y Selesai"
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _currentFilter == NutritionFilter.all
                          ? 'Daftar Menu Hari Ini'
                          : (_currentFilter == NutritionFilter.food
                              ? 'Pilihan Makanan Hari Ini'
                              : 'Pilihan Minuman Hari Ini'),
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2F1E8),
                        borderRadius: BorderRadius.circular(8),
                        border: isDark ? Border.all(color: const Color(0xFF334155)) : null,
                      ),
                      child: Text(
                        '$completedInFilter/$totalInFilter Selesai',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF2E6B4F),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 5. Daftar Card Menu Makanan & Minuman dengan Ceklis Manual
                ...filteredMeals.map((meal) => _buildMealCard(
                      meal,
                      isDark,
                      selectedDateKey,
                      isSelectedDateToday,
                      dailyMeals: dailyMeals,
                    )),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // RINGKASAN KALORI HARIAN & KATEGORI SKRINING
  // ==========================================
  Widget _buildCalorieSummaryBanner({
    required bool isDark,
    required String groupDisplayName,
    required int targetCalories,
    required int consumedCalories,
    required double progress,
  }) {
    final remainingCalories = targetCalories - consumedCalories;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          // Header Baris: Kategori & Target Kalori
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
                        Icon(
                          Icons.health_and_safety_rounded,
                          size: 14,
                          color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF36785A),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            'Kategori: $groupDisplayName',
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF36785A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Target Harian: ${targetCalories.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} kkal',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFFFEDD5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      size: 15,
                      color: Color(0xFFEA580C),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$consumedCalories kkal',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFEA580C),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress Bar Kalori Terkonsumsi
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? const Color(0xFF10B981) : const Color(0xFF36785A),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Subteks Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Terkonsumsi: $consumedCalories kkal (${(progress * 100).toInt()}%)',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              Text(
                remainingCalories > 0
                    ? 'Sisa: $remainingCalories kkal'
                    : 'Target tercapai!',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: remainingCalories > 0
                      ? (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569))
                      : const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // FILTER TABS (Semua, Makanan, Minuman)
  // ==========================================
  Widget _buildFilterTabs(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTabButton(
          title: 'Semua',
          icon: Icons.grid_view_rounded,
          filter: NutritionFilter.all,
          isDark: isDark,
        ),
        const SizedBox(width: 8),
        _buildTabButton(
          title: 'Makanan',
          icon: Icons.soup_kitchen_rounded,
          filter: NutritionFilter.food,
          isDark: isDark,
        ),
        const SizedBox(width: 8),
        _buildTabButton(
          title: 'Minuman',
          icon: Icons.local_drink_rounded,
          filter: NutritionFilter.drink,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required NutritionFilter filter,
    required bool isDark,
  }) {
    final isSelected = _currentFilter == filter;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentFilter = filter;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF36785A)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF36785A)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF36785A).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? Colors.white
                  : (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF36785A)),
            ),
            const SizedBox(width: 5),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white : const Color(0xFF36785A)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // DIALOG KONFIRMASI CEKLIS MAKANAN/MINUMAN
  // ==========================================
  Future<void> _confirmAndCompleteMeal({
    required BuildContext context,
    required String dateKey,
    required NutritionMealModel meal,
    required bool isDark,
    List<NutritionMealModel>? dailyMeals,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF36785A).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: Color(0xFF36785A),
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Konfirmasi Konsumsi',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Tandai sudah dikonsumsi? Ceklis tidak bisa dibatalkan.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            height: 1.45,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF36785A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Ya',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await NutritionChecklistService.instance.completeItem(
        dateKey,
        meal.id,
        meal: meal,
        dailyMeals: dailyMeals,
      );
    }
  }

  // ==========================================
  // CARD REKOMENDASI DENGAN CEKLIS MANUAL
  // ==========================================
  Widget _buildMealCard(
    NutritionMealModel meal,
    bool isDark,
    String dateKey,
    bool isToday, {
    List<NutritionMealModel>? dailyMeals,
  }) {
    final isCompleted = NutritionChecklistService.instance.isCompleted(dateKey, meal.id);

    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isCompleted
        ? (isToday
            ? (isDark ? const Color(0xFF58AF86) : const Color(0xFF36785A))
            : (isDark
                ? const Color(0xFF58AF86).withValues(alpha: 0.45)
                : const Color(0xFF36785A).withValues(alpha: 0.45)))
        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));
    final textTitle = isDark ? Colors.white : const Color(0xFF0F172A);
    final textDesc = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: cardBorder,
          width: isCompleted ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openDetail(meal),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Thumbnail Foto / Placeholder dengan Badge Centang
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 82,
                        height: 82,
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        child: (meal.hasCustomPhoto && meal.thumbImg.isNotEmpty)
                            ? Image.asset(
                                meal.thumbImg,
                                width: 82,
                                height: 82,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildPlaceholderThumb(meal, isDark),
                              )
                            : _buildPlaceholderThumb(meal, isDark),
                      ),
                    ),
                    // Checkmark badge di thumbnail saat selesai
                    if (isCompleted)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: isToday
                                ? const Color(0xFF16A34A)
                                : const Color(0xFF16A34A).withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 12),

                // 2. Info Menu (Kategori, Nama, Deskripsi, Pills)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kategori & Kalori Pill
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: meal.categoryBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(meal.categoryIcon, size: 10.5, color: meal.categoryText),
                                const SizedBox(width: 3.5),
                                Text(
                                  meal.category,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: meal.categoryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.local_fire_department_rounded,
                                  size: 11,
                                  color: Color(0xFFEA580C),
                                ),
                                const SizedBox(width: 2.5),
                                Text(
                                  '${meal.calories} kkal',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFEA580C),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Nama Menu
                      Text(
                        meal.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: textTitle,
                        ),
                      ),

                      const SizedBox(height: 2),

                      // Deskripsi Singkat
                      Text(
                        meal.desc,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: textDesc,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Pills Takaran / Kandungan
                      Wrap(
                        spacing: 5,
                        runSpacing: 3,
                        children: meal.pills.take(2).map((p) => _buildNutrientPill(p, isDark)).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),

                // 3. Lingkaran Ceklis Manual
                // Hanya bisa diketuk pada hari ini & belum tercentang
                // Tanggal selain hari ini: tampil nonaktif (faded) & muncul snackbar jika diketuk
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (!isToday) {
                      // Tanggal kemarin / besok: tampilkan pesan singkat
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Ceklis hanya bisa diisi pada hari ini',
                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
                          ),
                          backgroundColor: const Color(0xFF36785A),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                      return;
                    }

                    // Jika hari ini dan sudah tercentang: permanen, tidak ada aksi (tidak bisa uncheck)
                    if (isCompleted) {
                      return;
                    }

                    // Jika hari ini dan belum centang: tampilkan konfirmasi
                    _confirmAndCompleteMeal(
                      context: context,
                      dateKey: dateKey,
                      meal: meal,
                      isDark: isDark,
                      dailyMeals: dailyMeals,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                    child: Icon(
                      isCompleted
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: isToday
                          ? (isCompleted
                              ? (isDark ? const Color(0xFF58AF86) : const Color(0xFF36785A))
                              : (isDark ? const Color(0xFF64748B) : const Color(0xFFCBD5E1)))
                          : (isCompleted
                              ? (isDark
                                  ? const Color(0xFF58AF86).withValues(alpha: 0.4)
                                  : const Color(0xFF36785A).withValues(alpha: 0.4))
                              : (isDark
                                  ? const Color(0xFF64748B).withValues(alpha: 0.35)
                                  : const Color(0xFFCBD5E1).withValues(alpha: 0.45))),
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderThumb(NutritionMealModel meal, bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2F1E8),
      child: Center(
        child: Icon(
          meal.type == 'drink' ? Icons.local_drink_rounded : Icons.restaurant_rounded,
          color: isDark ? const Color(0xFF58AF86) : const Color(0xFF36785A),
          size: 34,
        ),
      ),
    );
  }

  Widget _buildNutrientPill(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: isDark ? Border.all(color: const Color(0xFF334155)) : null,
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 9.5,
          fontWeight: FontWeight.w500,
          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
        ),
      ),
    );
  }
}
