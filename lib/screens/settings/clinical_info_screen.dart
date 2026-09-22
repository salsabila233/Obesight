import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ClinicalInfoScreen extends StatelessWidget {
  const ClinicalInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF489874),
      appBar: AppBar(
        backgroundColor: const Color(0xFF489874),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Informasi dan Sumber',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFF4F8F6),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Alert Card: Penting
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pemberitahuan Medis',
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF92400E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Angka dan rekomendasi di aplikasi ini merupakan perkiraan umum untuk dewasa sehat, bukan saran medis, diagnosis klinis, atau resep pengobatan. Selalu konsultasikan dengan dokter atau ahli gizi untuk kondisi kesehatan spesifik Anda.',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFFB45309),
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. Card: Indeks Massa Tubuh (IMT / BMI)
              _buildInfoCard(
                title: 'Indeks Massa Tubuh (IMT / BMI)',
                icon: Icons.monitor_weight_outlined,
                iconColor: const Color(0xFF36785A),
                content:
                    'IMT dihitung dari berat badan (kg) dibagi kuadrat tinggi badan (m²). Kategori status berat badan di ObeSight mengikuti klasifikasi rujukan kesehatan masyarakat internasional (WHO) dan Kementerian Kesehatan RI untuk populasi dewasa Asia Pasifik:\n\n'
                    '• Kurus (< 18.5)\n'
                    '• Normal (18.5 - 24.9)\n'
                    '• Berat Badan Lebih (25.0 - 29.9)\n'
                    '• Obesitas (≥ 30.0)',
                references: [
                  _ReferenceLink(
                    title: 'KMK No. HK.01.07-MENKES-509-2025: Pedoman Nasional Pelayanan Klinis Tata Laksana Obesitas Dewasa',
                    organization: 'Kemenkes RI',
                  ),
                  _ReferenceLink(
                    title: 'WHO Obesity and Overweight Factsheet (2024)',
                    organization: 'World Health Organization',
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // 3. Card: Perkiraan Kalori
              _buildInfoCard(
                title: 'Perkiraan Kalori (Kebutuhan Energi)',
                icon: Icons.local_fire_department_outlined,
                iconColor: const Color(0xFFEA580C),
                content:
                    'Estimasi kebutuhan energi basal (BMR) dihitung menggunakan Persamaan Harris-Benedict yang telah direvisi (berdasarkan berat badan, tinggi badan, usia, dan jenis kelamin). Nilai ini kemudian dikalikan faktor aktivitas fisik (PAL) serta disesuaikan dengan target berat badan Anda.',
                references: [
                  _ReferenceLink(
                    title: 'CDC - Physical Activity Guidelines for Healthy Weight & Growth',
                    organization: 'Centers for Disease Control and Prevention',
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // 4. Card: Target Asupan Cairan
              _buildInfoCard(
                title: 'Asupan Cairan (Target Air Harian)',
                icon: Icons.water_drop_outlined,
                iconColor: const Color(0xFF0284C7),
                content:
                    'Kebutuhan cairan dasar diestimasi sekitar 30-35 mililiter per kilogram berat badan per hari untuk orang dewasa dengan aktivitas sedang di iklim tropis. Kebutuhan dapat meningkat saat berolahraga intensif atau cuaca panas.',
                references: [
                  _ReferenceLink(
                    title: 'EFSA Scientific Opinion on Dietary Reference Values for Water',
                    organization: 'European Food Safety Authority',
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String content,
    required List<_ReferenceLink> references,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAEFEA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: const Color(0xFF475569),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Text(
            'Referensi Ilmiah & Regulasi:',
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Column(
            children: references.map((ref) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.link_rounded, size: 16, color: Color(0xFF36785A)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ref.title,
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ref.organization,
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              color: const Color(0xFF36785A),
                              fontWeight: FontWeight.w500,
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
    );
  }
}

class _ReferenceLink {
  final String title;
  final String organization;

  _ReferenceLink({required this.title, required this.organization});
}
