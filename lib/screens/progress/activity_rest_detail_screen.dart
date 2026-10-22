import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/activity_timer_service.dart';
import '../../services/activity_rest_helper.dart';
import 'activity_timer_screen.dart';

/// Halaman Pemilihan Durasi Istirahat sesuai Storyboard Gambar 4 (Halaman Istirahat).
class ActivityRestDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? previousActivity;
  final int? completedDurationMinutes;

  const ActivityRestDetailScreen({
    super.key,
    this.previousActivity,
    this.completedDurationMinutes,
  });

  @override
  State<ActivityRestDetailScreen> createState() => _ActivityRestDetailScreenState();
}

class _ActivityRestDetailScreenState extends State<ActivityRestDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isSticky = false;
  late int _selectedMinutes;
  late int _recommendedMinutes;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final offset = _scrollController.offset;
      if (offset > 120 && !_isSticky) {
        setState(() => _isSticky = true);
      } else if (offset <= 120 && _isSticky) {
        setState(() => _isSticky = false);
      }
    });

    _recommendedMinutes = ActivityRestHelper.getRecommendedRestMinutes(
      activity: widget.previousActivity,
      completedDurationMinutes: widget.completedDurationMinutes,
    );
    _selectedMinutes = _recommendedMinutes;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onStartRest() {
    final service = ActivityTimerService.instance;
    final restActivity = {
      'id': 'rest_activity',
      'title': 'Istirahat Setelah Aktivitas',
      'heroImg': 'assets/progress/rest/hero_aktivitas_clean.png',
      'isRest': true,
      'targetText': '$_selectedMinutes menit',
    };

    service.setupSession(
      activity: restActivity,
      presetSeconds: _selectedMinutes * 60,
    );
    service.startOrResume();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ActivityTimerScreen(
          activity: restActivity,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerColor = isDark ? const Color(0xFF1E293B) : const Color(0xFF489874);
    final accentGreen = isDark ? const Color(0xFF58AF86) : const Color(0xFF489874);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final availableOptions = ActivityRestHelper.getAvailableRestOptions(widget.previousActivity);

    return Scaffold(
      backgroundColor: headerColor,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Sticky Collapsing SliverAppBar dengan hero image ilustrasi wanita istirahat / stretching
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            elevation: _isSticky ? 2 : 0,
            backgroundColor: headerColor,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _isSticky ? Colors.transparent : Colors.black.withValues(alpha: 0.38),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: AnimatedOpacity(
              opacity: _isSticky ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                'Waktu Istirahat',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            centerTitle: true,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/progress/rest/hero_aktivitas_clean.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      'assets/progress/clean/hero_aktivitas.png',
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        color: headerColor,
                        child: const Icon(Icons.spa_rounded, size: 72, color: Colors.white70),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.75),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Title overlay on hero image
                  Positioned(
                    bottom: 24,
                    left: 20,
                    right: 20,
                    child: AnimatedOpacity(
                      opacity: _isSticky ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 150),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: accentGreen.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.spa_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Waktu Istirahat',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content in Curved Sheet (Radius 28)
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 10,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              transform: Matrix4.translationValues(0, -20, 0),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subtitle sesuai Storyboard Gambar 4
                  Text(
                    'Istirahat membantu tubuh pulih dan mengurangi risiko cedera.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section Title: Pilih Durasi Istirahat
                  Text(
                    'Pilih Durasi Istirahat',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Daftar Opsi Durasi Istirahat (5, 10, 15, 20, 30 menit)
                  ...availableOptions.map((opt) {
                    final isSelected = _selectedMinutes == opt.minutes;
                    final isRecommended = opt.minutes == _recommendedMinutes;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedMinutes = opt.minutes;
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFEDF7F2))
                                : cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? accentGreen
                                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: accentGreen.withValues(alpha: 0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              // Radio Indicator
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? accentGreen
                                        : (isDark ? const Color(0xFF64748B) : const Color(0xFFCBD5E1)),
                                    width: 2,
                                  ),
                                  color: isSelected ? accentGreen : Colors.transparent,
                                ),
                                child: isSelected
                                    ? const Center(
                                        child: Icon(Icons.circle, size: 10, color: Colors.white),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 14),

                              // Text Durasi & Keterangan
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          opt.label,
                                          style: GoogleFonts.poppins(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w700,
                                            color: isSelected ? accentGreen : textPrimary,
                                          ),
                                        ),
                                        if (isRecommended) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF065F46) : const Color(0xFFDCFCE7),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'Rekomendasi',
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF16A34A),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      opt.subtitle,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: textSecondary,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  // Tombol "Mulai Istirahat"
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentGreen,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shadowColor: accentGreen.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _onStartRest,
                      child: Text(
                        'Mulai Istirahat',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Tips Pemulihan Optimal
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAF9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2EFE7),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb_outline_rounded,
                                size: 18, color: accentGreen),
                            const SizedBox(width: 8),
                            Text(
                              'Tips Pemulihan Optimal',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildCheckItem(
                            'Lakukan peregangan statis ringan selama sesi istirahat.', isDark),
                        const SizedBox(height: 6),
                        _buildCheckItem(
                            'Minum air putih secukupnya untuk rehidrasi cairan tubuh.', isDark),
                        const SizedBox(height: 6),
                        _buildCheckItem(
                            'Tarik napas perlahan dan biarkan detak jantung menurun stabil.', isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String text, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            Icons.check_rounded,
            size: 14,
            color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF16A34A),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
