import 'package:flutter/material.dart';
import '../../widgets/app_alert.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/activity_timer_service.dart';
import '../../services/activity_alarm_service.dart';
import '../../services/physical_activity_service.dart';
import 'activity_timer_screen.dart';
import 'activity_rest_detail_screen.dart';
import 'activity_duration_picker_screen.dart';
import '../../widgets/global_floating_timer_overlay.dart';

class ActivityDetailScreen extends StatefulWidget {
  final Map<String, dynamic> activity;
  final String? dateKey;

  const ActivityDetailScreen({
    super.key,
    required this.activity,
    this.dateKey,
  });

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isSticky = false;
  bool _isCardExpanded = false;
  bool _hasShownCompletionDialog = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final offset = _scrollController.offset;
      if (offset > 130 && !_isSticky) {
        setState(() => _isSticky = true);
      } else if (offset <= 130 && _isSticky) {
        setState(() => _isSticky = false);
      }
    });

    final service = ActivityTimerService.instance;
    service.addListener(_handleTimerServiceUpdate);

    if (service.isCompleted) {
      final actId = widget.activity['id'] as String? ?? '';
      if (service.activeActivity?['id'] == actId) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showCompletionDialog();
        });
      }
    }
  }

  void _handleTimerServiceUpdate() {
    if (!mounted) return;
    final service = ActivityTimerService.instance;
    final actId = widget.activity['id'] as String? ?? '';
    final isMatching = service.activeActivity?['id'] == actId;

    if (service.isCompleted && isMatching && !_hasShownCompletionDialog) {
      _hasShownCompletionDialog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showCompletionDialog();
      });
    }
  }

  @override
  void dispose() {
    ActivityTimerService.instance.removeListener(_handleTimerServiceUpdate);
    _scrollController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _showCompletionDialog() {
    _hasShownCompletionDialog = true;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final service = ActivityTimerService.instance;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Clock Icon (Green outline icon matching reference)
              const Icon(
                Icons.access_time_rounded,
                size: 42,
                color: Color(0xFF489874),
              ),
              const SizedBox(height: 14),
              // Title "Waktu Aktivitas Habis"
              Text(
                'Waktu Aktivitas Habis',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3B7A5E),
                ),
              ),
              const SizedBox(height: 16),
              // "00:00"
              Text(
                '00:00',
                style: GoogleFonts.poppins(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 24),
              // Button 1: "Lanjutkan istirahat" (filled green)
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF529B7A),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    ActivityAlarmService.instance.stopAlarm();
                    Navigator.pop(dialogCtx);
                    service.cancelSession();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => ActivityRestDetailScreen(
                          previousActivity: widget.activity,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'Lanjutkan istirahat',
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Button 2: "Batal dan Selesai" (green text button)
              TextButton(
                onPressed: () {
                  ActivityAlarmService.instance.stopAlarm();
                  Navigator.pop(dialogCtx);
                  service.cancelSession();
                },
                child: Text(
                  'Batal dan Selesai',
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF529B7A),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      ActivityAlarmService.instance.stopAlarm();
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.activity['title'] as String? ?? 'Aktivitas Fisik';
    final heroImg = widget.activity['heroImg'] as String? ?? 'assets/progress/clean/hero_jogging.png';
    final iconImg = widget.activity['icon'] as String? ?? 'assets/progress/clean/rec_icon_jogging.png';
    final aboutTitle = widget.activity['aboutTitle'] as String? ?? 'Tentang Latihan';
    final aboutDesc = widget.activity['aboutDesc'] as String? ?? '';
    final benefits = (widget.activity['benefits'] as List<dynamic>?)?.cast<String>() ?? [];
    final specs = widget.activity['specs'] as Map<String, dynamic>? ?? {};
    final tipsTitle = widget.activity['tipsTitle'] as String? ?? 'Tips Melakukan Latihan';
    final tips = (widget.activity['tips'] as List<dynamic>?)?.cast<String>() ?? [];
    final safetyNotes = widget.activity['safetyNotes'] as String?;
    final refLink = widget.activity['refLink'] as String? ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerColor = isDark ? const Color(0xFF1E293B) : const Color(0xFF489874);
    final accentGreen = isDark ? const Color(0xFF58AF86) : const Color(0xFF489874);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: headerColor,
      body: Stack(
        children: [
          // 1. Scrollable Content with Parallax Hero & Collapsing Toolbar
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Sticky Collapsing SliverAppBar
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                elevation: _isSticky ? 3 : 0,
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
                // Sticky Header Title (visible only when collapsed / scrolled down)
                title: AnimatedOpacity(
                  opacity: _isSticky ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    title,
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
                      // Full Hero Photo
                      Image.asset(
                        heroImg,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: headerColor,
                          child: const Icon(Icons.fitness_center_rounded, size: 72, color: Colors.white),
                        ),
                      ),

                      // Gradient Overlay for readability
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.5),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),

                      // Bottom Overlay: Icon + Nama Aktivitas (Posisi Awal)
                      Positioned(
                        bottom: 22,
                        left: 20,
                        right: 20,
                        child: AnimatedOpacity(
                          opacity: _isSticky ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 150),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Icon Circle Badge
                              Container(
                                width: 44,
                                height: 44,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: accentGreen.withValues(alpha: 0.85),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  iconImg,
                                  width: 24,
                                  height: 24,
                                  color: Colors.white,
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.directions_run_rounded,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Activity Name
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: accentGreen,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'PANDUAN LATIHAN',
                                        style: GoogleFonts.poppins(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      title,
                                      style: GoogleFonts.poppins(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ],
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

              // Content Sliver in curved container sheet
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F6F8),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  transform: Matrix4.translationValues(0, -20, 0),
                  padding: const EdgeInsets.fromLTRB(18, 24, 18, 150),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section: Tentang Aktivitas
                      Text(
                        aboutTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        aboutDesc,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: textSecondary,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 4-Column Spec Box
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cardBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            _buildSpecCol(Icons.timer_outlined, 'Durasi', specs['duration'] ?? '-', isDark, accentGreen, textPrimary, textSecondary),
                            _buildSpecCol(Icons.calendar_today_outlined, 'Frekuensi', specs['frequency'] ?? '-', isDark, accentGreen, textPrimary, textSecondary),
                            _buildSpecCol(Icons.speed_rounded, 'Intensitas', specs['intensity'] ?? '-', isDark, accentGreen, textPrimary, textSecondary),
                            _buildSpecCol(Icons.local_fire_department_outlined, 'Kalori', specs['calories'] ?? '-', isDark, accentGreen, textPrimary, textSecondary),
                          ],
                        ),
                      ),

                      if (safetyNotes != null && safetyNotes.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2D2314) : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.health_and_safety_rounded,
                                color: Color(0xFFD97706),
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Catatan Keselamatan & Klinis',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      safetyNotes,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11.5,
                                        color: isDark
                                            ? const Color(0xFFFDE68A).withValues(alpha: 0.9)
                                            : const Color(0xFF92400E),
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 22),

                      // Section: Manfaat Utama
                      Text(
                        'Manfaat Utama',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...benefits.map((b) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check_rounded,
                                    color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF16A34A),
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    b,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),

                      const SizedBox(height: 20),

                      // Section: Tips Melakukan
                      Text(
                        tipsTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Column(
                          children: tips
                              .map((t) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('• ', style: TextStyle(color: accentGreen, fontSize: 16, fontWeight: FontWeight.bold)),
                                        Expanded(
                                          child: Text(
                                            t,
                                            style: GoogleFonts.poppins(
                                              fontSize: 12.5,
                                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),

                      // Section: Sumber Referensi (Dipertahankan)
                      if (refLink.isNotEmpty) ...[
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Icon(Icons.link_rounded, size: 18, color: accentGreen),
                            const SizedBox(width: 6),
                            Text(
                              'Sumber Referensi',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: refLink));
                            AppAlert.showSuccess(
                              context,
                              'Tautan referensi berhasil disalin',
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFBBF7D0)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    refLink,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF15803D),
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.copy_rounded, size: 16, color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF15803D)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 2. Fixed Bottom Button: "Mulai"
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: SizedBox(
                  width: double.infinity,
                  child: ListenableBuilder(
                    listenable: ActivityTimerService.instance,
                    builder: (context, _) {
                      final service = ActivityTimerService.instance;
                      final actId = widget.activity['id'] as String? ?? '';
                      final isRunningThis = service.hasActiveSession &&
                          (service.activeActivity?['id'] == actId);

                      final isFuture = PhysicalActivityService.isFutureDateKey(widget.dateKey);

                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFuture
                              ? (isDark ? const Color(0xFF334155) : const Color(0xFF94A3B8))
                              : accentGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 3,
                        ),
                        onPressed: isFuture
                            ? () {
                                AppAlert.showWarning(
                                  context,
                                  'Latihan tidak dapat dimulai untuk tanggal mendatang. Progres hanya dapat dicatat untuk hari ini.',
                                );
                              }
                            : () async {
                                final Widget targetScreen;
                                if (isRunningThis) {
                                  targetScreen = ActivityTimerScreen(
                                    activity: widget.activity,
                                    dateKey: widget.dateKey,
                                  );
                                } else {
                                  targetScreen = ActivityDurationPickerScreen(
                                    activity: widget.activity,
                                    dateKey: widget.dateKey,
                                  );
                                }

                                final result = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => targetScreen,
                                  ),
                                );
                                if (!context.mounted) return;
                                if (result == 'rest') {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => ActivityRestDetailScreen(
                                        previousActivity: widget.activity,
                                      ),
                                    ),
                                  );
                                }
                              },
                        child: Text(
                          'Mulai',
                          style: GoogleFonts.poppins(fontSize: 15.5, fontWeight: FontWeight.w700),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // 3. Mini Timer / Expanded Timer Card in Header (Top Right)
          ListenableBuilder(
            listenable: ActivityTimerService.instance,
            builder: (context, _) {
              final service = ActivityTimerService.instance;
              final actId = widget.activity['id'] as String? ?? '';
              final isRunningThis = service.hasActiveSession &&
                  (service.activeActivity?['id'] == actId);

              if (!isRunningThis || GlobalFloatingTimerOverlay.isGlobalOverlayMounted) {
                return const SizedBox.shrink();
              }

              final topPadding = MediaQuery.of(context).padding.top;

              if (!_isCardExpanded) {
                // Mini Timer Pill (Image 3)
                return Positioned(
                  top: topPadding + 6,
                  right: 18,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isCardExpanded = true;
                      });
                    },
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.only(left: 14, right: 3, top: 3, bottom: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.16),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5A9E80),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(
                              _formatTime(service.secondsRemaining),
                              style: GoogleFonts.poppins(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              } else {
                // Larger Timer Card (Image 4)
                final progress = service.targetDuration > 0
                    ? (service.elapsedSeconds / service.targetDuration).clamp(0.0, 1.0)
                    : 0.0;

                return Positioned(
                  top: topPadding + 6,
                  right: 18,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isCardExpanded = false;
                      });
                    },
                    child: Container(
                      width: 175,
                      padding: const EdgeInsets.fromLTRB(14, 8, 12, 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Top right: Expand icon
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ActivityTimerScreen(
                                        activity: widget.activity,
                                        dateKey: widget.dateKey,
                                      ),
                                    ),
                                  );
                                  if (mounted) {
                                    setState(() {
                                      _isCardExpanded = false;
                                    });
                                  }
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(2),
                                  child: Icon(
                                    Icons.open_in_full_rounded,
                                    size: 15,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _formatTime(service.secondsRemaining),
                            style: GoogleFonts.poppins(
                              fontSize: 27,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              height: 7,
                              width: double.infinity,
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: const Color(0xFFE2E8F0),
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5A9E80)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSpecCol(
    IconData icon,
    String label,
    String value,
    bool isDark,
    Color accentGreen,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: accentGreen),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 10.5, color: textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: textPrimary),
          ),
        ],
      ),
    );
  }
}

