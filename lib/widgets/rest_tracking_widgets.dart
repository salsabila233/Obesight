import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/rest_reminder_service.dart';

/// Helper to format date in Indonesian format matching reference: e.g. "Sen, 28 Sep"
String formatIndonesianDate(DateTime date) {
  const dayNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
  const monthNames = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];
  final dayName = dayNames[date.weekday % 7];
  final monthName = monthNames[date.month];
  return '$dayName, ${date.day} $monthName';
}

/// Date Selector Pill: `<   Sen, 28 Sep   >`
class RestDateSelectorPill extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const RestDateSelectorPill({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE6EFEA),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onDateChanged(selectedDate.subtract(const Duration(days: 1))),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.chevron_left_rounded, size: 20, color: Color(0xFF475569)),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              formatIndonesianDate(selectedDate),
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(width: 14),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onDateChanged(selectedDate.add(const Duration(days: 1))),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF475569)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card 1: Sleep / Rest status card (matching Gambar 1 and Gambar 3)
class RestStatusCard extends StatelessWidget {
  final RestType type;
  final RestReminderData? reminder;
  final VoidCallback? onTap;

  const RestStatusCard({
    super.key,
    required this.type,
    this.reminder,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isNight = type == RestType.night;
    final isSaved = reminder != null && reminder!.isSet;

    final title = isNight ? 'Waktu tidur' : 'Waktu istirahat';
    final mainValue = isSaved ? reminder!.shortDurationDisplay : '-- j -- m';
    final subValue = isSaved
        ? reminder!.timeRangeFormatted
        : (isNight
            ? 'Rekam tidur Anda untuk melihat polanya dan mengelola tidur Anda.'
            : 'Atur istirahat siang Anda untuk melihat polanya dan menjaga energi Anda.');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE9F3ED)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E293B).withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Circular Badge
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isNight ? const Color(0xFFE2F1E8) : const Color(0xFFFEF3C7),
              ),
              child: Center(
                child: isNight
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                            Icons.nightlight_round,
                            size: 26,
                            color: Color(0xFF36785A),
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Text(
                              'z',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF36785A),
                              ),
                            ),
                          ),
                        ],
                      )
                    : const Icon(
                        Icons.wb_sunny_rounded,
                        size: 28,
                        color: Color(0xFFEAB308),
                      ),
              ),
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mainValue,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subValue,
                    style: GoogleFonts.poppins(
                      fontSize: isSaved ? 13 : 11,
                      fontWeight: isSaved ? FontWeight.w600 : FontWeight.w400,
                      color: isSaved ? const Color(0xFF36785A) : const Color(0xFF64748B),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card 2 (Empty Condition): 7 Days Overview before data is saved (GAMBAR 1)
class Rest7DayEmptyChartWidget extends StatelessWidget {
  final RestType type;
  final VoidCallback? onTap;

  const Rest7DayEmptyChartWidget({
    super.key,
    required this.type,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isNight = type == RestType.night;
    final title = isNight
        ? 'Waktu tidur selama 7 hari terakhir'
        : 'Waktu istirahat selama 7 hari terakhir';
    final emptyText = isNight ? 'Belum ada data tidur' : 'Belum ada data istirahat';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE9F3ED)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E293B).withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Dotted divider
            Container(
              height: 1,
              width: double.infinity,
              color: const Color(0xFFF1F5F9),
            ),
            const SizedBox(height: 24),

            // Center Cute Illustration & Empty Text
            Center(
              child: Column(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isNight ? const Color(0xFFF1F5F9) : const Color(0xFFFEF3C7).withValues(alpha: 0.6),
                    ),
                    child: Center(
                      child: isNight
                          ? Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(
                                  Icons.nightlight_round,
                                  size: 34,
                                  color: Color(0xFFCBD5E1),
                                ),
                                Positioned(
                                  top: 14,
                                  right: 14,
                                  child: Text(
                                    'z z',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : const Icon(
                              Icons.wb_sunny_rounded,
                              size: 36,
                              color: Color(0xFFFBBF24),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    emptyText,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Axis days ticks: 18  19  20  21  22  23  24 (24 in red as in Gambar 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDayTick('18', isHighlighted: false),
                _buildDayTick('19', isHighlighted: false),
                _buildDayTick('20', isHighlighted: false),
                _buildDayTick('21', isHighlighted: false),
                _buildDayTick('22', isHighlighted: false),
                _buildDayTick('23', isHighlighted: false),
                _buildDayTick('24', isHighlighted: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayTick(String text, {required bool isHighlighted}) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
        color: isHighlighted ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
      ),
    );
  }
}

/// Card 2 (Saved Condition): 7 Days Bar Chart after data is saved (GAMBAR 3)
class Rest7DayBarChartWidget extends StatelessWidget {
  final RestType type;
  final RestReminderData reminder;
  final VoidCallback? onTap;

  const Rest7DayBarChartWidget({
    super.key,
    required this.type,
    required this.reminder,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isNight = type == RestType.night;
    final title = isNight
        ? 'Waktu tidur selama 7 hari terakhir'
        : 'Waktu istirahat selama 7 hari terakhir';

    // 7 days data matching reference Gambar 3:
    // Days: 22, 23, 24, 25, 26, 27, 28
    // Night labels: 6j, 7j, 6j 30m, 8j, 7j 30m, 6j 45m, and user's saved duration (e.g. 7j)
    // Day labels: 20m, 30m, 25m, 30m, 20m, 30m, and user's saved duration (e.g. 30m or 1j)
    final List<String> labels;
    final List<double> heights; // 0.0 to 1.0 fraction
    final List<String> days = ['22', '23', '24', '25', '26', '27', '28'];

    if (isNight) {
      final todayH = reminder.durationHours;
      final todayM = reminder.durationRemainingMinutes;
      final todayLabel = todayM > 0 ? '${todayH}j ${todayM}m' : '${todayH}j';
      labels = ['6j', '7j', '6j 30m', '8j', '7j 30m', '6j 45m', todayLabel];
      final todayFraction = (reminder.durationMinutes / (8.5 * 60)).clamp(0.25, 1.0);
      heights = [0.65, 0.75, 0.70, 0.90, 0.82, 0.73, todayFraction];
    } else {
      final todayH = reminder.durationHours;
      final todayM = reminder.durationRemainingMinutes;
      final todayLabel = todayH > 0
          ? (todayM > 0 ? '${todayH}j ${todayM}m' : '${todayH}j')
          : '${todayM}m';
      labels = ['20m', '30m', '25m', '30m', '20m', '30m', todayLabel];
      final todayFraction = (reminder.durationMinutes / 60.0).clamp(0.3, 1.0);
      heights = [0.55, 0.85, 0.70, 0.85, 0.55, 0.85, todayFraction];
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE9F3ED)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E293B).withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Bar Chart Container
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  final isLast = i == 6; // Today
                  final barColor = isLast ? const Color(0xFF265C45) : const Color(0xFFA5D6C1);
                  final barHeight = (heights[i] * 78).clamp(18.0, 78.0);

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Label above bar
                      Text(
                        labels[i],
                        style: GoogleFonts.poppins(
                          fontSize: 9.5,
                          fontWeight: isLast ? FontWeight.w700 : FontWeight.w500,
                          color: isLast ? const Color(0xFF265C45) : const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 5),

                      // Vertical Rounded Bar
                      Container(
                        width: 16,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Day label below
                      Text(
                        days[i],
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: isLast ? FontWeight.w700 : FontWeight.w500,
                          color: isLast ? const Color(0xFF265C45) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular 24-Hour Dial Widget (GAMBAR 2)
class CircularSleepDial extends StatelessWidget {
  final RestType type;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  const CircularSleepDial({
    super.key,
    required this.type,
    required this.startTime,
    required this.endTime,
  });

  @override
  Widget build(BuildContext context) {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    final startFormatted =
        '${startTime.hour.toString().padLeft(2, '0')}.${startTime.minute.toString().padLeft(2, '0')}';
    final endFormatted =
        '${endTime.hour.toString().padLeft(2, '0')}.${endTime.minute.toString().padLeft(2, '0')}';

    final isNight = type == RestType.night;

    return Center(
      child: SizedBox(
        width: 220,
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Custom Painter for 24h dial
            CustomPaint(
              size: const Size(220, 220),
              painter: _DialPainter(
                startMinutes: startMinutes,
                endMinutes: endMinutes,
                isNight: isNight,
              ),
            ),

            // Center Content: Start & End Time
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isNight ? Icons.bed_rounded : Icons.wb_sunny_rounded,
                      size: 20,
                      color: isNight ? const Color(0xFF36785A) : const Color(0xFFEAB308),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      startFormatted,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isNight ? Icons.nightlight_round : Icons.alarm_on_rounded,
                      size: 19,
                      color: const Color(0xFF36785A),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      endFormatted,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  final int startMinutes;
  final int endMinutes;
  final bool isNight;

  _DialPainter({
    required this.startMinutes,
    required this.endMinutes,
    required this.isNight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 44) / 2;

    // 1. Background Circle Track
    final trackPaint = Paint()
      ..color = const Color(0xFFE2F1E8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;
    canvas.drawCircle(center, radius, trackPaint);

    // 2. Cardinal Numbers: 0 at top, 6 at right, 12 at bottom, 18 at left
    _drawLabel(canvas, '0', center + Offset(0, -radius - 12));
    _drawLabel(canvas, '6', center + Offset(radius + 12, 0));
    _drawLabel(canvas, '12', center + Offset(0, radius + 12));
    _drawLabel(canvas, '18', center + Offset(-radius - 12, 0));

    // 3. Active Arc (Start to End in 24h = 2*pi)
    // 0 minutes = top (-pi/2)
    final startAngle = -pi / 2 + (startMinutes / (24.0 * 60.0)) * 2 * pi;
    var sweepAngle = ((endMinutes - startMinutes) / (24.0 * 60.0)) * 2 * pi;
    if (sweepAngle <= 0) {
      sweepAngle += 2 * pi;
    }

    final arcPaint = Paint()
      ..color = const Color(0xFF36785A)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 14;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );

    // 4. Endpoint handle badges
    final startPoint = Offset(
      center.dx + radius * cos(startAngle),
      center.dy + radius * sin(startAngle),
    );
    final endPoint = Offset(
      center.dx + radius * cos(startAngle + sweepAngle),
      center.dy + radius * sin(startAngle + sweepAngle),
    );

    final handleBgPaint = Paint()
      ..color = const Color(0xFF235B42)
      ..style = PaintingStyle.fill;

    final handleBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Start Handle Circle
    canvas.drawCircle(startPoint, 10, handleBgPaint);
    canvas.drawCircle(startPoint, 10, handleBorderPaint);

    // End Handle Circle
    canvas.drawCircle(endPoint, 10, handleBgPaint);
    canvas.drawCircle(endPoint, 10, handleBorderPaint);
  }

  void _drawLabel(Canvas canvas, String text, Offset offset) {
    final textSpan = TextSpan(
      text: text,
      style: GoogleFonts.poppins(
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF475569),
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(offset.dx - textPainter.width / 2, offset.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) {
    return oldDelegate.startMinutes != startMinutes ||
        oldDelegate.endMinutes != endMinutes ||
        oldDelegate.isNight != isNight;
  }
}
