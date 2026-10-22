import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/sleep_record_model.dart';
import '../../services/sleep_tracking_service.dart';
import 'sleep_history_detail_screen.dart';
import 'sleep_record_form_screen.dart';

class NightSleepDetailScreen extends StatefulWidget {
  const NightSleepDetailScreen({super.key});

  @override
  State<NightSleepDetailScreen> createState() => _NightSleepDetailScreenState();
}

class _NightSleepDetailScreenState extends State<NightSleepDetailScreen> {
  final DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    SleepTrackingService.instance.checkDeviceInactivityCandidate();
    SleepTrackingService.instance.startFirestoreRealtimeListener();
    if (SleepTrackingService.instance.reminderEnabled) {
      SleepTrackingService.instance.scheduleBedtimeNotification();
    }
  }

  void _openForm({SleepRecord? recordToEdit}) {
    final service = SleepTrackingService.instance;
    final rec = service.getSavedRecordForDate(_selectedDate);
    final targetRecord = recordToEdit ?? rec;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SleepRecordFormScreen(
          recordToEdit: targetRecord,
          initialDate: _selectedDate,
        ),
      ),
    );
  }

  void _openHistoryDetail() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SleepHistoryDetailScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;

    return ListenableBuilder(
      listenable: SleepTrackingService.instance,
      builder: (context, _) {
        final service = SleepTrackingService.instance;
        final isSelectedToday = _selectedDate.year == now.year &&
            _selectedDate.month == now.month &&
            _selectedDate.day == now.day;

        final recordsForSelectedDate = service.getRecordsForDate(_selectedDate);
        final hasDataForSelectedDate = recordsForSelectedDate.isNotEmpty;
        final totalMinutesSelected = service.getTotalSleepMinutesForDate(_selectedDate);
        final statusText = service.getSleepStatus(totalMinutesSelected);
        final pendingAuto = service.pendingAutoDetectedRecord;
        final summaries = service.getPast7DaysSummaries(_selectedDate);

        // Format durasi
        final String totalDurationFormatted;
        if (hasDataForSelectedDate) {
          totalDurationFormatted = totalMinutesSelected >= 60
              ? '${totalMinutesSelected ~/ 60} j ${totalMinutesSelected % 60} m'
              : '$totalMinutesSelected m';
        } else if (isSelectedToday && pendingAuto != null) {
          final h = pendingAuto.durationHours;
          final m = pendingAuto.durationRemainingMinutes;
          totalDurationFormatted = '$h j $m m';
        } else {
          totalDurationFormatted = '-- j -- m';
        }

        final backgroundColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF4F8F6);

        return Scaffold(
          backgroundColor: backgroundColor,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Collapsible Header (Banner visual tidur + AppBar saat tergulung)
              SliverPersistentHeader(
                pinned: true,
                delegate: _SleepCollapsibleHeaderDelegate(
                  topPadding: topPadding,
                  isDark: isDark,
                  onBack: () => Navigator.of(context).pop(),
                ),
              ),

              // 2. Konten Utama Melengkung Bersih Tanpa Background Hijau Kusam
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  color: backgroundColor,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Deskripsi Singkat Modul (Judul Waktu Tidur Malam berada di Collapsible Header)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 16),
                        child: Text(
                          'Tidur yang cukup dan teratur membantu metabolisme tubuh tetap seimbang.',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            height: 1.45,
                          ),
                        ),
                      ),

                      // --- CARD 1: Status / Estimasi Waktu Tidur (dengan Tombol "Catat waktu ini") ---
                      _buildTodaySleepStatusCard(
                        service: service,
                        selectedRecs: recordsForSelectedDate,
                        hasDataForSelectedDate: hasDataForSelectedDate,
                        isSelectedToday: isSelectedToday,
                        selectedDate: _selectedDate,
                        totalDurationFormatted: totalDurationFormatted,
                        statusText: statusText,
                        pendingAuto: pendingAuto,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),

                      // --- CARD 2: Grafik Riwayat Tidur (Opsi: Jam, Hari, Minggu, Bulan) ---
                      _buildHistoryChartCard(
                        service: service,
                        summaries: summaries,
                        hasDataForSelectedDate: hasDataForSelectedDate,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),

                      // --- CARD 3: Pengingat Waktu Tidur (Background Push Notification) ---
                      _buildSleepReminderCard(
                        service: service,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),

                      // --- CARD TIPS ISTIRAHAT ---
                      _buildTipsSection(isDark: isDark),
                      const SizedBox(height: 24),

                      // --- TOMBOL UTAMA: Masukkan Data ---
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF36785A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                            elevation: 0,
                          ),
                          onPressed: () => _openForm(),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.access_time_filled_rounded,
                                size: 19,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Masukkan data',
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
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // CARD 1: Status Waktu Tidur & Estimasi Otomatis
  // ==========================================
  Widget _buildTodaySleepStatusCard({
    required SleepTrackingService service,
    required List<SleepRecord> selectedRecs,
    required bool hasDataForSelectedDate,
    required bool isSelectedToday,
    required DateTime selectedDate,
    required String totalDurationFormatted,
    required String statusText,
    required SleepRecord? pendingAuto,
    required bool isDark,
  }) {
    const monthNames = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    const dayNames = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    final dateStr = isSelectedToday
        ? 'Hari ini, ${selectedDate.day} ${monthNames[selectedDate.month]} ${selectedDate.year}'
        : '${dayNames[selectedDate.weekday % 7]}, ${selectedDate.day} ${monthNames[selectedDate.month]} ${selectedDate.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE9F3ED)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge Bulan Sabit
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7),
                ),
                child: const Center(
                  child: Icon(
                    Icons.nightlight_round,
                    size: 22,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Info Waktu Tidur & Durasi
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            'Waktu Tidur',
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        if (hasDataForSelectedDate)
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF134E4A).withValues(alpha: 0.6) : const Color(0xFFEDF7F2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                statusText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF265C45),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      dateStr,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                totalDurationFormatted,
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              if (hasDataForSelectedDate && selectedRecs.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    '${selectedRecs.first.startTimeFormatted.replaceAll(':', '.')} - ${selectedRecs.last.endTimeFormatted.replaceAll(':', '.')}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFF58AF86) : const Color(0xFF36785A),
                                    ),
                                  ),
                                )
                              else if (isSelectedToday && pendingAuto != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    '${pendingAuto.startTimeFormatted.replaceAll(':', '.')} - ${pendingAuto.endTimeFormatted.replaceAll(':', '.')}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFF58AF86) : const Color(0xFF36785A),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Tombol Aksi: Status "Tercatat" jika data sudah tercatat, atau "Catat waktu ini" jika belum
                        if (hasDataForSelectedDate)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF134E4A).withValues(alpha: 0.5) : const Color(0xFFEDF7F2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isDark ? const Color(0xFF059669) : const Color(0xFFA5D6C1)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 14,
                                  color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF265C45),
                                ),
                                const SizedBox(width: 5),
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Text(
                                      'Tercatat',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF265C45),
                                      ),
                                    ),
                                    Text(
                                      'Sudah Dicatat',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.transparent,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        else
                          InkWell(
                            onTap: _isSaving
                                ? null
                                : () async {
                                    if (isSelectedToday && pendingAuto != null) {
                                      setState(() {
                                        _isSaving = true;
                                      });
                                      try {
                                        final autoData = pendingAuto;
                                        final success = await service.acceptPendingAutoRecord(targetDate: selectedDate);
                                        if (mounted) {
                                          setState(() {
                                            _isSaving = false;
                                          });
                                          if (success) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Waktu tidur berhasil dicatat (${autoData.timeRangeFormatted}) dan grafik langsung diperbarui.',
                                                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 12.5),
                                                ),
                                                backgroundColor: const Color(0xFF36785A),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Gagal menyimpan data tidur. Silakan coba lagi.',
                                                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 12.5),
                                                ),
                                                backgroundColor: const Color(0xFFEF4444),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          setState(() {
                                            _isSaving = false;
                                          });
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Terjadi kesalahan saat menyimpan data: $e',
                                                style: GoogleFonts.poppins(color: Colors.white, fontSize: 12.5),
                                              ),
                                              backgroundColor: const Color(0xFFEF4444),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      } finally {
                                        if (mounted) {
                                          setState(() {
                                            _isSaving = false;
                                          });
                                        }
                                      }
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Data perkiraan waktu tidur belum tersedia. Silakan gunakan tombol Masukkan data.',
                                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 12.5),
                                          ),
                                          backgroundColor: const Color(0xFFE11D48),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: _isSaving
                                  ? SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(isDark ? const Color(0xFF58AF86) : const Color(0xFF36785A)),
                                      ),
                                    )
                                  : Text(
                                      'Catat waktu ini',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                                      ),
                                    ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          // Label Disclaimer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.transparent),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF94A3B8)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Perkiraan waktu tidur otomatis berdasarkan kombinasi aktivitas layar HP dan sensor cahaya lingkungan (ambient light sensor).',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      height: 1.35,
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

  // ==========================================
  // CARD 2: Grafik Riwayat Tidur (Hari Ini Saja)
  // Menampilkan fokus hari ini, navigasi ke SleepHistoryDetailScreen untuk filter lengkap
  // ==========================================
  Widget _buildHistoryChartCard({
    required SleepTrackingService service,
    required List<DailySleepSummary> summaries,
    required bool hasDataForSelectedDate,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE9F3ED)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Arrow > (buka riwayat lengkap & filter statistik)
          InkWell(
            onTap: _openHistoryDetail,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Waktu tidur selama 7 hari terakhir',
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
          const SizedBox(height: 16),

          // Konten Grafik: HARI INI & 7 HARI TERAKHIR
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 140),
            child: !hasDataForSelectedDate
                ? _buildDailyEmptyState(isDark: isDark)
                : _buildTodayOnlyChart(service, _selectedDate, summaries, isDark: isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayOnlyChart(
    SleepTrackingService service,
    DateTime date,
    List<DailySleepSummary> summaries, {
    required bool isDark,
  }) {
    final recs = service.getRecordsForDate(date);
    final totalMinutes = recs.fold<int>(0, (acc, r) => acc + r.durationMinutes);
    final targetM = service.targetSleepMinutes;
    final hours = totalMinutes / 60.0;
    final fraction = (hours / 9.0).clamp(0.0, 1.0);
    final percent = targetM > 0 ? (totalMinutes / targetM * 100).round() : 100;
    final status = service.getSleepStatus(totalMinutes);

    return Column(
      key: const ValueKey('daily_bars'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Single day bar representation
              SizedBox(
                width: 76,
                height: 120,
                child: Column(
                  children: [
                    SizedBox(
                      height: 18,
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            totalMinutes >= 60
                                ? '${totalMinutes ~/ 60}j ${totalMinutes % 60}m'
                                : '${totalMinutes}m',
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF265C45),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: fraction.clamp(0.12, 1.0),
                          widthFactor: 0.55,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF36785A), Color(0xFF265C45)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF36785A).withValues(alpha: 0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Hari Ini',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF265C45),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Detail metrics for today
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Capaian Target Ideal',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF134E4A).withValues(alpha: 0.6) : const Color(0xFFEDF7F2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$percent%',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF265C45),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: targetM > 0 ? (totalMinutes / targetM).clamp(0.0, 1.0) : 1.0,
                        minHeight: 8,
                        backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF36785A)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bedtime_outlined, size: 14, color: isDark ? const Color(0xFF58AF86) : const Color(0xFF36785A)),
                            const SizedBox(width: 4),
                            Text(
                              recs.isNotEmpty ? 'Tidur: ${recs.first.startTimeFormatted}' : '-',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.wb_sunny_outlined, size: 14, color: Color(0xFFEAB308)),
                            const SizedBox(width: 4),
                            Text(
                              recs.isNotEmpty ? 'Bangun: ${recs.last.endTimeFormatted}' : '-',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Status: $status (Target: ${targetM ~/ 60} jam)',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF58AF86) : const Color(0xFF265C45),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDailyEmptyState({required bool isDark}) {
    return Container(
      key: const ValueKey('daily_empty'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.nightlight_round,
                size: 26,
                color: Color(0xFFF59E0B),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada data tidur hari ini',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Catat perkiraan waktu tidur otomatis atau masukkan waktu tidur secara manual di bawah.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CARD TIPS ISTIRAHAT
  // ==========================================
  Widget _buildTipsSection({required bool isDark}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.lightbulb_rounded, color: Color(0xFFEAB308), size: 17),
            const SizedBox(width: 6),
            Text(
              'Tips Istirahat',
              style: GoogleFonts.poppins(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFF58AF86) : const Color(0xFF265C45),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEDF7F2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.transparent),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCheckItem('Hindari penggunaan gadget sebelum tidur', isDark: isDark),
              const SizedBox(height: 8),
              _buildCheckItem('Buat suasana kamar nyaman, tenang, dan gelap', isDark: isDark),
              const SizedBox(height: 8),
              _buildCheckItem('Usahakan tidur dan bangun di jam yang teratur setiap hari', isDark: isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckItem(String text, {required bool isDark}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(Icons.check_rounded, size: 15, color: isDark ? const Color(0xFF58AF86) : const Color(0xFF36785A)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF365E4C),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // CARD 3: Pengingat Waktu Tidur (Background Push Notification)
  // ==========================================
  Widget _buildSleepReminderCard({
    required SleepTrackingService service,
    required bool isDark,
  }) {
    final reminderTimeFormatted = SleepTrackingService.formatTimeOfDay(service.reminderTime);
    final bedtimeFormatted = SleepTrackingService.formatTimeOfDay(service.bedtimeTarget);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
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
                  color: isDark ? const Color(0xFF134E4A) : const Color(0xFFE2F1E8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.notifications_active_rounded,
                  size: 20,
                  color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF36785A),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Pengingat Waktu Tidur',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ),
              Switch(
                value: service.reminderEnabled,
                activeThumbColor: isDark ? const Color(0xFF58AF86) : const Color(0xFF36785A),
                activeTrackColor: isDark ? const Color(0xFF065F46) : null,
                onChanged: (val) async {
                  if (val) {
                    final granted = await service.requestNotificationPermission();
                    service.reminderEnabled = true;
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            granted
                                ? 'Pengingat aktif! Notifikasi dijadwalkan setiap malam pukul $reminderTimeFormatted.'
                                : 'Pengingat diaktifkan. Pastikan izin notifikasi diizinkan pada pengaturan sistem ponsel.',
                          ),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: const Color(0xFF36785A),
                        ),
                      );
                    }
                  } else {
                    service.reminderEnabled = false;
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pengingat waktu tidur dinonaktifkan.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Aplikasi akan mengirimkan notifikasi sistem secara otomatis 1 jam sebelum target waktu tidur agar Anda bersiap meletakkan gadget dan beristirahat.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),

          // Target Bedtime tile
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.bedtime_rounded,
              color: isDark ? const Color(0xFF58AF86) : const Color(0xFF36785A),
            ),
            title: Text(
              'Target Waktu Tidur',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            subtitle: Text(
              'Notifikasi aktif pada $reminderTimeFormatted (1 jam sebelumnya)',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            trailing: InkWell(
              onTap: service.reminderEnabled
                  ? () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: service.bedtimeTarget,
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
                                  ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        service.bedtimeTarget = picked;
                        if (mounted && service.reminderEnabled) {
                          final newReminderTime = SleepTrackingService.formatTimeOfDay(service.reminderTime);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Target tidur diatur ke ${SleepTrackingService.formatTimeOfDay(picked)}. Notifikasi pengingat dijadwalkan pukul $newReminderTime (1 jam sebelumnya).',
                              ),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: const Color(0xFF36785A),
                            ),
                          );
                        }
                      }
                    }
                  : null,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEDF7F2),
                  borderRadius: BorderRadius.circular(8),
                  border: isDark ? Border.all(color: const Color(0xFF334155)) : null,
                ),
                child: Text(
                  bedtimeFormatted,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF265C45),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),
          // Status Info Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: service.reminderEnabled
                  ? (isDark ? const Color(0xFF0F172A) : const Color(0xFFEDF7F2))
                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: service.reminderEnabled
                    ? (isDark ? const Color(0xFF334155) : const Color(0xFFA5D6C1))
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  service.reminderEnabled
                      ? Icons.check_circle_outline_rounded
                      : Icons.info_outline_rounded,
                  color: service.reminderEnabled
                      ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF265C45))
                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    service.reminderEnabled
                        ? 'Sistem pengingat aktif otomatis di latar belakang. Anda akan menerima notifikasi setiap malam pukul $reminderTimeFormatted.'
                        : 'Pengingat waktu tidur nonaktif. Aktifkan switch di atas untuk menjadwalkan notifikasi harian otomatis di sistem perangkat Anda.',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: service.reminderEnabled
                          ? (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF265C45))
                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      height: 1.45,
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
}

// =======================================================
// SLIVER PERSISTENT HEADER DELEGATE:
// Menampilkan banner visual jernih tanpa background hijau kusam.
// Saat di-scroll ke atas, bertransisi halus menjadi AppBar hijau
// brand ObeSight (0xFF489874) yang memuat judul dan tombol back.
// =======================================================
class _SleepCollapsibleHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double topPadding;
  final bool isDark;
  final VoidCallback onBack;

  _SleepCollapsibleHeaderDelegate({
    required this.topPadding,
    required this.isDark,
    required this.onBack,
  });

  @override
  double get minExtent => topPadding + 64.0;

  @override
  double get maxExtent => topPadding + 220.0;

  @override
  bool shouldRebuild(covariant _SleepCollapsibleHeaderDelegate oldDelegate) {
    return oldDelegate.topPadding != topPadding || oldDelegate.isDark != isDark;
  }

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double collapseRange = maxExtent - minExtent;
    final double t = collapseRange > 0 ? (shrinkOffset / collapseRange).clamp(0.0, 1.0) : 0.0;
    final backgroundColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF4F8F6);

    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Gambar Banner Visual Tidur Malam Bersih & HD
          if (t < 1.0)
            Positioned(
              top: -shrinkOffset * 0.7,
              left: 0,
              right: 0,
              height: topPadding + 220.0,
              child: Opacity(
                opacity: (1.0 - t * 1.2).clamp(0.0, 1.0),
                child: Image.asset(
                  'assets/progress/rest/hero_malam_hd.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    'assets/progress/rest/hero_malam_clean.png',
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      height: topPadding + 220.0,
                      color: const Color(0xFF1E4D3E),
                    ),
                  ),
                ),
              ),
            ),

          // 2. Gradient bayangan tipis pada banner bagian atas
          if (t < 0.8)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: topPadding + 80.0,
              child: Opacity(
                opacity: (1.0 - t * 1.4).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ),

          // 3. Pinned AppBar Hijau Brand ObeSight saat tergulung
          if (t > 0.0)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: topPadding + 64.0,
              child: Opacity(
                opacity: t,
                child: Container(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFF489874),
                ),
              ),
            ),

          // 4. Dasar Lembar Melengkung Bersih yang Menyatu dengan Body
          if (t < 1.0)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 24.0,
              child: Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28.0),
                  ),
                ),
              ),
            ),

          // 5. Judul & Ikon Bulan Sabit Transisi Mulus (Collapsible Title)
          Positioned(
            left: 20.0 + (58.0 - 20.0) * t,
            right: 16.0,
            top: (topPadding + 144.0) * (1.0 - t) + (topPadding + 18.0) * t,
            child: Row(
              children: [
                Container(
                  width: (30.0 + (22.0 - 30.0) * t),
                  height: (30.0 + (22.0 - 30.0) * t),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFEF3C7).withValues(alpha: (0.95 - 0.7 * t).clamp(0.0, 1.0)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: (0.25 * (1.0 - t)).clamp(0.0, 1.0)),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.nightlight_round,
                      size: (20.0 + (16.0 - 20.0) * t),
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'Waktu Tidur Malam',
                    style: GoogleFonts.poppins(
                      fontSize: (19.0 + (16.0 - 19.0) * t),
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: (0.75 * (1.0 - t) + 0.15 * t).clamp(0.0, 1.0)),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // 6. Tombol Kembali
          Positioned(
            top: topPadding + 12,
            left: 14,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onBack,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: t < 0.6
                      ? BoxDecoration(
                          color: Colors.white.withValues(alpha: (0.9 * (1.0 - t * 1.6)).clamp(0.0, 0.9)),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: (0.12 * (1.0 - t * 1.6)).clamp(0.0, 0.12)),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        )
                      : null,
                  child: Center(
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Color.lerp(const Color(0xFF265C45), Colors.white, t),
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
