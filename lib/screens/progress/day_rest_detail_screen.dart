import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DayRestDetailScreen extends StatefulWidget {
  const DayRestDetailScreen({super.key});

  @override
  State<DayRestDetailScreen> createState() => _DayRestDetailScreenState();
}

class _DayRestDetailScreenState extends State<DayRestDetailScreen> {
  void _showSetReminderDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFE2F1E8),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.notifications_active_rounded,
                    size: 32,
                    color: Color(0xFF36785A),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Atur Pengingat Istirahat',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pengingat untuk Istirahat Siang pukul 13.00 telah diaktifkan secara otomatis.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3E8D6B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Selesai',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F8),
      body: Stack(
        children: [
          // Scrollable Body
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Hero Image Header (Woman resting on couch with plants)
                Stack(
                  children: [
                    SizedBox(
                      height: 245,
                      width: double.infinity,
                      child: Image.asset(
                        'assets/progress/rest/hero_siang.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Image.asset(
                          'assets/progress/clean/hero_siang.png',
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            height: 245,
                            color: const Color(0xFF4A8B6F),
                          ),
                        ),
                      ),
                    ),
                    // Gradient overlay at top for back button contrast
                    Container(
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.35),
                            Colors.transparent,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),

                // 2. White Card with top rounded corners overlapping hero
                Transform.translate(
                  offset: const Offset(0, -28),
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 10,
                          offset: Offset(0, -3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                                      child: const Icon(Icons.wb_sunny_rounded, color: Color(0xFFEAB308), size: 32),
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
                                  color: const Color(0xFF235B42),
                                  height: 1.25,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Subtitle
                        Text(
                          'Istirahat siang bisa membantu tubuh lebih segar dan meingkatkan konsentrasi',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF4A705E),
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Two info cards: Waktu yang Disarankan & Durasi
                        Row(
                          children: [
                            // Card 1
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEDF7F2),
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
                                            'Waktu yang Disarankan',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.poppins(
                                              fontSize: 10.5,
                                              color: const Color(0xFF4A705E),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '13.00 - 14.00',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF265C45),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Card 2
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEDF7F2),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.history_rounded, size: 15, color: Color(0xFF36785A)),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            'Durasi',
                                            style: GoogleFonts.poppins(
                                              fontSize: 10.5,
                                              color: const Color(0xFF4A705E),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '20 - 30 menit',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF265C45),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Section Manfaat
                        Row(
                          children: [
                            const Icon(Icons.spa_rounded, color: Color(0xFF36785A), size: 17),
                            const SizedBox(width: 6),
                            Text(
                              'Manfaat',
                              style: GoogleFonts.poppins(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF265C45),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Manfaat Checklist Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDF7F2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCheckItem('Mengurangi rasa lelah dan stress'),
                              const SizedBox(height: 8),
                              _buildCheckItem('Meningkatkan fokus dan produktivitas'),
                              const SizedBox(height: 8),
                              _buildCheckItem('Membantu mengontrol nafsu makan'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Section Tips Istirahat
                        Row(
                          children: [
                            const Icon(Icons.lightbulb_rounded, color: Color(0xFFEAB308), size: 17),
                            const SizedBox(width: 6),
                            Text(
                              'Tips Istirahat',
                              style: GoogleFonts.poppins(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF265C45),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Tips Checklist Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDF7F2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCheckItem('Cari tempat yang nyaman dan tenang'),
                              const SizedBox(height: 8),
                              _buildCheckItem('Gunakan posisi duduk atau berbaring yang rileks'),
                              const SizedBox(height: 8),
                              _buildCheckItem('Hindari tidur terlalu lama (maks. 30 menit)'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Bottom Button: Atur pengingat
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3E8D6B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              elevation: 0,
                            ),
                            onPressed: _showSetReminderDialog,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.notifications_active_outlined, size: 19, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  'Atur pengingat',
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
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Floating Back Button on Top Left (Navigates back to Rekomendasi Waktu Istirahat)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 14,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.of(context).pop(), // Kembali ke Rekomendasi Waktu Istirahat
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFF265C45),
                      size: 16,
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

  Widget _buildCheckItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.check_rounded, size: 15, color: Color(0xFF36785A)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF365E4C),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
