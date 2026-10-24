import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/activity_timer_service.dart';
import '../../services/activity_rest_helper.dart';
import 'activity_timer_screen.dart';

/// Halaman pemilihan durasi aktivitas jogging / fisik dengan scrollable wheel picker
/// dan preset tombol sirkular (30:00, 45:00, 60:00) sesuai gambar referensi.
class ActivityDurationPickerScreen extends StatefulWidget {
  final Map<String, dynamic> activity;
  final String? dateKey;

  const ActivityDurationPickerScreen({
    super.key,
    required this.activity,
    this.dateKey,
  });

  @override
  State<ActivityDurationPickerScreen> createState() => _ActivityDurationPickerScreenState();
}

class _ActivityDurationPickerScreenState extends State<ActivityDurationPickerScreen> {
  late int _minMinutes;
  late int _maxMinutes;
  late int _selectedMinutes;
  late int _selectedSeconds;

  late FixedExtentScrollController _minutesController;
  late FixedExtentScrollController _secondsController;

  @override
  void initState() {
    super.initState();

    _minMinutes = ActivityRestHelper.getMinActivityDuration(widget.activity);
    _maxMinutes = ActivityRestHelper.getMaxActivityDuration(widget.activity);
    if (_maxMinutes < _minMinutes) {
      _maxMinutes = _minMinutes;
    }

    // Default duration (disesuaikan dengan rekomendasi atau 45 menit jika berada dalam rentang)
    final recommended = ActivityRestHelper.getRecommendedActivityDuration(widget.activity);
    if (45 >= _minMinutes && 45 <= _maxMinutes) {
      _selectedMinutes = 45;
    } else {
      _selectedMinutes = recommended.clamp(_minMinutes, _maxMinutes);
    }
    _selectedSeconds = 0;

    final initialMinuteIndex = _selectedMinutes - _minMinutes;
    _minutesController = FixedExtentScrollController(initialItem: initialMinuteIndex);
    _secondsController = FixedExtentScrollController(initialItem: _selectedSeconds);
  }

  @override
  void dispose() {
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  List<int> _getPresetMinutes() {
    final candidates = [30, 45, 60];
    final valid = candidates.where((m) => m >= _minMinutes && m <= _maxMinutes).toList();
    if (valid.isEmpty) {
      return [_minMinutes];
    }
    return valid;
  }

  void _onPresetTapped(int minutes) {
    setState(() {
      _selectedMinutes = minutes.clamp(_minMinutes, _maxMinutes);
      _selectedSeconds = 0;
    });

    final targetMinuteIndex = _selectedMinutes - _minMinutes;
    if (_minutesController.hasClients) {
      _minutesController.animateToItem(
        targetMinuteIndex,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
    if (_secondsController.hasClients) {
      _secondsController.animateToItem(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onStartPressed() async {
    final validatedMinutes = _selectedMinutes.clamp(_minMinutes, _maxMinutes);
    final totalSeconds = (validatedMinutes * 60) + _selectedSeconds;
    final minSeconds = _minMinutes * 60;
    final finalSeconds = totalSeconds < minSeconds ? minSeconds : totalSeconds;

    final service = ActivityTimerService.instance;
    service.setupSession(
      activity: widget.activity,
      presetSeconds: finalSeconds,
      dateKey: widget.dateKey,
    );
    await service.startOrResume();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ActivityTimerScreen(
          activity: widget.activity,
          dateKey: widget.dateKey,
        ),
      ),
    );
  }

  String _getTargetText() {
    final target = widget.activity['targetText'] as String?;
    if (target != null && target.isNotEmpty) return target;
    final specDur = widget.activity['specs']?['duration'] as String?;
    if (specDur != null && specDur.isNotEmpty) return specDur;
    return '$_minMinutes-$_maxMinutes menit';
  }

  String _getActivityTitle() {
    final name = widget.activity['name'] as String?;
    if (name != null && name.isNotEmpty) return name;
    final title = widget.activity['title'] as String?;
    if (title != null && title.isNotEmpty) return title;
    return 'Jogging';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accentGreen = Color(0xFF489874);
    final cardBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final heroImg = widget.activity['heroImg'] as String? ?? 'assets/progress/clean/hero_jogging.png';
    final iconImg = widget.activity['icon'] as String? ?? 'assets/progress/clean/rec_icon_jogging.png';

    final presetMinutes = _getPresetMinutes();
    final targetText = _getTargetText();
    final activityTitle = _getActivityTitle();

    return Scaffold(
      backgroundColor: cardBg,
      body: Stack(
        children: [
          // 1. Hero Image Background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 250,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  heroImg,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: accentGreen,
                    child: const Icon(Icons.directions_run_rounded, size: 72, color: Colors.white),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.70),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // Back Button
                SafeArea(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 14, top: 6),
                      child: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.38),
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
                    ),
                  ),
                ),
                // Activity Icon & Title in Hero
                Positioned(
                  bottom: 34,
                  left: 20,
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: accentGreen.withValues(alpha: 0.88),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                        ),
                        child: Image.asset(
                          iconImg,
                          color: Colors.white,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.directions_run_rounded,
                            size: 22,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        activityTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. White Curved Sheet for Duration Selection
          Positioned.fill(
            top: 220,
            child: Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                child: Column(
                  children: [
                    // Target Label & Value
                    Text(
                      'Target',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: accentGreen,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      targetText,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Column Headers: "Jam" and "Menit"
                    Row(
                      children: [
                        Expanded(
                          child: Center(
                            child: Text(
                              'Jam',
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 28),
                        Expanded(
                          child: Center(
                            child: Text(
                              'Menit',
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // 2-Column Wheel Picker (Menit : Detik)
                    SizedBox(
                      height: 180,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Left Wheel: Minutes
                          Expanded(
                            child: ListWheelScrollView.useDelegate(
                              controller: _minutesController,
                              itemExtent: 54,
                              perspective: 0.003,
                              diameterRatio: 1.3,
                              physics: const FixedExtentScrollPhysics(),
                              onSelectedItemChanged: (index) {
                                setState(() {
                                  _selectedMinutes = _minMinutes + index;
                                });
                              },
                              childDelegate: ListWheelChildBuilderDelegate(
                                childCount: (_maxMinutes - _minMinutes) + 1,
                                builder: (context, index) {
                                  final minute = _minMinutes + index;
                                  final isSelected = minute == _selectedMinutes;
                                  final formatted = minute.toString().padLeft(2, '0');

                                  return Center(
                                    child: Text(
                                      formatted,
                                      style: GoogleFonts.poppins(
                                        fontSize: isSelected ? 42 : 32,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                        color: isSelected
                                            ? textPrimary
                                            : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          // Separator colon ":"
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              ':',
                              style: GoogleFonts.poppins(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                              ),
                            ),
                          ),

                          // Right Wheel: Seconds (00 - 59)
                          Expanded(
                            child: ListWheelScrollView.useDelegate(
                              controller: _secondsController,
                              itemExtent: 54,
                              perspective: 0.003,
                              diameterRatio: 1.3,
                              physics: const FixedExtentScrollPhysics(),
                              onSelectedItemChanged: (index) {
                                setState(() {
                                  _selectedSeconds = index % 60;
                                });
                              },
                              childDelegate: ListWheelChildBuilderDelegate(
                                childCount: 60,
                                builder: (context, index) {
                                  final second = index;
                                  final isSelected = second == _selectedSeconds;
                                  final formatted = second.toString().padLeft(2, '0');

                                  return Center(
                                    child: Text(
                                      formatted,
                                      style: GoogleFonts.poppins(
                                        fontSize: isSelected ? 42 : 32,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                        color: isSelected
                                            ? textPrimary
                                            : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Preset Circular Buttons: 30:00, 45:00, 60:00
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: presetMinutes.map((minutes) {
                        final isSelected =
                            _selectedMinutes == minutes && _selectedSeconds == 0;
                        final formattedPreset = '${minutes.toString().padLeft(2, '0')}:00';

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: GestureDetector(
                            onTap: () => _onPresetTapped(minutes),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 66,
                              height: 66,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                border: Border.all(
                                  color: isSelected
                                      ? accentGreen
                                      : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                  width: isSelected ? 2.6 : 1.6,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: accentGreen.withValues(alpha: 0.25),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                formattedPreset,
                                style: GoogleFonts.poppins(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF0F172A))
                                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 32),

                    // Tombol "Mulai"
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
                        onPressed: _onStartPressed,
                        child: Text(
                          'Mulai',
                          style: GoogleFonts.poppins(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
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
    );
  }
}
