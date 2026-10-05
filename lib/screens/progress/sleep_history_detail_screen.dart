import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/sleep_record_model.dart';
import '../../services/sleep_tracking_service.dart';
import 'sleep_record_form_screen.dart';

class SleepHistoryDetailScreen extends StatefulWidget {
  const SleepHistoryDetailScreen({super.key});

  @override
  State<SleepHistoryDetailScreen> createState() => _SleepHistoryDetailScreenState();
}

class _SleepHistoryDetailScreenState extends State<SleepHistoryDetailScreen> {
  int _selectedTabIndex = 1; // 0: Jam, 1: Hari, 2: Minggu, 3: Bulan (default: Hari matching Gambar 2)
  DateTime _currentWeekEnd = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SleepTrackingService.instance,
      builder: (context, _) {
        final service = SleepTrackingService.instance;
        final summaries = service.getPast7DaysSummaries(_currentWeekEnd);
        final avgBedtime = service.getAverageBedtime7Days(_currentWeekEnd);
        final avgWakeTime = service.getAverageWakeTime7Days(_currentWeekEnd);
        final avgMinutes = service.getAverageSleepMinutes7Days(_currentWeekEnd);
        final avgHours = avgMinutes ~/ 60;
        final avgRemMins = (avgMinutes % 60).round();
        final hasTodayData = service.hasTodayData;

        // Date range string: e.g. "18-24 Sep" or "29 Sep - 05 Okt"
        final weekStart = summaries.isNotEmpty ? summaries.first.date : _currentWeekEnd.subtract(const Duration(days: 6));
        final weekEnd = summaries.isNotEmpty ? summaries.last.date : _currentWeekEnd;
        final weekRangeStr = _formatWeekRange(weekStart, weekEnd);

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
              'Tidur',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Segmented Tab Bar (Jam | Hari | Minggu | Bulan)
                _buildSegmentedTabs(),
                const SizedBox(height: 16),

                // 2. Main Weekly Card (Matching Gambar 2)
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
                      // Date range selector with prev / next navigation
                      Row(
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                _currentWeekEnd = _currentWeekEnd.subtract(const Duration(days: 7));
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.chevron_left_rounded, size: 22, color: Color(0xFF475569)),
                            ),
                          ),
                          Text(
                            weekRangeStr,
                            style: GoogleFonts.poppins(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _currentWeekEnd = _currentWeekEnd.add(const Duration(days: 7));
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.chevron_right_rounded, size: 22, color: Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Average bedtime & wake time
                      Text(
                        'Waktu tidur rata-rata  $avgBedtime',
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Waktu bangun rata-rata  $avgWakeTime',
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Bar Chart with right Y-axis (4, 5, 6, 7 hours)
                      _buildWeeklyBarChart(summaries),
                      const SizedBox(height: 16),

                      // 7-day average summary badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDF7F2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.insights_rounded, size: 18, color: Color(0xFF265C45)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Rata-rata tidur 7 hari: $avgHours jam $avgRemMins menit',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF265C45),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Section: Pengaturan Notifikasi Waktu Tidur (PDF Halaman 2)
                _buildReminderSection(service),
                const SizedBox(height: 20),

                // 4. Section: Riwayat Catatan Tidur (List records with edit & delete)
                _buildRecordListSection(service),
                const SizedBox(height: 24),

                // 5. Bottom Action Button (Masukkan Data / Tambah Data)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3E8D6B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SleepRecordFormScreen(),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          hasTodayData ? Icons.add_circle_outline_rounded : Icons.access_time_filled_rounded,
                          size: 19,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hasTodayData ? 'Tambah data' : 'Masukkan data',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
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

  // ==========================================
  // WIDGET BUILDERS
  // ==========================================

  Widget _buildSegmentedTabs() {
    final tabs = ['Jam', 'Hari', 'Minggu', 'Bulan'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2EBE5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    tabs[index],
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? const Color(0xFF265C45) : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWeeklyBarChart(List<DailySleepSummary> summaries) {
    const double chartHeight = 140;
    const double maxHours = 8.0;

    return SizedBox(
      height: chartHeight,
      child: Stack(
        children: [
          // Background dotted/horizontal guideline grid
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(4, (i) {
              return Container(
                height: 1,
                width: double.infinity,
                color: const Color(0xFFF1F5F9),
              );
            }),
          ),

          // Bars & Right Y-axis
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 7 Bars
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: summaries.map((summary) {
                    final hours = summary.totalMinutes / 60.0;
                    final fraction = (hours / maxHours).clamp(0.0, 1.0);
                    final barH = (fraction * (chartHeight - 32)).clamp(summary.hasData ? 14.0 : 4.0, chartHeight - 32);

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Tooltip duration if has data
                        if (summary.hasData)
                          Text(
                            '${hours.toStringAsFixed(1)}j',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: summary.isToday ? FontWeight.w700 : FontWeight.w500,
                              color: summary.isToday ? const Color(0xFF265C45) : const Color(0xFF64748B),
                            ),
                          )
                        else
                          const SizedBox(height: 12),
                        const SizedBox(height: 4),

                        // Vertical bar
                        Container(
                          width: 16,
                          height: barH,
                          decoration: BoxDecoration(
                            color: summary.hasData
                                ? (summary.isToday ? const Color(0xFF265C45) : const Color(0xFF5AA183))
                                : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Day number label
                        Text(
                          summary.dayNumber,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: summary.isToday ? FontWeight.w700 : FontWeight.w500,
                            color: summary.isToday ? const Color(0xFF265C45) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),

              // Right Y-axis numbers (4, 5, 6, 7 hours)
              Container(
                width: 28,
                padding: const EdgeInsets.only(bottom: 22),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    _YTick(text: '7'),
                    _YTick(text: '6'),
                    _YTick(text: '5'),
                    _YTick(text: '4'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReminderSection(SleepTrackingService service) {
    return Container(
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
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2F1E8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.notifications_active_rounded, size: 20, color: Color(0xFF36785A)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Pengingat Waktu Tidur',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
              Switch(
                value: service.reminderEnabled,
                activeThumbColor: const Color(0xFF36785A),
                onChanged: (val) {
                  service.reminderEnabled = val;
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Aplikasi akan mengirimkan pengingat 1 jam sebelum target waktu tidur agar Anda bersiap meletakkan gadget dan beristirahat.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF64748B),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),

          // Target Bedtime tile
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.bedtime_rounded, color: Color(0xFF36785A)),
            title: Text(
              'Target Waktu Tidur',
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
            ),
            subtitle: Text(
              'Pengingat aktif pada ${_formatTimeOfDay(service.reminderTime)} (1 jam sebelumnya)',
              style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF64748B)),
            ),
            trailing: InkWell(
              onTap: service.reminderEnabled
                  ? () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: service.bedtimeTarget,
                      );
                      if (picked != null) {
                        service.bedtimeTarget = picked;
                      }
                    }
                  : null,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF7F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatTimeOfDay(service.bedtimeTarget),
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF265C45),
                  ),
                ),
              ),
            ),
          ),

          if (service.reminderEnabled) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pratinjau Notifikasi:\n"${service.reminderMessage}"',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF92400E),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecordListSection(SleepTrackingService service) {
    final summaries = service.getPast7DaysSummaries(_currentWeekEnd);
    final allRecords = summaries.expand((s) => s.records).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Catatan Periode Tidur',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Text(
                '${allRecords.length} catatan',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (allRecords.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Belum ada catatan tidur pada periode ini.',
                  style: GoogleFonts.poppins(fontSize: 12.5, color: const Color(0xFF94A3B8)),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: allRecords.length,
              separatorBuilder: (context, index) => const Divider(height: 16, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final record = allRecords[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: record.isAutomatic ? const Color(0xFFE2F1E8) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        record.isAutomatic ? Icons.phone_android_rounded : Icons.edit_note_rounded,
                        size: 19,
                        color: record.isAutomatic ? const Color(0xFF265C45) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                record.timeRangeFormatted,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEDF7F2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  record.shortDurationFormatted,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF265C45),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${record.date} • ${record.sourceLabel}',
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SleepRecordFormScreen(recordToEdit: record),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                      onPressed: () => _confirmDelete(record),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  void _confirmDelete(SleepRecord record) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus Catatan Tidur', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
        content: Text('Apakah Anda yakin ingin menghapus catatan tidur ${record.timeRangeFormatted} (${record.durationFormatted})?',
            style: GoogleFonts.poppins(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Batal', style: GoogleFonts.poppins(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () {
              SleepTrackingService.instance.deleteRecord(record.id);
              Navigator.of(ctx).pop();
            },
            child: Text('Hapus', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatWeekRange(DateTime start, DateTime end) {
    const monthNames = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    if (start.month == end.month) {
      return '${start.day}-${end.day} ${monthNames[start.month]}';
    } else {
      return '${start.day} ${monthNames[start.month]} - ${end.day} ${monthNames[end.month]}';
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _YTick extends StatelessWidget {
  final String text;
  const _YTick({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF94A3B8),
      ),
    );
  }
}
