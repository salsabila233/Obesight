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
  int _selectedTabIndex = 1; // 0: Jam, 1: Hari, 2: Minggu, 3: Bulan (default: Hari)
  DateTime _currentWeekEnd = DateTime.now();
  DateTime _selectedHistoryDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    SleepTrackingService.instance.startFirestoreRealtimeListener();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: SleepTrackingService.instance,
      builder: (context, _) {
        final service = SleepTrackingService.instance;
        final summaries = service.getPast7DaysSummaries(_currentWeekEnd);

        return Scaffold(
          backgroundColor: const Color(0xFF36785A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF36785A),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Riwayat Tidur',
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
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF4F8F6),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Segmented Filter Tabs (Jam | Hari | Minggu | Bulan)
                    _buildSegmentedTabs(),
                    const SizedBox(height: 16),

                    // 2. Dynamic Chart Card (Jam / Hari / Minggu / Bulan)
                    _buildDynamicChartCard(service, summaries),
                    const SizedBox(height: 20),

                    // 3. Section: Pengaturan Notifikasi Waktu Tidur
                    _buildReminderSection(service),
                    const SizedBox(height: 20),

                    // 4. Section: Riwayat Catatan Tidur (List records with edit & delete)
                    _buildRecordListSection(service),
                  ],
                ),
              ),
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

  Widget _buildDynamicChartCard(SleepTrackingService service, List<DailySleepSummary> summaries) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildHourlyCard(service);
      case 2:
        return _buildSingleWeekSummaryCard(service);
      case 3:
        return _buildCalendarMonthSummaryCard(service);
      case 1:
      default:
        return _buildDailyCard(service, summaries);
    }
  }

  // ========================================================
  // TAB 0: JAM (Data per jam untuk satu tanggal yang dipilih)
  // ========================================================
  Widget _buildHourlyCard(SleepTrackingService service) {
    final hourly = service.getChronologicalHourlySleep(_selectedHistoryDate);
    final recs = service.getRecordsForDate(_selectedHistoryDate);
    final hasData = recs.isNotEmpty;
    final totalMinutes = service.getTotalSleepMinutesForDate(_selectedHistoryDate);
    final totalHours = totalMinutes ~/ 60;
    final totalRemMins = totalMinutes % 60;
    final statusText = service.getSleepStatus(totalMinutes);

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
          // Navigasi Tanggal Hari Ini / Hari Tertentu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _selectedHistoryDate = _selectedHistoryDate.subtract(const Duration(days: 1));
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.chevron_left_rounded, size: 22, color: Color(0xFF475569)),
                    ),
                  ),
                  Text(
                    _formatDateIndo(_selectedHistoryDate),
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _selectedHistoryDate = _selectedHistoryDate.add(const Duration(days: 1));
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.chevron_right_rounded, size: 22, color: Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
              if (totalMinutes > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF7F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    totalHours > 0 ? '${totalHours}j ${totalRemMins}m' : '${totalRemMins}m',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF265C45),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Visualisasi jam tidur malam (20.00 – 08.00) secara kronologis untuk tanggal terpilih',
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 18),

          // Horizontal scrollable hourly chart
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              height: 125,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: hourly.map((h) {
                  final fraction = (h.minutesSlept / 60.0).clamp(0.0, 1.0);
                  final barH = h.isAsleep ? (16.0 + fraction * 55.0) : 6.0;

                  return Container(
                    width: 38,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (h.isAsleep)
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${h.minutesSlept}m',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF265C45),
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: 12),
                        const SizedBox(height: 4),
                        Container(
                          width: 20,
                          height: barH,
                          decoration: BoxDecoration(
                            color: h.isAsleep ? const Color(0xFF36785A) : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${h.hour.toString().padLeft(2, '0')}.00',
                            style: GoogleFonts.poppins(
                              fontSize: 9.5,
                              fontWeight: h.isAsleep ? FontWeight.w700 : FontWeight.w500,
                              color: h.isAsleep ? const Color(0xFF265C45) : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Status & Info Rekaman Hari Terpilih (Mencegah Bad state: No element)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: hasData ? const Color(0xFFEDF7F2) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasData ? const Color(0xFFA5D6C1) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  hasData ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                  size: 18,
                  color: hasData ? const Color(0xFF265C45) : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasData ? 'Status: $statusText' : 'Belum Ada Data Tidur',
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: hasData ? const Color(0xFF265C45) : const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasData && recs.isNotEmpty
                            ? 'Waktu tidur: ${recs.first.startTimeFormatted.replaceAll(':', '.')} - ${recs.last.endTimeFormatted.replaceAll(':', '.')} (${recs.first.sourceLabel})'
                            : 'Tidak ada sesi tidur tercatat pada tanggal ${_formatDateIndo(_selectedHistoryDate)}.',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: hasData ? const Color(0xFF365E4C) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // TAB 1: HARI (Statistik satu hari penuh & grafik 7 hari)
  // ========================================================
  Widget _buildDailyCard(SleepTrackingService service, List<DailySleepSummary> summaries) {
    final avgBedtime = service.getAverageBedtime7Days(_currentWeekEnd);
    final avgWakeTime = service.getAverageWakeTime7Days(_currentWeekEnd);
    final avgMinutes = service.getAverageSleepMinutes7Days(_currentWeekEnd);
    final avgHours = avgMinutes ~/ 60;
    final avgRemMins = (avgMinutes % 60).round();

    final weekStart = summaries.isNotEmpty ? summaries.first.date : _currentWeekEnd.subtract(const Duration(days: 6));
    final weekEnd = summaries.isNotEmpty ? summaries.last.date : _currentWeekEnd;
    final weekRangeStr = _formatWeekRange(weekStart, weekEnd);

    // Temukan summary yang saat ini dipilih
    final selectedKey = SleepTrackingService.formatDateKey(_selectedHistoryDate);
    final selectedSummary = summaries.firstWhere(
      (s) => s.dateKey == selectedKey,
      orElse: () => summaries.isNotEmpty ? summaries.last : DailySleepSummary(
        date: _selectedHistoryDate,
        dateKey: selectedKey,
        dayName: '',
        dayNumber: _selectedHistoryDate.day.toString(),
        totalMinutes: 0,
        records: const [],
        isToday: false,
      ),
    );

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
          // Date range selector with prev / next navigation
          Row(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _currentWeekEnd = _currentWeekEnd.subtract(const Duration(days: 7));
                    _selectedHistoryDate = _currentWeekEnd;
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
                    _selectedHistoryDate = _currentWeekEnd;
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

          // Bar Chart with right Y-axis
          _buildWeeklyBarChart(summaries),
          const SizedBox(height: 14),

          // Card Rincian Tanggal yang Dipilih
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selectedSummary.hasData ? const Color(0xFFEDF7F2) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selectedSummary.hasData ? const Color(0xFFA5D6C1) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDateIndo(selectedSummary.date),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: selectedSummary.hasData ? const Color(0xFF265C45) : const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selectedSummary.hasData
                            ? 'Durasi: ${selectedSummary.formattedDuration} • ${service.getSleepStatus(selectedSummary.totalMinutes)}'
                            : 'Belum ada catatan tidur pada tanggal ini.',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: selectedSummary.hasData ? const Color(0xFF365E4C) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (selectedSummary.hasData)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedTabIndex = 0; // Pindah ke tab Jam
                      });
                    },
                    icon: const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFF265C45)),
                    label: Text(
                      'Rincian Jam',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF265C45),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 7-day average summary badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.insights_rounded, size: 16, color: Color(0xFF36785A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Rata-rata tidur 7 hari: $avgHours jam $avgRemMins menit',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // TAB 2: MINGGU (Data HANYA untuk 1 minggu: 7 hari Sen - Min)
  // ========================================================
  Widget _buildSingleWeekSummaryCard(SleepTrackingService service) {
    final singleWeek = service.getSingleWeekSummary(_currentWeekEnd);
    final weekTotalHours = singleWeek.totalMinutes ~/ 60;
    final weekTotalRemMins = singleWeek.totalMinutes % 60;

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
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _currentWeekEnd = _currentWeekEnd.subtract(const Duration(days: 7));
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.chevron_left_rounded, size: 22, color: Color(0xFF475569)),
                    ),
                  ),
                  Text(
                    singleWeek.weekLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
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
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.chevron_right_rounded, size: 22, color: Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF36785A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${singleWeek.daysWithData}/7 Hari',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Statistik tidur harian selama 1 minggu penuh (7 hari)',
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 18),

          // 7-day Bar Chart for this single week
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: singleWeek.days.map((d) {
                final hours = d.totalMinutes / 60.0;
                final fraction = (hours / 9.0).clamp(0.0, 1.0);
                final barH = (fraction * 75.0).clamp(d.hasData ? 14.0 : 4.0, 75.0);
                final isSelected = d.dateKey == SleepTrackingService.formatDateKey(_selectedHistoryDate);

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedHistoryDate = d.date;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (d.hasData)
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${hours.toStringAsFixed(1)}j',
                              style: GoogleFonts.poppins(
                                fontSize: 9.5,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? const Color(0xFF265C45) : const Color(0xFF64748B),
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: 14),
                        const SizedBox(height: 4),
                        Container(
                          width: 22,
                          height: barH,
                          decoration: BoxDecoration(
                            color: d.hasData
                                ? (isSelected ? const Color(0xFF265C45) : const Color(0xFF86C5A9))
                                : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          d.dayName,
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? const Color(0xFF265C45) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Detail Card Akumulasi 1 Minggu
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEDF7F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFA5D6C1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Akumulasi 1 Minggu',
                            style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF475569)),
                          ),
                          Text(
                            singleWeek.hasData
                                ? '$weekTotalHours jam $weekTotalRemMins menit'
                                : '0 jam',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rata-rata Per Hari',
                            style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF475569)),
                          ),
                          Text(
                            singleWeek.hasData
                                ? '${singleWeek.averageHours}j ${singleWeek.averageRemainingMinutes}m'
                                : '0 jam',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFC7E5D6)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rata-rata tidur: ${singleWeek.averageBedtime}',
                      style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF334155)),
                    ),
                    Text(
                      'Rata-rata bangun: ${singleWeek.averageWakeTime}',
                      style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF334155)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // TAB 3: BULAN (Data HANYA untuk satu bulan kalender)
  // ========================================================
  Widget _buildCalendarMonthSummaryCard(SleepTrackingService service) {
    final monthSummary = service.getCalendarMonthSummary(_currentWeekEnd);
    final monthTotalHours = monthSummary.totalMinutes ~/ 60;
    final monthTotalRemMins = monthSummary.totalMinutes % 60;

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
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        // Mundur 1 bulan kalender
                        final prevMonth = _currentWeekEnd.month == 1 ? 12 : _currentWeekEnd.month - 1;
                        final prevYear = _currentWeekEnd.month == 1 ? _currentWeekEnd.year - 1 : _currentWeekEnd.year;
                        final daysInPrev = DateTime(prevYear, prevMonth + 1, 0).day;
                        final safeDay = _currentWeekEnd.day.clamp(1, daysInPrev);
                        _currentWeekEnd = DateTime(prevYear, prevMonth, safeDay);
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.chevron_left_rounded, size: 22, color: Color(0xFF475569)),
                    ),
                  ),
                  Text(
                    monthSummary.monthLabel,
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
                        // Maju 1 bulan kalender
                        final nextMonth = _currentWeekEnd.month == 12 ? 1 : _currentWeekEnd.month + 1;
                        final nextYear = _currentWeekEnd.month == 12 ? _currentWeekEnd.year + 1 : _currentWeekEnd.year;
                        final daysInNext = DateTime(nextYear, nextMonth + 1, 0).day;
                        final safeDay = _currentWeekEnd.day.clamp(1, daysInNext);
                        _currentWeekEnd = DateTime(nextYear, nextMonth, safeDay);
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.chevron_right_rounded, size: 22, color: Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF36785A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${monthSummary.daysWithData}/${monthSummary.totalDaysInMonth} Hari',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Akumulasi data tidur selama 1 bulan kalender penuh',
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 18),

          // Weekly chunks within this calendar month
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: monthSummary.weeklyChunks.map((w) {
                final hours = w.averageMinutesPerDay / 60.0;
                final fraction = (hours / 9.0).clamp(0.0, 1.0);
                final barH = (fraction * 75.0).clamp(w.hasData ? 14.0 : 4.0, 75.0);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (w.hasData)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${hours.toStringAsFixed(1)}j',
                            style: GoogleFonts.poppins(
                              fontSize: 9.5,
                              fontWeight: w.isCurrentWeek ? FontWeight.w700 : FontWeight.w500,
                              color: w.isCurrentWeek ? const Color(0xFF265C45) : const Color(0xFF64748B),
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 14),
                      const SizedBox(height: 4),
                      Container(
                        width: 28,
                        height: barH,
                        decoration: BoxDecoration(
                          color: w.hasData
                              ? (w.isCurrentWeek ? const Color(0xFF265C45) : const Color(0xFF86C5A9))
                              : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        w.weekLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          fontWeight: w.isCurrentWeek ? FontWeight.w700 : FontWeight.w500,
                          color: w.isCurrentWeek ? const Color(0xFF265C45) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Detail Card Akumulasi Bulan Kalender Terpilih
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEDF7F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFA5D6C1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Akumulasi 1 Bulan',
                            style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF475569)),
                          ),
                          Text(
                            monthSummary.hasData
                                ? '$monthTotalHours jam $monthTotalRemMins m'
                                : '0 jam',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rata-rata Harian',
                            style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF475569)),
                          ),
                          Text(
                            monthSummary.hasData
                                ? '${monthSummary.averageHours}j ${monthSummary.averageRemainingMinutes}m'
                                : '0 jam',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
          // Background grid lines
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
                    final barH = (fraction * (chartHeight - 34)).clamp(summary.hasData ? 14.0 : 4.0, chartHeight - 34);
                    final selectedKey = SleepTrackingService.formatDateKey(_selectedHistoryDate);
                    final isSelected = summary.dateKey == selectedKey;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedHistoryDate = summary.date;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (summary.hasData)
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${hours.toStringAsFixed(1)}j',
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    fontWeight: (isSelected || summary.isToday) ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected
                                        ? const Color(0xFF265C45)
                                        : (summary.isToday ? const Color(0xFF265C45) : const Color(0xFF64748B)),
                                  ),
                                ),
                              )
                            else
                              const SizedBox(height: 12),
                            const SizedBox(height: 4),

                            // Vertical bar
                            Container(
                              width: isSelected ? 18 : 16,
                              height: barH,
                              decoration: BoxDecoration(
                                color: summary.hasData
                                    ? (isSelected
                                        ? const Color(0xFF265C45)
                                        : (summary.isToday ? const Color(0xFF36785A) : const Color(0xFF6EBE9B)))
                                    : (isSelected ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0)),
                                borderRadius: BorderRadius.circular(6),
                                border: isSelected
                                    ? Border.all(color: const Color(0xFF1E293B), width: 1.5)
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Day number label
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                summary.dayNumber,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: (isSelected || summary.isToday) ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected
                                      ? const Color(0xFF1E293B)
                                      : (summary.isToday ? const Color(0xFF265C45) : const Color(0xFF94A3B8)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
                onChanged: (val) async {
                  if (val) {
                    await service.requestNotificationPermission();
                  }
                  service.reminderEnabled = val;
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Aplikasi akan mengirimkan notifikasi sistem 1 jam sebelum target waktu tidur agar Anda bersiap meletakkan gadget dan beristirahat.',
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
              'Notifikasi aktif pada ${_formatTimeOfDay(service.reminderTime)} (1 jam sebelumnya)',
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
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEDF7F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA5D6C1)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF265C45), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sistem pengingat aktif otomatis di latar belakang. Anda akan menerima notifikasi setiap malam pukul ${_formatTimeOfDay(service.reminderTime)} (1 jam sebelum target tidur).',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: const Color(0xFF265C45),
                        height: 1.45,
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
                'Riwayat Catatan Tidur',
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
                  'Belum ada catatan tidur pada rentang tanggal ini.',
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
        content: Text(
          'Apakah Anda yakin ingin menghapus catatan tidur ${record.timeRangeFormatted} (${record.durationFormatted})?',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
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

  String _formatDateIndo(DateTime date) {
    const monthNames = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    const dayNames = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    if (isToday) {
      return 'Hari ini, ${date.day} ${monthNames[date.month]} ${date.year}';
    }
    return '${dayNames[date.weekday % 7]}, ${date.day} ${monthNames[date.month]} ${date.year}';
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
