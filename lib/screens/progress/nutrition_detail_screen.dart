import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NutritionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const NutritionDetailScreen({super.key, required this.item});

  @override
  State<NutritionDetailScreen> createState() => _NutritionDetailScreenState();
}

class _NutritionDetailScreenState extends State<NutritionDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isSticky = false;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      final offset = _scrollController.offset;
      if (offset > 125 && !_isSticky) {
        setState(() => _isSticky = true);
      } else if (offset <= 125 && _isSticky) {
        setState(() => _isSticky = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFood = widget.item['type'] == 'food';
    final title = (widget.item['title'] ?? widget.item['name']) as String? ?? 'Menu';
    final heroImg = widget.item['heroImg'] as String? ?? widget.item['thumbImg'] as String? ?? '';
    final detailDesc = widget.item['detailDesc'] as String? ?? widget.item['desc'] as String? ?? '';
    final calories = widget.item['calories'] as String? ?? '';
    final benefits = (widget.item['benefits'] as List<dynamic>?)?.cast<String>() ?? [];
    final portionGram = widget.item['portionGram'] as int?;
    final protein = widget.item['protein'] as double?;
    final carbs = widget.item['carbs'] as double?;
    final fat = widget.item['fat'] as double?;
    final pills = (widget.item['pills'] as List<dynamic>?)?.cast<String>() ?? [];
    final hasCustomPhoto = widget.item['hasCustomPhoto'] as bool? ?? true;

    final sheetBgColor = isDark ? const Color(0xFF0F172A) : Colors.white;

    return Scaffold(
      backgroundColor: sheetBgColor,
      body: Stack(
        children: [
          // Latar hijau di bagian atas untuk overscroll atas yang mulus
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 300,
            child: Container(
              color: const Color(0xFF36785A),
            ),
          ),

          // Konten Scrollable dengan Parallax Hero & Collapsing Sticky Header
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Sticky Collapsing SliverAppBar (Radius 28 curved sheet di bawahnya)
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                elevation: _isSticky ? 2 : 0,
                backgroundColor: const Color(0xFF36785A),
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _isSticky ? Colors.transparent : Colors.black.withValues(alpha: 0.38),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                // Judul menempel di header saat di-scroll (1 baris dengan elipsis)
                title: AnimatedOpacity(
                  opacity: _isSticky ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                centerTitle: true,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Full Hero Photo / Branded Placeholder
                      if (hasCustomPhoto && heroImg.isNotEmpty)
                        Image.asset(
                          heroImg,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildPlaceholderHeader(isFood),
                        )
                      else
                        _buildPlaceholderHeader(isFood),

                      // Gradient Overlay untuk keterbacaan teks judul di foto
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.45),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),

                      // Posisi awal: Nama makanan/minuman di bawah foto (boleh 2 baris agar tidak terpotong)
                      Positioned(
                        bottom: 24,
                        left: 20,
                        right: 20,
                        child: AnimatedOpacity(
                          opacity: _isSticky ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 150),
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.2,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content Body in Curved Sheet (Radius 28)
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: sheetBgColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 10,
                        offset: Offset(0, -3),
                      ),
                    ],
                  ),
                  transform: Matrix4.translationValues(0, -20, 0),
                  padding: EdgeInsets.fromLTRB(
                    22,
                    24,
                    22,
                    36 + MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Deskripsi Paragraf
                      Text(
                        detailDesc,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 2. Baris Info Kalori dengan Ikon Api Lingkaran Oranye Pastel
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFFFEDD5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF2D2314) : const Color(0xFFFFEDD5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.local_fire_department_rounded,
                                color: Color(0xFFEA580C),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Perkiraan Kalori (per sajian):',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      color: isDark ? const Color(0xFFFDBA74) : const Color(0xFF9A3412),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    calories,
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFEA580C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (portionGram != null && portionGram > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF475569) : const Color(0xFFFFD8B2),
                                  ),
                                ),
                                child: Text(
                                  'Porsi: ${portionGram}g',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFEA580C),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // 3. Makronutrien Card (Protein, Karbo, Lemak) jika tersedia
                      if (protein != null && carbs != null && fat != null) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _buildMacroPill('Protein', '${protein}g', const Color(0xFF0284C7), isDark ? const Color(0xFF0C4A6E).withValues(alpha: 0.3) : const Color(0xFFE0F2FE)),
                            const SizedBox(width: 8),
                            _buildMacroPill('Karbohidrat', '${carbs}g', const Color(0xFFD97706), isDark ? const Color(0xFF78350F).withValues(alpha: 0.3) : const Color(0xFFFEF3C7)),
                            const SizedBox(width: 8),
                            _buildMacroPill('Lemak', '${fat}g', const Color(0xFF16A34A), isDark ? const Color(0xFF14532D).withValues(alpha: 0.3) : const Color(0xFFDCFCE7)),
                          ],
                        ),
                      ],

                      // 4. Pill Rincian Takaran Bahan
                      if (pills.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Text(
                          'Takaran Bahan:',
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: pills.map((p) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              p,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                              ),
                            ),
                          )).toList(),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // 5. Heading "Manfaat & Kandungan"
                      Text(
                        'Manfaat & Kandungan:',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 6. List Bernomor (1, 2, 3, 4)
                      ...benefits.asMap().entries.map((entry) {
                        final index = entry.key + 1;
                        final text = entry.value;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                margin: const EdgeInsets.only(top: 2, right: 10),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE8F5EE),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '$index',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF36785A),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  text,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 16),
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

  Widget _buildMacroPill(String label, String value, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderHeader(bool isFood) {
    return Container(
      color: const Color(0xFF2D6A4F),
      child: Center(
        child: Icon(
          isFood ? Icons.restaurant_rounded : Icons.local_drink_rounded,
          size: 64,
          color: Colors.white.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}
