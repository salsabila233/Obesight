import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'health_article_detail_screen.dart';

class HealthArticleListScreen extends StatefulWidget {
  const HealthArticleListScreen({super.key});

  @override
  State<HealthArticleListScreen> createState() => _HealthArticleListScreenState();
}

class _HealthArticleListScreenState extends State<HealthArticleListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _articles = [
    {
      'id': 1,
      'title': '5 Pola Makan Penyebab Obesitas',
      'category': 'Pola Makan & Nutrisi',
      'snippet': 'Kenali Kebiasaan makan yang tanpa disadari meningkatkan resiko berat badan berlebih',
      'author': 'Dr. Hendra Wijaya, Sp.GK',
      'date': '21 September 2026',
      'readTime': '4 Menit Baca',
      'color': const Color(0xFF7E96AC),
      'content': 'Menerapkan pola makan sehat merupakan fondasi utama dalam mencegah dan mengendalikan obesitas. Hindari konsumsi minuman manis berlebih, hindari makan terburu-buru (mindless eating), jangan lewatkan sarapan bernutrisi seimbang, batasi camilan larut malam, serta kelola stres agar tidak memicu emotional eating.',
      'takeaways': [
        'Hindari kalori cair dari minuman manis dan bersoda.',
        'Makan secara perlahan dan nikmati setiap suapan.',
        'Jaga jam makan tetap teratur untuk menstabilkan metabolisme.',
      ]
    },
    {
      'id': 2,
      'title': 'Obesitas Bukan Sekadar Masalah Penampilan',
      'category': 'Edukasi Kesehatan',
      'snippet': 'Pola hidup sehat sangat bermanfaat dimasa depan untuk mencegah risiko penyakit metabolik.',
      'author': 'dr. Nurul Aisyah, M.Kes',
      'date': '20 September 2026',
      'readTime': '5 Menit Baca',
      'color': const Color(0xFFE5BD87),
      'content': 'Obesitas merupakan kondisi metabolik kronis yang dapat memicu peradangan tingkat rendah pada organ-organ vital seperti jantung, pankreas, dan hati. Menurunkan berat badan 5-10% memberikan proteksi kardiovaskular yang sangat signifikan.',
      'takeaways': [
        'Obesitas adalah penyakit metabolik medis, bukan sekadar isu penampilan.',
        'Penurunan berat badan bertahap memberikan dampak kesehatan jangka panjang.',
      ]
    },
    {
      'id': 3,
      'title': 'Isi Piringku: Cara Sederhana Mengatur Porsi Makan',
      'category': 'Panduan Kemenkes',
      'snippet': 'Konsep 4 Sehat 5 Sempurna vs Isi Piringku untuk panduan porsi gizi seimbang harian.',
      'author': 'Kementerian Kesehatan RI',
      'date': '19 September 2026',
      'readTime': '4 Menit Baca',
      'color': const Color(0xFFF472B6),
      'content': 'Panduan Isi Piringku dari Kemenkes RI membagi satu piring makan menjadi: 1/3 makanan pokok karbohidrat kompleks, 1/3 sayur-mayur, 1/6 lauk pauk protein, dan 1/6 buah-buahan segar. Terapkan pula anjuran G4-G1-L5 untuk membatasi gula, garam, dan lemak.',
      'takeaways': [
        'Separuh piring diisi oleh sayuran dan buah-buahan berserat tinggi.',
        'Batasi konsumsi gula, garam, dan lemak harian sesuai anjuran Kemenkes.',
      ]
    },
    {
      'id': 4,
      'title': 'Cegah Obesitas dengan Pola Hidup Sehat',
      'category': 'Gaya Hidup Sehat',
      'snippet': 'Kenali kebiasaan sederhana yang dapat menjaga berat badan ideal dan tubuh bugar.',
      'author': 'Tim Medis ObeSight',
      'date': '18 September 2026',
      'readTime': '4 Menit Baca',
      'color': const Color(0xFF86EFAC),
      'content': 'Kombinasikan aktivitas fisik harian (NEAT) minimal 7.000 langkah, olahraga aerobik 150 menit per minggu, latihan beban 2 kali seminggu, tidur 7-8 jam per malam, dan manajemen stres secara konsisten.',
      'takeaways': [
        'Konsistensi kebiasaan kecil jauh lebih penting daripada diet ekstrem sesaat.',
        'Jaga kualitas tidur dan rutin bergerak setiap 45 menit.',
      ]
    },
    {
      'id': 5,
      'title': 'Obesitas Sebagai Pemicu Komplikasi',
      'category': 'Klinis & Medis',
      'snippet': 'Memahami bagaimana resistensi insulin dan peradangan kronis memicu berbagai komplikasi kesehatan.',
      'author': 'Dr. Hendra Wijaya, Sp.GK',
      'date': '17 September 2026',
      'readTime': '5 Menit Baca',
      'color': const Color(0xFF94A3B8),
      'content': 'Penumpukan lemak berlebih berkaitan erat dengan resistensi insulin, diabetes melitus tipe 2, hipertensi, dislipidemia, penyakit jantung koroner, hingga sleep apnea.',
      'takeaways': [
        'Deteksi dini dan skrining berkala mencegah komplikasi permanen.',
      ]
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openArticleDetail(Map<String, dynamic> article) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HealthArticleDetailScreen(article: article),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredArticles = _articles.where((art) {
      if (_searchQuery.isEmpty) return true;
      final title = (art['title'] as String).toLowerCase();
      final snippet = (art['snippet'] as String).toLowerCase();
      final query = _searchQuery.toLowerCase();
      return title.contains(query) || snippet.contains(query);
    }).toList();

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
          'Daftar Artikel Kesehatan',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
        physics: const BouncingScrollPhysics(),
        children: [
          // Featured Banner Card (Static Non-Interactive)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE6F7F0), Color(0xFFD4F1E4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFC4ECDA)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14489874),
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yuk, Kenali Pola Hidup Sehat untuk Cegah Obesitas',
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF112A1F),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Temukan informasi risiko obesitas berdasarkan pola hidup dan kebiasaan sehari-hari.',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFF375347),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: Image.asset(
                    'assets/illustration_woman.png',
                    height: 105,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Search Bar
          Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() => _searchQuery = val);
                    },
                    style: GoogleFonts.poppins(fontSize: 13.5, color: const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'Cari',
                      hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8)),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 18),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Article Cards List
          if (filteredArticles.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              margin: const EdgeInsets.only(top: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 12),
                  Text(
                    'Artikel Tidak Ditemukan',
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tidak ada artikel yang cocok dengan pencarian "$_searchQuery".',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B)),
                  ),
                ],
              ),
            )
          else
            ...filteredArticles.map((art) {
              final color = art['color'] as Color? ?? const Color(0xFF489874);
              return GestureDetector(
                onTap: () => _openArticleDetail(art),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE8EEF3)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Thumbnail
                      Container(
                        width: 105,
                        height: 90,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(Icons.menu_book_rounded, color: Colors.white.withValues(alpha: 0.85), size: 36),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              art['title'] as String,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              art['snippet'] as String,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: const Color(0xFF64748B),
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF489874),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Selengkapnya',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    const Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.white),
                                  ],
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
            }),
        ],
      ),
    );
  }
}
