import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/article_model.dart';
import '../../services/article_service.dart';

import '../../widgets/curved_header_scaffold.dart';

class HealthArticleDetailScreen extends StatelessWidget {
  final ArticleModel article;

  HealthArticleDetailScreen({
    super.key,
    required dynamic article,
  }) : article = article is ArticleModel
            ? article
            : (article is Map<String, dynamic>
                ? ArticleModel.fromMap(article)
                : (article is String
                    ? (ArticleService().getArticleById(article) ??
                        ArticleService().getArticles().first)
                    : ArticleService().getArticles().first));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final otherArticles = ArticleService()
        .getArticles()
        .where((art) => art.id != article.id)
        .take(3)
        .toList();

    return CurvedHeaderScaffold(
      title: article.title,
      headerColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF36785A),
      sheetColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      imageUrl: article.imageUrl,
      imageAsset: article.imageAsset,
      expandedHeight: 250,
      imagePlaceholderIcon: article.icon,
      imagePlaceholderColor: article.headerColor,
      overlap: 24,
      contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            article.title,
            style: GoogleFonts.poppins(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              height: 1.35,
            ),
          ),
                  const SizedBox(height: 10),

                  // Reading Time & Date Info Bar (Clean, no doctor / author info)
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 14, color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF36785A)),
                      const SizedBox(width: 5),
                      Text(
                        article.readTime,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF36785A),
                        ),
                      ),
                      Text('   •   ', style: TextStyle(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1), fontSize: 10)),
                      const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 5),
                      Text(
                        article.date,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Lead Snippet Box
                  if (article.snippet.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFF4FAF7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border(
                          left: BorderSide(
                            color: isDark ? const Color(0xFF58AF86) : const Color(0xFF36785A),
                            width: 4,
                          ),
                        ),
                      ),
                      child: Text(
                        article.snippet,
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFFD1FAE5) : const Color(0xFF2E6B4F),
                          height: 1.55,
                        ),
                      ),
                    ),

                  // Article Content Paragraphs
                  ...article.content.split('\n\n').map((paragraph) {
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

                  // Key Takeaways Box
                  if (article.takeaways.isNotEmpty) ...[
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
                          ...article.takeaways.map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2, right: 8),
                                      child: Icon(
                                        Icons.check_circle_rounded,
                                        size: 16,
                                        color: isDark ? const Color(0xFF58AF86) : const Color(0xFF36785A),
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

                  Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  const SizedBox(height: 18),

                  // Artikel Lainnya Section (Clean without category or tags)
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
                            builder: (_) => HealthArticleDetailScreen(article: otherArt),
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
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: (otherArt.imageUrl != null && otherArt.imageUrl!.trim().startsWith('http'))
                                  ? Image.network(
                                      otherArt.imageUrl!,
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        width: 56,
                                        height: 56,
                                        color: otherArt.headerColor.withValues(alpha: 0.15),
                                        child: Icon(otherArt.icon, color: otherArt.headerColor, size: 24),
                                      ),
                                    )
                                  : Image.asset(
                                      otherArt.imageAsset,
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        width: 56,
                                        height: 56,
                                        color: otherArt.headerColor.withValues(alpha: 0.15),
                                        child: Icon(otherArt.icon, color: otherArt.headerColor, size: 24),
                                      ),
                                    ),
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
              ),
            );
          }
        }
