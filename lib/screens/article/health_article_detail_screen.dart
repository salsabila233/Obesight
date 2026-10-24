import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/article_model.dart';
import '../../services/article_service.dart';
import '../../widgets/article_thumbnail_image.dart';
import '../../widgets/curved_header_scaffold.dart';

class HealthArticleDetailScreen extends StatefulWidget {
  final dynamic article;
  final bool isAdmin;

  const HealthArticleDetailScreen({
    super.key,
    required this.article,
    this.isAdmin = false,
  });

  @override
  State<HealthArticleDetailScreen> createState() => _HealthArticleDetailScreenState();
}

class _HealthArticleDetailScreenState extends State<HealthArticleDetailScreen> {
  late ArticleModel _article;
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    _article = widget.article is ArticleModel
        ? widget.article as ArticleModel
        : (widget.article is Map<String, dynamic>
            ? ArticleModel.fromMap(widget.article)
            : (widget.article is String
                ? (ArticleService().getArticleById(widget.article) ??
                    ArticleService().getArticles().first)
                : ArticleService().getArticles().first));
  }

  Future<void> _publishNow() async {
    setState(() => _isPublishing = true);
    await ArticleService().togglePublishStatus(_article.id, true);
    if (!mounted) return;
    setState(() {
      _article = _article.copyWith(isPublished: true, publishedAt: DateTime.now());
      _isPublishing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Artikel "${_article.title}" berhasil dipublikasikan!',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color(0xFF2E7D5A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final otherArticles = ArticleService()
        .getArticles()
        .where((art) => art.id != _article.id && art.isPublished)
        .take(3)
        .toList();

    return CurvedHeaderScaffold(
      title: 'Artikel',
      centerTitle: true,
      headerColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF388E6B),
      sheetColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      imageUrl: _article.imageUrl,
      imageAsset: _article.imageAsset,
      expandedHeight: 250,
      imagePlaceholderIcon: _article.icon,
      imagePlaceholderColor: _article.headerColor,
      overlap: 24,
      contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Status jika berstatus DRAF (untuk Admin)
          if (!_article.isPublished)
            Container(
              margin: const EdgeInsets.only(bottom: 18),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2D2305) : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pratinjau Draf Artikel',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Artikel ini berstatus Draf dan belum tampil untuk pengguna umum.',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isPublishing ? null : _publishNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF388E6B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isPublishing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'Publikasikan',
                            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                  ),
                ],
              ),
            ),

          // Title Artikel
          Text(
            _article.title,
            style: GoogleFonts.poppins(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),

          // Tanggal Artikel & Waktu Baca
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF94A3B8)),
              const SizedBox(width: 5),
              Text(
                _article.date,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              Text(
                '   •   ',
                style: TextStyle(
                  color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                  fontSize: 10,
                ),
              ),
              Icon(
                Icons.access_time_rounded,
                size: 14,
                color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF388E6B),
              ),
              const SizedBox(width: 5),
              Text(
                _article.readTime,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF388E6B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Lead Snippet Box (jika ada)
          if (_article.snippet.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFF4FAF7),
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  left: BorderSide(
                    color: isDark ? const Color(0xFF58AF86) : const Color(0xFF388E6B),
                    width: 4,
                  ),
                ),
              ),
              child: Text(
                _article.snippet,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFFD1FAE5) : const Color(0xFF2E6B4F),
                  height: 1.55,
                ),
              ),
            ),

          // Konten Artikel Paragraf demi Paragraf
          ..._article.content.split('\n\n').map((paragraph) {
            if (paragraph.trim().isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                paragraph.trim(),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                  height: 1.7,
                ),
              ),
            );
          }),
          const SizedBox(height: 16),

          // Key Takeaways Box (jika ada)
          if (_article.takeaways.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F291E) : const Color(0xFFF4FAF7),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? const Color(0xFF22543D) : const Color(0xFFC8EBD9),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFD4F1E4),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.shield_outlined,
                          size: 17,
                          color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF2E6B4F),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Poin Penting untuk Diingat',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF143728),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._article.takeaways.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2, right: 8),
                              child: Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                                color: isDark ? const Color(0xFF58AF86) : const Color(0xFF388E6B),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                item,
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF2D5241),
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 28),
          ],

          // Artikel Lainnya Section
          if (otherArticles.isNotEmpty) ...[
            Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            const SizedBox(height: 18),
            Text(
              'Artikel Lainnya',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),

            ...otherArticles.map((otherArt) {
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => HealthArticleDetailScreen(
                        article: otherArt,
                        isAdmin: widget.isAdmin,
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      ArticleThumbnailImage(
                        imageUrl: otherArt.imageUrl,
                        imageAsset: otherArt.imageAsset,
                        width: 56,
                        height: 56,
                        borderRadius: BorderRadius.circular(10),
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              otherArt.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              otherArt.readTime,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
