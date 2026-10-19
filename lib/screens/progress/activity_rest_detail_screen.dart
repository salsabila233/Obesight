import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'activity_timer_screen.dart';

class ActivityRestDetailScreen extends StatefulWidget {
  const ActivityRestDetailScreen({super.key});

  @override
  State<ActivityRestDetailScreen> createState() => _ActivityRestDetailScreenState();
}

class _ActivityRestDetailScreenState extends State<ActivityRestDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isSticky = false;

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
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerColor = isDark ? const Color(0xFF1E293B) : const Color(0xFF36785A);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFF36785A),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Sticky Collapsing SliverAppBar
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            elevation: _isSticky ? 2 : 0,
            backgroundColor: headerColor,
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
            title: AnimatedOpacity(
              opacity: _isSticky ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                'Istirahat Setelah Aktivitas',
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
                  Image.asset(
                    'assets/progress/rest/hero_aktivitas.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      'assets/progress/clean/hero_aktivitas.png',
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        color: const Color(0xFF36785A),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.75),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content in Curved White Container Sheet (Radius 28)
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row: Circle Activity Rest Icon & Title side-by-side
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFE8F4EE),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/progress/rest/circle_aktivitas.png',
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Image.asset(
                              'assets/progress/clean/circle_aktivitas.png',
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, st) => Container(
                                color: const Color(0xFFE2F1E8),
                                child: const Icon(Icons.directions_run_rounded, color: Color(0xFF36785A), size: 32),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Istirahat Setelah Aktivitas',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF235B42),
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Subtitle
                  Text(
                    'Setelah beraktivitas fisik, tubuh membutuhkan waktu untuk memulihkan energi dan menurunkan detak jantung. Berikut rekomendasi waktu istirahat yang sesuai untuk Anda.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF4A705E),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Two info cards: Durasi Istirahat & Manfaat
                  Row(
                    children: [
                      // Card 1: Durasi Istirahat
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEDF7F2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.history_rounded, size: 16, color: Color(0xFF36785A)),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      'Durasi Istirahat',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A7E6C),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '10 - 20 Menit',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF235B42),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Card 2: Manfaat
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEDF7F2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.favorite_rounded, size: 16, color: Color(0xFF36785A)),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      'Manfaat Utama',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A7E6C),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Pemulihan Otot',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF235B42),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Tips Istirahat Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF7FAF8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2EFE7),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lightbulb_outline_rounded, size: 18, color: Color(0xFF36785A)),
                            const SizedBox(width: 8),
                            Text(
                              'Tips Pemulihan Optimal',
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF235B42),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildCheckItem('Lakukan pendinginan ringan dan peregangan statis selama 5 menit.', isDark),
                        const SizedBox(height: 8),
                        _buildCheckItem('Minum air putih secukupnya untuk mengganti cairan yang hilang.', isDark),
                        const SizedBox(height: 8),
                        _buildCheckItem('Duduk atau berbaring rileks dengan posisi bernapas teratur.', isDark),
                        const SizedBox(height: 8),
                        _buildCheckItem('Hindari langsung mandi air dingin sesaat setelah berolahraga intens.', isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Button "Mulai Istirahat"
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF36785A),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ActivityTimerScreen(
                              activity: {
                                'id': 'rest_activity',
                                'title': 'Istirahat Setelah Aktivitas',
                                'heroImg': 'assets/progress/rest/hero_aktivitas.png',
                                'isRest': true,
                                'targetText': '15 menit',
                              },
                            ),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_circle_outline_rounded, size: 20, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Mulai Istirahat',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String text, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            Icons.check_rounded,
            size: 15,
            color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF36785A),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF365E4C),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
