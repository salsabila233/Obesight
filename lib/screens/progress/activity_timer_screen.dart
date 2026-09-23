import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActivityTimerScreen extends StatefulWidget {
  final Map<String, dynamic> activity;

  const ActivityTimerScreen({super.key, required this.activity});

  @override
  State<ActivityTimerScreen> createState() => _ActivityTimerScreenState();
}

class _ActivityTimerScreenState extends State<ActivityTimerScreen> {
  Timer? _timer;
  int? _selectedPreset;
  late int _secondsRemaining;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    // Default initial time is 00:00 as shown in design reference (Pages 1-5)
    _selectedPreset = null;
    _secondsRemaining = 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<int> _getPresets() {
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

  void _selectPreset(int seconds) {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _selectedPreset = seconds;
      _secondsRemaining = seconds;
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
        });
      }
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 0) {
          setState(() => _secondsRemaining--);
        } else {
          _timer?.cancel();
          setState(() => _isRunning = false);
          _showCompletionDialog();
        }
      });
    }
  }

  void _showCompletionDialog() {
    final title = widget.activity['title'] as String? ?? 'Aktivitas';
    final calories = (widget.activity['specs'] as Map<String, dynamic>?)?['calories'] ?? '250 kkal';

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
                    'Estimasi terbakar: $calories',
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4E8F73),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).pop();
              },
              child: Text('Simpan & Selesai', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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
    final heroImg = widget.activity['heroImg'] as String? ?? 'assets/progress/clean/hero_jogging.png';
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
                    child: const Icon(Icons.directions_run_rounded, size: 72, color: Colors.white70),
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
                        'Target',
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

                    // Preset Duration Circle Buttons (e.g. 30:00, 45:00, 60:00)
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

                    // "Selesaikan Aktivitas" Action Button
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
                        onPressed: _showCompletionDialog,
                        child: Text(
                          'Selesaikan Aktivitas',
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
