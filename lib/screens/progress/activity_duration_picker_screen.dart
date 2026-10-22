import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/activity_timer_service.dart';
import '../../services/activity_rest_helper.dart';
import 'activity_timer_screen.dart';

/// Halaman pemilihan durasi aktivitas fisik berbentuk wheel picker angka (15-60 menit)
/// sesuai dengan Storyboard Gambar 5 (Mulai Timer / Pemilihan Waktu Timer).
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
  static const int _minDuration = ActivityRestHelper.minActivityDurationMinutes; // 15
  static const int _maxDuration = ActivityRestHelper.maxActivityDurationMinutes; // 60

  late int _selectedMinutes;
  late FixedExtentScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    final recommended = ActivityRestHelper.getRecommendedActivityDuration(widget.activity);
    _selectedMinutes = recommended.clamp(_minDuration, _maxDuration);
    final initialIndex = _selectedMinutes - _minDuration;
    _scrollController = FixedExtentScrollController(initialItem: initialIndex);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onStartPressed() {
    final validatedMinutes = _selectedMinutes.clamp(_minDuration, _maxDuration);
    final service = ActivityTimerService.instance;

    service.setupSession(
      activity: widget.activity,
      presetSeconds: validatedMinutes * 60,
      dateKey: widget.dateKey,
    );
    service.startOrResume();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ActivityTimerScreen(
          activity: widget.activity,
          dateKey: widget.dateKey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF132E23); // Dark forest green background sesuai Storyboard 5
    const accentGreen = Color(0xFF489874);
    const cardBg = Color(0xFF1B3D2F);
    final activityTitle = widget.activity['name'] as String? ??
        widget.activity['title'] as String? ??
        'Aktivitas Fisik';
    final activityIcon = ActivityRestHelper.getActivityIcon(widget.activity);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Tombol Back
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
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
                ],
              ),
            ),

            // Header Title & Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    'Mulai Timer',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Atur durasi aktivitas fisik sesuai kebutuhanmu.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Wheel / Drum Roll Number Picker (15 - 60)
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Center Highlight Pill Card (seperti pill putih di Storyboard)
                  Container(
                    width: 96,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),

                  // Drum Roll Wheel List
                  ListWheelScrollView.useDelegate(
                    controller: _scrollController,
                    itemExtent: 56,
                    perspective: 0.003,
                    diameterRatio: 1.4,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _selectedMinutes = _minDuration + index;
                      });
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: (_maxDuration - _minDuration) + 1,
                      builder: (context, index) {
                        final minute = _minDuration + index;
                        final isSelected = minute == _selectedMinutes;
                        final formattedNumber = minute.toString().padLeft(2, '0');

                        return Center(
                          child: Text(
                            formattedNumber,
                            style: GoogleFonts.poppins(
                              fontSize: isSelected ? 30 : 22,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                              color: isSelected
                                  ? bgColor // Dark green text inside white pill
                                  : Colors.white.withValues(alpha: 0.40),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Helper Info: Durasi minimal 15 menit dan maksimal 60 menit.
            Text(
              'Durasi minimal 15 menit dan maksimal 60 menit.',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: Colors.white.withValues(alpha: 0.68),
                fontWeight: FontWeight.w400,
              ),
            ),

            const SizedBox(height: 24),

            // Card Info Aktivitas Fisik Terpilih
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accentGreen.withValues(alpha: 0.28),
                        shape: BoxShape.circle,
                        border: Border.all(color: accentGreen.withValues(alpha: 0.4)),
                      ),
                      child: Icon(
                        activityIcon,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Aktivitas Fisik',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.65),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activityTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Tombol "Mulai"
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentGreen,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: accentGreen.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _onStartPressed,
                  child: Text(
                    'Mulai',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
