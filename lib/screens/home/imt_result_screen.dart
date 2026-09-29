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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryGreen = isDark ? const Color(0xFF58AF86) : const Color(0xFF4E8F73);
    final appBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F9F7);
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFEBF7F2);
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFD4EFE4);
    final textHeading = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    return Scaffold(
      backgroundColor: appBg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF4E8F73),
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
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFF4E8F73),
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
                          SizedBox(
                            width: double.infinity,
                            height: 128,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Ilustrasi Wanita Berlari (Page 9 design asset) di sisi kiri
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Image.asset(
                                    'assets/bmi_woman_running.png',
                                    width: 84,
                                    height: 114,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, _, _) => const SizedBox(
                                      width: 72,
                                      height: 96,
                                      child: Icon(Icons.directions_run_rounded, size: 52, color: Colors.white70),
                                    ),
                                  ),
                                ),

                                // Angka Besar IMT & Pill Status Kategori persis di tengah simetris
                                Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Angka Besar IMT
                                      Text(
                                        _formattedBmi,
                                        textAlign: TextAlign.center,
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
                                          color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          category,
                                          textAlign: TextAlign.center,
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
                              color: cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: cardBorder),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Berat Badan Anda Dalam Kategori $category.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: textHeading,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _recommendationMessage,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: textSub,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // SLIDER INDIKATOR KATEGORI IMT & BADGE RISIKO
                          _ImtCategoryBar(bmi: bmi, risk: risk, isDark: isDark),
                          const SizedBox(height: 18),

                          // CARD 2: Detail Data Anda / Ringkasan Data Fisik
                          _DetailDataCard(
                            age: age,
                            gender: gender,
                            height: height,
                            weight: weight,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 18),

                          // CARD 3: Tabel Kategori IMT
                          _BmiCategoryTable(isDark: isDark),
                          const SizedBox(height: 18),

                          // SECTION: Rekomendasi Gaya Hidup & Aktivitas
                          _LifestyleRecommendationsSection(isDark: isDark),
                          const SizedBox(height: 24),

                          // TOMBOL: Hitung Ulang ↻
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4E8F73),
                                foregroundColor: Colors.white,
                                elevation: 3,
                                shadowColor: const Color(0xFF4E8F73).withValues(alpha: 0.35),
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
  final bool isDark;

  const _DetailDataCard({
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final primaryGreen = isDark ? const Color(0xFF58AF86) : const Color(0xFF4E8F73);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final dividerColor = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
    final labelColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final valueColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
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
          _buildDetailRow(Icons.calendar_today_outlined, 'Usia', '$age Tahun', primaryGreen, labelColor, valueColor),
          Divider(height: 18, color: dividerColor),
          _buildDetailRow(Icons.wc_rounded, 'Gender', gender, primaryGreen, labelColor, valueColor),
          Divider(height: 18, color: dividerColor),
          _buildDetailRow(Icons.height_rounded, 'Tinggi Badan', '${height % 1 == 0 ? height.toInt() : height} CM', primaryGreen, labelColor, valueColor),
          Divider(height: 18, color: dividerColor),
          _buildDetailRow(Icons.scale_rounded, 'Berat Badan', '${weight % 1 == 0 ? weight.toInt() : weight} KG', primaryGreen, labelColor, valueColor),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color iconColor, Color labelColor, Color valueColor) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: labelColor,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: valueColor,
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
  final bool isDark;

  const _BmiCategoryTable({this.isDark = false});

  @override
  Widget build(BuildContext context) {
    final primaryGreen = isDark ? const Color(0xFF58AF86) : const Color(0xFF4E8F73);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final dividerColor = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
    final titleColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final rangeColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
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
          _buildCategoryRow(const Color(0xFF38BDF8), 'Kurus', '<18,5', titleColor, rangeColor),
          Divider(height: 16, color: dividerColor),
          _buildCategoryRow(const Color(0xFF22C55E), 'Ideal', '18,5-24,9', titleColor, rangeColor),
          Divider(height: 16, color: dividerColor),
          _buildCategoryRow(const Color(0xFFF59E0B), 'Kelebihan Berat', '25-29,9', titleColor, rangeColor),
          Divider(height: 16, color: dividerColor),
          _buildCategoryRow(const Color(0xFFEF4444), 'Obesitas', '>30', titleColor, rangeColor),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(Color dotColor, String title, String range, Color titleColor, Color rangeColor) {
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
            color: titleColor,
          ),
        ),
        const Spacer(),
        Text(
          range,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: rangeColor,
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
  final bool isDark;

  const _ImtCategoryBar({
    required this.bmi,
    required this.risk,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final primaryGreen = isDark ? const Color(0xFF58AF86) : const Color(0xFF4E8F73);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final badgeBorder = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    final badgeText = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final labelColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    // Calculate percentage position along range [15.0 to 35.0]
    final clampedBmi = bmi.clamp(15.0, 35.0);
    final percentage = (clampedBmi - 15.0) / (35.0 - 15.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Badge Risiko Obesitas
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: badgeBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: primaryGreen),
                  const SizedBox(width: 6),
                  Text(
                    'Risiko Obesitas: $risk',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: badgeText,
                    ),
                  ),
                ],
              ),
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
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFF1A1A2E),
                                  borderRadius: BorderRadius.circular(6),
                                  border: isDark ? Border.all(color: const Color(0xFF334155)) : null,
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
                                painter: _TrianglePainter(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFF1A1A2E),
                                ),
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
                      _buildBarLabel('Kurus', labelColor),
                      _buildBarLabel('Normal', labelColor),
                      _buildBarLabel('Gemuk', labelColor),
                      _buildBarLabel('Obesitas', labelColor),
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

  Widget _buildBarLabel(String text, Color color) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
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
  final bool isDark;

  const _LifestyleRecommendationsSection({this.isDark = false});

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rekomendasi Gaya Hidup & Aktivitas',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: titleColor,
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
    final primaryGreen = isDark ? const Color(0xFF58AF86) : const Color(0xFF4E8F73);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final iconBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFE8F5EE);
    final titleColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final descColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
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
            decoration: BoxDecoration(
              color: iconBg,
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
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: descColor,
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
