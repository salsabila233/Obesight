import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/activity_timer_service.dart';
import '../services/activity_alarm_service.dart';
import '../screens/progress/activity_timer_screen.dart';
import '../screens/progress/activity_rest_detail_screen.dart';

/// Overlay pewaktu mengambang global yang tampil di seluruh halaman
/// (Beranda, Progres, Aktivitas Fisik, Detail, dsb.) saat timer aktif berjalan
class GlobalFloatingTimerOverlay extends StatefulWidget {
  final Widget child;

  const GlobalFloatingTimerOverlay({
    super.key,
    required this.child,
  });

  /// Penanda apakah global overlay sudah terpasang di root MaterialApp
  static bool isGlobalOverlayMounted = false;

  @override
  State<GlobalFloatingTimerOverlay> createState() => _GlobalFloatingTimerOverlayState();
}

class _GlobalFloatingTimerOverlayState extends State<GlobalFloatingTimerOverlay> {
  bool _isExpanded = false;
  Offset? _customPosition;
  bool _hasShownCompletionDialog = false;

  @override
  void initState() {
    super.initState();
    GlobalFloatingTimerOverlay.isGlobalOverlayMounted = true;
    ActivityTimerService.instance.addListener(_handleTimerServiceUpdate);
  }

  @override
  void dispose() {
    GlobalFloatingTimerOverlay.isGlobalOverlayMounted = false;
    ActivityTimerService.instance.removeListener(_handleTimerServiceUpdate);
    super.dispose();
  }

  void _handleTimerServiceUpdate() {
    final service = ActivityTimerService.instance;
    if (service.isCompleted && !_hasShownCompletionDialog) {
      _hasShownCompletionDialog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showCompletionDialog();
      });
    } else if (service.isIdle) {
      _hasShownCompletionDialog = false;
    }
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _openFullTimerScreen() {
    final service = ActivityTimerService.instance;
    final act = service.activeActivity;
    if (act == null) return;

    ActivityTimerService.navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => ActivityTimerScreen(
          activity: act,
          dateKey: service.dateKey,
        ),
      ),
    );
  }

  void _showCompletionDialog() {
    final navContext = ActivityTimerService.navigatorKey.currentContext ?? context;
    final isDark = Theme.of(navContext).brightness == Brightness.dark;
    final service = ActivityTimerService.instance;
    final act = service.activeActivity;

    showDialog(
      context: navContext,
      barrierDismissible: false,
      builder: (dialogCtx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 42,
                color: Color(0xFF489874),
              ),
              const SizedBox(height: 14),
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
                    if (act != null) {
                      ActivityTimerService.navigatorKey.currentState?.push(
                        MaterialPageRoute(
                          builder: (_) => ActivityRestDetailScreen(
                            previousActivity: act,
                          ),
                        ),
                      );
                    }
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
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  onPressed: () {
                    ActivityAlarmService.instance.stopAlarm();
                    Navigator.pop(dialogCtx);
                    service.cancelSession();
                  },
                  child: Text(
                    'Batal dan Selesai',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ActivityTimerService.instance,
      builder: (context, _) {
        final service = ActivityTimerService.instance;
        final shouldShow = service.hasActiveSession &&
            (service.isRunning || service.isPaused) &&
            !service.isTimerScreenActive;

        return Stack(
          children: [
            widget.child,
            if (shouldShow) _buildFloatingTimerWidget(context, service),
          ],
        );
      },
    );
  }

  Widget _buildFloatingTimerWidget(BuildContext context, ActivityTimerService service) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final screenSize = mediaQuery.size;

    final defaultX = screenSize.width - (_isExpanded ? 195.0 : 120.0);
    final defaultY = topPadding + 10;

    final posX = _customPosition?.dx ?? defaultX;
    final posY = _customPosition?.dy ?? defaultY;

    final progress = service.targetDuration > 0
        ? (service.elapsedSeconds / service.targetDuration).clamp(0.0, 1.0)
        : 0.0;

    return Positioned(
      left: posX.clamp(10.0, screenSize.width - (_isExpanded ? 190.0 : 130.0)),
      top: posY.clamp(topPadding, screenSize.height - 120.0),
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _customPosition = Offset(
              posX + details.delta.dx,
              posY + details.delta.dy,
            );
          });
        },
        child: Material(
          color: Colors.transparent,
          child: _isExpanded
              ? _buildExpandedCard(service, progress)
              : _buildCollapsedPill(service),
        ),
      ),
    );
  }

  Widget _buildCollapsedPill(ActivityTimerService service) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = true;
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
              color: Colors.black.withValues(alpha: 0.18),
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
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedCard(ActivityTimerService service, double progress) {
    return Container(
      width: 175,
      padding: const EdgeInsets.fromLTRB(14, 8, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = false;
                  });
                },
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
              GestureDetector(
                onTap: _openFullTimerScreen,
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
          GestureDetector(
            onTap: _openFullTimerScreen,
            child: Text(
              _formatTime(service.secondsRemaining),
              style: GoogleFonts.poppins(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 8),
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
    );
  }
}
