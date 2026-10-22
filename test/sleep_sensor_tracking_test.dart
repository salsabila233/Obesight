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

  group('Deteksi Waktu Tidur Berbasis Sensor (SleepTrackingService)', () {
    final service = SleepTrackingService.instance;

    test('1. Menggabungkan Screen Off dan Ruangan Gelap di Malam Hari (Start Time)', () {
      // Skenario A: Layar mati 22:30, lampu dimatikan 22:50 (lux rendah).
      // Waktu mulai tidur disempurnakan ke 22:50 (ketika ruangan gelap & layar mati).
      final screenOff = DateTime(2026, 10, 20, 22, 30);
      final darkTime = DateTime(2026, 10, 20, 22, 50);
      final screenOn = DateTime(2026, 10, 21, 6, 15);
      final lightRise = DateTime(2026, 10, 21, 6, 0);

      final candidate = service.detectSleepFromSensors(
        screenOff: screenOff,
        darkTime: darkTime,
        screenOn: screenOn,
        lightRiseTime: lightRise,
      );

      expect(candidate, isNotNull);
      expect(candidate!.startTime, darkTime);
      expect(candidate.endTime, lightRise);
      expect(candidate.durationMinutes, 430); // 22:50 ke 06:00 = 7 jam 10 menit
      expect(candidate.isAutomatic, isTrue);
      expect(candidate.isConfirmed, isFalse);
    });

    test('2. Menggabungkan Ruangan Gelap lebih awal dan Screen Off di ranjang (Start Time)', () {
      // Skenario B: Lampu kamar mati 22:15, pengguna masih memainkan HP hingga 22:45 baru mematikan layar.
      // Waktu mulai tidur adalah 22:45 saat HP dimatikan.
      final darkTime = DateTime(2026, 10, 20, 22, 15);
      final screenOff = DateTime(2026, 10, 20, 22, 45);
      final screenOn = DateTime(2026, 10, 21, 6, 30);

      final candidate = service.detectSleepFromSensors(
        screenOff: screenOff,
        darkTime: darkTime,
        screenOn: screenOn,
      );

      expect(candidate, isNotNull);
      expect(candidate!.startTime, screenOff);
      expect(candidate.endTime, screenOn);
      expect(candidate.durationMinutes, 465); // 7 jam 45 menit
    });

    test('3. Deteksi Bangun Pagi melalui Peningkatan Cahaya (Ambient Light Rise)', () {
      // Pengguna bangun jam 05:45 (lampu kamar dinyalakan / matahari terbit), baru buka HP jam 06:15
      final screenOff = DateTime(2026, 10, 20, 23, 0);
      final lightRise = DateTime(2026, 10, 21, 5, 45);
      final screenOn = DateTime(2026, 10, 21, 6, 15);

      final candidate = service.detectSleepFromSensors(
        screenOff: screenOff,
        lightRiseTime: lightRise,
        screenOn: screenOn,
      );

      expect(candidate, isNotNull);
      expect(candidate!.endTime, lightRise);
      expect(candidate.durationMinutes, 405); // 6 jam 45 menit
    });

    test('4. Menolak durasi di bawah batas minimal tidur malam (3 jam)', () {
      // Hanya 1 jam (misal HP mati 23:00 - 00:00)
      final screenOff = DateTime(2026, 10, 20, 23, 0);
      final screenOn = DateTime(2026, 10, 21, 0, 0);

      final candidate = service.detectSleepFromSensors(
        screenOff: screenOff,
        screenOn: screenOn,
      );

      expect(candidate, isNull);
    });

    test('5. Menolak aktivitas di luar jam malam untuk sesi tidur malam', () {
      // Layar mati siang hari (13:00 - 15:00) bukan tidur malam
      final screenOff = DateTime(2026, 10, 20, 13, 0);
      final screenOn = DateTime(2026, 10, 20, 15, 0);

      final candidate = service.detectSleepFromSensors(
        screenOff: screenOff,
        screenOn: screenOn,
      );

      expect(candidate, isNull);
    });

    test('6. Service background tetap aktif secara independen (isSensorTrackingActive)', () async {
      await service.initialize();
      expect(service.isSensorTrackingActive, isTrue);

      // Simulasikan deteksi sensor
      service.simulateSensorDetection(
        screenOff: DateTime(2026, 10, 20, 22, 30),
        darkTime: DateTime(2026, 10, 20, 22, 45),
        screenOn: DateTime(2026, 10, 21, 6, 0),
        lightRiseTime: DateTime(2026, 10, 21, 5, 55),
      );

      expect(service.pendingAutoDetectedRecord, isNotNull);
      expect(service.pendingAutoDetectedRecord!.durationMinutes, 430);
    });
  });

  group('Pemisahan Service (Perekam) & Priority Check UI', () {
    testWidgets('1. JIKA HARI INI SUDAH ADA DATA TERSIMPAN: Tampilkan durasi di card utama & grafik, tombol menjadi "Tercatat", service background tetap aktif', (tester) async {
      setPhoneViewport(tester);

      final service = SleepTrackingService.instance;
      final now = DateTime.now();
      final dateKey = SleepTrackingService.formatDateKey(now);

      // Simpan data tidur resmi hari ini (7 jam = 420 menit)
      final savedRecord = SleepRecord(
        id: 'rec_official_today',
        userId: service.currentUserId,
        date: dateKey,
        startTime: DateTime(now.year, now.month, now.day - 1, 23, 0),
        endTime: DateTime(now.year, now.month, now.day, 6, 0),
        durationMinutes: 420,
        source: 'automatic',
        isConfirmed: true,
      );
      await service.addRecord(savedRecord);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const NightSleepDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Card utama menampilkan durasi tersimpan
      expect(find.text('7 j 0 m'), findsOneWidget);
      expect(find.text('23.00 - 06.00'), findsOneWidget);

      // Tombol "Catat waktu ini" berubah/tergantikan menjadi "Tercatat" dengan ikon centang
      expect(find.text('Tercatat'), findsOneWidget);
      expect(find.text('Catat waktu ini'), findsNothing);
      expect(find.byIcon(Icons.check_circle_rounded), findsWidgets);

      // Grafik langsung menampilkan bar hari ini
      expect(find.byKey(const ValueKey('daily_bars')), findsOneWidget);
      expect(find.text('Belum ada data tidur hari ini'), findsNothing);

      // Mengetuk badge status "Tercatat" tidak memicu duplikasi data
      await tester.tap(find.byIcon(Icons.check_circle_rounded).first);
      await tester.pumpAndSettle();
      expect(service.allRecords.length, 1);

      // Background tracking service tetap aktif untuk memantau hari berikutnya
      expect(service.isSensorTrackingActive, isTrue);
    });

    testWidgets('2. JIKA HARI INI BELUM ADA DATA TERSIMPAN: Tampilkan estimasi sensor di card utama & tombol "Catat waktu ini"', (tester) async {
      setPhoneViewport(tester);

      final service = SleepTrackingService.instance;
      final now = DateTime.now();

      // Buat estimasi otomatis dari sensor (7 jam 45 menit: 22:30 -> 06:15)
      service.simulateSensorDetection(
        screenOff: DateTime(now.year, now.month, now.day - 1, 22, 30),
        screenOn: DateTime(now.year, now.month, now.day, 6, 15),
        darkTime: DateTime(now.year, now.month, now.day - 1, 22, 30),
        lightRiseTime: DateTime(now.year, now.month, now.day, 6, 15),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const NightSleepDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Card utama menampilkan estimasi otomatis dari sensor
      expect(find.text('7 j 45 m'), findsOneWidget);
      expect(find.text('22.30 - 06.15'), findsOneWidget);

      // Tombol "Catat waktu ini" aktif ditampilkan
      expect(find.text('Catat waktu ini'), findsOneWidget);

      // Tekan tombol "Catat waktu ini"
      await tester.tap(find.text('Catat waktu ini'));
      await tester.pumpAndSettle();

      // Setelah dicatat:
      // 1. Data resmi tersimpan
      expect(service.todayRecords.length, 1);
      expect(service.todayRecords.first.durationMinutes, 465);

      // 2. Tombol berubah menjadi "Tercatat"
      expect(find.text('Tercatat'), findsOneWidget);
      expect(find.text('Catat waktu ini'), findsNothing);

      // 3. Grafik langsung terupdate menampilkan visual data hari ini
      expect(find.byKey(const ValueKey('daily_bars')), findsOneWidget);
    });
  });
}
