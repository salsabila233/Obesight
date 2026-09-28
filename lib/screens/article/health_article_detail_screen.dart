import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/article_model.dart';
import '../../services/article_service.dart';

class HealthArticleDetailScreen extends StatefulWidget {
  final ArticleModel article;

  HealthArticleDetailScreen({
    super.key,
    required dynamic article,
  }) : article = article is ArticleModel
            ? article
            : (article is Map<String, dynamic>
                ? ArticleModel.fromMap(article)
                : ArticleService().getArticles().first);

  @override
  State<HealthArticleDetailScreen> createState() => _HealthArticleDetailScreenState();
}

class _HealthArticleDetailScreenState extends State<HealthArticleDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showStickyTitle = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        if (_scrollController.offset > 140 && !_showStickyTitle) {
          setState(() => _showStickyTitle = true);
        } else if (_scrollController.offset <= 140 && _showStickyTitle) {
          setState(() => _showStickyTitle = false);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    final otherArticles = ArticleService()
        .getArticles()
        .where((art) => art.id != article.id)
        .take(3)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Sliver App Bar with full article image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            elevation: _showStickyTitle ? 2 : 0,
            backgroundColor: const Color(0xFF36785A),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _showStickyTitle ? Colors.transparent : Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 17),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: AnimatedOpacity(
              opacity: _showStickyTitle ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                article.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            centerTitle: false,
            actions: const [], // Tidak ada bookmark atau tombol samping
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    article.imageAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: article.headerColor,
                      child: Center(
                        child: Icon(article.icon, size: 80, color: Colors.white.withValues(alpha: 0.5)),
                      ),
                    ),
                  ),
                  // Gradient overlay to ensure back button and text readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.45),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Article Content
          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0, -18, 0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    article.title,
                    style: GoogleFonts.poppins(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Reading Time & Date Info Bar (Clean, no doctor / author info)
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF36785A)),
                      const SizedBox(width: 5),
                      Text(
                        article.readTime,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF36785A),
                        ),
                      ),
                      const Text('   •   ', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 10)),
                      const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 5),
                      Text(
                        article.date,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: const Color(0xFF64748B),
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
                        color: const Color(0xFFF4FAF7),
                        borderRadius: BorderRadius.circular(12),
                        border: const Border(
                          left: BorderSide(color: Color(0xFF36785A), width: 4),
                        ),
                      ),
                      child: Text(
                        article.snippet,
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF2E6B4F),
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
                          color: const Color(0xFF334155),
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
                        color: const Color(0xFFF4FAF7),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFC8EBD9), width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFD4F1E4),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.shield_outlined, size: 17, color: Color(0xFF2E6B4F)),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Poin Penting untuk Diingat',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF143728),
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
                                    const Padding(
                                      padding: EdgeInsets.only(top: 2, right: 8),
                                      child: Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF36785A)),
                                    ),
                                    Expanded(
                                      child: Text(
                                        item,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12.5,
                                          color: const Color(0xFF2D5241),
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

                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 18),

                  // Artikel Lainnya Section (Clean without category or tags)
                  Text(
                    'Artikel Lainnya',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
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
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
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
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    otherArt.readTime,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: const Color(0xFF64748B),
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
            ),
          ),
        ],
      ),
    );
  }
}
