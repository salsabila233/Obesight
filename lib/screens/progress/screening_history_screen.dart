import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScreeningHistoryScreen extends StatelessWidget {
  const ScreeningHistoryScreen({super.key});

  final List<Map<String, dynamic>> _historyData = const [
    {
      'day': '11',
      'monthYear': 'Ags 2026',
      'fullDate': '11 Agustus 2026',
      'bmi': '26,8',
      'risk': 'Sedang',
      'category': 'Kategori Overweight (IMT 25–27)',
      'riskColor': Color(0xFFD97706),
      'riskBg': Color(0xFFFEF3C7),
      'riskDesc': 'Risiko sedang terhadap komplikasi metabolik. Disarankan meningkatkan aktivitas fisik rutin dan memperhatikan porsi makan.',
      'recommendations': [
        'Aktivitas aerobik minimal 150 menit per minggu.',
        'Kurangi makanan tinggi gula dan lemak jenuh.',
        'Perbanyak konsumsi sayur, buah, dan air putih.',
      ],
    },
    {
      'day': '16',
      'monthYear': 'Jul 2026',
      'fullDate': '16 Juli 2026',
      'bmi': '27,5',
      'risk': 'Tinggi',
      'category': 'Kategori Obesitas (IMT > 27)',
      'riskColor': Color(0xFFDC2626),
      'riskBg': Color(0xFFFEE2E2),
      'riskDesc': 'Risiko tinggi terhadap gangguan kardiovaskular dan resistensi insulin. Sangat dianjurkan konsultasi dengan dokter atau ahli gizi.',
      'recommendations': [
        'Konsultasikan target penurunan berat badan dengan tenaga medis.',
        'Mulai latihan bertahap dengan olahraga low-impact seperti jalan cepat atau bersepeda.',
        'Catat asupan kalori harian secara disiplin.',
      ],
    },
    {
      'day': '05',
      'monthYear': 'Jul 2026',
      'fullDate': '05 Juli 2026',
      'bmi': '28,0',
      'risk': 'Tinggi',
      'category': 'Kategori Obesitas (IMT > 27)',
      'riskColor': Color(0xFFDC2626),
      'riskBg': Color(0xFFFEE2E2),
      'riskDesc': 'Skrining awal: Indeks Massa Tubuh berada pada tingkat obesitas. Diperlukan intervensi gaya hidup sehat secara konsisten.',
      'recommendations': [
        'Fokus pada pembentukan kebiasaan makan sehat secara bertahap.',
        'Hindari minuman berpemanis dalam kemasan.',
        'Tidur teratur 7-8 jam per malam untuk menjaga metabolisme tubuh.',
      ],
    },
  ];

  void _showDetailModal(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Modal Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detail Hasil Skrining',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      item['fullDate'] as String,
                      style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: item['riskBg'] as Color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Risiko ${item['risk']}',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: item['riskColor'] as Color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // BMI Highlight Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF36785A).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.monitor_heart_rounded, color: Color(0xFF36785A), size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Indeks Massa Tubuh (IMT)',
                          style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFF64748B)),
                        ),
                        Text(
                          '${item['bmi']} kg/m²',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          item['category'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: item['riskColor'] as Color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              'Analisis & Rekomendasi:',
              style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            Text(
              item['riskDesc'] as String,
              style: GoogleFonts.poppins(fontSize: 12.5, color: const Color(0xFF475569), height: 1.45),
            ),
            const SizedBox(height: 14),

            // Recommendations List
            ...((item['recommendations'] as List<String>).map((rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: Color(0xFF36785A), fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(
                          rec,
                          style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF334155), height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ))),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF36785A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text('Tutup', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF36785A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Riwayat Skrining',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Ringkasan
            Text(
              'Ringkasan',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),

            // 4 Stats Cards Grid (Total Skrining, Risiko Tinggi, Sedang, Rendah)
            Row(
              children: [
                _buildStatCard(
                  number: '3',
                  label: 'Total Skrining',
                  bgColor: const Color(0xFFFDF2F8),
                  borderColor: const Color(0xFFFCE7F3),
                  numColor: const Color(0xFFDB2777),
                ),
                const SizedBox(width: 10),
                _buildStatCard(
                  number: '2',
                  label: 'Risiko Tinggi',
                  bgColor: const Color(0xFFFEF2F2),
                  borderColor: const Color(0xFFFEE2E2),
                  numColor: const Color(0xFFDC2626),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildStatCard(
                  number: '1',
                  label: 'Risiko Sedang',
                  bgColor: const Color(0xFFFFFBEB),
                  borderColor: const Color(0xFFFEF3C7),
                  numColor: const Color(0xFFD97706),
                ),
                const SizedBox(width: 10),
                _buildStatCard(
                  number: '0',
                  label: 'Risiko Rendah',
                  bgColor: const Color(0xFFF0FDF4),
                  borderColor: const Color(0xFFDCFCE7),
                  numColor: const Color(0xFF16A34A),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Section 2: Motivation Sparkle Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE6F7F0), Color(0xFFD4F1E4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFC4ECDA)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF36785A).withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF36785A).withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFF2D6A4F),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Terus pertahankan kebiasaan baikmu! Perkembangan kecil setiap hari membawa perubahan besar untuk kesehatanmu.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF112A1F),
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section 3: Daftar Riwayat
            Text(
              'Daftar Riwayat',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 14),

            // Timeline List of Entries
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _historyData.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _historyData[index];
                return _buildTimelineCard(context, item);
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String number,
    required String label,
    required Color bgColor,
    required Color borderColor,
    required Color numColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              number,
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: numColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineCard(BuildContext context, Map<String, dynamic> item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showDetailModal(context, item),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Date Box
                Container(
                  width: 58,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item['day'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        item['monthYear'] as String,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Info Box (IMT Value + Badge + Category Desc)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'IMT: ',
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            item['bmi'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: item['riskBg'] as Color,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item['risk'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: item['riskColor'] as Color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['category'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),

                // Chevron Arrow
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
