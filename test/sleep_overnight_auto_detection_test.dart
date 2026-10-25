import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:obesight/models/sleep_record_model.dart';
import 'package:obesight/screens/progress/night_sleep_detail_screen.dart';
import 'package:obesight/services/sleep_tracking_service.dart';
import 'package:obesight/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SleepTrackingService.instance.clearAll();
  });

  group('Uji Menyeluruh Deteksi Otomatis Tidur Malam & Integrasi Grafik', () {
    // -------------------------------------------------------------------------
    // 1. Deteksi Semalam (22:30 -> 06:15) = 465 menit (7j 45m), rollover tengah malam
    // -------------------------------------------------------------------------
    test('1. Perkiraan waktu tidur 22.30 hingga 06.15 menghasilkan durasi tepat 465 menit', () {
      final nightOff = DateTime(2026, 10, 24, 22, 30);
      final morningOn = DateTime(2026, 10, 25, 6, 15);

      final candidate = SleepTrackingService.instance.detectSleepFromSensors(
        screenOff: nightOff,
        screenOn: morningOn,
        darkTime: nightOff,
        lightRiseTime: morningOn,
        referenceNow: morningOn,
      );

      expect(candidate, isNotNull);
      expect(candidate!.durationMinutes, 465); // 7 * 60 + 45 = 465
      expect(candidate.durationHours, 7);
      expect(candidate.durationRemainingMinutes, 45);
      expect(candidate.source, 'automatic');
      expect(candidate.date, '2026-10-25');
      expect(candidate.shortDurationFormatted, '7j 45m');

      // Verifikasi penyesuaian sensor ambient light jika kamar gelap 5 menit setelah layar mati (22:35) dan terang 5 menit sebelum layar aktif (06:10)
      final candidateWithSensorOffset = SleepTrackingService.instance.detectSleepFromSensors(
        screenOff: nightOff,
        screenOn: morningOn,
        darkTime: nightOff.add(const Duration(minutes: 5)),
        lightRiseTime: morningOn.subtract(const Duration(minutes: 5)),
        referenceNow: morningOn,
      );
      expect(candidateWithSensorOffset, isNotNull);
      expect(candidateWithSensorOffset!.durationMinutes, 455); // 465 - 10 = 455
    });

    // -------------------------------------------------------------------------
    // 2. Fallback Sensor Cahaya Tidak Tersedia: Hanya gunakan sinyal layar & interaksi
    // -------------------------------------------------------------------------
    test('2. Deteksi tetap berhasil tanpa sensor ambient light (fallback screen & interaction)', () {
      final nightOff = DateTime(2026, 10, 24, 23, 0);
      final morningOn = DateTime(2026, 10, 25, 6, 30);

      final candidate = SleepTrackingService.instance.detectSleepFromSensors(
        screenOff: nightOff,
        screenOn: morningOn,
        darkTime: null, // Sensor cahaya absen/tidak didukung
        lightRiseTime: null,
        referenceNow: morningOn,
      );

      expect(candidate, isNotNull);
      expect(candidate!.durationMinutes, 450); // 7.5 jam = 450 menit
      expect(candidate.startTime, nightOff);
      expect(candidate.endTime, morningOn);
      expect(candidate.source, 'automatic');
    });

    // -------------------------------------------------------------------------
    // 3. Waktu bangun TIDAK dihitung berdasarkan waktu buka aplikasi (harus null jika sinyal perangkat belum ada)
    // -------------------------------------------------------------------------
    test('3. Waktu bangun tidak dihitung dari waktu buka aplikasi (harus null jika sinyal perangkat belum ada)', () {
      final nightOff = DateTime(2026, 10, 24, 23, 15);
      final appOpenTime = DateTime(2026, 10, 25, 7, 0);

      final candidate = SleepTrackingService.instance.detectSleepFromSensors(
        screenOff: nightOff,
        screenOn: null, // Perangkat belum merekam screenOn di pagi hari
        darkTime: null,
        lightRiseTime: null,
        referenceNow: appOpenTime, // Aplikasi dibuka jam 07:00 pagi
      );

      // Tidak boleh membuat data tidur palsu hanya karena pengguna membuka aplikasi
      expect(candidate, isNull);
    });

    // -------------------------------------------------------------------------
    // 4. Validasi batas durasi tidur: tolak durasi < 180 menit atau > 840 menit
    // -------------------------------------------------------------------------
    test('4. Tolak kandidat otomatis tidak wajar (< 3 jam atau > 14 jam)', () {
      final night = DateTime(2026, 10, 25, 2, 0);
      final wakeTooShort = DateTime(2026, 10, 25, 3, 30); // 1.5 jam = 90 menit

      final candidateShort = SleepTrackingService.instance.detectSleepFromSensors(
        screenOff: night,
        screenOn: wakeTooShort,
        referenceNow: wakeTooShort,
      );
      expect(candidateShort, isNull);

      final nightStart = DateTime(2026, 10, 24, 18, 0);
      final wakeTooLong = DateTime(2026, 10, 25, 12, 0); // 18 jam
      final candidateLong = SleepTrackingService.instance.detectSleepFromSensors(
        screenOff: nightStart,
        screenOn: wakeTooLong,
        referenceNow: wakeTooLong,
      );
      expect(candidateLong, isNull);
    });

    // -------------------------------------------------------------------------
    // 5. Inaktivitas malam hari dari Flutter SharedPreferences jika native 0
    // -------------------------------------------------------------------------
    test('5. Menggunakan Flutter lastInactivityTime jika native screenOff kosong', () {
      final flutterNightInactive = DateTime(2026, 10, 24, 22, 45);
      final morningWake = DateTime(2026, 10, 25, 6, 15);

      final candidate = SleepTrackingService.instance.detectSleepFromSensors(
        screenOff: null,
        screenOn: morningWake,
        lastInactivityTime: flutterNightInactive,
        referenceNow: morningWake,
      );

      expect(candidate, isNotNull);
      expect(candidate!.startTime, flutterNightInactive);
      expect(candidate.durationMinutes, 450); // 7 jam 30 menit
    });

    // -------------------------------------------------------------------------
    // 6. Perlindungan data manual: Kandidat otomatis tidak menimpa manual confirmed
    // -------------------------------------------------------------------------
    test('6. Data manual yang sudah dicatat tidak tertimpa otomatis tanpa konfirmasi pengguna', () async {
      final service = SleepTrackingService.instance;
      final now = DateTime(2026, 10, 25, 8, 0);
      final dateKey = SleepTrackingService.formatDateKey(now);

      final manualRec = SleepRecord(
        id: 'manual_rec_user',
        userId: service.currentUserId,
        date: dateKey,
        startTime: DateTime(2026, 10, 24, 23, 0),
        endTime: DateTime(2026, 10, 25, 6, 0),
        durationMinutes: 420,
        source: 'manual',
        isConfirmed: true,
      );
      await service.addRecord(manualRec);

      // Coba masukkan auto record yang belum diverifikasi
      final autoRec = SleepRecord(
        id: 'auto_unverified',
        userId: service.currentUserId,
        date: dateKey,
        startTime: DateTime(2026, 10, 24, 22, 0),
        endTime: DateTime(2026, 10, 25, 5, 0),
        durationMinutes: 420,
        source: 'automatic',
        isConfirmed: false,
      );
      await service.addRecord(autoRec);

      // Data manual tetap dipertahankan
      final records = service.getRecordsForDate(now);
      expect(records.length, 1);
      expect(records.first.id, 'manual_rec_user');
      expect(records.first.source, 'manual');
    });

    // -------------------------------------------------------------------------
    // 7. Tombol 'Catat waktu ini': Validasi, update state & UI tanpa restart
    // -------------------------------------------------------------------------
    testWidgets('7. Tombol Catat waktu ini menyimpan kandidat dan langsung memperbarui UI', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final service = SleepTrackingService.instance;
      final now = DateTime.now();
      final dateKey = SleepTrackingService.formatDateKey(now);

      final candidate = SleepRecord(
        id: 'candidate_auto_2230_0615',
        userId: service.currentUserId,
        date: dateKey,
        startTime: DateTime(now.year, now.month, now.day - 1, 22, 30),
        endTime: DateTime(now.year, now.month, now.day, 6, 15),
        durationMinutes: 465,
        source: 'automatic',
        isConfirmed: false,
      );
      service.setPendingAutoRecord(candidate);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const NightSleepDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // UI menampilkan perkiraan 7 j 45 m dan tombol Catat waktu ini
      expect(find.text('7 j 45 m'), findsOneWidget);
      final catatBtn = find.text('Catat waktu ini');
      expect(catatBtn, findsOneWidget);

      // Tekan tombol Catat waktu ini
      await tester.tap(catatBtn);
      await tester.pumpAndSettle();

      // State langsung terupdate
      expect(service.pendingAutoDetectedRecord, isNull);
      expect(service.todayRecords.length, 1);
      expect(service.todayRecords.first.durationMinutes, 465);
      expect(service.todayTotalMinutes, 465);

      // Tombol berubah status menjadi tercatat
      expect(find.text('Tercatat'), findsOneWidget);

      // Grafik langsung aktif (daily_bars ditampilkan)
      expect(find.byKey(const ValueKey('daily_bars')), findsOneWidget);
      expect(find.byKey(const ValueKey('daily_empty')), findsNothing);
    });

    // -------------------------------------------------------------------------
    // 8. Tekan 'Catat waktu ini' saat tidak ada data: feedback jelas ke input manual
    // -------------------------------------------------------------------------
    testWidgets('8. Menekan Catat waktu ini saat data kosong memberi arahan input manual', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await SleepTrackingService.instance.clearAll();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const NightSleepDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final catatBtn = find.text('Catat waktu ini');
      expect(catatBtn, findsOneWidget);

      await tester.tap(catatBtn);
      await tester.pump();

      // Feedback peringatan muncul mengarahkan ke Masukkan data
      expect(find.textContaining('Data perkiraan waktu tidur belum tersedia'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // 9. Integrasi Riwayat 7 Hari & SleepHistoryDetailScreen konsisten
    // -------------------------------------------------------------------------
    test('9. Riwayat 7 hari terpetakan akurat tanpa pergeseran atau duplikasi tanggal', () async {
      final service = SleepTrackingService.instance;
      final baseDate = DateTime(2026, 10, 25, 9, 0);

      // Catat 3 sesi tidur pada 3 hari berbeda
      for (int i = 0; i < 3; i++) {
        final d = baseDate.subtract(Duration(days: i));
        final rec = SleepRecord(
          id: 'rec_day_$i',
          userId: service.currentUserId,
          date: SleepTrackingService.formatDateKey(d),
          startTime: DateTime(d.year, d.month, d.day - 1, 23, 0),
          endTime: DateTime(d.year, d.month, d.day, 6, 30),
          durationMinutes: 450,
          source: 'automatic',
        );
        await service.addRecord(rec);
      }

      final summaries = service.getPast7DaysSummaries(baseDate);
      expect(summaries.length, 7);

      // 3 hari terakhir (H-0, H-1, H-2) terisi data
      expect(summaries[6].hasData, isTrue); // Hari ini
      expect(summaries[6].totalMinutes, 450);
      expect(summaries[5].hasData, isTrue); // H-1
      expect(summaries[5].totalMinutes, 450);
      expect(summaries[4].hasData, isTrue); // H-2
      expect(summaries[4].totalMinutes, 450);

      // Hari sebelumnya kosong
      expect(summaries[0].hasData, isFalse);
      expect(summaries[1].hasData, isFalse);
      expect(summaries[2].hasData, isFalse);
      expect(summaries[3].hasData, isFalse);
    });
  });
}
