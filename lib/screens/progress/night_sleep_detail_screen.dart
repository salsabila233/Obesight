import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/sleep_record_model.dart';
import '../../services/sleep_tracking_service.dart';
import '../../services/rest_reminder_service.dart';
import 'rest_reminder_setting_screen.dart';
import 'sleep_history_detail_screen.dart';
import 'sleep_record_form_screen.dart';

class NightSleepDetailScreen extends StatefulWidget {
  const NightSleepDetailScreen({super.key});

  @override
  State<NightSleepDetailScreen> createState() => _NightSleepDetailScreenState();
}

class _NightSleepDetailScreenState extends State<NightSleepDetailScreen> {
  void _openReminderSetting() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const RestReminderSettingScreen(type: RestType.night),
      ),
    );
  }

  void _openForm({SleepRecord? recordToEdit}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SleepRecordFormScreen(recordToEdit: recordToEdit),
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

  void _showSimulationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.phone_android_rounded, color: Color(0xFF36785A)),
            const SizedBox(width: 8),
            Text(
              'Simulasi Deteksi HP Mati',
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          'Fitur ini menyimulasikan kondisi HP tidak aktif selama lebih dari batas minimum (15 menit), misalnya dari pukul 22:30 hingga 06:15 (durasi 7 jam 45 menit).\n\nApakah Anda ingin menjalankan simulasi pencatatan otomatis?',
          style: GoogleFonts.poppins(fontSize: 12.5, height: 1.45, color: const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Batal', style: GoogleFonts.poppins(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3E8D6B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              final now = DateTime.now();
              final end = DateTime(now.year, now.month, now.day, 6, 15);
              final start = end.subtract(const Duration(hours: 7, minutes: 45));
              SleepTrackingService.instance.simulateInactivity(
                customStart: start,
                customEnd: end,
                durationMinutes: 465,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Simulasi berhasil: Terdeteksi perkiraan waktu tidur 22:30 – 06:15 (7j 45m)',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 12.5),
                  ),
                  backgroundColor: const Color(0xFF36785A),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text('Jalankan Simulasi', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SleepTrackingService.instance,
      builder: (context, _) {
        final service = SleepTrackingService.instance;
        final todayRecs = service.todayRecords;
        final hasTodayData = todayRecs.isNotEmpty;
        final totalMinutes = service.todayTotalMinutes;
        final awakeMinutes = service.todayAwakeMinutes;
        final statusText = service.getSleepStatus(totalMinutes);
        final pendingAuto = service.pendingAutoDetectedRecord;
        final summaries = service.getPast7DaysSummaries();

        // Primary start/end for today
        final firstStart = todayRecs.isNotEmpty ? todayRecs.first.startTimeFormatted : '22.00';
        final lastEnd = todayRecs.isNotEmpty ? todayRecs.last.endTimeFormatted : '06.00';
        final totalDurationFormatted = todayRecs.isNotEmpty
            ? (totalMinutes >= 60
                ? '${totalMinutes ~/ 60} j ${totalMinutes % 60} m'
                : '$totalMinutes m')
            : '-- j -- m';

        return Scaffold(
          backgroundColor: const Color(0xFFF3F6F8),
          body: Stack(
            children: [
              // Scrollable Body
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Hero Image Header (Night bedroom scene)
                    Stack(
                      children: [
                        SizedBox(
                          height: 245,
                          width: double.infinity,
                          child: Image.asset(
                            'assets/progress/rest/hero_malam.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Image.asset(
                              'assets/progress/clean/hero_malam.png',
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                height: 245,
                                color: const Color(0xFF1E4D3E),
                              ),
                            ),
                          ),
                        ),
                        // Gradient overlay at top for back button contrast
                        Container(
                          height: 90,
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
                      ],
                    ),

                    // 2. White Card with top rounded corners overlapping hero
                    Transform.translate(
                      offset: const Offset(0, -28),
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 10,
                              offset: Offset(0, -3),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row: Circle Moon Icon & Title
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 58,
                                  height: 58,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFE8F4EE),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0x14000000),
                                        blurRadius: 8,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/progress/rest/circle_malam.png',
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => Image.asset(
                                        'assets/progress/clean/circle_malam.png',
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, err, st) => Container(
                                          color: const Color(0xFFE2F1E8),
                                          child: const Icon(
                                            Icons.nightlight_round,
                                            color: Color(0xFFEAB308),
                                            size: 28,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    'Waktu Tidur Malam',
                                    style: GoogleFonts.poppins(
                                      fontSize: 17.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF235B42),
                                      height: 1.25,
                                    ),
                                  ),
                                ),
                                // Simulation trigger button for easy testing
                                IconButton(
                                  tooltip: 'Simulasi deteksi HP tidak aktif',
                                  icon: const Icon(Icons.flash_on_rounded, color: Color(0xFFEAB308), size: 22),
                                  onPressed: _showSimulationDialog,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Subtitle
                            Text(
                              'Tidur yang cukup dan teratur membantu metabolisme tubuh tetap seimbang.',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF4A705E),
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 18),

                            // --- CARD 1: Status Waktu Tidur Hari Ini (Matching Gambar 1 & 4) ---
                            _buildTodaySleepStatusCard(
                              service: service,
                              todayRecs: todayRecs,
                              hasTodayData: hasTodayData,
                              totalMinutes: totalMinutes,
                              totalDurationFormatted: totalDurationFormatted,
                              statusText: statusText,
                              pendingAuto: pendingAuto,
                            ),
                            const SizedBox(height: 14),

                            // --- CARD 2: 7 Hari Terakhir (Empty atau Bar Chart, tap buka Riwayat) ---
                            _build7DayOverviewCard(summaries, hasTodayData),
                            const SizedBox(height: 20),

                            // --- CARD 3: Info Ringkasan (Waktu Mulai, Bangun, Durasi, Waktu Terjaga) ---
                            _buildInfoCards(
                              startTimeStr: todayRecs.isNotEmpty ? firstStart : '22.00 - 23.00',
                              wakeTimeStr: todayRecs.isNotEmpty ? lastEnd : '05.00 - 06.00',
                              durationStr: todayRecs.isNotEmpty
                                  ? (totalMinutes >= 60
                                      ? '${totalMinutes ~/ 60} jam ${totalMinutes % 60} mnt'
                                      : '$totalMinutes mnt')
                                  : '7 - 8 jam',
                              awakeMinutes: awakeMinutes,
                            ),
                            const SizedBox(height: 20),

                            // --- CARD 4: Section Manfaat & Tips ---
                            _buildBenefitsSection(),
                            const SizedBox(height: 20),
                            _buildTipsSection(),
                            const SizedBox(height: 24),

                            // --- BOTTOM BUTTON: Masukkan Data / Tambah Data (Matching Gambar 1 & 4) ---
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
                                onPressed: () => _openForm(),
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
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF36785A),
                                  side: const BorderSide(color: Color(0xFF3E8D6B), width: 1.2),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                ),
                                onPressed: _openReminderSetting,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.alarm_on_rounded, size: 18, color: Color(0xFF36785A)),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Atur pengingat',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF36785A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Floating Back Button on Top Left
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 14,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Color(0xFF265C45),
                          size: 16,
                        ),
                      ),
                    ),
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
  // CARD 1: Status Waktu Tidur Hari Ini
  // ==========================================
  Widget _buildTodaySleepStatusCard({
    required SleepTrackingService service,
    required List<SleepRecord> todayRecs,
    required bool hasTodayData,
    required int totalMinutes,
    required String totalDurationFormatted,
    required String statusText,
    required SleepRecord? pendingAuto,
  }) {
    final now = DateTime.now();
    const monthNames = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final dateStr = 'Hari ini, ${now.day} ${monthNames[now.month]} ${now.year}';

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row: Icon, Title, Date, Big Duration & Action Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Circular Moon Badge
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE2F1E8),
                ),
                child: const Center(
                  child: Icon(
                    Icons.nightlight_round,
                    size: 24,
                    color: Color(0xFF36785A),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Title, Date, Duration
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Waktu tidur',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    Text(
                      dateStr,
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      totalDurationFormatted,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (hasTodayData)
                      Text(
                        '${todayRecs.first.startTimeFormatted.replaceAll(':', '.')} - ${todayRecs.last.endTimeFormatted.replaceAll(':', '.')}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF36785A),
                        ),
                      )
                    else
                      Text(
                        'Rekam tidur Anda untuk melihat polanya dan mengelola tidur Anda.',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                          height: 1.35,
                        ),
                      ),
                  ],
                ),
              ),

              // Action button / pill on right: "Catat waktu ini" (Matching Gambar 1)
              if (pendingAuto != null)
                InkWell(
                  onTap: () {
                    service.acceptPendingAutoRecord();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Perkiraan waktu tidur (${pendingAuto.timeRangeFormatted}) berhasil dicatat.',
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                        ),
                        backgroundColor: const Color(0xFF36785A),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2F1E8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF36785A), width: 1.2),
                    ),
                    child: Text(
                      'Catat waktu ini',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF265C45),
                      ),
                    ),
                  ),
                )
              else if (hasTodayData)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF7F2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF265C45),
                    ),
                  ),
                ),
            ],
          ),

          // Multi-period breakdown if multiple records exist today (Section 5 of prompt)
          if (todayRecs.length > 1) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 10),
            Text(
              'Rincian Periode Tidur Hari Ini:',
              style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFF334155)),
            ),
            const SizedBox(height: 6),
            ...todayRecs.asMap().entries.map((entry) {
              final idx = entry.key;
              final rec = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 6, color: Color(0xFF36785A)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Periode ${idx + 1}: ${rec.timeRangeFormatted} (${rec.durationFormatted})',
                        style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFF475569)),
                      ),
                    ),
                    InkWell(
                      onTap: () => _openForm(recordToEdit: rec),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(Icons.edit_outlined, size: 15, color: Color(0xFF64748B)),
                      ),
                    ),
                    InkWell(
                      onTap: () => service.deleteRecord(rec.id),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(Icons.delete_outline_rounded, size: 15, color: Color(0xFFEF4444)),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          const SizedBox(height: 10),
          // Disclaimer Label (Section 2 & 15 of prompt)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF94A3B8)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Perkiraan waktu tidur berdasarkan aktivitas perangkat, bukan hasil pengukuran medis.',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: const Color(0xFF64748B),
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
  // CARD 2: Waktu Tidur 7 Hari Terakhir
  // ==========================================
  Widget _build7DayOverviewCard(List<DailySleepSummary> summaries, bool hasTodayData) {
    final hasAnyData = hasTodayData;

    return InkWell(
      onTap: _openHistoryDetail,
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
            // Header Row with Arrow >
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Waktu tidur selama 7 hari terakhir',
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
            const SizedBox(height: 16),

            if (!hasAnyData) ...[
              // Empty State Illustration (Matching Gambar 1)
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFF1F5F9),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                            Icons.nightlight_round,
                            size: 32,
                            color: Color(0xFFCBD5E1),
                          ),
                          Positioned(
                            top: 14,
                            right: 14,
                            child: Text(
                              'z z',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Belum ada data tidur',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Axis days
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: summaries.map((s) {
                  return Text(
                    s.dayNumber,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: s.isToday ? FontWeight.w700 : FontWeight.w500,
                      color: s.isToday ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
                    ),
                  );
                }).toList(),
              ),
            ] else ...[
              // Saved State: Real Bar Chart (Matching Gambar 4)
              SizedBox(
                height: 110,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: summaries.map((s) {
                    final hours = s.totalMinutes / 60.0;
                    final barH = (hours / 9.0 * 68.0).clamp(s.hasData ? 14.0 : 4.0, 68.0);
                    final isHighlighted = s.isToday;

                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (s.hasData)
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                s.formattedDuration,
                                style: GoogleFonts.poppins(
                                  fontSize: 8.5,
                                  fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
                                  color: isHighlighted ? const Color(0xFF265C45) : const Color(0xFF475569),
                                ),
                              ),
                            )
                          else
                            const SizedBox(height: 12),
                          const SizedBox(height: 4),

                          Container(
                            width: 14,
                            height: barH,
                            decoration: BoxDecoration(
                              color: s.hasData
                                  ? (isHighlighted ? const Color(0xFF265C45) : const Color(0xFFA5D6C1))
                                  : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 6),

                          Text(
                            s.dayNumber,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
                              color: isHighlighted ? const Color(0xFF265C45) : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================
  // CARD 3: Info Waktu Tidur, Bangun, Durasi, Terjaga
  // ==========================================
  Widget _buildInfoCards({
    required String startTimeStr,
    required String wakeTimeStr,
    required String durationStr,
    required int awakeMinutes,
  }) {
    return Column(
      children: [
        Row(
          children: [
            // Card 1: Waktu Mulai Tidur
            Expanded(
              child: _buildSingleInfoTile(
                icon: Icons.bed_rounded,
                title: 'Waktu Tidur',
                value: startTimeStr,
              ),
            ),
            const SizedBox(width: 8),

            // Card 2: Waktu Bangun
            Expanded(
              child: _buildSingleInfoTile(
                icon: Icons.wb_sunny_outlined,
                title: 'Waktu Bangun',
                value: wakeTimeStr,
              ),
            ),
            const SizedBox(width: 8),

            // Card 3: Durasi Tidur
            Expanded(
              child: _buildSingleInfoTile(
                icon: Icons.nightlight_round,
                title: 'Durasi Tidur',
                value: durationStr,
              ),
            ),
          ],
        ),
        if (awakeMinutes > 0) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.remove_red_eye_outlined, size: 16, color: Color(0xFFD97706)),
                const SizedBox(width: 8),
                Text(
                  'Waktu terjaga di antara periode tidur: $awakeMinutes menit',
                  style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF92400E)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSingleInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF7F2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF36785A)),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 9.5,
              color: const Color(0xFF4A705E),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF265C45),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CARD 4: Manfaat & Tips
  // ==========================================
  Widget _buildBenefitsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.spa_rounded, color: Color(0xFF36785A), size: 17),
            const SizedBox(width: 6),
            Text(
              'Manfaat',
              style: GoogleFonts.poppins(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF265C45),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEDF7F2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCheckItem('Menjaga metabolisme dan hormon tubuh'),
              const SizedBox(height: 8),
              _buildCheckItem('Mengurangi stress dan keinginan makan berlebih'),
              const SizedBox(height: 8),
              _buildCheckItem('Membantu pembakaran lemak lebih optimal'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipsSection() {
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
                color: const Color(0xFF265C45),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEDF7F2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCheckItem('Hindari gadget sebelum tidur'),
              const SizedBox(height: 8),
              _buildCheckItem('Buat suasana kamar yang nyaman dan gelap'),
              const SizedBox(height: 8),
              _buildCheckItem('Tidur dan bangun di jam yang sama setiap hari'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.check_rounded, size: 15, color: Color(0xFF36785A)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF365E4C),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
