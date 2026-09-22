import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'activity_timer_screen.dart';

class ActivityDetailScreen extends StatelessWidget {
  final Map<String, dynamic> activity;

  const ActivityDetailScreen({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final title = activity['title'] as String? ?? 'Aktivitas Fisik';
    final heroImg = activity['heroImg'] as String? ?? 'assets/progress/clean/hero_jogging.png';
    final aboutTitle = activity['aboutTitle'] as String? ?? 'Tentang Latihan';
    final aboutDesc = activity['aboutDesc'] as String? ?? '';
    final quote = activity['quote'] as String? ?? '';
    final benefits = (activity['benefits'] as List<dynamic>?)?.cast<String>() ?? [];
    final specs = activity['specs'] as Map<String, dynamic>? ?? {};
    final tipsTitle = activity['tipsTitle'] as String? ?? 'Tips Melakukan Latihan';
    final tips = (activity['tips'] as List<dynamic>?)?.cast<String>() ?? [];
    final refLink = activity['refLink'] as String? ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F8),
      body: Stack(
        children: [
          // Scrollable Content
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Hero Banner
                Stack(
                  children: [
                    Container(
                      height: 250,
                      width: double.infinity,
                      color: const Color(0xFF2D6A4F),
                      child: Image.asset(
                        heroImg,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFF2D6A4F),
                          child: const Icon(Icons.fitness_center_rounded, size: 72, color: Colors.white),
                        ),
                      ),
                    ),
                    Container(
                      height: 250,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.55),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    // Floating Back Button
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                    // Bottom Title Overlay
                    Positioned(
                      bottom: 18,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF36785A),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'PANDUAN LATIHAN',
                              style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // 2. Main Body Content
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // About Section
                      Text(
                        aboutTitle,
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        aboutDesc,
                        style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF475569), height: 1.5),
                      ),

                      const SizedBox(height: 18),

                      // Research Quote Card
                      if (quote.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F7F0),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFC4ECDA)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.format_quote_rounded, color: Color(0xFF36785A), size: 26),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  quote,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: const Color(0xFF1E3A2F),
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 20),

                      // 4-Column Spec Box
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            _buildSpecCol(Icons.timer_outlined, 'Durasi', specs['duration'] ?? '-'),
                            _buildSpecCol(Icons.calendar_today_outlined, 'Frekuensi', specs['frequency'] ?? '-'),
                            _buildSpecCol(Icons.speed_rounded, 'Intensitas', specs['intensity'] ?? '-'),
                            _buildSpecCol(Icons.local_fire_department_outlined, 'Kalori', specs['calories'] ?? '-'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      // Manfaat Utama
                      Text(
                        'Manfaat Utama',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 10),
                      ...benefits.map((b) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFDCFCE7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check_rounded, color: Color(0xFF16A34A), size: 14),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    b,
                                    style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF334155), height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          )),

                      const SizedBox(height: 20),

                      // Tips Melakukan
                      Text(
                        tipsTitle,
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: tips
                              .map((t) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('• ', style: TextStyle(color: Color(0xFF36785A), fontSize: 16, fontWeight: FontWeight.bold)),
                                        Expanded(
                                          child: Text(
                                            t,
                                            style: GoogleFonts.poppins(fontSize: 12.5, color: const Color(0xFF475569), height: 1.4),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),

                      if (refLink.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Text(
                          'Sumber Referensi Ilmiah',
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          refLink,
                          style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFF0284C7), decoration: TextDecoration.underline),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Fixed Bottom Button: "Mulai"
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF36785A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ActivityTimerScreen(activity: activity),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow_rounded, size: 22),
                    label: Text(
                      'Mulai Latihan',
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
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

  Widget _buildSpecCol(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF36785A)),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 10.5, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
          ),
        ],
      ),
    );
  }
}
