import 'package:flutter/material.dart';
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
      // Default for Jogging, Bodyweight, Cycling, Jalan Cepat
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
    } else if (id.contains('jalan') || title.toLowerCase().contains('jalan')) {
      return 'Jalan Cepat';
    }
    return title;
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

  double _getCalorieRatePerMinute() {
    final id = (widget.activity['id'] as String? ?? '').toLowerCase();
    final title = (widget.activity['title'] as String? ?? '').toLowerCase();

    if (id.contains('hiit') || title.contains('hiit') || title.contains('interval')) {
      return 350.0 / 22.5;
    } else if (id.contains('bodyweight') || title.contains('bodyweight') || title.contains('kekuatan')) {
      return 250.0 / 32.5;
    } else if (id.contains('yoga') || title.contains('yoga')) {
      return 150.0 / 30.0;
    } else if (id.contains('cycling') || title.contains('sepeda')) {
      return 300.0 / 45.0;
    } else {
      return 300.0 / 45.0;
    }
  }

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

  void _showCustomDurationPicker() {
    final service = ActivityTimerService.instance;
    int tempMinutes = (service.targetDuration > 0 ? (service.targetDuration ~/ 60) : 30)
        .clamp(ActivityRestHelper.minActivityDurationMinutes, ActivityRestHelper.maxActivityDurationMinutes);

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
                    'Pilih durasi antara 15 hingga 60 menit',
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
                            initialItem: tempMinutes - ActivityRestHelper.minActivityDurationMinutes,
                          ),
                          itemExtent: 48,
                          perspective: 0.003,
                          diameterRatio: 1.3,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (idx) {
                            setModalState(() {
                              tempMinutes = ActivityRestHelper.minActivityDurationMinutes + idx;
                            });
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: (ActivityRestHelper.maxActivityDurationMinutes -
                                    ActivityRestHelper.minActivityDurationMinutes) +
                                1,
                            builder: (context, idx) {
                              final val = ActivityRestHelper.minActivityDurationMinutes + idx;
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
      _showCompletionDialog();
    } else {
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

  // Popup Latihan Selesai sesuai Storyboard Gambar 3 (Alarm & Card Selesai)
  // Menampilkan ikon lonceng, 00:00 eksplisit, tombol "Selesai", dan tombol "Lanjut Istirahat"
  void _showCompletionDialog() {
    _hasShownDialog = true;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final service = ActivityTimerService.instance;
    final title = (widget.activity['name'] as String?) ?? (widget.activity['title'] as String?) ?? 'Aktivitas';
    final durationMins = service.targetDuration ~/ 60;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
        titlePadding: EdgeInsets.zero,
        title: Stack(
          children: [
            Positioned(
              top: 12,
              right: 12,
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
              padding: const EdgeInsets.only(top: 26, left: 20, right: 20),
              child: Center(
                child: Column(
                  children: [
                    // Ikon lonceng hijau melingkar sesuai Storyboard Gambar 3
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: Color(0xFF16A34A),
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Aktivitas Fisik Selesai!',
                      textAlign: TextAlign.center,
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
              'Kamu telah menyelesaikan ${title.toLowerCase()} selama $durationMins menit.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 16),

            // Tampilan waktu eksplisit 00:00 (Besar & Jelas)
            Text(
              '00:00',
              style: GoogleFonts.poppins(
                fontSize: 44,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 22),

            // Tombol 1: "Selesai" (Filled Green)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF58AF86) : const Color(0xFF489874),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  ActivityAlarmService.instance.stopAlarm();
                  Navigator.pop(ctx);
                  service.cancelSession();
                  Navigator.of(context).pop(true);
                },
                child: Text(
                  'Selesai',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Tombol 2: "Lanjut Istirahat" (Outlined Green)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? const Color(0xFF58AF86) : const Color(0xFF489874),
                  side: BorderSide(
                    color: isDark ? const Color(0xFF58AF86) : const Color(0xFF489874),
                    width: 1.5,
                  ),
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
                        completedDurationMinutes: durationMins,
                      ),
                    ),
                  );
                },
                child: Text(
                  'Lanjut Istirahat',
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      ActivityAlarmService.instance.stopAlarm();
      if (mounted && Navigator.of(context).canPop()) {
        service.cancelSession();
        Navigator.of(context).pop(true);
      }
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
        final initialMinutes = (service.targetDuration > 0 ? (service.targetDuration ~/ 60) : 30);

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
                            onTap: service.isIdle && !isRest ? _showCustomDurationPicker : null,
                            child: SizedBox(
                              width: 230,
                              height: 230,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Background Circular Ring
                                  SizedBox(
                                    width: 220,
                                    height: 220,
                                    child: CircularProgressIndicator(
                                      value: isRunning || isPaused ? progress : 1.0,
                                      strokeWidth: 10,
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
                                          fontSize: 46,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -1,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      Text(
                                        'Sisa Waktu',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        ),
                                      ),
                                      if (service.isIdle && !isRest) ...[
                                        const SizedBox(height: 6),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.tune_rounded, size: 13, color: accentGreen),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Ketuk untuk ubah',
                                              style: GoogleFonts.poppins(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w600,
                                                color: accentGreen,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Info Row: Durasi Awal & Badge Status sesuai Storyboard Gambar 2
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Durasi Awal (hanya ditampilkan untuk aktivitas fisik, sesi istirahat sudah memiliki Durasi Istirahat)
                                if (!isRest)
                                  Flexible(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 18,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'Durasi awal',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                                ),
                                              ),
                                              Text(
                                                '$initialMinutes menit',
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  const SizedBox.shrink(),

                                // Status Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isRunning
                                        ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7))
                                        : (isPaused
                                            ? (isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7))
                                            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isRunning
                                              ? const Color(0xFF16A34A)
                                              : (isPaused ? const Color(0xFFD97706) : const Color(0xFF94A3B8)),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isRunning
                                            ? 'Sedang Berjalan'
                                            : (isPaused ? 'Dijeda' : 'Siap Dimulai'),
                                        style: GoogleFonts.poppins(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: isRunning
                                              ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF16A34A))
                                              : (isPaused
                                                  ? const Color(0xFFD97706)
                                                  : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B))),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Preset Chips jika Timer Idle
                          if (service.isIdle) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: presets.map((duration) {
                                final isSelected = selectedPreset == duration;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: GestureDetector(
                                    onTap: () => _selectPreset(duration),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      width: 68,
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
                            const SizedBox(height: 18),
                          ],

                          // Tombol Utama: "Jeda" / "Lanjutkan" / "Mulai" sesuai Storyboard Gambar 2
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
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: _toggleTimer,
                              child: Text(
                                isRunning
                                    ? 'Jeda'
                                    : (isPaused ? 'Lanjutkan' : 'Mulai'),
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Tombol "Selesaikan Aktivitas" / "Selesaikan Istirahat"
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: accentGreen,
                                side: BorderSide(color: accentGreen, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _onFinishButtonPressed,
                              child: Text(
                                isRest ? 'Selesaikan Istirahat' : 'Selesaikan Aktivitas',
                                style: GoogleFonts.poppins(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
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
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
