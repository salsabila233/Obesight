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
  // 0: Jam, 1: Hari, 2: Minggu, 3: Bulan (default: Hari matching Gambar 1 & 4)
  int _selectedFilterTab = 1;

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
            Expanded(
              child: Text(
                'Simulasi Deteksi HP Mati',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          'Fitur ini menyimulasikan deteksi otomatis durasi tidur berdasarkan aktivitas perangkat (sesi terakhir menutup HP di malam hari pukul 22:30 hingga membuka HP di pagi hari pukul 06:15, durasi 7 jam 45 menit).\n\nApakah Anda ingin menjalankan simulasi pencatatan otomatis?',
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
    final topPadding = MediaQuery.of(context).padding.top;

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

        // Tampilan durasi hari ini
        final String totalDurationFormatted;
        if (hasTodayData) {
          totalDurationFormatted = totalMinutes >= 60
              ? '${totalMinutes ~/ 60} j ${totalMinutes % 60} m'
              : '$totalMinutes m';
        } else if (pendingAuto != null) {
          // Durasi estimasi otomatis perangkat (sesuai Gambar 1: 5 j 10 m)
          final h = pendingAuto.durationHours;
          final m = pendingAuto.durationRemainingMinutes;
          totalDurationFormatted = '$h j $m m';
        } else {
          totalDurationFormatted = '-- j -- m';
        }

        final firstStart = hasTodayData
            ? todayRecs.first.startTimeFormatted
            : (pendingAuto != null ? pendingAuto.startTimeFormatted : '22.00');
        final lastEnd = hasTodayData
            ? todayRecs.last.endTimeFormatted
            : (pendingAuto != null ? pendingAuto.endTimeFormatted : '06.00');

        return Scaffold(
          backgroundColor: const Color(0xFFF3F6F8),
          body: Stack(
            children: [
              // Main CustomScrollView with Sticky Header
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 1. Hero Image Header (Aset bersih hero_malam_clean.png)
                  SliverToBoxAdapter(
                    child: Stack(
                      children: [
                        SizedBox(
                          height: 245,
                          width: double.infinity,
                          child: Image.asset(
                            'assets/progress/rest/hero_malam_clean.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Image.asset(
                              'assets/progress/clean/hero_malam_clean.png',
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Image.asset(
                                'assets/progress/rest/hero_malam.png',
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, st) => Container(
                                  height: 245,
                                  color: const Color(0xFF1E4D3E),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Gradient bayangan tipis di bagian atas
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
                        // Unpinned Back Button (Hanya tampil saat hero terlihat)
                        Positioned(
                          top: topPadding + 8,
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
                  ),

                  // 2. Sticky Header Judul "Waktu Tidur Malam"
                  // Menetap di atas saat halaman di-scroll ke atas
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _NightSleepStickyHeaderDelegate(
                      topPadding: topPadding,
                      onBack: () => Navigator.of(context).pop(),
                      onSimulate: _showSimulationDialog,
                    ),
                  ),

                  // 3. Konten Utama
                  SliverToBoxAdapter(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),

                          // --- CARD 1: Status Waktu Tidur Hari Ini (Matching Gambar 1 & 4) ---
                          _buildTodaySleepStatusCard(
                            service: service,
                            todayRecs: todayRecs,
                            hasTodayData: hasTodayData,
                            totalDurationFormatted: totalDurationFormatted,
                            statusText: statusText,
                            pendingAuto: pendingAuto,
                          ),
                          const SizedBox(height: 16),

                          // --- CARD 2: Grafik Riwayat Tidur (Opsi: Jam, Hari, Minggu, Bulan) ---
                          _buildHistoryChartCard(
                            service: service,
                            summaries: summaries,
                            hasTodayData: hasTodayData,
                          ),
                          const SizedBox(height: 20),

                          // --- CARD 3: Info Ringkasan (Waktu Mulai, Bangun, Durasi, Waktu Terjaga) ---
                          _buildInfoCards(
                            startTimeStr: firstStart,
                            wakeTimeStr: lastEnd,
                            durationStr: hasTodayData
                                ? (totalMinutes >= 60
                                    ? '${totalMinutes ~/ 60} jam ${totalMinutes % 60} mnt'
                                    : '$totalMinutes mnt')
                                : (pendingAuto != null
                                    ? '${pendingAuto.durationHours} jam ${pendingAuto.durationRemainingMinutes} mnt'
                                    : '7 - 8 jam'),
                            awakeMinutes: awakeMinutes,
                          ),
                          const SizedBox(height: 20),

                          // --- CARD 4: Manfaat & Tips ---
                          _buildBenefitsSection(),
                          const SizedBox(height: 20),
                          _buildTipsSection(),
                          const SizedBox(height: 28),

                          // --- TOMBOL UTAMA: Masukkan Data (Pill Hijau dengan ikon (+)) ---
                          // Tombol "Atur Pengingat" telah dihapus sesuai ketentuan
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3E8D6B),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                                elevation: 1,
                              ),
                              onPressed: () => _openForm(),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.alarm_add_rounded,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Masukkan data',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge Bulan Sabit Hijau
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

              // Info Waktu Tidur & Durasi
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Waktu Tidur',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
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
                    Text(
                      totalDurationFormatted,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (hasTodayData)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '${todayRecs.first.startTimeFormatted.replaceAll(':', '.')} - ${todayRecs.last.endTimeFormatted.replaceAll(':', '.')}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF36785A),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Tombol Aksi Pill "Catat waktu ini" (Matching Gambar 1)
              if (pendingAuto != null && !hasTodayData)
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Catat waktu ini',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
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

          // Jika ada lebih dari satu periode tidur hari ini
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
          // Label Disclaimer
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
  // CARD 2: Grafik Riwayat Tidur
  // Opsi: Jam | Hari | Minggu | Bulan
  // Bebas dari error bottom overflowed menggunakan flexible layout
  // ==========================================
  Widget _buildHistoryChartCard({
    required SleepTrackingService service,
    required List<DailySleepSummary> summaries,
    required bool hasTodayData,
  }) {
    String cardTitle;
    switch (_selectedFilterTab) {
      case 0:
        cardTitle = 'Distribusi tidur per jam hari ini';
        break;
      case 2:
        cardTitle = 'Waktu tidur selama 4 minggu terakhir';
        break;
      case 3:
        cardTitle = 'Waktu tidur selama 6 bulan terakhir';
        break;
      case 1:
      default:
        cardTitle = 'Waktu tidur selama 7 hari terakhir';
        break;
    }

    return Container(
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
          // Header Row with Arrow > (buka riwayat lengkap)
          InkWell(
            onTap: _openHistoryDetail,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    cardTitle,
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
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Segmented Tabs: [ Jam | Hari | Minggu | Bulan ]
          _buildSegmentedFilterTabs(),
          const SizedBox(height: 16),

          // Konten Grafik berdasarkan tab terpilih
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _buildChartContentForTab(
              tabIndex: _selectedFilterTab,
              service: service,
              summaries: summaries,
              hasTodayData: hasTodayData,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedFilterTabs() {
    final tabs = ['Jam', 'Hari', 'Minggu', 'Bulan'];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final idx = entry.key;
          final title = entry.value;
          final isSelected = _selectedFilterTab == idx;

          return Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedFilterTab = idx;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF36785A) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChartContentForTab({
    required int tabIndex,
    required SleepTrackingService service,
    required List<DailySleepSummary> summaries,
    required bool hasTodayData,
  }) {
    switch (tabIndex) {
      case 0:
        // Tab Jam (Per Jam 24 jam)
        return _buildHourlyChart(service);
      case 2:
        // Tab Minggu (4 Minggu terakhir)
        return _buildWeeklyChart(service);
      case 3:
        // Tab Bulan (6 Bulan terakhir)
        return _buildMonthlyChart(service);
      case 1:
      default:
        // Tab Hari (7 Hari Terakhir)
        if (!hasTodayData) {
          // Empty State Illustration saat belum ada data tidur hari ini (Matching Gambar 1)
          return Column(
            key: const ValueKey('daily_empty'),
            children: [
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
                      'Belum ada data tidur hari ini',
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
              // Axis days horizontal (18 19 20 21 22 23 24)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: summaries.map((s) {
                  return Text(
                    s.dayNumber,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: s.isToday ? FontWeight.w700 : FontWeight.w500,
                      color: s.isToday ? const Color(0xFF265C45) : const Color(0xFF94A3B8),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        } else {
          // Bar Chart 7 Hari yang fleksibel (tidak pernah overflow)
          return _buildDailyBarChart(summaries);
        }
    }
  }

  // ==========================================
  // KOMPONEN BAR CHART FLEKSIBEL (NO OVERFLOW)
  // ==========================================
  Widget _buildDailyBarChart(List<DailySleepSummary> summaries) {
    return SizedBox(
      key: const ValueKey('daily_bars'),
      height: 135,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: summaries.map((s) {
          final hours = s.totalMinutes / 60.0;
          final fraction = (hours / 9.0).clamp(0.0, 1.0);
          final isHighlighted = s.isToday;

          return _buildFlexibleBar(
            topLabel: s.hasData ? s.formattedDuration : '',
            bottomLabel: s.dayNumber,
            fraction: fraction,
            isHighlighted: isHighlighted,
            hasData: s.hasData,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHourlyChart(SleepTrackingService service) {
    final now = DateTime.now();
    final hourly = service.getHourlySleepForDate(now);

    // Tampilkan jam tidur malam - pagi yang relevan (20.00 hingga 08.00)
    // yaitu jam 20, 21, 22, 23, 0, 1, 2, 3, 4, 5, 6, 7, 8
    final relevantHours = [20, 21, 22, 23, 0, 1, 2, 3, 4, 5, 6, 7, 8];
    final selectedHourly = relevantHours.map((h) => hourly[h]).toList();

    return Column(
      key: const ValueKey('hourly_chart'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 135,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: selectedHourly.map((h) {
              final isHighlighted = h.isAsleep;
              return _buildFlexibleBar(
                topLabel: h.minutesSlept > 0 ? '${h.minutesSlept}m' : '',
                bottomLabel: h.hour.toString().padLeft(2, '0'),
                fraction: h.fraction,
                isHighlighted: isHighlighted,
                hasData: h.isAsleep,
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            'Rentang waktu istirahat malam (20.00 – 08.00)',
            style: GoogleFonts.poppins(fontSize: 10.5, color: const Color(0xFF64748B)),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart(SleepTrackingService service) {
    final weeks = service.getPast4WeeksSummaries();
    return SizedBox(
      key: const ValueKey('weekly_chart'),
      height: 135,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: weeks.map((w) {
          final hours = w.averageMinutesPerDay / 60.0;
          final fraction = (hours / 9.0).clamp(0.0, 1.0);
          final isHighlighted = w.isCurrentWeek;

          return _buildFlexibleBar(
            topLabel: w.hasData ? w.formattedAverage : '',
            bottomLabel: w.weekLabel,
            fraction: fraction,
            isHighlighted: isHighlighted,
            hasData: w.hasData,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthlyChart(SleepTrackingService service) {
    final months = service.getPastMonthsSummaries(6);
    return SizedBox(
      key: const ValueKey('monthly_chart'),
      height: 135,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: months.map((m) {
          final hours = m.averageMinutesPerDay / 60.0;
          final fraction = (hours / 9.0).clamp(0.0, 1.0);
          final isHighlighted = m.isCurrentMonth;

          return _buildFlexibleBar(
            topLabel: m.hasData ? m.formattedAverage : '',
            bottomLabel: m.monthLabel,
            fraction: fraction,
            isHighlighted: isHighlighted,
            hasData: m.hasData,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFlexibleBar({
    required String topLabel,
    required String bottomLabel,
    required double fraction,
    required bool isHighlighted,
    required bool hasData,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          children: [
            // Label durasi di atas bar
            SizedBox(
              height: 18,
              child: Center(
                child: hasData && topLabel.isNotEmpty
                    ? FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          topLabel,
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
                            color: isHighlighted ? const Color(0xFF265C45) : const Color(0xFF475569),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 4),

            // Track Bar: Menggunakan Expanded dan FractionallySizedBox sehingga kebal overflow
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: hasData ? fraction.clamp(0.08, 1.0) : 0.04,
                  widthFactor: 0.55,
                  child: Container(
                    decoration: BoxDecoration(
                      color: hasData
                          ? (isHighlighted ? const Color(0xFF265C45) : const Color(0xFFA5D6C1))
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Label sumbu X di bawah bar
            SizedBox(
              height: 20,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    bottomLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
                      color: isHighlighted ? const Color(0xFF265C45) : const Color(0xFF94A3B8),
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
            Expanded(
              child: _buildSingleInfoTile(
                icon: Icons.bed_rounded,
                title: 'Waktu Tidur',
                value: startTimeStr,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSingleInfoTile(
                icon: Icons.wb_sunny_outlined,
                title: 'Waktu Bangun',
                value: wakeTimeStr,
              ),
            ),
            const SizedBox(width: 8),
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

// =======================================================
// SLIVER PERSISTENT HEADER DELEGATE: STICKY HEADER EFEK
// Teks judul "Waktu Tidur Malam" bergerak naik dan menetap
// di bagian atas saat di-scroll ke atas
// =======================================================
class _NightSleepStickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double topPadding;
  final VoidCallback onBack;
  final VoidCallback onSimulate;

  _NightSleepStickyHeaderDelegate({
    required this.topPadding,
    required this.onBack,
    required this.onSimulate,
  });

  @override
  double get minExtent => topPadding + 56.0;

  @override
  double get maxExtent => topPadding + 138.0;

  @override
  bool shouldRebuild(covariant _NightSleepStickyHeaderDelegate oldDelegate) {
    return oldDelegate.topPadding != topPadding;
  }

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double collapseRange = maxExtent - minExtent;
    final double t = (shrinkOffset / (collapseRange > 0 ? collapseRange : 1.0)).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular((1.0 - t) * 28.0),
        ),
        boxShadow: t > 0.15
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06 * t),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          // 1. Tampilan saat belum di-scroll / expanded (t mendekati 0.0)
          if (t < 0.95)
            Positioned.fill(
              child: Opacity(
                opacity: (1.0 - t * 1.2).clamp(0.0, 1.0),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                      Row(
                        children: [
                          // Lingkaran Ikon Bulan
                          Container(
                            width: 52,
                            height: 52,
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
                                      size: 26,
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
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF235B42),
                                height: 1.25,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Simulasi deteksi HP tidak aktif',
                            icon: const Icon(Icons.flash_on_rounded, color: Color(0xFFEAB308), size: 22),
                            onPressed: onSimulate,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tidur yang cukup dan teratur membantu metabolisme tubuh tetap seimbang.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF4A705E),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Tampilan Sticky Header saat di-scroll ke atas (t mendekati 1.0)
          // Menetap di atas, di bawah status bar / AppBar
          if (t > 0.15)
            Positioned(
              top: topPadding,
              left: 0,
              right: 0,
              height: 56,
              child: Opacity(
                opacity: ((t - 0.15) / 0.85).clamp(0.0, 1.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Color(0xFF235B42),
                          size: 18,
                        ),
                        onPressed: onBack,
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFE8F4EE),
                        ),
                        child: const Icon(
                          Icons.nightlight_round,
                          color: Color(0xFFEAB308),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Waktu Tidur Malam',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF235B42),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Simulasi deteksi HP',
                        icon: const Icon(Icons.flash_on_rounded, color: Color(0xFFEAB308), size: 20),
                        onPressed: onSimulate,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
