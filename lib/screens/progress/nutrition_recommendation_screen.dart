import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/nutrition_service.dart';
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
    extends State<NutritionRecommendationScreen> {
  late NutritionFilter _currentFilter;

  // Date Scroller state
  late final ScrollController _dateScrollController;
  final int _todayOffset = 7; // Index of today in [-7 .. +13] (total 21 days)
  late int _selectedDayIndex;

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialFilter;
    _selectedDayIndex = _todayOffset;
    _dateScrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_dateScrollController.hasClients) {
        final scrollPosition = (_todayOffset * 68.0) - 120.0;
        _dateScrollController.animateTo(
          scrollPosition.clamp(0.0, _dateScrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _dateScrollController.dispose();
    super.dispose();
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

  List<Map<String, dynamic>> get _filteredItems {
    final all = NutritionService.allItems;
    switch (_currentFilter) {
      case NutritionFilter.food:
        return all.where((it) => it['type'] == 'food').toList();
      case NutritionFilter.drink:
        return all.where((it) => it['type'] == 'drink').toList();
      case NutritionFilter.all:
        // 4 Makanan followed by 4 Minuman
        final foods = all.where((it) => it['type'] == 'food').toList();
        final drinks = all.where((it) => it['type'] == 'drink').toList();
        return [...foods, ...drinks];
    }
  }

  void _openDetail(Map<String, dynamic> item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NutritionDetailScreen(item: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final itemsToDisplay = _filteredItems;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F8),
      // Sticky AppBar at the top of the screen
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
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            _headerTitle,
            key: ValueKey<String>(_headerTitle),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
                  final offset = index - _todayOffset;
                  final date = now.add(Duration(days: offset));
                  final isSelected = _selectedDayIndex == index;
                  final isPast = offset < 0;
                  final isToday = offset == 0;

                  String dayName;
                  if (isToday) {
                    dayName = 'Hari ini';
                  } else {
                    switch (date.weekday) {
                      case DateTime.monday:
                        dayName = 'Senin';
                        break;
                      case DateTime.tuesday:
                        dayName = 'Selasa';
                        break;
                      case DateTime.wednesday:
                        dayName = 'Rabu';
                        break;
                      case DateTime.thursday:
                        dayName = 'Kamis';
                        break;
                      case DateTime.friday:
                        dayName = 'Jum\'at';
                        break;
                      case DateTime.saturday:
                        dayName = 'Sabtu';
                        break;
                      case DateTime.sunday:
                      default:
                        dayName = 'Minggu';
                        break;
                    }
                  }

                  final dateStr =
                      '${date.day}/${date.month}/${date.year.toString().substring(2)}';

                  Color bgColor;
                  Color textColor;
                  Color subTextColor;
                  Border border;

                  if (isSelected) {
                    bgColor = const Color(0xFF36785A);
                    textColor = Colors.white;
                    subTextColor = Colors.white.withValues(alpha: 0.9);
                    border = Border.all(color: const Color(0xFF36785A), width: 1.5);
                  } else if (isPast) {
                    // Past Days -> Merah, Teks Putih
                    bgColor = const Color(0xFFEF4444);
                    textColor = Colors.white;
                    subTextColor = Colors.white.withValues(alpha: 0.85);
                    border = Border.all(color: const Color(0xFFDC2626));
                  } else if (isToday) {
                    // Today -> Hijau Pastel
                    bgColor = const Color(0xFFD1FAE5);
                    textColor = const Color(0xFF065F46);
                    subTextColor = const Color(0xFF047857);
                    border = Border.all(color: const Color(0xFF10B981), width: 1.5);
                  } else {
                    // Future Days -> Putih
                    bgColor = Colors.white;
                    textColor = const Color(0xFF0F172A);
                    subTextColor = const Color(0xFF64748B);
                    border = Border.all(color: const Color(0xFFE2E8F0));
                  }

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDayIndex = index;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 60,
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
                                  color: Colors.black.withValues(alpha: 0.02),
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
                              fontSize: isToday ? 9.5 : 10.5,
                              fontWeight: isToday || isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: subTextColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateStr,
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
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

            // 2. Filter Tabs (Semua, Makanan, Minuman) dengan Underline Indicator
            _buildFilterTabs(),

            const SizedBox(height: 16),

            // 3. Daftar Card Makanan & Minuman
            ...itemsToDisplay.map((item) => _buildItemCard(item)),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Filter Tabs Pill Bar
  Widget _buildFilterTabs() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTabButton(
              title: 'Semua',
              icon: Icons.grid_view_rounded,
              filter: NutritionFilter.all,
            ),
            const SizedBox(width: 10),
            _buildTabButton(
              title: 'Makanan',
              icon: Icons.soup_kitchen_rounded,
              filter: NutritionFilter.food,
            ),
            const SizedBox(width: 10),
            _buildTabButton(
              title: 'Minuman',
              icon: Icons.local_drink_rounded,
              filter: NutritionFilter.drink,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required NutritionFilter filter,
  }) {
    final isSelected = _currentFilter == filter;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _currentFilter = filter;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF36785A) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF36785A)
                    : const Color(0xFFCBD5E1),
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
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      )
                    ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: isSelected ? Colors.white : const Color(0xFF36785A),
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF36785A),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 5),
        // Underline Indicator
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 2.5,
          width: isSelected ? 40 : 0,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF36785A) : Colors.transparent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  // Card Item Makanan & Minuman
  Widget _buildItemCard(Map<String, dynamic> item) {
    final title = item['title'] as String;
    final category = item['category'] as String;
    final desc = item['desc'] as String;
    final pills = (item['pills'] as List<dynamic>?)?.cast<String>() ?? [];
    final categoryIcon = item['categoryIcon'] as IconData? ?? Icons.star_rounded;
    final categoryBg = item['categoryBg'] as Color? ?? const Color(0xFFFFF7ED);
    final categoryText = item['categoryText'] as Color? ?? const Color(0xFFEA580C);
    final thumbImg = item['thumbImg'] as String;

    // Menentukan apakah card menampilkan foto di list:
    // Pada tab 'Minuman' (Page 2), Teh Hijau dan Jus Buah tampil tanpa foto (card lebih pendek).
    // Pada tab 'Semua' (Page 3), foto tampil di semua item.
    final bool showPhoto = _currentFilter == NutritionFilter.drink
        ? (item['hasThumbInDrinkTab'] as bool? ?? true)
        : true;

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
          onTap: () => _openDetail(item),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: showPhoto
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Foto Kiri Rounded
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 96,
                          height: 96,
                          color: const Color(0xFFF1F5F9),
                          child: Image.asset(
                            thumbImg,
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: const Color(0xFFE2E8F0),
                              child: const Icon(
                                Icons.restaurant_rounded,
                                color: Color(0xFF94A3B8),
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Konten Kanan
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Badge Kategori Waktu Makan di Kanan Atas
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: categoryBg,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        categoryIcon,
                                        size: 11,
                                        color: categoryText,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        category,
                                        style: GoogleFonts.poppins(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: categoryText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),

                            // Nama Menu
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Deskripsi Singkat
                            Text(
                              desc,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: const Color(0xFF64748B),
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Pill Kandungan Gizi
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: pills.map((p) => _buildNutrientPill(p)).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge Kategori di Atas
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: categoryBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  categoryIcon,
                                  size: 11,
                                  color: categoryText,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  category,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: categoryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),

                      // Nama Menu (Bold)
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Deskripsi
                      Text(
                        desc,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: const Color(0xFF64748B),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Pill Kandungan Gizi
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: pills.map((p) => _buildNutrientPill(p)).toList(),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildNutrientPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5), // Soft pastel cyan/green
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD1FAE5)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF047857),
        ),
      ),
    );
  }
}
