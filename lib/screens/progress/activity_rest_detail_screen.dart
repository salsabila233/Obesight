import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActivityRestDetailScreen extends StatefulWidget {
  const ActivityRestDetailScreen({super.key});

  @override
  State<ActivityRestDetailScreen> createState() => _ActivityRestDetailScreenState();
}

class _ActivityRestDetailScreenState extends State<ActivityRestDetailScreen> {
  void _startRestTimerDialog() {
    int remainingSeconds = 15 * 60; // 15 minutes default
    Timer? timer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            timer ??= Timer.periodic(const Duration(seconds: 1), (t) {
              if (remainingSeconds > 0) {
                setDialogState(() {
                  remainingSeconds--;
                });
              } else {
                t.cancel();
              }
            });

            final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
            final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
            final progress = 1.0 - (remainingSeconds / (15 * 60));

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Sesi Istirahat Berlangsung',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF265C45),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tarik napas perlahan dan minum air putih.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Circular Countdown Timer
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 140,
                          height: 140,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 8,
                            backgroundColor: const Color(0xFFE2F1E8),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3E8D6B)),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$minutes:$seconds',
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Menit',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: const Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Tombol Selesai
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
                        onPressed: () {
                          timer?.cancel();
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          'Selesai Istirahat',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      timer?.cancel();
    });
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
                // 1. Hero Image Header (Athlete resting outdoors in park)
                Stack(
                  children: [
                    SizedBox(
                      height: 245,
                      width: double.infinity,
                      child: Image.asset(
                        'assets/progress/rest/hero_aktivitas.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Image.asset(
                          'assets/progress/clean/hero_aktivitas.png',
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            height: 245,
                            color: const Color(0xFF91CCE9),
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
                          'Setelah beraktivitas fisik, tubuh membutuhkan waktu untuk memulihkan energi dan menurunkan detak jantung. Berikut rekomendasi wakttu istirahat yang sesuai untuk Anda.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF4A705E),
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
                                  color: const Color(0xFFEDF7F2),
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
                                      '15 - 30 menit',
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

                            // Card 2: Manfaat
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
                                        const Icon(Icons.favorite_rounded, size: 16, color: Color(0xFF36785A)),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            'Manfaat',
                                            style: GoogleFonts.poppins(
                                              fontSize: 10.5,
                                              color: const Color(0xFF4A705E),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Mengurangi kelelahan, menjaga kondisi jantung, dan memulihkan otot',
                                      style: GoogleFonts.poppins(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF265C45),
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Section Tips Melakukan Istirahat
                        Row(
                          children: [
                            const Icon(Icons.lightbulb_rounded, color: Color(0xFFEAB308), size: 17),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Tips Melakukan Istirahat',
                                style: GoogleFonts.poppins(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF265C45),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Tips Checklist Card (4 items)
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
                              _buildCheckItem('Duduk atau berbaring di tempat yang nyaman'),
                              const SizedBox(height: 8),
                              _buildCheckItem('Minum air putih untuk mengganti cairan yang hilang'),
                              const SizedBox(height: 8),
                              _buildCheckItem('Lakukan peregangan ringan'),
                              const SizedBox(height: 8),
                              _buildCheckItem('Hindari penggunaan gadget terlalu lama'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Warning / Disclaimer Box (Gambar ke 4)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDF7F2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFC7E5D5)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF36785A),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(Icons.priority_high_rounded, color: Colors.white, size: 20),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Istirahat yang cukup setelah aktivtas fisik sangat penting untuk mencegah cedera dan menjaga kebugaran tubuh',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: const Color(0xFF265C45),
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Bottom Button: Mulai Istirahat
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
                            onPressed: _startRestTimerDialog,
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
