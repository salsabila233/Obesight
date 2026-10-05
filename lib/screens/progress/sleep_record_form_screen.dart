import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/sleep_record_model.dart';
import '../../services/sleep_tracking_service.dart';
import '../../services/rest_reminder_service.dart';
import '../../widgets/rest_tracking_widgets.dart';

class SleepRecordFormScreen extends StatefulWidget {
  final SleepRecord? recordToEdit;
  final DateTime? initialDate;

  const SleepRecordFormScreen({
    super.key,
    this.recordToEdit,
    this.initialDate,
  });

  @override
  State<SleepRecordFormScreen> createState() => _SleepRecordFormScreenState();
}

class _SleepRecordFormScreenState extends State<SleepRecordFormScreen> {
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  String _source = 'manual';

  @override
  void initState() {
    super.initState();
    if (widget.recordToEdit != null) {
      final r = widget.recordToEdit!;
      _selectedDate = DateTime.parse(r.date);
      _startTime = TimeOfDay(hour: r.startTime.hour, minute: r.startTime.minute);
      _endTime = TimeOfDay(hour: r.endTime.hour, minute: r.endTime.minute);
      _source = r.source;
    } else {
      _selectedDate = widget.initialDate ?? DateTime.now();
      // Default: 22:30 -> 06:15 (sesuai contoh prompt: 7 jam 45 menit)
      _startTime = const TimeOfDay(hour: 22, minute: 30);
      _endTime = const TimeOfDay(hour: 6, minute: 15);
    }
  }

  int get _durationMinutes {
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    var diff = endMinutes - startMinutes;
    if (diff <= 0) {
      // Melewati tengah malam
      diff += 24 * 60;
    }
    return diff;
  }

  String get _durationFormatted {
    final h = _durationMinutes ~/ 60;
    final m = _durationMinutes % 60;
    if (h > 0 && m > 0) {
      return '$h jam $m menit';
    } else if (h > 0) {
      return '$h jam';
    } else {
      return '$m menit';
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
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

  Future<void> _saveRecord() async {
    // Validasi 1: Waktu bangun tidak boleh sama dengan waktu tidur
    if (_startTime.hour == _endTime.hour && _startTime.minute == _endTime.minute) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Waktu bangun tidak boleh sama persis dengan waktu tidur.',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final dateKey = SleepTrackingService.formatDateKey(_selectedDate);

    // Hitung DateTime start dan end
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

    final service = SleepTrackingService.instance;

    // Validasi 2: Deteksi tumpang tindih dengan data yang ada
    final overlapping = service.findOverlappingRecord(
      startDt,
      endDt,
      dateKey,
      excludeId: widget.recordToEdit?.id,
    );

    if (overlapping != null) {
      // Tampilkan pilihan penanganan data ganda
      final action = await _showOverlapDialog(overlapping);
      if (action == 'cancel') return;
      if (action == 'replace') {
        final newRecord = SleepRecord(
          id: widget.recordToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          userId: service.currentUserId,
          date: dateKey,
          startTime: startDt,
          endTime: endDt,
          durationMinutes: _durationMinutes,
          source: _source,
        );
        await service.replaceRecord(overlapping.id, newRecord);
        _showSuccessAndPop();
        return;
      }
    }

    // Simpan record baru atau update
    final record = SleepRecord(
      id: widget.recordToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: service.currentUserId,
      date: dateKey,
      startTime: startDt,
      endTime: endDt,
      durationMinutes: _durationMinutes,
      source: _source,
    );

    if (widget.recordToEdit != null) {
      await service.updateRecord(record);
    } else {
      await service.addRecord(record);
    }

    _showSuccessAndPop();
  }

  void _showSuccessAndPop() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.recordToEdit != null
              ? 'Catatan tidur berhasil diperbarui'
              : 'Catatan tidur baru berhasil disimpan',
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

  Future<String?> _showOverlapDialog(SleepRecord existing) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFEAB308), size: 24),
            const SizedBox(width: 8),
            Text(
              'Waktu Tumpang Tindih',
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Periode tidur yang Anda masukkan bertabrakan dengan data yang sudah ada:\n\n'
              '• Data tersimpan: ${existing.timeRangeFormatted} (${existing.durationFormatted})\n'
              '• Data baru: ${_formatTimeOfDay(_startTime)} – ${_formatTimeOfDay(_endTime)} ($_durationFormatted)\n\n'
              'Silakan pilih tindakan yang Anda inginkan:',
              style: GoogleFonts.poppins(fontSize: 12.5, height: 1.45, color: const Color(0xFF334155)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('cancel'),
            child: Text('Edit Waktu', style: GoogleFonts.poppins(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF36785A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop('replace'),
            child: Text('Ganti Data Lama', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.recordToEdit != null;
    final screenTitle = isEditing ? 'Edit Data Tidur' : 'Masukkan Data Istirahat';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF36785A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
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
            // Date Selector Pill (< Min, 4 Okt >)
            RestDateSelectorPill(
              selectedDate: _selectedDate,
              onDateChanged: (newDate) {
                setState(() {
                  _selectedDate = newDate;
                });
              },
            ),
            const SizedBox(height: 16),

            // Main Sleep Input Card (Matching Gambar 3)
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
                          color: const Color(0xFFE2F1E8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.bed_rounded, size: 20, color: Color(0xFF36785A)),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Waktu Istirahat',
                        style: GoogleFonts.poppins(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF265C45),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Circular 24-Hour Dial
                  CircularSleepDial(
                    type: RestType.night,
                    startTime: _startTime,
                    endTime: _endTime,
                  ),
                  const SizedBox(height: 24),

                  // Tile 1: Jam tidur
                  _buildSettingTile(
                    icon: Icons.bed_rounded,
                    iconBg: const Color(0xFFE2F1E8),
                    iconColor: const Color(0xFF36785A),
                    title: 'Jam istirahat',
                    value: _formatTimeOfDay(_startTime),
                    showChevron: true,
                    onTap: () => _pickTime(isStart: true),
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

                  // Tile 2: Jam bangun
                  _buildSettingTile(
                    icon: Icons.alarm_on_rounded,
                    iconBg: const Color(0xFFFFFBEB),
                    iconColor: const Color(0xFFF59E0B),
                    title: 'Jam selesai',
                    value: _formatTimeOfDay(_endTime),
                    showChevron: true,
                    onTap: () => _pickTime(isStart: false),
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

                  // Tile 3: Durasi tidur (Auto-calculated!)
                  _buildSettingTile(
                    icon: Icons.access_time_rounded,
                    iconBg: const Color(0xFFEDF7F2),
                    iconColor: const Color(0xFF36785A),
                    title: 'Durasi istirahat',
                    value: _durationFormatted,
                    showChevron: false,
                    onTap: null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Bottom Buttons: Batal & Simpan
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF475569),
                      side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
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
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3E8D6B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 0,
                    ),
                    onPressed: _saveRecord,
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
