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

  void setPhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('Uji Logika Perekaman Waktu Tidur Otomatis & Standar Halodoc (7–9 Jam)', () {
    final service = SleepTrackingService.instance;

    // =========================================================================
    // 1. Logika Deteksi Perekaman Tidur Otomatis Berdasarkan Aktivitas Perangkat
    // =========================================================================
    test('1.1. Mulai tidur diambil dari layar mati malam (screenOff) & bangun dari layar nyala pagi (screenOn)', () {
      final nightOff = DateTime(2026, 11, 10, 22, 30); // 22:30 malam
      final morningOn = DateTime(2026, 11, 11, 6, 15);  // 06:15 pagi

      final detected = service.detectSleepFromSensors(
        screenOff: nightOff,
        screenOn: morningOn,
        referenceNow: DateTime(2026, 11, 11, 7, 0),
      );

      expect(detected, isNotNull);
      expect(detected!.startTime, nightOff);
      expect(detected.endTime, morningOn);
      expect(detected.durationMinutes, 465); // 7 jam 45 menit
      expect(detected.durationHours, 7);
      expect(detected.durationRemainingMinutes, 45);
      expect(detected.source, 'automatic');
    });

    test('1.2. Multi-sesi dengan jeda layar menyala di tengah malam: mengambil longest continuous sleep session', () {
      // Pengguna mematikan layar pukul 22:00
      // Bangun sejenak cek ponsel pukul 02:00 (Sesi 1: 22:00 - 02:00 = 4 jam / 240 menit)
      final session1 = SleepSessionInterval(
        startTime: DateTime(2026, 11, 10, 22, 0),
        endTime: DateTime(2026, 11, 11, 2, 0),
      );

      // Tidur kembali pukul 02:20, ponsel dibuka pagi hari pukul 07:20 (Sesi 2: 02:20 - 07:20 = 5 jam / 300 menit)
      final session2 = SleepSessionInterval(
        startTime: DateTime(2026, 11, 11, 2, 20),
        endTime: DateTime(2026, 11, 11, 7, 20),
      );

      final detected = service.detectSleepFromSensors(
        sessions: [session1, session2],
        referenceNow: DateTime(2026, 11, 11, 8, 0),
      );

      expect(detected, isNotNull);
      // Sistem mengambil sesi terlama (Sesi 2: 300 menit vs 240 menit)
      expect(detected!.startTime, session2.startTime);
      expect(detected.endTime, session2.endTime);
      expect(detected.durationMinutes, 300);
      expect(detected.durationHours, 5);
      expect(detected.durationRemainingMinutes, 0);
    });

    test('1.3. Multi-sesi di mana sesi pertama lebih panjang: tetap memilih rentang durasi terpanjang', () {
      // Sesi 1: 21:30 - 05:00 (7 jam 30 menit = 450 menit)
      final session1 = SleepSessionInterval(
        startTime: DateTime(2026, 11, 10, 21, 30),
        endTime: DateTime(2026, 11, 11, 5, 0),
      );
      // Sesi 2: 05:45 - 06:45 (1 jam = 60 menit)
      final session2 = SleepSessionInterval(
        startTime: DateTime(2026, 11, 11, 5, 45),
        endTime: DateTime(2026, 11, 11, 6, 45),
      );

      final detected = service.detectSleepFromSensors(
        sessions: [session1, session2],
        referenceNow: DateTime(2026, 11, 11, 7, 0),
      );

      expect(detected, isNotNull);
      expect(detected!.startTime, session1.startTime);
      expect(detected.durationMinutes, 450);
      expect(detected.durationHours, 7);
      expect(detected.durationRemainingMinutes, 30);
    });

    // =========================================================================
    // 2. Standar Acuan Durasi Tidur Medis (Halodoc: Ideal 7–9 Jam)
    // =========================================================================
    test('2.1. Total durasi tidur < 7 jam (< 420 menit) berstatus "Tidur Kurang"', () {
      // 5 jam (300 menit)
      expect(service.getSleepStandardHalodocCategory(300), 'Tidur Kurang');
      expect(service.getSleepStandardHalodocStatus(300), 'Tidur Kurang');
      expect(service.isSleepDurationIdealHalodoc(300), isFalse);

      // 6 jam 30 menit (390 menit)
      expect(service.getSleepStandardHalodocCategory(390), 'Tidur Kurang');
      expect(service.isSleepDurationIdealHalodoc(390), isFalse);

      // 6 jam 59 menit (419 menit)
      expect(service.getSleepStandardHalodocCategory(419), 'Tidur Kurang');
      expect(service.isSleepDurationIdealHalodoc(419), isFalse);
    });

    test('2.2. Total durasi tidur memenuhi ideal (7–9 jam atau lebih / >= 420 menit) berstatus "Tidur Cukup" (Ideal)', () {
      // Tepat 7 jam (420 menit) -> Masuk rentang ideal 7-9 jam
      expect(service.getSleepStandardHalodocCategory(420), 'Tidur Cukup');
      expect(service.getSleepStandardHalodocStatus(420), 'Ideal');
      expect(service.isSleepDurationIdealHalodoc(420), isTrue);

      // 7 jam 45 menit (465 menit) -> Masuk rentang ideal 7-9 jam
      expect(service.getSleepStandardHalodocCategory(465), 'Tidur Cukup');
      expect(service.getSleepStandardHalodocStatus(465), 'Ideal');
      expect(service.isSleepDurationIdealHalodoc(465), isTrue);

      // 8 jam (480 menit) -> Masuk rentang ideal 7-9 jam
      expect(service.getSleepStandardHalodocCategory(480), 'Tidur Cukup');
      expect(service.getSleepStandardHalodocStatus(480), 'Ideal');
      expect(service.isSleepDurationIdealHalodoc(480), isTrue);

      // 9 jam (540 menit) -> Masuk rentang ideal 7-9 jam
      expect(service.getSleepStandardHalodocCategory(540), 'Tidur Cukup');
      expect(service.getSleepStandardHalodocStatus(540), 'Ideal');
      expect(service.isSleepDurationIdealHalodoc(540), isTrue);

      // 9 jam 30 menit (570 menit) -> Lebih dari batas minimal 7 jam
      expect(service.getSleepStandardHalodocCategory(570), 'Tidur Cukup');
      expect(service.isSleepDurationIdealHalodoc(570), isTrue);
    });

    // =========================================================================
    // 3. Render Estimasi Otomatis pada Kartu Ringkasan Tanpa Mengganggu Manual
    // =========================================================================
    testWidgets('3.1. Kartu ringkasan merender estimasi otomatis (Tidur Kurang) & tombol manual tetap aman', (WidgetTester tester) async {
      setPhoneViewport(tester);

      // Simulasikan kandidat tidur otomatis 5 jam 30 menit (330 menit < 7 jam)
      final now = DateTime.now();
      final nightOff = DateTime(now.year, now.month, now.day - 1, 23, 30);
      final morningOn = DateTime(now.year, now.month, now.day, 5, 0);

      service.simulateSensorDetection(
        screenOff: nightOff,
        screenOn: morningOn,
        referenceNow: now,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const NightSleepDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Durasi otomatis 5 j 30 m ter-render akurat di kartu ringkasan
      expect(find.text('5 j 30 m'), findsOneWidget);
      // Status kategori otomatis "Tidur Kurang" (< 7 jam)
      expect(find.text('Tidur Kurang'), findsWidgets);

      // Tombol "Catat waktu ini" tersedia tanpa mengganggu input manual
      final catatButton = find.text('Catat waktu ini');
      expect(catatButton, findsOneWidget);

      // Tombol manual "Masukkan data" di FAB / Header tetap ada dan bisa ditekan
      expect(find.text('Masukkan data'), findsOneWidget);
    });

    testWidgets('3.2. Kartu ringkasan merender estimasi otomatis ideal (Tidur Cukup / Ideal: 7j 45m)', (WidgetTester tester) async {
      setPhoneViewport(tester);

      // Simulasikan kandidat tidur otomatis 7 jam 45 menit (465 menit: 7–9 jam)
      final now = DateTime.now();
      final nightOff = DateTime(now.year, now.month, now.day - 1, 22, 30);
      final morningOn = DateTime(now.year, now.month, now.day, 6, 15);

      service.simulateSensorDetection(
        screenOff: nightOff,
        screenOn: morningOn,
        referenceNow: now,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const NightSleepDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Durasi 7 j 45 m ter-render akurat
      expect(find.text('7 j 45 m'), findsOneWidget);
      // Status kategori otomatis "Tidur Cukup" & badge "Ideal" sesuai standar Halodoc
      expect(find.text('Tidur Cukup'), findsWidgets);
      expect(find.text('Ideal'), findsWidgets);

      // Menekan "Catat waktu ini" berhasil menyimpan data dan merender status "Tercatat"
      await tester.tap(find.text('Catat waktu ini'));
      await tester.pumpAndSettle();

      expect(find.text('Tercatat'), findsOneWidget);
      expect(service.hasTodayData, isTrue);
    });

    test('3.3. Proteksi data manual: Rekaman manual yang sudah ada tidak ditimpa oleh deteksi otomatis', () async {
      final now = DateTime.now();
      final dateKey = SleepTrackingService.formatDateKey(now);

      // User mencatat manual terlebih dahulu
      final manualRec = SleepRecord(
        id: 'manual_confirmed_1',
        userId: service.currentUserId,
        date: dateKey,
        startTime: DateTime(now.year, now.month, now.day - 1, 22, 0),
        endTime: DateTime(now.year, now.month, now.day, 6, 0),
        durationMinutes: 480,
        source: 'manual',
        isConfirmed: true,
      );
      await service.addRecord(manualRec);

      // Perekaman otomatis mencoba berjalan
      final candidate = await service.recordAutomaticSleep(
        screenOff: DateTime(now.year, now.month, now.day - 1, 23, 0),
        screenOn: DateTime(now.year, now.month, now.day, 5, 0),
        referenceNow: now,
      );

      // Deteksi otomatis harus ditolak / tidak menimpa data manual pengguna
      expect(candidate, isNull);
      final saved = service.getSavedRecordForDate(now);
      expect(saved, isNotNull);
      expect(saved!.source, 'manual');
      expect(saved.durationMinutes, 480);
    });
  });
}
