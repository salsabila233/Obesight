import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/rest_reminder_service.dart';
import '../../widgets/rest_tracking_widgets.dart';
import 'rest_reminder_setting_screen.dart';

class DayRestDetailScreen extends StatefulWidget {
  const DayRestDetailScreen({super.key});

  @override
  State<DayRestDetailScreen> createState() => _DayRestDetailScreenState();
}

class _DayRestDetailScreenState extends State<DayRestDetailScreen> {
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

  void _openReminderSetting() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const RestReminderSettingScreen(type: RestType.day),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: RestReminderService.instance,
      builder: (context, _) {
        final reminder = RestReminderService.instance.dayRestReminder;

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
                    'Istirahat Siang Hari',
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
                        'assets/progress/rest/hero_siang.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Image.asset(
                          'assets/progress/clean/hero_siang.png',
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
                      // Header Row: Circle Sun Icon & Title side-by-side
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
                                'assets/progress/rest/circle_siang.png',
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Image.asset(
                                  'assets/progress/clean/circle_siang.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, st) => Container(
                                    color: const Color(0xFFE2F1E8),
                                    child: const Icon(
                                      Icons.wb_sunny_rounded,
                                      color: Color(0xFFEAB308),
                                      size: 32,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Waktu Istirahat yang Disarankan',
                              maxLines: 2,
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
                        'Istirahat siang bisa membantu tubuh lebih segar dan meningkatkan konsentrasi.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF4A705E),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Card 1: Status Waktu Istirahat
                      RestStatusCard(
                        type: RestType.day,
                        reminder: reminder,
                        onTap: _openReminderSetting,
                      ),
                      const SizedBox(height: 14),

                      // Card 2: 7 Hari Terakhir
                      if (reminder == null)
                        Rest7DayEmptyChartWidget(
                          type: RestType.day,
                          onTap: _openReminderSetting,
                        )
                      else
                        Rest7DayBarChartWidget(
                          type: RestType.day,
                          reminder: reminder,
                          onTap: _openReminderSetting,
                        ),
                      const SizedBox(height: 20),

                      // Two info cards: Waktu yang Disarankan & Durasi
                      Row(
                        children: [
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
                                      const Icon(Icons.access_time_rounded, size: 15, color: Color(0xFF36785A)),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          'Waktu Disarankan',
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
                                    '13.00 - 15.00',
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
                                          'Durasi Ideal',
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
                                    '20 - 30 Menit',
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
                                  'Tips Istirahat Siang Efektif',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF235B42),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildCheckItem('Batasi tidur siang maksimal 20-30 menit agar tidak pusing saat bangun (sleep inertia).', isDark),
                            const SizedBox(height: 8),
                            _buildCheckItem('Pilih tempat yang redup, sejuk, dan tenang untuk mempermudah relaksasi tubuh.', isDark),
                            const SizedBox(height: 8),
                            _buildCheckItem('Hindari tidur siang terlalu sore (di atas pukul 15.30) agar tidak mengganggu tidur malam.', isDark),
                          ],
                        ),
                      ),
                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
