import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/activity_timer_service.dart';
import '../../services/activity_alarm_service.dart';
import '../../services/physical_activity_service.dart';
import 'activity_rest_detail_screen.dart';

class ActivityTimerScreen extends StatefulWidget {
  final Map<String, dynamic> activity;
  final String? dateKey;

  const ActivityTimerScreen({super.key, required this.activity, this.dateKey});

  @override
  State<ActivityTimerScreen> createState() => _ActivityTimerScreenState();
}

class _ActivityTimerScreenState extends State<ActivityTimerScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isSticky = false;
  bool _hasShownDialog = false;

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

    final service = ActivityTimerService.instance;
    final actId = widget.activity['id'] as String? ?? '';
    final activeId = service.activeActivity?['id'] as String? ?? '';
    final isSameActivity = activeId.isNotEmpty && activeId == actId;

    if (!isSameActivity || service.isIdle) {
      final isRest = widget.activity['isRest'] == true;
      final defaultRestSeconds = 15 * 60;
      service.setupSession(
        activity: widget.activity,
        presetSeconds: isRest ? defaultRestSeconds : null,
        dateKey: widget.dateKey,
      );
    }

    service.addListener(_handleTimerServiceUpdate);
  }

  void _handleTimerServiceUpdate() {
    if (!mounted) return;
    final service = ActivityTimerService.instance;
    if (service.isCompleted && !_hasShownDialog) {
      _hasShownDialog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _onTimerFinishedNaturally();
      });
    }
  }

  @override
  void dispose() {
    ActivityAlarmService.instance.stopAlarm();
    ActivityTimerService.instance.removeListener(_handleTimerServiceUpdate);
    _scrollController.dispose();
    super.dispose();
  }

  List<int> _getPresets() {
    final isRest = widget.activity['isRest'] == true;
    if (isRest) {
      return [10 * 60, 15 * 60, 20 * 60];
    }

    final id = (widget.activity['id'] as String? ?? '').toLowerCase();
    final title = (widget.activity['title'] as String? ?? '').toLowerCase();

    if (id.contains('yoga') || title.contains('yoga')) {
      return [15 * 60, 30 * 60, 40 * 60];
    } else if (id.contains('hiit') || title.contains('hiit') || title.contains('interval')) {
      return [20 * 60, 25 * 60, 30 * 60];
    } else {
      // Default for Jogging, Bodyweight, Cycling
      return [30 * 60, 45 * 60, 60 * 60];
    }
  }

  String _getDisplayTitle() {
    final isRest = widget.activity['isRest'] == true;
    if (isRest) {
      return 'Istirahat Setelah\nAktivitas';
    }

    final id = (widget.activity['id'] as String? ?? '').toLowerCase();
    final title = widget.activity['title'] as String? ?? 'Aktivitas';

    if (id.contains('bodyweight') || title.toLowerCase().contains('bodyweight')) {
      return 'Latihan\nBodyweight';
    } else if (id.contains('hiit') || title.toLowerCase().contains('hiit')) {
      return 'High-Intensity Interval\nTraining';
    } else if (id.contains('cycling') || title.toLowerCase().contains('sepeda')) {
      return 'Bersepeda';
    } else if (id.contains('jogging') || title.toLowerCase().contains('jogging')) {
      return 'Jogging';
    } else if (id.contains('yoga') || title.toLowerCase().contains('yoga')) {
      return 'Yoga';
    }
    return title;
  }

  IconData _getActivityIcon() {
    final isRest = widget.activity['isRest'] == true;
    if (isRest) {
      return Icons.spa_rounded;
    }

    final id = (widget.activity['id'] as String? ?? '').toLowerCase();
    final title = (widget.activity['title'] as String? ?? '').toLowerCase();

    if (id.contains('jogging') || title.contains('jogging')) {
      return Icons.directions_run_rounded;
    } else if (id.contains('bodyweight') || title.contains('bodyweight') || title.contains('kekuatan')) {
      return Icons.fitness_center_rounded;
    } else if (id.contains('cycling') || title.contains('sepeda')) {
      return Icons.directions_bike_rounded;
    } else if (id.contains('yoga') || title.contains('yoga')) {
      return Icons.self_improvement_rounded;
    } else if (id.contains('hiit') || title.contains('hiit') || title.contains('interval')) {
      return Icons.bolt_rounded;
    }
    return Icons.fitness_center_rounded;
  }

  String? _getTargetText() {
    final isRest = widget.activity['isRest'] == true;
    if (isRest) {
      return '15 menit';
    }

    final id = (widget.activity['id'] as String? ?? '').toLowerCase();
    final title = (widget.activity['title'] as String? ?? '').toLowerCase();

    if (id.contains('yoga') ||
        title.contains('yoga') ||
        id.contains('cycling') ||
        title.contains('sepeda') ||
        id.contains('hiit') ||
        title.contains('hiit')) {
      return null;
    }
    return widget.activity['targetText'] as String? ?? '30-60 menit';
  }

  /// Hitung kkal/menit dari nilai tengah kalori dibagi nilai tengah durasi masing-masing aktivitas
  double _getCalorieRatePerMinute() {
    final id = (widget.activity['id'] as String? ?? '').toLowerCase();
    final title = (widget.activity['title'] as String? ?? '').toLowerCase();

    if (id.contains('hiit') || title.contains('hiit') || title.contains('interval')) {
      return 350.0 / 22.5; // ~15.56 kkal/menit
    } else if (id.contains('bodyweight') || title.contains('bodyweight') || title.contains('kekuatan')) {
      return 250.0 / 32.5; // ~7.69 kkal/menit
    } else if (id.contains('yoga') || title.contains('yoga')) {
      return 150.0 / 30.0; // 5.00 kkal/menit
    } else if (id.contains('cycling') || title.contains('sepeda')) {
      return 300.0 / 45.0; // ~6.67 kkal/menit
    } else {
      return 300.0 / 45.0; // ~6.67 kkal/menit
    }
  }

  /// Hitung estimasi kalori proporsional terhadap durasi aktual yang dijalani user
  int _calculateBurnedCalories(int elapsedSecs) {
    final minutes = elapsedSecs / 60.0;
    final rate = _getCalorieRatePerMinute();
    return (minutes * rate).round();
  }

  void _selectPreset(int seconds) {
    _hasShownDialog = false;
    ActivityAlarmService.instance.stopAlarm();
    ActivityTimerService.instance.setPreset(seconds);
  }

  void _toggleTimer() {
    final service = ActivityTimerService.instance;
    final targetDateKey = widget.dateKey ?? service.dateKey;
    final isRest = widget.activity['isRest'] == true;

    if (!isRest && PhysicalActivityService.isFutureDateKey(targetDateKey)) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Latihan tidak dapat dimulai untuk tanggal mendatang. Progres hanya dapat dicatat untuk hari ini.',
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (service.targetDuration <= 0 && service.selectedPreset == null) {
      final presets = _getPresets();
      service.setPreset(presets.first);
    }
    service.togglePlayPause();
  }

  void _onTimerFinishedNaturally() {
    final isRest = widget.activity['isRest'] == true;
    final targetDateKey = widget.dateKey ?? ActivityTimerService.instance.dateKey;

    if (!isRest && PhysicalActivityService.isFutureDateKey(targetDateKey)) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Progres latihan hanya dapat dicatat untuk tanggal hari ini.',
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (isRest) {
      _showRestCompletionDialog();
    } else {
      _showCompletionDialog();
    }
  }

  Future<void> _onFinishButtonPressed() async {
    final service = ActivityTimerService.instance;
    final isRest = widget.activity['isRest'] == true;

    if (isRest) {
      service.pause();
      _showRestCompletionDialog();
      return;
    }

    final targetDateKey = widget.dateKey ?? service.dateKey;
    if (PhysicalActivityService.isFutureDateKey(targetDateKey)) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Progres latihan hanya dapat dicatat untuk tanggal hari ini.',
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // Evaluasi aturan minimal 50% durasi aktual
    if (!service.meetsMinimum50Percent) {
      _showInsufficientDurationDialog();
      return;
    }

    final success = await service.finishManually();
    if (!mounted) return;
    if (success) {
      // Skenario A: Durasi berjalan >= 50% target & Berhasil simpan -> Popup Sukses
      _showCompletionDialog();
    } else {
      // Skenario Gagal Simpan: Beritahu pengguna dengan pesan jelas (Requirement 11)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menyimpan progres aktivitas ke Firestore. Silakan periksa koneksi Anda.',
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Skenario B: Dialog Peringatan jika durasi belum mencukupi 50% target
  void _showInsufficientDurationDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        elevation: 10,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Peringatan Kuning/Amber
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 38,
                    color: Color(0xFFD97706),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Judul Dialog
              Text(
                'Durasi Belum Mencukupi',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),

              // Pesan Konfirmasi
              Text(
                'Apakah Anda yakin ingin menyudahi aktivitas fisik ini? Durasi latihan Anda belum mencukupi (minimal 50% dari target) dan tidak akan tercatat sebagai aktivitas selesai.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),

              // Tombol Batal & Ya, Sudahi
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx); // Tutup dialog, kembali ke timer
                      },
                      child: Text(
                        'Batal',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx); // Tutup dialog peringatan
                        ActivityTimerService.instance.cancelSession();
                        Navigator.of(context).pop(false); // Keluar tanpa simpan / tidak centang
                      },
                      child: Text(
                        'Ya, Sudahi',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Skenario A: Popup Latihan Selesai! 🎉 dengan HANYA SATU Tombol "Lanjut Istirahat" & Auto-Save
  void _showCompletionDialog() {
    if (_hasShownDialog) return;
    _hasShownDialog = true;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final service = ActivityTimerService.instance;
    final title = (widget.activity['name'] as String?) ?? (widget.activity['title'] as String?) ?? 'Aktivitas';
    final burnedCalories = _calculateBurnedCalories(service.elapsedSeconds);

    showDialog(
      context: context,
      barrierDismissible: true, // Pengguna bisa tap di luar popup
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
        titlePadding: EdgeInsets.zero,
        title: Stack(
          children: [
            // Tombol Close (X) di pojok kanan atas agar pengguna tidak terjebak
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, size: 22, color: Color(0xFF94A3B8)),
                splashRadius: 18,
                onPressed: () {
                  ActivityAlarmService.instance.stopAlarm();
                  Navigator.pop(ctx);
                  service.cancelSession();
                  Navigator.of(context).pop(true);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 24, left: 16, right: 16),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.emoji_events_rounded,
                        color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF16A34A),
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Latihan Selesai! 🎉',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hebat! Kamu telah menyelesaikan sesi $title hari ini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: isDark ? Border.all(color: const Color(0xFF334155)) : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department_rounded, color: Color(0xFFEA580C), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Estimasi terbakar: $burnedCalories kkal',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Poin 3: Tombol "Simpan & Selesai" dihapus, HANYA menyisakan "Lanjut Istirahat"
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF58AF86) : const Color(0xFF489874),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                onPressed: () {
                  ActivityAlarmService.instance.stopAlarm();
                  Navigator.pop(ctx); // Tutup dialog
                  service.cancelSession();
                  // Arahkan langsung ke halaman Istirahat Setelah Aktivitas
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const ActivityRestDetailScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.spa_rounded, size: 20, color: Colors.white),
                label: Text(
                  'Lanjut Istirahat',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      ActivityAlarmService.instance.stopAlarm();
      // Jika pengguna menutup popup via tap di luar dialog
      if (mounted && Navigator.of(context).canPop()) {
        service.cancelSession();
        Navigator.of(context).pop(true);
      }
    });
  }

  // Popup Penyelesaian Sesi Istirahat
  void _showRestCompletionDialog() {
    if (_hasShownDialog) return;
    _hasShownDialog = true;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final service = ActivityTimerService.instance;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF064E3B) : const Color(0xFFEDF7F2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.spa_rounded,
                color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF489874),
                size: 40,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Istirahat Selesai! 🌿',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: Text(
          'Sesi istirahat Anda telah selesai. Tubuh Anda kini lebih segar, rileks, dan siap beraktivitas kembali.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF58AF86) : const Color(0xFF489874),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                ActivityAlarmService.instance.stopAlarm();
                Navigator.pop(ctx);
                service.cancelSession();
                Navigator.of(context).pop();
              },
              child: Text(
                'Selesai',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13.5),
              ),
            ),
          ),
        ],
      ),
    ).then((_) {
      ActivityAlarmService.instance.stopAlarm();
      if (mounted && Navigator.of(context).canPop()) {
        service.cancelSession();
        Navigator.of(context).pop();
      }
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerColor = isDark ? const Color(0xFF1E293B) : const Color(0xFF489874);
    final accentGreen = isDark ? const Color(0xFF58AF86) : const Color(0xFF489874);
    final isRest = widget.activity['isRest'] == true;
    final heroImg = widget.activity['heroImg'] as String? ??
        (isRest ? 'assets/progress/rest/hero_aktivitas.png' : 'assets/progress/clean/hero_jogging.png');
    final targetText = _getTargetText();
    final presets = _getPresets();

    return ListenableBuilder(
      listenable: ActivityTimerService.instance,
      builder: (context, _) {
        final service = ActivityTimerService.instance;
        final secondsRemaining = service.secondsRemaining;
        final isRunning = service.isRunning;
        final selectedPreset = service.selectedPreset;

        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, result) {
            ActivityAlarmService.instance.stopAlarm();
          },
          child: Scaffold(
            backgroundColor: headerColor,
            body: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Sticky Collapsing SliverAppBar dengan tombol back & title yang tetap menempel di atas
                SliverAppBar(
                  expandedHeight: 230,
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
                    onPressed: () {
                      ActivityAlarmService.instance.stopAlarm();
                      // Keluar dari halaman timer tanpa membatalkan sesi background
                      Navigator.of(context).pop();
                    },
                  ),
                title: AnimatedOpacity(
                  opacity: _isSticky ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    _getDisplayTitle().replaceAll('\n', ' '),
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
                        heroImg,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: headerColor,
                          child: Icon(
                            isRest ? Icons.spa_rounded : Icons.directions_run_rounded,
                            size: 72,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      // Gradient for readability
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.4),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.75),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      // Activity Badge and Title over hero image
                      Positioned(
                        bottom: 30,
                        left: 20,
                        right: 20,
                        child: AnimatedOpacity(
                          opacity: _isSticky ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 150),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: accentGreen.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(_getActivityIcon(), color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  _getDisplayTitle(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1.15,
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

              // Content Lembaran Melengkung (Radius 28) menumpuk di atas header
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  transform: Matrix4.translationValues(0, -20, 0),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Target Header
                        if (targetText != null) ...[
                          Text(
                            isRest ? 'Durasi Istirahat' : 'Target',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: accentGreen,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            targetText,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 18),
                        ] else ...[
                          const SizedBox(height: 8),
                        ],

                        // Big Circular Timer
                        Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            border: Border.all(
                              color: accentGreen,
                              width: 9,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _formatTime(secondsRemaining),
                            style: GoogleFonts.poppins(
                              fontSize: 48,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 26),

                        // Preset Duration Circle Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: presets.map((duration) {
                            final isSelected = selectedPreset == duration;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: GestureDetector(
                                onTap: () => _selectPreset(duration),
                                child: Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                    border: Border.all(
                                      color: isSelected
                                          ? accentGreen
                                          : (isDark ? const Color(0xFF334155) : const Color(0xFFD1D5DB)),
                                      width: isSelected ? 2.5 : 2,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    _formatTime(duration),
                                    style: GoogleFonts.poppins(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? accentGreen
                                          : (isDark ? Colors.white : const Color(0xFF1A1A2E)),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 22),

                        // Play / Pause Circular Control Button
                        GestureDetector(
                          onTap: _toggleTimer,
                          child: Container(
                            width: 66,
                            height: 66,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              border: Border.all(
                                color: accentGreen,
                                width: 3.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              size: 38,
                              color: accentGreen,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // "Selesaikan Aktivitas" / "Selesaikan Istirahat" Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentGreen,
                              foregroundColor: Colors.white,
                              elevation: 3,
                              shadowColor: accentGreen.withValues(alpha: 0.35),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _onFinishButtonPressed,
                            child: Text(
                              isRest ? 'Selesaikan Istirahat' : 'Selesaikan Aktivitas',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // "Batal" Action Button - Menghentikan dan menghapus state timer
                        TextButton(
                          onPressed: () {
                            ActivityAlarmService.instance.stopAlarm();
                            service.cancelSession();
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            'Batal',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: accentGreen,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  }
}

