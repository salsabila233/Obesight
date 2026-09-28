import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/rest_reminder_service.dart';
import '../../widgets/rest_tracking_widgets.dart';

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
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.type == RestType.day
              ? 'Pengingat istirahat siang berhasil disimpan'
              : 'Pengingat tidur malam berhasil disimpan',
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
        ),
        backgroundColor: const Color(0xFF36785A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );

    Navigator.of(context).pop();
  }

  void _onCancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isNight = widget.type == RestType.night;
    final screenTitle = isNight ? 'Masukkan Data Tidur' : 'Masukkan Data Istirahat';
    final cardTitle = isNight ? 'Waktu Tidur' : 'Waktu Istirahat';

    final tile1Title = isNight ? 'Jam tidur' : 'Jam istirahat';
    final tile2Title = isNight ? 'Jam bangun' : 'Jam selesai';
    final tile3Title = isNight ? 'Durasi tidur' : 'Durasi istirahat';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF36785A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: _onCancel,
        ),
        title: Text(
          screenTitle,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.05),
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
                          color: isNight ? const Color(0xFFE2F1E8) : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isNight ? Icons.bed_rounded : Icons.wb_sunny_rounded,
                          size: 20,
                          color: isNight ? const Color(0xFF36785A) : const Color(0xFFEAB308),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        cardTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF265C45),
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
                    icon: isNight ? Icons.bed_rounded : Icons.wb_sunny_rounded,
                    iconBg: isNight ? const Color(0xFFE2F1E8) : const Color(0xFFFEF3C7),
                    iconColor: isNight ? const Color(0xFF36785A) : const Color(0xFFEAB308),
                    title: tile1Title,
                    value: _formatTime(_startTime),
                    showChevron: true,
                    onTap: () => _pickTime(isStart: true),
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

                  // List Tile 2: Jam bangun / Jam selesai
                  _buildSettingTile(
                    icon: isNight ? Icons.wb_sunny_outlined : Icons.alarm_on_rounded,
                    iconBg: isNight ? const Color(0xFFFFFBEB) : const Color(0xFFE2F1E8),
                    iconColor: isNight ? const Color(0xFFF59E0B) : const Color(0xFF36785A),
                    title: tile2Title,
                    value: _formatTime(_endTime),
                    showChevron: true,
                    onTap: () => _pickTime(isStart: false),
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

                  // List Tile 3: Durasi tidur / Durasi istirahat
                  _buildSettingTile(
                    icon: Icons.access_time_rounded,
                    iconBg: const Color(0xFFEDF7F2),
                    iconColor: const Color(0xFF36785A),
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
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF475569),
                      side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    onPressed: _onCancel,
                    child: Text(
                      'Batal',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
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
                  color: const Color(0xFF475569),
                ),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            if (showChevron) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Color(0xFF94A3B8),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
