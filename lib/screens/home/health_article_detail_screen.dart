import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HealthArticleDetailScreen extends StatefulWidget {
  final Map<String, dynamic> article;

  const HealthArticleDetailScreen({
    super.key,
    required this.article,
  });

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
      if (_scrollController.offset > 120 && !_showStickyTitle) {
        setState(() => _showStickyTitle = true);
      } else if (_scrollController.offset <= 120 && _showStickyTitle) {
        setState(() => _showStickyTitle = false);
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
    final title = widget.article['title'] as String? ?? 'Artikel Kesehatan';
    final category = widget.article['category'] as String? ?? 'Pola Makan & Nutrisi';
    final date = widget.article['date'] as String? ?? '21 September 2026';
    final readTime = widget.article['readTime'] as String? ?? '4 Menit Baca';
    final author = widget.article['author'] as String? ?? 'Tim Medis ObeSight';
    final content = widget.article['content'] as String? ?? '';
    final takeaways = widget.article['takeaways'] as List<String>? ?? [
      'Terapkan pola makan gizi seimbang sesuai panduan Isi Piringku.',
      'Jaga konsistensi aktivitas fisik minimal 30 menit per hari.',
      'Perhatikan kualitas tidur dan kelola stres dengan baik.'
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: Stack(
        children: [
          // Scrollable Article Content with Hero Banner Parallax
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Sliver App Bar with full-width banner
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                elevation: _showStickyTitle ? 3 : 0,
                backgroundColor: const Color(0xFF489874),
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _showStickyTitle ? Colors.transparent : Colors.black.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: AnimatedOpacity(
                  opacity: _showStickyTitle ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _showStickyTitle ? Colors.transparent : Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Tautan artikel disalin', style: GoogleFonts.poppins()),
                          backgroundColor: const Color(0xFF2E6B4F),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF2E6B4F), Color(0xFF489874)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.health_and_safety_rounded,
                            size: 90,
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.3),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.4),
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

              // Content Sliver
              SliverToBoxAdapter(
                child: Container(
                  transform: Matrix4.translationValues(0, -18, 0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x0F000000),
                        blurRadius: 16,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category & Read Time
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5EE),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              category.toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2E6B4F),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '⏱️ $readTime',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Main Title
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Author and Publish Date directly under title
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded, size: 15, color: Color(0xFF36785A)),
                          const SizedBox(width: 4),
                          Text(
                            author,
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF36785A),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text(
                            date,
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, color: Color(0xFFE2E8F0)),

                      // Article Content
                      Text(
                        content.isNotEmpty
                            ? content
                            : 'Menerapkan pola hidup sehat dan pola makan gizi seimbang merupakan kunci utama pencegahan obesitas dan sindrom metabolik. Jaga asupan nutrisi makro dan mikro, kurangi konsumsi gula berlebih, dan luangkan waktu minimal 30 menit per hari untuk berolahraga teratur.',
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          color: const Color(0xFF334155),
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Takeaways Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4FAF7),
                          borderRadius: BorderRadius.circular(16),
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
                                  child: const Icon(Icons.shield_outlined, size: 16, color: Color(0xFF2E6B4F)),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Poin Penting untuk Diingat',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF143728),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ...takeaways.map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('• ', style: TextStyle(color: Color(0xFF2E6B4F), fontWeight: FontWeight.bold)),
                                      Expanded(
                                        child: Text(
                                          item,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
