import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/article_model.dart';
import '../../services/article_service.dart';
import 'health_article_detail_screen.dart';

import '../../widgets/curved_header_scaffold.dart';

class HealthArticleListScreen extends StatefulWidget {
  const HealthArticleListScreen({super.key});

  @override
  State<HealthArticleListScreen> createState() => _HealthArticleListScreenState();
}

class _HealthArticleListScreenState extends State<HealthArticleListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openArticleDetail(ArticleModel article) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HealthArticleDetailScreen(article: article),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<List<ArticleModel>>(
      stream: ArticleService().getArticlesStream(),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData;
        final hasError = snapshot.hasError;

        // Fallback ke data lokal HANYA saat terjadi error / offline
        final allArticles = hasError
            ? ArticleService().initialArticles
            : (snapshot.data ?? const <ArticleModel>[]);

        final q = _searchQuery.trim().toLowerCase();
        final filteredArticles = q.isEmpty
            ? allArticles
            : allArticles.where((art) {
                return art.title.toLowerCase().contains(q) ||
                    art.snippet.toLowerCase().contains(q) ||
                    art.category.toLowerCase().contains(q);
              }).toList();

        return CurvedHeaderScaffold(
          title: 'Daftar Artikel Kesehatan',
          headerColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF36785A),
          sheetColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAF9),
          centerTitle: false,
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            physics: const BouncingScrollPhysics(),
        children: [
          // Banner Status Error jika Firestore belum mengizinkan akses / offline
          if (hasError)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFFEF4444).withValues(alpha: 0.3) : const Color(0xFFFECACA),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFFEF4444), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sinkronisasi Cloud Firestore',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF991B1B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Menampilkan data artikel tersimpan. Data remote Cloud Firestore belum dapat diakses langsung (${snapshot.error}).',
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFFB91C1C),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          // Featured Banner Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E3A2F), const Color(0xFF132A20)]
                    : [const Color(0xFFE6F7F0), const Color(0xFFD4F1E4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF2A503F) : const Color(0xFFC4ECDA),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1436785A),
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF36785A),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'EDUKASI KESEHATAN',
                          style: GoogleFonts.poppins(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Informasi & Panduan Gaya Hidup Sehat',
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF112A1F),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Temukan wawasan gizi, pola makan, kualitas tidur, dan aktivitas fisik untuk pencegahan obesitas.',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF375347),
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
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFF36785A).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Icon(Icons.health_and_safety_rounded, size: 48, color: Color(0xFF36785A)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Search Bar
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() => _searchQuery = val);
                    },
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cari judul artikel...',
                      hintStyle: GoogleFonts.poppins(
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
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
                    child: Icon(Icons.close_rounded, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), size: 18),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Loading State
          if (isLoading)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF36785A)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Menghubungkan ke Cloud Firestore...',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            )
          // Empty State (Koleksi Kosong / Belum Ada Artikel)
          else if (allArticles.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              margin: const EdgeInsets.only(top: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.article_outlined, size: 48, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 12),
                  Text(
                    'Belum Ada Artikel Terbit',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Belum ada artikel kesehatan dengan status terbit (isPublished == true) di Cloud Firestore.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            )
          // Search Empty State
          else if (filteredArticles.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              margin: const EdgeInsets.only(top: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 12),
                  Text(
                    'Artikel Tidak Ditemukan',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tidak ada artikel yang cocok dengan kata kunci "$_searchQuery".',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF58AF86),
                      side: const BorderSide(color: Color(0xFF58AF86)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Reset Pencarian', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            )
          else
            ...filteredArticles.map((art) {
              return GestureDetector(
                onTap: () => _openArticleDetail(art),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE8EEF3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gambar Artikel di bagian atas kartu
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: (art.imageUrl != null && art.imageUrl!.trim().startsWith('http'))
                              ? Image.network(
                                  art.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: art.headerColor.withValues(alpha: 0.2),
                                    child: Center(
                                      child: Icon(art.icon, size: 48, color: art.headerColor),
                                    ),
                                  ),
                                )
                              : Image.asset(
                                  art.imageAsset,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: art.headerColor.withValues(alpha: 0.2),
                                    child: Center(
                                      child: Icon(art.icon, size: 48, color: art.headerColor),
                                    ),
                                  ),
                                ),
                        ),
                      ),

                      // Konten di bawah gambar (Kategori, Judul, Snippet, Waktu Baca & Tombol Baca)
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Kategori Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E3A2F)
                                    : const Color(0xFFE8F5EF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                art.category.toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF2E6B4F),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Judul di bawah gambar
                            Text(
                              art.title,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Snippet / Ringkasan
                            Text(
                              art.snippet,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Footer Info (Waktu Baca & Tombol Baca)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF94A3B8)),
                                    const SizedBox(width: 4),
                                    Text(
                                      art.readTime,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: const Color(0xFF94A3B8),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF36785A),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Baca Artikel',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.arrow_forward_rounded, size: 13, color: Colors.white),
                                    ],
                                  ),
                                ),
                              ],
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
      },
    );
  }
}
