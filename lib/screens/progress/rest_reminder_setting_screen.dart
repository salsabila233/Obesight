import 'package:flutter/material.dart';
import '../../widgets/app_alert.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/sleep_record_model.dart';
import '../../services/sleep_tracking_service.dart';
import '../../services/rest_reminder_service.dart';
import '../../widgets/rest_tracking_widgets.dart';

import '../../widgets/curved_header_scaffold.dart';

class RestReminderSettingScreen extends StatefulWidget {
  final RestType type;

  const RestReminderSettingScreen({
    super.key,
    required this.type,
  });

  @override
  State<RestReminderSettingScreen> createState() => _RestReminderSettingScreenState();
}

class _RestReminderSettingScreenState extends State<RestReminderSettingScreen> {
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();

    final existing = RestReminderService.instance.getReminder(widget.type);
    if (existing != null) {
      _startTime = existing.startTime;
      _endTime = existing.endTime;
    } else {
      if (widget.type == RestType.night) {
        // Default matching GAMBAR 2: 22.00 to 05.00
        _startTime = const TimeOfDay(hour: 22, minute: 0);
        _endTime = const TimeOfDay(hour: 5, minute: 0);
      } else {
        // Default for day rest: 13.00 to 14.00
        _startTime = const TimeOfDay(hour: 13, minute: 0);
        _endTime = const TimeOfDay(hour: 14, minute: 0);
      }
    }
  }

  int get _durationMinutes {
    final startM = _startTime.hour * 60 + _startTime.minute;
    final endM = _endTime.hour * 60 + _endTime.minute;
    var diff = endM - startM;
    if (diff <= 0) {
      diff += 24 * 60;
    }
    return diff;
  }

  String get _durationFormatted {
    final hours = _durationMinutes ~/ 60;
    final mins = _durationMinutes % 60;
    if (hours > 0 && mins > 0) {
      return '$hours jam $mins menit';
    } else if (hours > 0) {
      return '$hours jam';
    } else {
      return '$mins menit';
    }
  }

  String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h.$m';
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _startTime : _endTime;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: isDark
              ? ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: Color(0xFF489874),
                    onPrimary: Colors.white,
                    surface: Color(0xFF1E293B),
                    onSurface: Colors.white,
                  ),
                  dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF1E293B)),
                )
              : Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFF36785A),
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Color(0xFF1E293B),
                  ),
                  textButtonTheme: TextButtonThemeData(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF36785A),
                      textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _onSave() {
    RestReminderService.instance.saveReminder(
      type: widget.type,
      startTime: _startTime,
      endTime: _endTime,
      date: _selectedDate,
    );

    if (widget.type == RestType.night) {
      final dateKey = SleepTrackingService.formatDateKey(_selectedDate);
      final startDt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      DateTime endDt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _endTime.hour,
        _endTime.minute,
      );
      if (endDt.isBefore(startDt) || endDt.isAtSameMomentAs(startDt)) {
        endDt = endDt.add(const Duration(days: 1));
      }

      SleepTrackingService.instance.bedtimeTarget = _startTime;
      SleepTrackingService.instance.reminderEnabled = true;
      SleepTrackingService.instance.scheduleBedtimeNotification();

      SleepTrackingService.instance.addRecord(
        SleepRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: SleepTrackingService.instance.currentUserId,
          date: dateKey,
          startTime: startDt,
          endTime: endDt,
          durationMinutes: _durationMinutes,
          source: 'manual',
        ),
      );
    }

    AppAlert.showSuccess(
      context,
      widget.type == RestType.day
          ? 'Pengingat istirahat siang berhasil disimpan'
          : 'Pengingat tidur malam berhasil disimpan',
      duration: const Duration(seconds: 2),
    );

    Navigator.of(context).pop();
  }

  void _onCancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNight = widget.type == RestType.night;
    final screenTitle = isNight ? 'Masukkan Data Tidur' : 'Masukkan Data Istirahat';
    final cardTitle = isNight ? 'Waktu Tidur' : 'Waktu Istirahat';

    final tile1Title = isNight ? 'Jam tidur' : 'Jam istirahat';
    final tile2Title = isNight ? 'Jam bangun' : 'Jam selesai';
    final tile3Title = isNight ? 'Durasi tidur' : 'Durasi istirahat';
    final headerColor = isDark ? const Color(0xFF1E293B) : const Color(0xFF36785A);

    return CurvedHeaderScaffold(
      title: screenTitle,
      headerColor: headerColor,
      sheetColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F6F8),
      centerTitle: true,
      onBack: _onCancel,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Date Selector Pill
            RestDateSelectorPill(
              selectedDate: _selectedDate,
              onDateChanged: (newDate) {
                setState(() {
                  _selectedDate = newDate;
                });
              },
            ),
            const SizedBox(height: 16),

            // Main Settings Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: isDark ? Border.all(color: const Color(0xFF334155)) : null,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E293B).withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header inside Card
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isNight
                              ? (isDark ? const Color(0xFF0F3627) : const Color(0xFFE2F1E8))
                              : (isDark ? const Color(0xFF452205) : const Color(0xFFFEF3C7)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isNight ? Icons.bed_rounded : Icons.wb_sunny_rounded,
                          size: 20,
                          color: isNight
                              ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF36785A))
                              : (isDark ? const Color(0xFFFBBF24) : const Color(0xFFEAB308)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        cardTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF265C45),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 24-Hour Circular Dial
                  CircularSleepDial(
                    type: widget.type,
                    startTime: _startTime,
                    endTime: _endTime,
                  ),
                  const SizedBox(height: 24),

                  // List Tile 1: Jam tidur / Jam istirahat
                  _buildSettingTile(
                    isDark: isDark,
                    icon: isNight ? Icons.bed_rounded : Icons.wb_sunny_rounded,
                    iconBg: isNight
                        ? (isDark ? const Color(0xFF0F3627) : const Color(0xFFE2F1E8))
                        : (isDark ? const Color(0xFF452205) : const Color(0xFFFEF3C7)),
                    iconColor: isNight
                        ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF36785A))
                        : (isDark ? const Color(0xFFFBBF24) : const Color(0xFFEAB308)),
                    title: tile1Title,
                    value: _formatTime(_startTime),
                    showChevron: true,
                    onTap: () => _pickTime(isStart: true),
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                  ),

                  // List Tile 2: Jam bangun / Jam selesai
                  _buildSettingTile(
                    isDark: isDark,
                    icon: isNight ? Icons.wb_sunny_outlined : Icons.alarm_on_rounded,
                    iconBg: isNight
                        ? (isDark ? const Color(0xFF452205) : const Color(0xFFFFFBEB))
                        : (isDark ? const Color(0xFF0F3627) : const Color(0xFFE2F1E8)),
                    iconColor: isNight
                        ? (isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B))
                        : (isDark ? const Color(0xFF4ADE80) : const Color(0xFF36785A)),
                    title: tile2Title,
                    value: _formatTime(_endTime),
                    showChevron: true,
                    onTap: () => _pickTime(isStart: false),
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                  ),

                  // List Tile 3: Durasi tidur / Durasi istirahat
                  _buildSettingTile(
                    isDark: isDark,
                    icon: Icons.access_time_rounded,
                    iconBg: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFFEDF7F2),
                    iconColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF36785A),
                    title: tile3Title,
                    value: _durationFormatted,
                    showChevron: false,
                    onTap: null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Bottom Action Buttons: Batal & Simpan
            Row(
              children: [
                // Batal Button
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      foregroundColor: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                      side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0), width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    onPressed: _onCancel,
                    child: Text(
                      'Batal',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Simpan Button
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3E8D6B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 0,
                    ),
                    onPressed: _onSave,
                    child: Text(
                      'Simpan',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required bool isDark,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String value,
    required bool showChevron,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                ),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            if (showChevron) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
