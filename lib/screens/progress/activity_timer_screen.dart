import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/physical_activity_service.dart';

class ActivityTimerScreen extends StatefulWidget {
  final Map<String, dynamic> activity;
  final String? dateKey;

  const ActivityTimerScreen({super.key, required this.activity, this.dateKey});

  @override
  State<ActivityTimerScreen> createState() => _ActivityTimerScreenState();
}

class _ActivityTimerScreenState extends State<ActivityTimerScreen> {
  Timer? _timer;
  int? _selectedPreset;
  late int _secondsRemaining;
  bool _isRunning = false;
  int _elapsedSeconds = 0;
  int _targetDuration = 0;

  @override
  void initState() {
    super.initState();
    final isRest = widget.activity['isRest'] == true;
    if (isRest) {
      // Default initial time is 15 minutes for rest
      final defaultRestSeconds = 15 * 60;
      _selectedPreset = defaultRestSeconds;
      _secondsRemaining = defaultRestSeconds;
      _targetDuration = defaultRestSeconds;
    } else {
      // Default initial time is 00:00 as shown in design reference (Pages 1-5)
      _selectedPreset = null;
      _secondsRemaining = 0;
      _targetDuration = 0;
    }
    _elapsedSeconds = 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
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

    // In the design PDF, target header is specifically displayed on Jogging and Bodyweight screens
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
      // 15-30 menit (mid: 22.5) -> 250-450 kkal (mid: 350)
      return 350.0 / 22.5; // ~15.56 kkal/menit
    } else if (id.contains('bodyweight') || title.contains('bodyweight') || title.contains('kekuatan')) {
      // 20-45 menit (mid: 32.5) -> 150-350 kkal (mid: 250)
      return 250.0 / 32.5; // ~7.69 kkal/menit
    } else if (id.contains('yoga') || title.contains('yoga')) {
      // 20-40 menit (mid: 30.0) -> 100-200 kkal (mid: 150)
      return 150.0 / 30.0; // 5.00 kkal/menit
    } else if (id.contains('cycling') || title.contains('sepeda')) {
      // 30-60 menit (mid: 45.0) -> 200-400 kkal (mid: 300)
      return 300.0 / 45.0; // ~6.67 kkal/menit
    } else {
      // Jogging / default: 30-60 menit (mid: 45.0) -> 200-400 kkal (mid: 300)
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
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _selectedPreset = seconds;
      _secondsRemaining = seconds;
      _targetDuration = seconds;
      _elapsedSeconds = 0;
    });
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      if (_secondsRemaining <= 0) {
        final presets = _getPresets();
        final defaultDuration = _selectedPreset ?? presets.first;
        setState(() {
          _selectedPreset = defaultDuration;
          _secondsRemaining = defaultDuration;
          _targetDuration = defaultDuration;
        });
      } else if (_targetDuration <= 0 && _selectedPreset != null) {
        _targetDuration = _selectedPreset!;
      }
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 0) {
          setState(() {
            _secondsRemaining--;
            _elapsedSeconds++;
          });
        } else {
          _timer?.cancel();
          setState(() => _isRunning = false);
          _onTimerFinishedNaturally();
        }
      });
    }
  }

  void _onTimerFinishedNaturally() {
    final isRest = widget.activity['isRest'] == true;
    if (isRest) {
      _showRestCompletionDialog();
    } else {
      _showCompletionDialog();
    }
  }

  void _onFinishButtonPressed() {
    _timer?.cancel();
    setState(() => _isRunning = false);

    final isRest = widget.activity['isRest'] == true;
    if (isRest) {
      _showRestCompletionDialog();
      return;
    }

    // Aturan Poin 4: Durasi berjalan harus minimal 50% dari target durasi yang dipilih
    final target = _targetDuration > 0
        ? _targetDuration
        : (_selectedPreset ?? _getPresets().first);
    final halfTarget = target * 0.5;

    if (_elapsedSeconds < halfTarget) {
      // Skenario B: Durasi berjalan < 50% target -> Dialog Peringatan
      _showInsufficientDurationDialog();
    } else {
      // Skenario A: Durasi berjalan >= 50% target -> Popup Sukses
      _showCompletionDialog();
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
                        Navigator.pop(ctx); // Tutup dialog
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

  // Skenario A: Popup Latihan Selesai! 🎉 dengan Estimasi Kalori Proporsional & Opsi Lanjut Istirahat
  void _showCompletionDialog() {
    final title = widget.activity['title'] as String? ?? 'Aktivitas';
    final actId = widget.activity['id'] as String? ?? '';
    final dateKey = widget.dateKey ?? PhysicalActivityService.instance.todayKey;
    final burnedCalories = _calculateBurnedCalories(_elapsedSeconds);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emoji_events_rounded, color: Color(0xFF16A34A), size: 40),
            ),
            const SizedBox(height: 14),
            Text(
              'Latihan Selesai! 🎉',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hebat! Kamu telah menyelesaikan sesi $title hari ini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF475569)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department_rounded, color: Color(0xFFEA580C), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Estimasi terbakar: $burnedCalories kkal',
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // 1. Tombol Simpan & Selesai
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4E8F73),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                if (actId.isNotEmpty) {
                  PhysicalActivityService.instance.completeActivity(dateKey, actId);
                }
                Navigator.pop(ctx);
                Navigator.of(context).pop(true);
              },
              child: Text(
                'Simpan & Selesai',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13.5),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 2. Tombol Poin 5: Lanjut Istirahat
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF4E8F73), width: 1.5),
                foregroundColor: const Color(0xFF265C45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 11),
              ),
              onPressed: () {
                if (actId.isNotEmpty) {
                  PhysicalActivityService.instance.completeActivity(dateKey, actId);
                }
                Navigator.pop(ctx); // Tutup dialog
                Navigator.of(context).pop('rest'); // Kirim signal 'rest' ke ActivityDetailScreen
              },
              icon: const Icon(Icons.spa_rounded, size: 18, color: Color(0xFF36785A)),
              label: Text(
                'Lanjut Istirahat',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  color: const Color(0xFF265C45),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Popup Penyelesaian Sesi Istirahat
  void _showRestCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFEDF7F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.spa_rounded, color: Color(0xFF36785A), size: 40),
            ),
            const SizedBox(height: 14),
            Text(
              'Istirahat Selesai! 🌿',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          'Sesi istirahat Anda telah selesai. Tubuh Anda kini lebih segar, rileks, dan siap beraktivitas kembali.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF475569)),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF36785A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                Navigator.pop(ctx);
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
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isRest = widget.activity['isRest'] == true;
    final heroImg = widget.activity['heroImg'] as String? ??
        (isRest ? 'assets/progress/rest/hero_aktivitas.png' : 'assets/progress/clean/hero_jogging.png');
    final targetText = _getTargetText();
    final presets = _getPresets();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Hero Box with Background Image, Back Button, Activity Icon and Title
          Stack(
            children: [
              Container(
                height: 230,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFF3B6E57),
                ),
                child: Image.asset(
                  heroImg,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFF3B6E57),
                    child: Icon(
                      isRest ? Icons.spa_rounded : Icons.directions_run_rounded,
                      size: 72,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
              // Gradient for readability
              Container(
                height: 230,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.4),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.65),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // Top Back Button
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
                    onPressed: () {
                      _timer?.cancel();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
              // Activity Badge and Title over hero image
              Positioned(
                bottom: 24,
                left: 20,
                right: 20,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4E8F73).withValues(alpha: 0.85),
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
            ],
          ),

          // Main White Card Content with Rounded Top Border
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Target Header (displayed if present in design)
                    if (targetText != null) ...[
                      Text(
                        isRest ? 'Durasi Istirahat' : 'Target',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4E8F73),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        targetText,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ] else ...[
                      const SizedBox(height: 8),
                    ],

                    // Big Circular Timer - Clean green circle with ONLY ONE single large bold text inside
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFF4E8F73),
                          width: 9,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _formatTime(_secondsRemaining),
                        style: GoogleFonts.poppins(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A2E),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 26),

                    // Preset Duration Circle Buttons (e.g. 30:00, 45:00, 60:00 or 10:00, 15:00, 20:00)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: presets.map((duration) {
                        final isSelected = _selectedPreset == duration;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: GestureDetector(
                            onTap: () => _selectPreset(duration),
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF4E8F73) : const Color(0xFFD1D5DB),
                                  width: isSelected ? 2.5 : 2,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _formatTime(duration),
                                style: GoogleFonts.poppins(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A1A2E),
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
                          color: Colors.white,
                          border: Border.all(
                            color: const Color(0xFF4E8F73),
                            width: 3.5,
                          ),
                        ),
                        child: Icon(
                          _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          size: 38,
                          color: const Color(0xFF4E8F73),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // "Selesaikan Aktivitas" / "Selesaikan Istirahat" Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4E8F73),
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shadowColor: const Color(0xFF4E8F73).withValues(alpha: 0.35),
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

                    // "Batal" Action Button
                    TextButton(
                      onPressed: () {
                        _timer?.cancel();
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Batal',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4E8F73),
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
    );
  }
}
