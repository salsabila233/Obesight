import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BmiResultScreen extends StatelessWidget {
  final double bmi;
  final double weight;
  final double height;
  final String gender;
  final int age;
  final String category;
  final String risk;

  const BmiResultScreen({
    super.key,
    required this.bmi,
    required this.weight,
    required this.height,
    required this.gender,
    required this.category,
    required this.risk,
    this.age = 22,
  });

  Color _getStatusColor() {
    if (bmi < 18.5) return const Color(0xFF0284C7);
    if (bmi <= 22.9) return const Color(0xFF16A34A);
    if (bmi <= 24.9) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  Color _getStatusBgColor() {
    if (bmi < 18.5) return const Color(0xFFE0F2FE);
    if (bmi <= 22.9) return const Color(0xFFDCFCE7);
    if (bmi <= 24.9) return const Color(0xFFFEF3C7);
    return const Color(0xFFFEE2E2);
  }

  String _getBmiDescription() {
    if (bmi < 18.5) {
      return 'Berat badan Anda berada di bawah rentang ideal. Disarankan untuk meningkatkan asupan makanan bergizi seimbang serta berkonsultasi dengan ahli gizi.';
    } else if (bmi <= 22.9) {
      return 'Selamat! Berat badan Anda berada dalam kategori normal dan sehat. Pertahankan pola makan bergizi serta aktivitas fisik minimal 30 menit per hari.';
    } else if (bmi <= 24.9) {
      return 'Berat badan Anda sedikit di atas batas normal. Kurangi konsumsi makanan tinggi gula, garam, lemak serta tingkatkan aktivitas fisik harian.';
    } else {
      return 'Berat badan Anda tergolong obesitas. Disarankan untuk menerapkan defisit kalori sehat, aktivitas fisik teratur, serta konsultasi dengan dokter spesialis gizi.';
    }
  }

  List<Map<String, String>> _getRecommendations() {
    if (bmi < 18.5) {
      return [
        {
          'title': 'Pola Makan Padat Nutrisi',
          'desc': 'Tingkatkan asupan kalori sehat dari protein (telur, ikan, tahu/tempe) dan karbohidrat kompleks.',
          'icon': 'food',
        },
        {
          'title': 'Latihan Penguatan Otot',
          'desc': 'Lakukan latihan resistensi atau angkat beban 2-3 kali seminggu untuk membentuk massa otot.',
          'icon': 'fitness',
        },
        {
          'title': 'Camilan Sehat Teratur',
          'desc': 'Tambahkan camilan padat nutrisi seperti kacang-kacangan, alpukat, atau susu di antara jam makan.',
          'icon': 'water',
        },
      ];
    } else if (bmi <= 22.9) {
      return [
        {
          'title': 'Pola Gizi Seimbang',
          'desc': 'Terapkan konsep "Isi Piringku": 1/3 karbohidrat, 1/3 sayuran, 1/6 lauk pauk, dan 1/6 buah-buahan.',
          'icon': 'food',
        },
        {
          'title': 'Aktivitas Fisik Rutin',
          'desc': 'Lakukan olahraga aerobik (jalan cepat, jogging, bersepeda) minimal 150 menit per minggu.',
          'icon': 'fitness',
        },
        {
          'title': 'Hidrasi & Tidur Cukup',
          'desc': 'Konsumsi minimal 2 liter air putih sehari dan tidur teratur 7-8 jam per malam untuk menjaga metabolisme.',
          'icon': 'water',
        },
      ];
    } else if (bmi <= 24.9) {
      return [
        {
          'title': 'Batasi Gula, Garam, Lemak',
          'desc': 'Ikuti anjuran Kemenkes: maksimal 4 sdm gula, 1 sdt garam, dan 5 sdm lemak per hari.',
          'icon': 'food',
        },
        {
          'title': 'Tingkatkan Gerak Harian',
          'desc': 'Tingkatkan aktivitas fisik (NEAT): jalan 7.000-10.000 langkah/hari dan pilih tangga daripada lift.',
          'icon': 'fitness',
        },
        {
          'title': 'Hindari Kalori Cair',
          'desc': 'Hindari minuman bersoda, boba, kopi manis kemasan, dan ganti dengan air putih atau teh tawar.',
          'icon': 'water',
        },
      ];
    } else {
      return [
        {
          'title': 'Pengaturan Porsi Makan',
          'desc': 'Kurangi porsi karbohidrat sederhana dan perbanyak porsi sayuran hijau berserat tinggi.',
          'icon': 'food',
        },
        {
          'title': 'Olahraga Rendah Benturan',
          'desc': 'Mulai dengan olahraga ramah sendi seperti jalan santai, renang, atau bersepeda statis 30 menit sehari.',
          'icon': 'fitness',
        },
        {
          'title': 'Konsultasi Medis & Gizi',
          'desc': 'Lakukan pemeriksaan kesehatan berkala dan konsultasikan program penurunan berat badan dengan dokter.',
          'icon': 'water',
        },
      ];
    }
  }

  IconData _getRecommendationIcon(String type) {
    switch (type) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'fitness':
        return Icons.directions_run_rounded;
      case 'water':
      default:
        return Icons.eco_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final statusBgColor = _getStatusBgColor();
    // Indonesian formatted number with comma e.g. "23,4"
    final bmiString = bmi.toStringAsFixed(1).replaceAll('.', ',');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF489874),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Hasil Perhitungan IMT',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
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
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // A. HASIL UTAMA (Hero Card)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            statusBgColor.withValues(alpha: 0.65),
                            Colors.white,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: statusColor.withValues(alpha: 0.25), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Indeks Massa Tubuh (IMT)',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Large BMI Score e.g. "23,4"
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                bmiString,
                                style: GoogleFonts.poppins(
                                  fontSize: 46,
                                  fontWeight: FontWeight.w800,
                                  color: statusColor,
                                  letterSpacing: -1,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'kg/m²',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Status IMT Badge Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: statusColor.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              category,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Short Explanation Paragraph
                          Text(
                            _getBmiDescription(),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF334155),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // B. INFORMASI DATA (Summary List Card)
                    Text(
                      'Rincian Data Pengukuran',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildDataRow(
                            label: 'Berat Badan',
                            value: '${weight.toStringAsFixed(1)} kg',
                            icon: Icons.monitor_weight_outlined,
                          ),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          _buildDataRow(
                            label: 'Tinggi Badan',
                            value: '${height.toStringAsFixed(0)} cm',
                            icon: Icons.height_rounded,
                          ),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          _buildDataRow(
                            label: 'Jenis Kelamin',
                            value: gender,
                            icon: gender == 'Laki-laki' ? Icons.male_rounded : Icons.female_rounded,
                          ),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          _buildDataRow(
                            label: 'Kategori Status',
                            value: category,
                            icon: Icons.bookmark_outline_rounded,
                            valueColor: statusColor,
                          ),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          _buildDataRow(
                            label: 'Rentang Normal (Sehat)',
                            value: '18,5 - 22,9 kg/m²',
                            icon: Icons.verified_outlined,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // C. INFORMASI / REKOMENDASI LANJUTAN
                    Text(
                      'Rekomendasi Pola Hidup',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Column(
                      children: _getRecommendations().map((rec) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5EE),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _getRecommendationIcon(rec['icon']!),
                                  color: const Color(0xFF368260),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      rec['title']!,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      rec['desc']!,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11.5,
                                        color: const Color(0xFF475569),
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            // D. BOTTOM ACTION BUTTONS
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Primary Button "Kembali ke Beranda"
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF489874),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        // Pop back to home screen
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      child: Text(
                        'Kembali ke Beranda',
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Secondary Button "Hitung Ulang"
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF36785A),
                        side: const BorderSide(color: Color(0xFF489874), width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        // Pop back to calculation screen for editing
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Hitung Ulang',
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF36785A),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow({
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          Expanded(
            flex: 6,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: valueColor ?? const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
