import 'package:flutter/material.dart';
import '../../widgets/app_alert.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/activity_timer_service.dart';
import '../../services/activity_alarm_service.dart';
import '../../services/physical_activity_service.dart';
import '../../services/activity_rest_helper.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ActivityTimerService.instance.setTimerScreenActive(true);
    });

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

    // Jika belum ada sesi berjalan untuk aktivitas ini, inisialisasi sesi baru
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

    // Jika timer sudah selesai saat halaman dibuka
    if (service.isCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onTimerFinishedNaturally();
      });
    }
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
    ActivityTimerService.instance.setTimerScreenActive(false);
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

    final options = ActivityRestHelper.getActivityDurationOptions(widget.activity);
    if (options.isNotEmpty) {
      return options.map((m) => m * 60).toList();
    }

    final id = (widget.activity['id'] as String? ?? '').toLowerCase();
    final title = (widget.activity['title'] as String? ?? '').toLowerCase();

    if (id.contains('yoga') || title.contains('yoga')) {
      return [15 * 60, 30 * 60, 40 * 60];
    } else if (id.contains('hiit') || title.contains('hiit') || title.contains('interval')) {
      return [20 * 60, 25 * 60, 30 * 60];
    } else {
      // Default for Jogging, Bodyweight, Cycling, Jalan Cepat
      return [30 * 60, 45 * 60, 60 * 60];
    }
  }

  bool _isTargetHeaderSport() {
    final id = (widget.activity['id'] as String? ?? '').toLowerCase();
    final name = (widget.activity['name'] as String? ?? '').toLowerCase();
    final title = (widget.activity['title'] as String? ?? '').toLowerCase();
    final combined = '$id $name $title';

    final isStrength = id == 'underweight_strength' ||
        combined.contains('latihan beban & kekuatan') ||
        combined.contains('beban & kekuatan') ||
        combined.contains('strength training') ||
        (combined.contains('latihan beban') && (combined.contains('kekuatan') || combined.contains('strength')));

    final isCalisthenics = id == 'underweight_calisthenics' ||
        combined.contains('kalistenik');

    final isRecovery = id == 'underweight_recovery' ||
        combined.contains('peregangan pemulihan') ||
        combined.contains('pemulihan & mobilitas') ||
        (combined.contains('peregangan') && combined.contains('mobilitas'));

    return isStrength || isCalisthenics || isRecovery;
  }

  String _getDisplayTitle() {
    final isRest = widget.activity['isRest'] == true;
    if (isRest) {
      return 'Istirahat Setelah\nAktivitas';
    }

    final id = (widget.activity['id'] as String? ?? '').toLowerCase();
    final name = (widget.activity['name'] as String? ?? '').toLowerCase();
    final title = (widget.activity['title'] as String? ?? '').toLowerCase();
    final combined = '$id $name $title';

    if (id == 'underweight_strength' ||
        combined.contains('latihan beban & kekuatan') ||
        combined.contains('beban & kekuatan') ||
        combined.contains('strength training') ||
        (combined.contains('latihan beban') && (combined.contains('kekuatan') || combined.contains('strength')))) {
      return 'Latihan Beban &\nKekuatan';
    } else if (id == 'underweight_calisthenics' || combined.contains('kalistenik')) {
      return 'Kalistenik Kompon\n(Bodyweight)';
    } else if (id == 'underweight_recovery' ||
        combined.contains('peregangan pemulihan') ||
        combined.contains('pemulihan & mobilitas') ||
        (combined.contains('peregangan') && combined.contains('mobilitas'))) {
      return 'Peregangan Pemulihan\n& Mobilitas';
    }

    if (id.contains('bodyweight') || title.contains('bodyweight')) {
      return 'Latihan\nBodyweight';
    } else if (id.contains('hiit') || title.contains('hiit')) {
      return 'High-Intensity Interval\nTraining';
    } else if (id.contains('cycling') || title.contains('sepeda')) {
      return 'Bersepeda';
    } else if (id.contains('jogging') || title.contains('jogging')) {
      return 'Jogging';
    } else if (id.contains('yoga') || title.contains('yoga')) {
      return 'Yoga';
    } else if (id.contains('jalan') || title.contains('jalan')) {
      return 'Jalan Cepat';
    }
    return widget.activity['title'] as String? ?? 'Aktivitas';
  }

  String _getActivityCardTitle() {
    final isRest = widget.activity['isRest'] == true;
    if (isRest) return 'Sesi Istirahat';
    return (widget.activity['name'] as String?) ??
        (widget.activity['title'] as String?) ??
        'Aktivitas Fisik';
  }

  String _getActivityCardDesc() {
    final isRest = widget.activity['isRest'] == true;
    if (isRest) {
      return 'Tarik napas perlahan dan minum air putih.';
    }
    final desc = widget.activity['desc'] as String?;
    if (desc != null && desc.isNotEmpty) return desc;
    return 'Meningkatkan daya tahan tubuh dan kesehatan jantung.';
  }

  IconData _getActivityIcon() {
    return ActivityRestHelper.getActivityIcon(widget.activity);
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

  void _selectPreset(int seconds) {
    _hasShownDialog = false;
    ActivityAlarmService.instance.stopAlarm();
    ActivityTimerService.instance.setPreset(seconds);
  }

  void _showCustomDurationPicker() {
    final service = ActivityTimerService.instance;
    final minMin = ActivityRestHelper.getMinActivityDuration(widget.activity);
    final maxMin = ActivityRestHelper.getMaxActivityDuration(widget.activity);
    int tempMinutes = (service.targetDuration > 0 ? (service.targetDuration ~/ 60) : minMin)
        .clamp(minMin, maxMin);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Atur Durasi Aktivitas',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pilih durasi antara $minMin hingga $maxMin menit',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 90,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF064E3B) : const Color(0xFFEDF7F2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF489874), width: 1.5),
                          ),
                        ),
                        ListWheelScrollView.useDelegate(
                          controller: FixedExtentScrollController(
                            initialItem: tempMinutes - minMin,
                          ),
                          itemExtent: 48,
                          perspective: 0.003,
                          diameterRatio: 1.3,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (idx) {
                            setModalState(() {
                              tempMinutes = minMin + idx;
                            });
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: (maxMin - minMin) + 1,
                            builder: (context, idx) {
                              final val = minMin + idx;
                              final isCur = val == tempMinutes;
                              return Center(
                                child: Text(
                                  '$val menit',
                                  style: GoogleFonts.poppins(
                                    fontSize: isCur ? 19 : 15,
                                    fontWeight: isCur ? FontWeight.w700 : FontWeight.w500,
                                    color: isCur
                                        ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF489874))
                                        : (isDark ? Colors.white54 : const Color(0xFF94A3B8)),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF489874),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _selectPreset(tempMinutes * 60);
                      },
                      child: Text(
                        'Simpan Durasi',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _toggleTimer() {
    final service = ActivityTimerService.instance;
    final targetDateKey = widget.dateKey ?? service.dateKey;
    final isRest = widget.activity['isRest'] == true;

    if (!isRest && PhysicalActivityService.isFutureDateKey(targetDateKey)) {
      AppAlert.showWarning(
        context,
        'Latihan tidak dapat dimulai untuk tanggal mendatang. Progres hanya dapat dicatat untuk hari ini.',
      );
      return;
    }

    if (service.isCompleted) {
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
      AppAlert.showWarning(
        context,
        'Progres latihan hanya dapat dicatat untuk tanggal hari ini.',
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
      AppAlert.showWarning(
        context,
        'Progres latihan hanya dapat dicatat untuk tanggal hari ini.',
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
      _showCompletionDialog();
    } else {
      AppAlert.showError(
        context,
        'Gagal menyimpan progres aktivitas ke Firestore. Silakan periksa koneksi Anda.',
      );
    }
  }

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
              Text(
                'Durasi Belum Mencukupi',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
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
                      onPressed: () => Navigator.pop(ctx),
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
                        Navigator.pop(ctx);
                        ActivityTimerService.instance.cancelSession();
                        Navigator.of(context).pop(false);
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

  // Popup Latihan Selesai sesuai gambar referensi Image 5 (Waktu Aktivitas Habis)
  void _showCompletionDialog() {
    _hasShownDialog = true;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final service = ActivityTimerService.instance;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Clock Icon matching Image 5
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
              // Tombol 1: "Lanjutkan istirahat" (filled green)
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF529B7A),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    ActivityAlarmService.instance.stopAlarm();
                    Navigator.pop(ctx);
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
              // Tombol 2: "Batal dan Selesai" (green text button)
              TextButton(
                onPressed: () {
                  ActivityAlarmService.instance.stopAlarm();
                  Navigator.pop(ctx);
                  service.cancelSession();
                  Navigator.of(context).pop(true);
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

  // Popup Penyelesaian Sesi Istirahat
  void _showRestCompletionDialog() {
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sesi istirahat Anda telah selesai. Tubuh Anda kini lebih segar, rileks, dan siap beraktivitas kembali.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '00:00',
              style: GoogleFonts.poppins(
                fontSize: 38,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
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
        (isRest ? 'assets/progress/rest/hero_aktivitas_clean.png' : 'assets/progress/clean/hero_jogging.png');
    final targetText = _getTargetText();
    final presets = _getPresets();

    return ListenableBuilder(
      listenable: ActivityTimerService.instance,
      builder: (context, _) {
        final service = ActivityTimerService.instance;
        final secondsRemaining = service.secondsRemaining;
        final isRunning = service.isRunning;
        final isPaused = service.isPaused;
        final selectedPreset = service.selectedPreset;

        // Progress countdown (0.0 sampai 1.0)
        final double progress;
        if (service.targetDuration > 0) {
          progress = (secondsRemaining / service.targetDuration).clamp(0.0, 1.0);
        } else {
          progress = 0.0;
        }

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
                // Sticky SliverAppBar
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
                        // Badge dan Title Aktivitas di atas Hero Banner
                        Positioned(
                          bottom: 26,
                          left: 20,
                          right: 20,
                          child: AnimatedOpacity(
                            opacity: _isSticky ? 0.0 : 1.0,
                            duration: const Duration(milliseconds: 150),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: accentGreen.withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(_getActivityIcon(), color: Colors.white, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _isTargetHeaderSport()
                                      ? FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            _getDisplayTitle(),
                                            style: GoogleFonts.poppins(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                              height: 1.15,
                                            ),
                                          ),
                                        )
                                      : Text(
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

                // Sheet Konten Utama Melengkung (Radius 28)
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    transform: Matrix4.translationValues(0, -20, 0),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 36),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Card Aktivitas Fisik sesuai Storyboard Gambar 2
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAF9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2EFE7),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: accentGreen,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(_getActivityIcon(), color: Colors.white, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _getActivityCardTitle(),
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _getActivityCardDesc(),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          fontSize: 11.5,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Target info (jika ada dan timer idle)
                          if (targetText != null) ...[
                            Text(
                              isRest ? 'Durasi Istirahat' : 'Target',
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: accentGreen,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              targetText,
                              style: GoogleFonts.poppins(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Big Circular Progress Timer (Countdown Ring)
                          GestureDetector(
                            onTap: service.isIdle && !isRest ? _showCustomDurationPicker : _toggleTimer,
                            child: SizedBox(
                              width: 250,
                              height: 250,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Background Circular Ring
                                  SizedBox(
                                    width: 235,
                                    height: 235,
                                    child: CircularProgressIndicator(
                                      value: isRunning || isPaused ? progress : 1.0,
                                      strokeWidth: 11,
                                      strokeCap: StrokeCap.round,
                                      backgroundColor: isDark
                                          ? const Color(0xFF1E293B)
                                          : const Color(0xFFE2EFE7),
                                      valueColor: AlwaysStoppedAnimation<Color>(accentGreen),
                                    ),
                                  ),

                                  // Inner Time Display
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _formatTime(secondsRemaining),
                                        style: GoogleFonts.poppins(
                                          fontSize: 50,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -1,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Preset Chips jika Timer Idle
                          if (service.isIdle) ...[
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: presets.map((duration) {
                                  final isSelected = selectedPreset == duration;
                                  final chipWidth = presets.length > 3 ? 64.0 : 68.0;
                                  final chipPadding = presets.length > 3 ? 4.0 : 6.0;

                                  return Padding(
                                    padding: EdgeInsets.symmetric(horizontal: chipPadding),
                                    child: GestureDetector(
                                      onTap: () => _selectPreset(duration),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 150),
                                        width: chipWidth,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          color: isSelected
                                              ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFEDF7F2))
                                              : (isDark ? const Color(0xFF1E293B) : Colors.white),
                                          border: Border.all(
                                            color: isSelected
                                                ? accentGreen
                                                : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                            width: isSelected ? 2 : 1,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          _formatTime(duration),
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
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
                            ),
                            const SizedBox(height: 18),
                          ],

                          // Tombol "Selesaikan Aktivitas" / "Selesaikan Istirahat" (Filled Green matching Image 2)
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentGreen,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _onFinishButtonPressed,
                              child: Text(
                                isRest ? 'Selesaikan Istirahat' : 'Selesaikan Aktivitas',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Tombol "Batal"
                          TextButton(
                            onPressed: () {
                              ActivityAlarmService.instance.stopAlarm();
                              service.cancelSession();
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              'Batal',
                              style: GoogleFonts.poppins(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: accentGreen,
                              ),
                            ),
                          ),
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
