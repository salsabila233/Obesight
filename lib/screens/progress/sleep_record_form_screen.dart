import 'package:flutter/material.dart';
import '../../widgets/app_alert.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/sleep_record_model.dart';
import '../../services/sleep_tracking_service.dart';
import '../../services/rest_reminder_service.dart';
import '../../widgets/rest_tracking_widgets.dart';

enum _TimeField { session1Start, session1End, session2Start, session2End }

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
  late TimeOfDay _startTime; // Sesi 1 / Tunggal: Jam tidur
  late TimeOfDay _firstEndTime; // Sesi 1: Jam terbangun di tengah malam
  late TimeOfDay _secondStartTime; // Sesi 2: Jam tidur kembali
  late TimeOfDay _endTime; // Sesi 2 / Tunggal: Jam bangun akhir
  bool _isSplitSleep = false;
  String _source = 'manual';

  @override
  void initState() {
    super.initState();
    if (widget.recordToEdit != null) {
      final r = widget.recordToEdit!;
      _selectedDate = DateTime.parse(r.date);
      _startTime = TimeOfDay(hour: r.startTime.hour, minute: r.startTime.minute);
      _endTime = TimeOfDay(hour: r.endTime.hour, minute: r.endTime.minute);
      _isSplitSleep = r.isSplitSleep;
      if (r.isSplitSleep && r.firstEndTime != null && r.secondStartTime != null) {
        _firstEndTime = TimeOfDay(hour: r.firstEndTime!.hour, minute: r.firstEndTime!.minute);
        _secondStartTime = TimeOfDay(hour: r.secondStartTime!.hour, minute: r.secondStartTime!.minute);
      } else {
        _firstEndTime = const TimeOfDay(hour: 2, minute: 0);
        _secondStartTime = const TimeOfDay(hour: 3, minute: 0);
      }
      _source = r.source;
    } else {
      _selectedDate = widget.initialDate ?? DateTime.now();
      // Default: 22:30 -> 06:15 (7 jam 45 menit)
      _startTime = const TimeOfDay(hour: 22, minute: 30);
      _firstEndTime = const TimeOfDay(hour: 2, minute: 0);
      _secondStartTime = const TimeOfDay(hour: 3, minute: 0);
      _endTime = const TimeOfDay(hour: 6, minute: 15);
    }
  }

  int _calcDiffMinutes(TimeOfDay start, TimeOfDay end) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    var diff = endMinutes - startMinutes;
    if (diff <= 0) {
      // Melewati tengah malam
      diff += 24 * 60;
    }
    return diff;
  }

  int get _session1Minutes => _calcDiffMinutes(_startTime, _firstEndTime);
  int get _session2Minutes => _calcDiffMinutes(_secondStartTime, _endTime);

  int get _awakeGapMinutes {
    final startMinutes = _firstEndTime.hour * 60 + _firstEndTime.minute;
    final endMinutes = _secondStartTime.hour * 60 + _secondStartTime.minute;
    var diff = endMinutes - startMinutes;
    if (diff < 0) {
      diff += 24 * 60;
    }
    return diff;
  }

  int get _durationMinutes {
    if (_isSplitSleep) {
      return _session1Minutes + _session2Minutes;
    }
    return _calcDiffMinutes(_startTime, _endTime);
  }

  String _formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) {
      return '$h jam $m menit';
    } else if (h > 0) {
      return '$h jam';
    } else {
      return '$m menit';
    }
  }

  String get _durationFormatted => _formatMinutes(_durationMinutes);
  String get _session1Formatted => _formatMinutes(_session1Minutes);
  String get _session2Formatted => _formatMinutes(_session2Minutes);
  String get _awakeGapFormatted => _formatMinutes(_awakeGapMinutes);

  String _formatTimeOfDay(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h.$m';
  }

  Future<void> _pickTimeForField(_TimeField field) async {
    TimeOfDay initial;
    switch (field) {
      case _TimeField.session1Start:
        initial = _startTime;
        break;
      case _TimeField.session1End:
        initial = _firstEndTime;
        break;
      case _TimeField.session2Start:
        initial = _secondStartTime;
        break;
      case _TimeField.session2End:
        initial = _endTime;
        break;
    }

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
        switch (field) {
          case _TimeField.session1Start:
            _startTime = picked;
            break;
          case _TimeField.session1End:
            _firstEndTime = picked;
            break;
          case _TimeField.session2Start:
            _secondStartTime = picked;
            break;
          case _TimeField.session2End:
            _endTime = picked;
            break;
        }
      });
    }
  }

  DateTime _resolveDt(
    DateTime baseDate,
    TimeOfDay time, {
    required DateTime after,
    bool allowEqual = false,
  }) {
    var dt = DateTime(baseDate.year, baseDate.month, baseDate.day, time.hour, time.minute);
    while (allowEqual
        ? dt.isBefore(after)
        : (dt.isBefore(after) || dt.isAtSameMomentAs(after))) {
      dt = dt.add(const Duration(days: 1));
    }
    return dt;
  }

  Future<void> _saveRecord() async {
    final dateKey = SleepTrackingService.formatDateKey(_selectedDate);
    final service = SleepTrackingService.instance;

    DateTime startDt;
    DateTime endDt;
    DateTime? firstEndDt;
    DateTime? secondStartDt;
    int? firstSessionMins;
    int? secondSessionMins;
    int totalMins;

    if (_isSplitSleep) {
      // Validasi 1: Sesi 1 waktu mulai & selesai tidak boleh sama
      if (_startTime.hour == _firstEndTime.hour && _startTime.minute == _firstEndTime.minute) {
        AppAlert.showError(
          context,
          'Waktu terbangun Sesi 1 tidak boleh sama dengan waktu tidur.',
        );
        return;
      }

      // Validasi 2: Sesi 2 waktu tidur lagi & bangun akhir tidak boleh sama
      if (_secondStartTime.hour == _endTime.hour && _secondStartTime.minute == _endTime.minute) {
        AppAlert.showError(
          context,
          'Waktu bangun akhir Sesi 2 tidak boleh sama dengan waktu tidur kembali.',
        );
        return;
      }

      startDt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      firstEndDt = _resolveDt(_selectedDate, _firstEndTime, after: startDt, allowEqual: false);
      secondStartDt = _resolveDt(_selectedDate, _secondStartTime, after: firstEndDt, allowEqual: true);
      endDt = _resolveDt(_selectedDate, _endTime, after: secondStartDt, allowEqual: false);

      firstSessionMins = _session1Minutes;
      secondSessionMins = _session2Minutes;
      totalMins = firstSessionMins + secondSessionMins;
    } else {
      // Validasi: Waktu bangun tidak boleh sama dengan waktu tidur
      if (_startTime.hour == _endTime.hour && _startTime.minute == _endTime.minute) {
        AppAlert.showError(
          context,
          'Waktu bangun tidak boleh sama persis dengan waktu tidur.',
        );
        return;
      }

      startDt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      endDt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      if (endDt.isBefore(startDt) || endDt.isAtSameMomentAs(startDt)) {
        endDt = endDt.add(const Duration(days: 1));
      }
      totalMins = _calcDiffMinutes(_startTime, _endTime);
    }

    // Validasi 2: Deteksi tumpang tindih dengan data yang ada
    final overlapping = service.findOverlappingRecord(
      startDt,
      endDt,
      dateKey,
      excludeId: widget.recordToEdit?.id,
    );

    if (overlapping != null) {
      final action = await _showOverlapDialog(overlapping);
      if (action == 'cancel') return;
      if (action == 'replace') {
        final newRecord = SleepRecord(
          id: widget.recordToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          userId: service.currentUserId,
          date: dateKey,
          startTime: startDt,
          endTime: endDt,
          durationMinutes: totalMins,
          source: _source,
          isSplitSleep: _isSplitSleep,
          firstEndTime: firstEndDt,
          secondStartTime: secondStartDt,
          firstSessionMinutes: firstSessionMins,
          secondSessionMinutes: secondSessionMins,
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
      durationMinutes: totalMins,
      source: _source,
      isSplitSleep: _isSplitSleep,
      firstEndTime: firstEndDt,
      secondStartTime: secondStartDt,
      firstSessionMinutes: firstSessionMins,
      secondSessionMinutes: secondSessionMins,
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
    AppAlert.showSuccess(
      context,
      widget.recordToEdit != null
          ? 'Catatan tidur berhasil diperbarui'
          : 'Catatan tidur baru berhasil disimpan',
      duration: const Duration(seconds: 2),
    );
    Navigator.of(context).pop();
  }

  Future<String?> _showOverlapDialog(SleepRecord existing) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final newTimeRange = _isSplitSleep
        ? '${_formatTimeOfDay(_startTime)}–${_formatTimeOfDay(_firstEndTime)} & ${_formatTimeOfDay(_secondStartTime)}–${_formatTimeOfDay(_endTime)}'
        : '${_formatTimeOfDay(_startTime)} – ${_formatTimeOfDay(_endTime)}';

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFEAB308), size: 24),
            const SizedBox(width: 8),
            Text(
              'Waktu Tumpang Tindih',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Waktu tidur yang Anda masukkan bertabrakan dengan data yang sudah ada:\n\n'
              '• Data tersimpan: ${existing.timeRangeFormatted} (${existing.durationFormatted})\n'
              '• Data baru: $newTimeRange ($_durationFormatted)\n\n'
              'Silakan pilih tindakan yang Anda inginkan:',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                height: 1.45,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('cancel'),
            child: Text(
              'Edit Waktu',
              style: GoogleFonts.poppins(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF58AF86) : const Color(0xFF489874),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerColor = isDark ? const Color(0xFF1E293B) : const Color(0xFF489874);

    return Scaffold(
      backgroundColor: headerColor,
      appBar: AppBar(
        backgroundColor: headerColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          screenTitle,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF4F8F6),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
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
              const SizedBox(height: 14),

              // Opsi Sesi Tidur Terbagi (Split Sleep Toggle Card)
              _buildSplitSleepToggleCard(isDark),
              const SizedBox(height: 14),

              // Main Input Section (Single Dial vs Dual Session Cards)
              if (!_isSplitSleep)
                _buildSingleSleepCard(isDark)
              else
                _buildSplitSleepCards(isDark),

              const SizedBox(height: 20),

              // Bottom Buttons: Batal & Simpan
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                        side: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Batal',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF58AF86) : const Color(0xFF489874),
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
      ),
    );
  }

  /// Toggle Card untuk mengaktifkan / menonaktifkan Sesi Tidur Terbagi (Split Sleep)
  Widget _buildSplitSleepToggleCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isSplitSleep
              ? (isDark ? const Color(0xFF58AF86) : const Color(0xFF489874))
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: _isSplitSleep ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _isSplitSleep
                  ? (isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE2F1E8))
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.call_split_rounded,
              size: 20,
              color: _isSplitSleep
                  ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF36785A))
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tidur Terbagi (Split Sleep)',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  'Terbangun di tengah malam lalu tidur lagi',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isSplitSleep,
            activeTrackColor: isDark ? const Color(0xFF58AF86) : const Color(0xFF489874),
            onChanged: (val) {
              setState(() {
                _isSplitSleep = val;
              });
            },
          ),
        ],
      ),
    );
  }

  /// Tampilan Form Tidur Tunggal (Standar dengan Dial 24-Jam)
  Widget _buildSingleSleepCard(bool isDark) {
    return Container(
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
                  color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE2F1E8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.bed_rounded,
                  size: 20,
                  color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF36785A),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Waktu Istirahat',
                style: GoogleFonts.poppins(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF265C45),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Interactive Circular 24-Hour Dial
          CircularSleepDial(
            type: RestType.night,
            startTime: _startTime,
            endTime: _endTime,
            isInteractive: true,
            onStartTimeChanged: (newStart) {
              setState(() => _startTime = newStart);
            },
            onEndTimeChanged: (newEnd) {
              setState(() => _endTime = newEnd);
            },
            onRangeChanged: (newStart, newEnd) {
              setState(() {
                _startTime = newStart;
                _endTime = newEnd;
              });
            },
          ),
          const SizedBox(height: 24),

          // Tile 1: Jam tidur
          _buildSettingTile(
            context,
            icon: Icons.bed_rounded,
            iconBg: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE2F1E8),
            iconColor: isDark ? const Color(0xFF4ADE80) : const Color(0xFF36785A),
            title: 'Jam istirahat',
            value: _formatTimeOfDay(_startTime),
            showChevron: true,
            onTap: () => _pickTimeForField(_TimeField.session1Start),
          ),
          Divider(height: 1, thickness: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),

          // Tile 2: Jam bangun
          _buildSettingTile(
            context,
            icon: Icons.alarm_on_rounded,
            iconBg: isDark ? const Color(0xFF3E2D12) : const Color(0xFFFFFBEB),
            iconColor: const Color(0xFFF59E0B),
            title: 'Jam selesai',
            value: _formatTimeOfDay(_endTime),
            showChevron: true,
            onTap: () => _pickTimeForField(_TimeField.session2End),
          ),
          Divider(height: 1, thickness: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),

          // Tile 3: Durasi tidur (Auto-calculated)
          _buildSettingTile(
            context,
            icon: Icons.access_time_rounded,
            iconBg: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFEDF7F2),
            iconColor: isDark ? const Color(0xFF4ADE80) : const Color(0xFF36785A),
            title: 'Durasi istirahat',
            value: _durationFormatted,
            showChevron: false,
            onTap: null,
          ),
        ],
      ),
    );
  }

  /// Tampilan Form Tidur Terbagi (Sesi 1, Jeda Terjaga, Sesi 2, & Akumulasi Total)
  Widget _buildSplitSleepCards(bool isDark) {
    return Column(
      children: [
        // Card Sesi 1: Tidur Pertama
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE2F1E8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.looks_one_rounded,
                            size: 18,
                            color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF36785A),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'Sesi 1: Tidur Pertama',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEDF7F2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _session1Formatted,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF265C45),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildSettingTile(
                context,
                icon: Icons.bed_rounded,
                iconBg: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE2F1E8),
                iconColor: isDark ? const Color(0xFF4ADE80) : const Color(0xFF36785A),
                title: 'Jam tidur (mulai sesi 1)',
                value: _formatTimeOfDay(_startTime),
                showChevron: true,
                onTap: () => _pickTimeForField(_TimeField.session1Start),
              ),
              Divider(height: 1, thickness: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),

              _buildSettingTile(
                context,
                icon: Icons.airline_seat_recline_normal_rounded,
                iconBg: isDark ? const Color(0xFF3E2D12) : const Color(0xFFFFFBEB),
                iconColor: const Color(0xFFF59E0B),
                title: 'Jam terbangun (akhir sesi 1)',
                value: _formatTimeOfDay(_firstEndTime),
                showChevron: true,
                onTap: () => _pickTimeForField(_TimeField.session1End),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Jeda Terjaga di Tengah Malam (Awake Gap Card)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF172554) : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF1E40AF) : const Color(0xFFBFDBFE),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.nightlight_outlined,
                size: 18,
                color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Terjaga di tengah malam: $_awakeGapFormatted (${_formatTimeOfDay(_firstEndTime)} – ${_formatTimeOfDay(_secondStartTime)})',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFFBFDBFE) : const Color(0xFF1E40AF),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Card Sesi 2: Tidur Kembali
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE2F1E8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.looks_two_rounded,
                            size: 18,
                            color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF36785A),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'Sesi 2: Tidur Kembali',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEDF7F2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _session2Formatted,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF265C45),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildSettingTile(
                context,
                icon: Icons.hotel_rounded,
                iconBg: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE2F1E8),
                iconColor: isDark ? const Color(0xFF4ADE80) : const Color(0xFF36785A),
                title: 'Jam tidur lagi (mulai sesi 2)',
                value: _formatTimeOfDay(_secondStartTime),
                showChevron: true,
                onTap: () => _pickTimeForField(_TimeField.session2Start),
              ),
              Divider(height: 1, thickness: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),

              _buildSettingTile(
                context,
                icon: Icons.alarm_on_rounded,
                iconBg: isDark ? const Color(0xFF3E2D12) : const Color(0xFFFFFBEB),
                iconColor: const Color(0xFFF59E0B),
                title: 'Jam bangun akhir (selesai sesi 2)',
                value: _formatTimeOfDay(_endTime),
                showChevron: true,
                onTap: () => _pickTimeForField(_TimeField.session2End),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Card Akumulasi Total Durasi Tidur
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFEDF7F2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF059669) : const Color(0xFFA5D6C1),
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time_filled_rounded,
                          size: 20,
                          color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF22674A),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Total Akumulasi Tidur',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _durationFormatted,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Sesi 1 ($_session1Formatted) + Sesi 2 ($_session2Formatted)',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: _durationMinutes >= 420
                          ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7))
                          : (isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _durationMinutes >= 420 ? 'Tidur Cukup' : 'Tidur Kurang',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _durationMinutes >= 420
                            ? (isDark ? const Color(0xFF34D399) : const Color(0xFF15803D))
                            : (isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String value,
    required bool showChevron,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
