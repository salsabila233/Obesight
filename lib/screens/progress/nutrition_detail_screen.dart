import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/nutrition_service.dart';

class NutritionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const NutritionDetailScreen({super.key, required this.item});

  @override
  State<NutritionDetailScreen> createState() => _NutritionDetailScreenState();
}

class _NutritionDetailScreenState extends State<NutritionDetailScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isSticky = false;

  // Toast Notification state & animation
  bool _showToast = false;
  String _toastMessage = '';
  Timer? _toastTimer;
  late final AnimationController _toastAnimController;
  late final Animation<Offset> _toastSlideAnimation;
  late final Animation<double> _toastFadeAnimation;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      final offset = _scrollController.offset;
      if (offset > 120 && !_isSticky) {
        setState(() => _isSticky = true);
      } else if (offset <= 120 && _isSticky) {
        setState(() => _isSticky = false);
      }
    });

    _toastAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _toastSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _toastAnimController,
      curve: Curves.easeOutCubic,
    ));

    _toastFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _toastAnimController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _toastTimer?.cancel();
    _toastAnimController.dispose();
    super.dispose();
  }

  void _handleAddItem() {
    final isFood = widget.item['type'] == 'food';

    if (isFood) {
      NutritionService.instance.addFood(widget.item);
      _triggerToast('Makanan berhasil disimpan!');
    } else {
      NutritionService.instance.addDrink(widget.item);
      _triggerToast('Minuman berhasil disimpan!');
    }
  }

  void _triggerToast(String message) {
    _toastTimer?.cancel();

    setState(() {
      _toastMessage = message;
      _showToast = true;
    });

    _toastAnimController.forward();

    _toastTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        _toastAnimController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _showToast = false;
            });
          }
        });
      }
    });
  }

  void _dismissToast() {
    _toastTimer?.cancel();
    _toastAnimController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _showToast = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isFood = widget.item['type'] == 'food';
    final title = widget.item['title'] as String? ?? 'Menu';
    final heroImg = widget.item['heroImg'] as String? ?? widget.item['thumbImg'] as String;
    final detailDesc = widget.item['detailDesc'] as String? ?? widget.item['desc'] as String? ?? '';
    final calories = widget.item['calories'] as String? ?? '';
    final benefits = (widget.item['benefits'] as List<dynamic>?)?.cast<String>() ?? [];
    final headerHeight = MediaQuery.of(context).size.height * 0.35;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Scrollable Content with Parallax & Collapsing Toolbar
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Sticky Collapsing SliverAppBar
              SliverAppBar(
                expandedHeight: headerHeight.clamp(230.0, 310.0),
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
                // Sticky Header Title (visible only when collapsed)
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
                      // Full Hero Photo
                      Image.asset(
                        heroImg,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFF2D6A4F),
                          child: Icon(
                            isFood ? Icons.restaurant_rounded : Icons.local_drink_rounded,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      // Gradient Overlay for readability
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

                      // Bottom Overlay: Nama Menu (Posisi Awal pada Gambar)
                      Positioned(
                        bottom: 22,
                        left: 20,
                        right: 20,
                        child: AnimatedOpacity(
                          opacity: _isSticky ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 150),
                          child: Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content Body in White Card
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  transform: Matrix4.translationValues(0, -12, 0),
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Deskripsi Paragraf (langsung paragraf tanpa judul section)
                      Text(
                        detailDesc,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF334155),
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 2. Heading "Manfaat & Kandungan"
                      Text(
                        'Manfaat & Kandungan',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // 3. Baris Info Kalori dengan Ikon Api Lingkaran Oranye Pastel
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFEDD5), // oranye pastel
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.local_fire_department_rounded,
                              color: Color(0xFFEA580C),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: const Color(0xFF1E293B),
                                  height: 1.45,
                                ),
                                children: [
                                  const TextSpan(
                                    text: 'Perkiraan Kalori (per sajian): ',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  TextSpan(
                                    text: calories,
                                    style: const TextStyle(fontWeight: FontWeight.normal),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // 4. Sub-heading "Kandungan:"
                      Text(
                        'Kandungan:',
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // 5. List Bernomor (1, 2, 3, 4)
                      ...benefits.asMap().entries.map((entry) {
                        final index = entry.key + 1;
                        final text = entry.value;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$index. ',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  text,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: const Color(0xFF334155),
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 32),

                      // 6. Tombol Full-Width Hijau di Bagian Bawah
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF36785A),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _handleAddItem,
                          child: Text(
                            isFood ? 'Tambah sebagai makananku' : 'Tambah sebagai Minumanku',
                            style: GoogleFonts.poppins(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 2. Top Floating Toast Notification (sesuai Page 6)
          if (_showToast)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 24,
              right: 24,
              child: SlideTransition(
                position: _toastSlideAnimation,
                child: FadeTransition(
                  opacity: _toastFadeAnimation,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF16A34A),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _toastMessage,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: _dismissToast,
                            borderRadius: BorderRadius.circular(12),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
