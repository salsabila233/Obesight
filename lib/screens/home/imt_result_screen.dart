import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ImtResultScreen extends StatelessWidget {
  final double bmi;
  final double weight;
  final double height;
  final String gender;
  final int age;
  final String category;
  final String risk;

  const ImtResultScreen({
    super.key,
    required this.bmi,
    required this.weight,
    required this.height,
    required this.gender,
    this.age = 21,
    required this.category,
    required this.risk,
  });

  String get _formattedBmi => bmi.toStringAsFixed(1).replaceAll('.', ',');

  String get _recommendationMessage {
    final cat = category.toLowerCase();
    if (cat.contains('kurus')) {
      return 'Tingkatkan asupan kalori bernutrisi dan konsultasikan pola makan dengan ahli gizi untuk mencapai berat badan ideal.';
    } else if (cat.contains('gemuk') || cat.contains('kelebihan')) {
      return 'Tingkatkan aktivitas fisik rutin dan kurangi konsumsi makanan tinggi gula/lemak jenuh untuk menurunkan berat badan secara bertahap.';
    } else if (cat.contains('obesitas')) {
      return 'Sangat disarankan berkonsultasi dengan dokter atau tenaga medis untuk program penurunan berat badan yang aman dan terpantau.';
    } else {
      return 'Pertahankan pola makan sehat dan aktivitas fisik yang teratur untuk menjaga berat badan ideal.';
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF4E8F73); // #4CAF93 / #3E8E7E
    const appBg = Color(0xFFF5F9F7);

    return Scaffold(
      backgroundColor: appBg,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Hasil Perhitungan IMT anda',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // HERO CARD HIJAU DENGAN ILUSTRASI PEREMPUAN BERLARI & ANGKA BESAR
                    Container(
                      width: double.infinity,
                      color: primaryGreen,
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              'Indeks Masa Tubuh Anda',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Ilustrasi Wanita Berlari (Page 9 design asset)
                              Image.asset(
                                'assets/bmi_woman_running.png',
                                width: 110,
                                height: 130,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const SizedBox(
                                  width: 100,
                                  height: 120,
                                  child: Icon(Icons.directions_run_rounded, size: 64, color: Colors.white70),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Angka Besar IMT
                                    Text(
                                      _formattedBmi,
                                      style: GoogleFonts.poppins(
                                        fontSize: 52,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: -1,
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    // Pill Badge Kategori
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.08),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        category,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: primaryGreen,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // BODY CONTENT
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                      child: Column(
                        children: [
                          // CARD 1: Pesan Status & Saran Singkat
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBF7F2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFD4EFE4)),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Berat Badan Anda Dalam Kategori $category.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1A1A2E),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _recommendationMessage,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: const Color(0xFF475569),
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // SLIDER INDIKATOR KATEGORI IMT & BADGE RISIKO
                          _ImtCategoryBar(bmi: bmi, risk: risk),
                          const SizedBox(height: 18),

                          // CARD 2: Detail Data Anda / Ringkasan Data Fisik
                          _DetailDataCard(
                            age: age,
                            gender: gender,
                            height: height,
                            weight: weight,
                          ),
                          const SizedBox(height: 18),

                          // CARD 3: Tabel Kategori IMT
                          const _BmiCategoryTable(),
                          const SizedBox(height: 18),

                          // SECTION: Rekomendasi Gaya Hidup & Aktivitas
                          const _LifestyleRecommendationsSection(),
                          const SizedBox(height: 24),

                          // TOMBOL: Hitung Ulang ↻
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryGreen,
                                foregroundColor: Colors.white,
                                elevation: 3,
                                shadowColor: primaryGreen.withValues(alpha: 0.35),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Hitung Ulang',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.refresh_rounded, size: 20),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // TOMBOL: Kembali ke Beranda
                          TextButton(
                            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                            child: Text(
                              'Kembali ke Beranda',
                              style: GoogleFonts.poppins(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// SUB-WIDGET: Detail Data Anda Card
// ==========================================
class _DetailDataCard extends StatelessWidget {
  final int age;
  final String gender;
  final double height;
  final double weight;

  const _DetailDataCard({
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF4E8F73);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detail Data Anda',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: primaryGreen,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.calendar_today_outlined, 'Usia', '$age Tahun'),
          const Divider(height: 18, color: Color(0xFFF1F5F9)),
          _buildDetailRow(Icons.wc_rounded, 'Gender', gender),
          const Divider(height: 18, color: Color(0xFFF1F5F9)),
          _buildDetailRow(Icons.height_rounded, 'Tinggi Badan', '${height % 1 == 0 ? height.toInt() : height} CM'),
          const Divider(height: 18, color: Color(0xFFF1F5F9)),
          _buildDetailRow(Icons.scale_rounded, 'Berat Badan', '${weight % 1 == 0 ? weight.toInt() : weight} KG'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    const primaryGreen = Color(0xFF4E8F73);

    return Row(
      children: [
        Icon(icon, size: 18, color: primaryGreen),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF475569),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// SUB-WIDGET: Kategori IMT Table Card
// ==========================================
class _BmiCategoryTable extends StatelessWidget {
  const _BmiCategoryTable();

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF4E8F73);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kategori IMT',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: primaryGreen,
            ),
          ),
          const SizedBox(height: 12),
          _buildCategoryRow(const Color(0xFF38BDF8), 'Kurus', '<18,5'),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),
          _buildCategoryRow(const Color(0xFF22C55E), 'Ideal', '18,5-24,9'),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),
          _buildCategoryRow(const Color(0xFFF59E0B), 'Kelebihan Berat', '25-29,9'),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),
          _buildCategoryRow(const Color(0xFFEF4444), 'Obesitas', '>30'),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(Color dotColor, String title, String range) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A2E),
          ),
        ),
        const Spacer(),
        Text(
          range,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF334155),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// SUB-WIDGET: Interactive Category Slider
// ==========================================
class _ImtCategoryBar extends StatelessWidget {
  final double bmi;
  final String risk;

  const _ImtCategoryBar({
    required this.bmi,
    required this.risk,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF4E8F73);

    // Calculate percentage position along range [15.0 to 35.0]
    final clampedBmi = bmi.clamp(15.0, 35.0);
    final percentage = (clampedBmi - 15.0) / (35.0 - 15.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Badge Risiko Obesitas
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: primaryGreen),
                const SizedBox(width: 6),
                Text(
                  'Risiko Obesitas: $risk',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Stack for Bar + Dynamic Positioned Tooltip
          LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              const tooltipWidth = 46.0;
              final leftPos = (percentage * (totalWidth - tooltipWidth)).clamp(0.0, totalWidth - tooltipWidth);

              return Column(
                children: [
                  // Tooltip Pointer
                  SizedBox(
                    height: 28,
                    child: Stack(
                      children: [
                        Positioned(
                          left: leftPos,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1A2E),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  bmi.toStringAsFixed(1),
                                  style: GoogleFonts.poppins(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              CustomPaint(
                                size: const Size(8, 4),
                                painter: _TrianglePainter(color: const Color(0xFF1A1A2E)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Horizontal 4-Segment Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      children: const [
                        Expanded(child: SizedBox(height: 10, child: ColoredBox(color: Color(0xFF38BDF8)))), // Kurus
                        SizedBox(width: 2),
                        Expanded(child: SizedBox(height: 10, child: ColoredBox(color: Color(0xFF22C55E)))), // Normal
                        SizedBox(width: 2),
                        Expanded(child: SizedBox(height: 10, child: ColoredBox(color: Color(0xFFF59E0B)))), // Gemuk
                        SizedBox(width: 2),
                        Expanded(child: SizedBox(height: 10, child: ColoredBox(color: Color(0xFFEF4444)))), // Obesitas
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Labels below Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBarLabel('Kurus'),
                      _buildBarLabel('Normal'),
                      _buildBarLabel('Gemuk'),
                      _buildBarLabel('Obesitas'),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBarLabel(String text) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF64748B),
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ==========================================
// SUB-WIDGET: Lifestyle Recommendations Section
// ==========================================
class _LifestyleRecommendationsSection extends StatelessWidget {
  const _LifestyleRecommendationsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rekomendasi Gaya Hidup & Aktivitas',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 12),
        _buildItem(
          Icons.restaurant_menu_rounded,
          'Pola Gizi Seimbang',
          'Prioritaskan makanan segar berprotein tinggi dan serat sayur-buahan untuk menjaga metabolisme tubuh.',
        ),
        const SizedBox(height: 10),
        _buildItem(
          Icons.directions_run_rounded,
          'Aktivitas Fisik Rutin',
          'Lakukan latihan aerobik atau jalan cepat 30–60 menit minimal 3-5 kali per minggu.',
        ),
        const SizedBox(height: 10),
        _buildItem(
          Icons.nightlight_round,
          'Istirahat & Manajemen Stres',
          'Tidur teratur 7-8 jam per malam untuk menjaga keseimbangan hormon pengatur nafsu makan.',
        ),
      ],
    );
  }

  Widget _buildItem(IconData icon, String title, String desc) {
    const primaryGreen = Color(0xFF4E8F73);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5EE),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primaryGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
