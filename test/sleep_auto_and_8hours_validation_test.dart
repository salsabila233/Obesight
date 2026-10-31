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

  group('Uji Logika Rekam Tidur Otomatis & Validasi Acuan Standar 8 Jam', () {
    // =========================================================================
    // BAGIAN 1: Logika Rekam Tidur Otomatis (Screen Off Malam & Screen On Pagi)
    // =========================================================================

    test('1.1. Deteksi waktu tidur otomatis mendeteksi screen off malam (>= 20.00) dan screen on pagi (05.00-14.00)', () {
      final service = SleepTrackingService.instance;
      final nightOff = DateTime(2026, 10, 24, 23, 0); // 23:00 malam
      final morningOn = DateTime(2026, 10, 25, 7, 0); // 07:00 pagi

      final detected = service.detectSleepFromScreenActivity(
        screenOff: nightOff,
        screenOn: morningOn,
        referenceNow: morningOn,
      );

      expect(detected, isNotNull);
      expect(detected!.startTime, nightOff);
      expect(detected.endTime, morningOn);
      expect(detected.durationMinutes, 480); // 8 jam = 480 menit
      expect(detected.source, 'automatic');
      expect(detected.isAutomatic, isTrue);
      expect(detected.isConfirmed, isFalse);
    });

    test('1.2. recordAutomaticSleep menghubungkan data deteksi otomatis ke sistem tanpa mengganggu input manual', () async {
      final service = SleepTrackingService.instance;
      final now = DateTime(2026, 10, 25, 8, 0);
      final dateKey = SleepTrackingService.formatDateKey(now);

      // Simulasikan pengguna telah memasukkan data tidur manual terlebih dahulu
      final manualRecord = SleepRecord(
        id: 'manual_user_input',
        userId: service.currentUserId,
        date: dateKey,
        startTime: DateTime(2026, 10, 24, 22, 0),
        endTime: DateTime(2026, 10, 25, 6, 0),
        durationMinutes: 480,
        source: 'manual',
        isConfirmed: true,
      );
      await service.addRecord(manualRecord);
      expect(service.getRecordsForDate(now).first.id, 'manual_user_input');

      // Jalankan deteksi rekam tidur otomatis dari sinyal layar perangkat
      final autoResult = await service.recordAutomaticSleep(
        screenOff: DateTime(2026, 10, 24, 23, 30),
        screenOn: DateTime(2026, 10, 25, 7, 15),
        referenceNow: now,
      );

      // Deteksi otomatis tidak boleh menimpa atau mengganggu data manual yang sudah ada
      expect(autoResult, isNull);
      final recordsAfter = service.getRecordsForDate(now);
      expect(recordsAfter.length, 1);
      expect(recordsAfter.first.id, 'manual_user_input');
      expect(recordsAfter.first.source, 'manual');
    });

    test('1.3. recordAutomaticSleep menghubungkan kandidat otomatis ketika belum ada data manual', () async {
      final service = SleepTrackingService.instance;
      final now = DateTime(2026, 10, 25, 8, 0);

      final autoResult = await service.recordAutomaticSleep(
        screenOff: DateTime(2026, 10, 24, 22, 30),
        screenOn: DateTime(2026, 10, 25, 6, 45),
        referenceNow: now,
      );

      expect(autoResult, isNotNull);
      expect(service.pendingAutoDetectedRecord, isNotNull);
      expect(service.pendingAutoDetectedRecord!.durationMinutes, 495); // 8j 15m
      expect(service.pendingAutoDetectedRecord!.source, 'automatic');
    });

    // =========================================================================
    // BAGIAN 2: Validasi Acuan Standar Tidur 8 Jam
    // =========================================================================

    test('2.1. Durasi tidur < 8 jam (< 480 menit) dikategorikan sebagai "Tidur Kurang"', () {
      final service = SleepTrackingService.instance;

      // Kasus 1: 5 jam (300 menit)
      expect(service.getSleepStandard8HoursCategory(300), 'Tidur Kurang');
      expect(service.getSleepStandard8HoursStatus(300), 'Tidur Kurang');
      expect(service.isSleepDurationIdeal8Hours(300), isFalse);

      // Kasus 2: 7 jam 45 menit (465 menit)
      expect(service.getSleepStandard8HoursCategory(465), 'Tidur Kurang');
      expect(service.getSleepStandard8HoursStatus(465), 'Tidur Kurang');
      expect(service.isSleepDurationIdeal8Hours(465), isFalse);

      // Kasus 3: 7 jam 59 menit (479 menit) - tepat di bawah 8 jam
      expect(service.getSleepStandard8HoursCategory(479), 'Tidur Kurang');
      expect(service.isSleepDurationIdeal8Hours(479), isFalse);
    });

    test('2.2. Durasi tidur >= 8 jam (>= 480 menit) dikategorikan sebagai "Tidur Cukup" / "Ideal"', () {
      final service = SleepTrackingService.instance;

      // Kasus 1: Tepat 8 jam (480 menit)
      expect(service.getSleepStandard8HoursCategory(480), 'Tidur Cukup');
      expect(service.getSleepStandard8HoursStatus(480), 'Ideal');
      expect(service.isSleepDurationIdeal8Hours(480), isTrue);

      // Kasus 2: 8 jam 30 menit (510 menit)
      expect(service.getSleepStandard8HoursCategory(510), 'Tidur Cukup');
      expect(service.getSleepStandard8HoursStatus(510), 'Ideal');
      expect(service.isSleepDurationIdeal8Hours(510), isTrue);

      // Kasus 3: 9 jam (540 menit)
      expect(service.getSleepStandard8HoursCategory(540), 'Tidur Cukup');
      expect(service.getSleepStandard8HoursStatus(540), 'Ideal');
      expect(service.isSleepDurationIdeal8Hours(540), isTrue);
    });

    // =========================================================================
    // BAGIAN 3: Tampilan Kategori pada Kartu Ringkasan Tidur Harian di UI
    // =========================================================================

    testWidgets('3.1. Kartu ringkasan tidur harian menampilkan label "Tidur Kurang" ketika durasi < 8 jam', (tester) async {
      setPhoneViewport(tester);

      final service = SleepTrackingService.instance;
      final now = DateTime.now();
      final dateKey = SleepTrackingService.formatDateKey(now);

      // Catat tidur 7 jam (420 menit, < 8 jam)
      final recordShort = SleepRecord(
        id: 'rec_short_sleep',
        userId: service.currentUserId,
        date: dateKey,
        startTime: DateTime(now.year, now.month, now.day - 1, 23, 0),
        endTime: DateTime(now.year, now.month, now.day, 6, 0),
        durationMinutes: 420,
        source: 'manual',
        isConfirmed: true,
      );
      await service.addRecord(recordShort);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const NightSleepDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Memastikan label penanda "Tidur Kurang" tampil dengan jelas pada kartu ringkasan tidur harian
      expect(find.text('Tidur Kurang'), findsWidgets);
      expect(find.text('7 j 0 m'), findsOneWidget);
      expect(find.textContaining('Acuan Standar 8 Jam: Tidur Kurang'), findsOneWidget);
    });

    testWidgets('3.2. Kartu ringkasan tidur harian menampilkan status "Tidur Cukup" dan "Ideal" ketika durasi >= 8 jam', (tester) async {
      setPhoneViewport(tester);

      final service = SleepTrackingService.instance;
      final now = DateTime.now();
      final dateKey = SleepTrackingService.formatDateKey(now);

      // Catat tidur 8 jam (480 menit, >= 8 jam)
      final recordIdeal = SleepRecord(
        id: 'rec_ideal_sleep',
        userId: service.currentUserId,
        date: dateKey,
        startTime: DateTime(now.year, now.month, now.day - 1, 22, 0),
        endTime: DateTime(now.year, now.month, now.day, 6, 0),
        durationMinutes: 480,
        source: 'automatic',
        isConfirmed: true,
      );
      await service.addRecord(recordIdeal);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const NightSleepDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Memastikan status "Tidur Cukup" dan penanda "Ideal" tampil dengan jelas pada kartu ringkasan tidur harian
      expect(find.text('Tidur Cukup'), findsWidgets);
      expect(find.text('Ideal'), findsWidgets);
      expect(find.text('8 j 0 m'), findsOneWidget);
      expect(find.textContaining('Acuan Standar 8 Jam: Tidur Cukup'), findsOneWidget);
    });

    testWidgets('3.3. Tombol "Catat waktu ini" dan grafik 7 hari tetap bekerja dengan tepat', (tester) async {
      setPhoneViewport(tester);

      final service = SleepTrackingService.instance;
      final now = DateTime.now();
      final dateKey = SleepTrackingService.formatDateKey(now);

      // Siapkan kandidat deteksi otomatis tidur 8 jam 15 menit
      final candidate = SleepRecord(
        id: 'candidate_auto_ideal',
        userId: service.currentUserId,
        date: dateKey,
        startTime: DateTime(now.year, now.month, now.day - 1, 22, 15),
        endTime: DateTime(now.year, now.month, now.day, 6, 30),
        durationMinutes: 495,
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

      // Kartu menampilkan estimasi dan status validasi 8 jam
      expect(find.text('8 j 15 m'), findsOneWidget);
      expect(find.text('Tidur Cukup'), findsWidgets);
      expect(find.text('Ideal'), findsWidgets);

      // Tombol "Catat waktu ini" tersedia
      final catatBtn = find.text('Catat waktu ini');
      expect(catatBtn, findsOneWidget);

      // Tekan tombol "Catat waktu ini"
      await tester.tap(catatBtn);
      await tester.pumpAndSettle();

      // Tombol berubah menjadi status tercatat
      expect(find.text('Tercatat'), findsOneWidget);

      // Grafik 7 hari langsung aktif memperbarui batang harian
      expect(find.byKey(const ValueKey('daily_bars')), findsOneWidget);
      expect(find.byKey(const ValueKey('daily_empty')), findsNothing);
    });
  });
}
