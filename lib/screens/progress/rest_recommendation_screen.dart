import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'day_rest_detail_screen.dart';
import 'night_sleep_detail_screen.dart';
import 'activity_rest_detail_screen.dart';

class RestRecommendationScreen extends StatefulWidget {
  const RestRecommendationScreen({super.key});

  @override
  State<RestRecommendationScreen> createState() => _RestRecommendationScreenState();
}

class _RestRecommendationScreenState extends State<RestRecommendationScreen> {
  late final ScrollController _dateScrollController;
  final int _todayOffset = 7; // Index of today in [-7 .. +13] (total 21 days)
  late int _selectedDayIndex;

  @override
  void initState() {
    super.initState();
    _selectedDayIndex = _todayOffset;
    _dateScrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_dateScrollController.hasClients) {
        // Scroll so today's pill is centered
        final scrollPosition = (_todayOffset * 64.0) - 120.0;
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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF36785A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(), // Kembali ke Halaman Progress
        ),
        title: Text(
          'Rekomendasi Waktu Istirahat',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Scrollable Body
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Horizontal Date Selector (Real-Time 21 days: -7 to +13)
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

                      final dayName = isToday ? 'Hari ini' : dayNames[date.weekday % 7];
                      final dateStr = '${date.day}/${date.month}/${date.year.toString().substring(2)}';

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
                        // Past Days -> Merah
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
                        textColor = const Color(0xFF475569);
                        subTextColor = const Color(0xFF94A3B8);
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
                          width: 58,
                          margin: const EdgeInsets.only(right: 8, bottom: 4),
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
                                  fontSize: isToday ? 9.5 : 11,
                                  fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.w500,
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
                const SizedBox(height: 20),

                // 1. Pilihan 1: Istirahat Siang
                _buildOptionCard(
                  circleAsset: 'assets/progress/rest/circle_siang.png',
                  fallbackCircleAsset: 'assets/progress/clean/circle_siang.png',
                  fallbackIcon: Icons.wb_sunny_rounded,
                  title: 'Istirahat Siang',
                  desc: 'Membantu mengurangi rasa lelah dan meningkatkan fokus',
                  badges: [
                    _buildPill(Icons.access_time_rounded, '13.00 - 14.00'),
                    _buildPill(Icons.history_rounded, '20-30 menit'),
                  ],
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DayRestDetailScreen()),
                    );
                  },
                ),
                const SizedBox(height: 14),

                // 2. Pilihan 2: Waktu Tidur Malam
                _buildOptionCard(
                  circleAsset: 'assets/progress/rest/circle_malam.png',
                  fallbackCircleAsset: 'assets/progress/clean/circle_malam.png',
                  fallbackIcon: Icons.nightlight_round,
                  title: 'Waktu Tidur Malam',
                  desc: 'Menjaga metabolisme tubuh dan mengurangi risiko obesitas',
                  badges: [
                    _buildPill(Icons.access_time_rounded, '22.00 – 09.00'),
                    _buildPill(Icons.nightlight_round, '7-8 jam'),
                  ],
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NightSleepDetailScreen()),
                    );
                  },
                ),
                const SizedBox(height: 14),

                // 3. Pilihan 3: Istirahat Setelah Aktivitas
                _buildOptionCard(
                  circleAsset: 'assets/progress/rest/circle_aktivitas.png',
                  fallbackCircleAsset: 'assets/progress/clean/circle_aktivitas.png',
                  fallbackIcon: Icons.directions_run_rounded,
                  title: 'Istirahat Setelah Aktivitas',
                  desc: 'Membantu tubuh pulih dan mencegah kelelahan berlebih',
                  badges: [
                    _buildPill(Icons.directions_run_rounded, 'Setelah beraktivitas'),
                    _buildPill(Icons.history_rounded, '10-15 menit'),
                  ],
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ActivityRestDetailScreen()),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Disclaimer / Info Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDFF1E8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2E6B4F),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.priority_high_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              color: const Color(0xFF2E6B4F),
                              height: 1.45,
                            ),
                            children: const [
                              TextSpan(text: 'Rekomendasi ini dibuat berdasarkan pola hidup sehat '),
                              TextSpan(
                                text: 'untuk membantu risiko obesitas.',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Floating Rounded Navigation Bar at Bottom (matching Gambar 1)
          Positioned(
            left: 24,
            right: 24,
            bottom: 16,
            child: Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF489874),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E6B4F).withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Tab 0: Home (Kembali ke beranda)
                  IconButton(
                    icon: const Icon(Icons.home_rounded, color: Colors.white, size: 24),
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  ),

                  // Tab 1: Stats / Progress (Active indicator)
                  Container(
                    width: 44,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.bar_chart_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),

                  // Tab 2: Settings
                  IconButton(
                    icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 24),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required String circleAsset,
    required String fallbackCircleAsset,
    required IconData fallbackIcon,
    required String title,
    required String desc,
    required List<Widget> badges,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: Row(
              children: [
                // Circle Icon
                Container(
                  width: 62,
                  height: 62,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      circleAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        fallbackCircleAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          color: const Color(0xFFE2F1E8),
                          child: Icon(fallbackIcon, color: const Color(0xFF36785A), size: 28),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Center Content: Title, Badges, Desc
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E3A2F),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: badges,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        desc,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // Trailing Chevron
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFDFF1E8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: const Color(0xFF2E6B4F)),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2E6B4F),
            ),
          ),
        ],
      ),
    );
  }
}
