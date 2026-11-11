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
    // BAGIAN 2: Validasi Acuan Standar Tidur Medis (Halodoc: 7–9 Jam)
    // =========================================================================

    test('2.1. Durasi tidur < 7 jam (< 420 menit) dikategorikan sebagai "Tidur Kurang"', () {
      final service = SleepTrackingService.instance;

      // Kasus 1: 5 jam (300 menit)
      expect(service.getSleepStandardHalodocCategory(300), 'Tidur Kurang');
      expect(service.getSleepStandardHalodocStatus(300), 'Tidur Kurang');
      expect(service.isSleepDurationIdealHalodoc(300), isFalse);

      // Kasus 2: 6 jam 30 menit (390 menit)
      expect(service.getSleepStandardHalodocCategory(390), 'Tidur Kurang');
      expect(service.getSleepStandardHalodocStatus(390), 'Tidur Kurang');
      expect(service.isSleepDurationIdealHalodoc(390), isFalse);

      // Kasus 3: 6 jam 59 menit (419 menit) - tepat di bawah 7 jam
      expect(service.getSleepStandardHalodocCategory(419), 'Tidur Kurang');
      expect(service.isSleepDurationIdealHalodoc(419), isFalse);
    });

    test('2.2. Durasi tidur >= 7 jam (>= 420 menit, 7–9 jam atau lebih) dikategorikan sebagai "Tidur Cukup" / "Ideal"', () {
      final service = SleepTrackingService.instance;

      // Kasus 1: Tepat 7 jam (420 menit)
      expect(service.getSleepStandardHalodocCategory(420), 'Tidur Cukup');
      expect(service.getSleepStandardHalodocStatus(420), 'Ideal');
      expect(service.isSleepDurationIdealHalodoc(420), isTrue);

      // Kasus 2: 7 jam 45 menit (465 menit)
      expect(service.getSleepStandardHalodocCategory(465), 'Tidur Cukup');
      expect(service.getSleepStandardHalodocStatus(465), 'Ideal');
      expect(service.isSleepDurationIdealHalodoc(465), isTrue);

      // Kasus 3: 8 jam (480 menit)
      expect(service.getSleepStandardHalodocCategory(480), 'Tidur Cukup');
      expect(service.getSleepStandardHalodocStatus(480), 'Ideal');
      expect(service.isSleepDurationIdealHalodoc(480), isTrue);

      // Kasus 4: 9 jam (540 menit)
      expect(service.getSleepStandardHalodocCategory(540), 'Tidur Cukup');
      expect(service.getSleepStandardHalodocStatus(540), 'Ideal');
      expect(service.isSleepDurationIdealHalodoc(540), isTrue);
    });

    // =========================================================================
    // BAGIAN 3: Tampilan Kategori pada Kartu Ringkasan Tidur Harian di UI
    // =========================================================================

    testWidgets('3.1. Kartu ringkasan tidur harian menampilkan label "Tidur Kurang" ketika durasi < 7 jam', (tester) async {
      setPhoneViewport(tester);

      final service = SleepTrackingService.instance;
      final now = DateTime.now();
      final dateKey = SleepTrackingService.formatDateKey(now);

      // Catat tidur 6 jam (360 menit, < 7 jam)
      final recordShort = SleepRecord(
        id: 'rec_short_sleep',
        userId: service.currentUserId,
        date: dateKey,
        startTime: DateTime(now.year, now.month, now.day - 1, 23, 0),
        endTime: DateTime(now.year, now.month, now.day, 5, 0),
        durationMinutes: 360,
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
      expect(find.text('6 j 0 m'), findsOneWidget);
      expect(find.textContaining('Acuan Standar Halodoc (7–9 Jam): Tidur Kurang'), findsOneWidget);
    });

    testWidgets('3.2. Kartu ringkasan tidur harian menampilkan status "Tidur Cukup" dan "Ideal" ketika durasi >= 7 jam', (tester) async {
      setPhoneViewport(tester);

      final service = SleepTrackingService.instance;
      final now = DateTime.now();
      final dateKey = SleepTrackingService.formatDateKey(now);

      // Catat tidur 8 jam (480 menit, >= 7 jam)
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
      expect(find.textContaining('Acuan Standar Halodoc (7–9 Jam): Tidur Cukup'), findsOneWidget);
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

    // =========================================================================
    // BAGIAN 4: Verifikasi Patokan Waktu Bangun (First Screen Unlock) & Waktu Tidur (Last Screen Off)
    // =========================================================================

    test('4.1. Jam bangun tidur diambil dari screen on/unlock pertama (05.05), BUKAN dari jam buka aplikasi (05.25)', () {
      final service = SleepTrackingService.instance;
      // Pengguna mematikan layar HP pukul 23:30 malam
      final screenOffNight = DateTime(2026, 10, 24, 23, 30);
      // Pengguna bangun tidur dan menyalakan/unlock HP pertama kali pukul 05:05 pagi
      final firstScreenUnlockMorning = DateTime(2026, 10, 25, 5, 5);
      // Pengguna baru membuka aplikasi ObeSight pukul 05:25 pagi
      final appOpenTime = DateTime(2026, 10, 25, 5, 25);

      final candidate = service.detectSleepFromSensors(
        screenOff: screenOffNight,
        screenOn: firstScreenUnlockMorning,
        referenceNow: appOpenTime,
      );

      expect(candidate, isNotNull);
      // Jam bangun tidur HARUS 05:05 (pertama kali buka kunci layar), BUKAN 05:25 (jam buka aplikasi)
      expect(candidate!.endTime, firstScreenUnlockMorning);
      expect(candidate.endTime.hour, 5);
      expect(candidate.endTime.minute, 5);
      expect(candidate.endTime != appOpenTime, isTrue);

      // Jam mulai tidur 23:30
      expect(candidate.startTime, screenOffNight);
      // Durasi dihitung tepat: 23:30 s.d. 05:05 = 5 jam 35 menit = 335 menit (BUKAN 355 menit)
      expect(candidate.durationMinutes, 335);
      expect(candidate.durationHours, 5);
      expect(candidate.durationRemainingMinutes, 35);
      expect(candidate.shortDurationFormatted, '5j 35m');
    });

    test('4.2. Jam mulai tidur diambil dari terakhir layar HP dimatikan (23.45), BUKAN dari jam aplikasi diminimalkan (21.00)', () {
      final service = SleepTrackingService.instance;
      // Aplikasi diminimalkan pada pukul 21:00
      final appMinimizedTime = DateTime(2026, 10, 24, 21, 0);
      // Layar HP baru dimatikan pengguna sebelum tidur pada pukul 23:45
      final lastScreenOffTime = DateTime(2026, 10, 24, 23, 45);
      // Bangun pertama di pagi hari pukul 06:15
      final morningWakeTime = DateTime(2026, 10, 25, 6, 15);

      final candidate = service.detectSleepFromSensors(
        screenOff: lastScreenOffTime,
        screenOn: morningWakeTime,
        lastInactivityTime: appMinimizedTime,
        referenceNow: morningWakeTime,
      );

      expect(candidate, isNotNull);
      // Jam mulai tidur HARUS 23:45 (last screen off), BUKAN 21:00 (saat tutup aplikasi)
      expect(candidate!.startTime, lastScreenOffTime);
      expect(candidate.startTime.hour, 23);
      expect(candidate.startTime.minute, 45);

      // Durasi dihitung tepat dari 23:45 s.d. 06:15 = 6 jam 30 menit = 390 menit
      expect(candidate.durationMinutes, 390);
      expect(candidate.durationHours, 6);
      expect(candidate.durationRemainingMinutes, 30);
    });

    test('4.3. Aplikasi dibuka pagi hari tanpa ada rekaman screen on/unlock pagi TIDAK boleh membuat kandidat tidur palsu', () async {
      final service = SleepTrackingService.instance;
      final nightOff = DateTime(2026, 10, 24, 23, 0);
      final morningAppOpen = DateTime(2026, 10, 25, 5, 25);

      // Simulasikan screen off semalam tapi screenOn belum terekam dari perangkat saat aplikasi dibuka pukul 05:25
      service.simulateSensorDetection(
        screenOff: nightOff,
        screenOn: null,
        referenceNow: morningAppOpen,
      );

      // Kandidat harus null karena tidak boleh menggunakan jam buka aplikasi (05.25) sebagai jam bangun
      expect(service.pendingAutoDetectedRecord, isNull);
    });

    // =========================================================================
    // BAGIAN 5: Logika Multi-Sesi Tidur Malam (Longest Continuous Sleep Session)
    // =========================================================================

    test('5.1. Multi-sesi: Mengambil rentang durasi terlama (longest continuous sleep session) saat ada beberapa sesi tertidur', () {
      final service = SleepTrackingService.instance;
      // Sesi 1: Tidur jam 22:00, terbangun/layar menyala jam 01:00 (Durasi: 3 jam = 180 menit)
      final session1 = SleepSessionInterval(
        startTime: DateTime(2026, 10, 24, 22, 0),
        endTime: DateTime(2026, 10, 25, 1, 0),
      );

      // Sesi 2: Tidur kembali jam 01:30, bangun pagi/layar unlock jam 07:30 (Durasi: 6 jam = 360 menit)
      final session2 = SleepSessionInterval(
        startTime: DateTime(2026, 10, 25, 1, 30),
        endTime: DateTime(2026, 10, 25, 7, 30),
      );

      final detected = service.detectSleepFromSensors(
        sessions: [session1, session2],
        referenceNow: DateTime(2026, 10, 25, 8, 0),
      );

      expect(detected, isNotNull);
      // Sistem HARUS memilih Sesi 2 karena merupakan sesi continuous terlama (6 jam vs 3 jam)
      expect(detected!.startTime, session2.startTime);
      expect(detected.endTime, session2.endTime);
      expect(detected.durationMinutes, 360);
      expect(detected.durationHours, 6);
      expect(detected.durationRemainingMinutes, 0);
      expect(detected.standard8HoursCategory, 'Tidur Kurang');
    });

    test('5.2. Multi-sesi: Memilih sesi pertama jika sesi pertama yang terlama dan mencapai standar >= 8 jam ("Tidur Cukup")', () {
      final service = SleepTrackingService.instance;
      // Sesi 1: Tidur jam 21:30, terbangun jam 05:45 (Durasi: 8 jam 15 menit = 495 menit)
      final session1 = SleepSessionInterval(
        startTime: DateTime(2026, 10, 24, 21, 30),
        endTime: DateTime(2026, 10, 25, 5, 45),
      );

      // Sesi 2: Tidur siang/pagi sejenak jam 06:15 s.d. 07:30 (Durasi: 1 jam 15 menit = 75 menit)
      final session2 = SleepSessionInterval(
        startTime: DateTime(2026, 10, 25, 6, 15),
        endTime: DateTime(2026, 10, 25, 7, 30),
      );

      final detected = service.detectSleepFromSensors(
        sessions: [session1, session2],
        referenceNow: DateTime(2026, 10, 25, 8, 0),
      );

      expect(detected, isNotNull);
      // Sistem HARUS memilih Sesi 1 (495 menit)
      expect(detected!.startTime, session1.startTime);
      expect(detected.endTime, session1.endTime);
      expect(detected.durationMinutes, 495);
      expect(detected.standard8HoursCategory, 'Tidur Cukup');
      expect(detected.isIdeal8Hours, isTrue);
    });

    testWidgets('5.3. Sinkronisasi real-time ke Card Utama Waktu Tidur saat aplikasi dibuka di pagi hari', (WidgetTester tester) async {
      setPhoneViewport(tester);
      final service = SleepTrackingService.instance;

      // Buat kandidat otomatis dari multi-sesi malam hari
      final session1 = SleepSessionInterval(
        startTime: DateTime(2026, 10, 24, 22, 0),
        endTime: DateTime(2026, 10, 25, 1, 0),
      );
      final session2 = SleepSessionInterval(
        startTime: DateTime(2026, 10, 25, 1, 30),
        endTime: DateTime(2026, 10, 25, 7, 30),
      );

      // Simulasikan deteksi otomatis multi-sesi pagi hari
      service.simulateSensorDetection(
        sessions: [session1, session2],
        referenceNow: DateTime(2026, 10, 25, 8, 0),
      );

      expect(service.pendingAutoDetectedRecord, isNotNull);
      expect(service.pendingAutoDetectedRecord!.durationHours, 6);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const NightSleepDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Card Utama Waktu Tidur menampilkan data sesi tidur terlama (6j 0m) secara real-time
      expect(find.text('6 j 0 m'), findsOneWidget);
      expect(find.text('Tidur Kurang'), findsOneWidget);

      // Tombol "Catat waktu ini" tersedia untuk menyimpan data ini secara bersih ke database
      final catatButton = find.text('Catat waktu ini');
      expect(catatButton, findsOneWidget);

      // Pengguna mengklik "Catat waktu ini"
      await tester.tap(catatButton);
      await tester.pumpAndSettle();

      // Data resmi tersimpan tanpa error dan status berubah menjadi "Tercatat"
      expect(find.text('Tercatat'), findsOneWidget);
      expect(service.hasTodayData, isTrue);
    });
  });
}
