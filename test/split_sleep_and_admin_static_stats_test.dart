import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obesight/models/sleep_record_model.dart';
import 'package:obesight/screens/home/admin_home_screen.dart';
import 'package:obesight/screens/progress/sleep_record_form_screen.dart';
import 'package:obesight/services/auth_service.dart';
import 'package:obesight/services/sleep_tracking_service.dart';
import 'package:obesight/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SleepTrackingService.instance.clearAll();
  });

  group('Uji Dukungan Sesi Tidur Terbagi (Split Sleep) - Model & Akumulasi', () {
    test('1.1. Model SleepRecord mengakumulasikan durasi tidur dari Sesi 1 dan Sesi 2', () {
      final start = DateTime(2026, 11, 18, 22, 0); // 22:00
      final firstEnd = DateTime(2026, 11, 19, 2, 0); // 02:00 (4 jam = 240 menit)
      final secondStart = DateTime(2026, 11, 19, 3, 0); // 03:00 (terjaga 1 jam)
      final secondEnd = DateTime(2026, 11, 19, 6, 30); // 06:30 (3 jam 30 menit = 210 menit)

      final record = SleepRecord(
        id: 'split_1',
        userId: 'test_user',
        date: '2026-11-19',
        startTime: start,
        firstEndTime: firstEnd,
        secondStartTime: secondStart,
        endTime: secondEnd,
        isSplitSleep: true,
        firstSessionMinutes: 240,
        secondSessionMinutes: 210,
      );

      // Akumulasi total durasi tidur: 240 + 210 = 450 menit (7 jam 30 menit)
      expect(record.durationMinutes, 450);
      expect(record.durationHours, 7);
      expect(record.durationRemainingMinutes, 30);
      expect(record.durationFormatted, '7 jam 30 menit');
      expect(record.shortDurationFormatted, '7j 30m');

      // Waktu terjaga di tengah malam: 02:00 sampai 03:00 = 60 menit (1 jam)
      expect(record.awakeGapMinutes, 60);
      expect(record.awakeGapFormatted, '1 jam');

      // Tampilan format rentang jam tidur terbagi
      expect(record.timeRangeFormatted, '22:00–02:00 & 03:00–06:30');
      expect(record.firstSessionFormatted, '4 jam');
      expect(record.secondSessionFormatted, '3 jam 30 menit');

      // Evaluasi standar ideal medis Halodoc (>= 7 jam / 420 menit)
      expect(record.standardHalodocCategory, 'Tidur Cukup');
      expect(record.isIdealHalodoc, isTrue);
    });

    test('1.2. Serialisasi toMap, toFirestoreMap, dan deserialisasi fromMap mempertahankan data split sleep', () {
      final start = DateTime(2026, 11, 18, 23, 0);
      final firstEnd = DateTime(2026, 11, 19, 1, 30); // 2j 30m = 150 menit
      final secondStart = DateTime(2026, 11, 19, 2, 15); // jeda 45 menit
      final secondEnd = DateTime(2026, 11, 19, 6, 0); // 3j 45m = 225 menit

      final original = SleepRecord(
        id: 'split_serial_test',
        userId: 'user_123',
        date: '2026-11-19',
        startTime: start,
        firstEndTime: firstEnd,
        secondStartTime: secondStart,
        endTime: secondEnd,
        isSplitSleep: true,
        firstSessionMinutes: 150,
        secondSessionMinutes: 225,
      );

      final map = original.toMap();
      expect(map['isSplitSleep'], isTrue);
      expect(map['firstSessionMinutes'], 150);
      expect(map['secondSessionMinutes'], 225);

      final restored = SleepRecord.fromMap(map);
      expect(restored.isSplitSleep, isTrue);
      expect(restored.durationMinutes, 375); // 150 + 225 = 375 menit
      expect(restored.firstSessionMinutes, 150);
      expect(restored.secondSessionMinutes, 225);
      expect(restored.awakeGapMinutes, 45);
      expect(restored.awakeGapFormatted, '45 menit');
      expect(restored.timeRangeFormatted, '23:00–01:30 & 02:15–06:00');
    });

    test('1.3. Integrasi SleepTrackingService: getPast7DaysSummaries mengakumulasi durasi split sleep', () async {
      final service = SleepTrackingService.instance;
      final start = DateTime(2026, 11, 18, 22, 30);
      final firstEnd = DateTime(2026, 11, 19, 2, 0); // 210 menit
      final secondStart = DateTime(2026, 11, 19, 3, 0);
      final secondEnd = DateTime(2026, 11, 19, 7, 0); // 240 menit

      final record = SleepRecord(
        id: 'rec_service_split',
        userId: service.currentUserId,
        date: '2026-11-19',
        startTime: start,
        firstEndTime: firstEnd,
        secondStartTime: secondStart,
        endTime: secondEnd,
        isSplitSleep: true,
        firstSessionMinutes: 210,
        secondSessionMinutes: 240,
        source: 'manual',
      );

      await service.addRecord(record);

      final summaries = service.getPast7DaysSummaries(DateTime(2026, 11, 19));
      final daySummary = summaries.firstWhere((s) => s.dateKey == '2026-11-19');
      expect(daySummary.hasData, isTrue);
      expect(daySummary.totalMinutes, 450); // 210 + 240 = 450 menit (7j 30m)
      expect(daySummary.standardHalodocCategory, 'Tidur Cukup');
    });
  });

  group('Uji Form Pencatatan Tidur Manual (SleepRecordFormScreen)', () {
    testWidgets('2.1. Toggle Split Sleep menampilkan input Sesi 1, Jeda Terjaga, Sesi 2, dan Akumulasi', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SleepRecordFormScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Secara default: mode tidur tunggal aktif (ada CircularSleepDial)
      expect(find.text('Tidur Terbagi (Split Sleep)'), findsOneWidget);
      expect(find.text('Jam istirahat'), findsOneWidget);
      expect(find.text('Jam selesai'), findsOneWidget);
      expect(find.text('Durasi istirahat'), findsOneWidget);

      // Aktifkan toggle Split Sleep
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Memastikan section Sesi 1, Jeda Terjaga, Sesi 2, dan Akumulasi muncul
      expect(find.text('Sesi 1: Tidur Pertama'), findsOneWidget);
      expect(find.text('Jam tidur (mulai sesi 1)'), findsOneWidget);
      expect(find.text('Jam terbangun (akhir sesi 1)'), findsOneWidget);
      expect(find.textContaining('Terjaga di tengah malam:'), findsOneWidget);
      expect(find.text('Sesi 2: Tidur Kembali'), findsOneWidget);
      expect(find.text('Jam tidur lagi (mulai sesi 2)'), findsOneWidget);
      expect(find.text('Jam bangun akhir (selesai sesi 2)'), findsOneWidget);
      expect(find.text('Total Akumulasi Tidur'), findsOneWidget);
    });

    testWidgets('2.2. Menyimpan form Split Sleep menyimpan data terakumulasi ke SleepTrackingService', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SleepRecordFormScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Aktifkan switch Split Sleep
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Tekan tombol Simpan
      final simpanBtn = find.text('Simpan');
      await tester.ensureVisible(simpanBtn);
      await tester.tap(simpanBtn);
      await tester.pumpAndSettle();

      // Verifikasi catatan tersimpan di service
      final records = SleepTrackingService.instance.allRecords;
      expect(records.isNotEmpty, isTrue);
      final saved = records.last;
      expect(saved.isSplitSleep, isTrue);
      expect(saved.firstEndTime, isNotNull);
      expect(saved.secondStartTime, isNotNull);
      expect(saved.durationMinutes, saved.firstSessionMinutes! + saved.secondSessionMinutes!);
    });
  });

  group('Uji Admin Home Screen - Kartu Statistik Pengguna Bersifat Statis', () {
    testWidgets('3.1. Kartu Statistik Pengguna dan Total Pengguna tidak dapat diklik (tidak memiliki wrapper InkWell/GestureDetector navigasi)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final adminUser = AuthService.defaultAdminAccount;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: AdminHomeScreen(user: adminUser),
        ),
      );
      await tester.pumpAndSettle();

      // Kartu Total Pengguna dan Statistik Pengguna harus ada di layar
      expect(find.text('Total Pengguna'), findsOneWidget);
      expect(find.text('Statistik Pengguna'), findsOneWidget);

      // Cari elemen Text "Statistik Pengguna"
      final statsTitleFinder = find.text('Statistik Pengguna');
      expect(statsTitleFinder, findsOneWidget);

      // Pastikan widget kartu "Statistik Pengguna" tidak memiliki ancestor InkWell
      final inkWellAncestor = find.ancestor(
        of: statsTitleFinder,
        matching: find.byType(InkWell),
      );
      expect(inkWellAncestor, findsNothing,
          reason: 'Kartu Statistik Pengguna harus statis dan tidak boleh dibungkus InkWell navigasi');

      // Verifikasi kartu Total Pengguna tidak memiliki ancestor GestureDetector langsung untuk navigasi
      final totalPenggunaFinder = find.text('Total Pengguna');
      final gestureAncestor = find.ancestor(
        of: totalPenggunaFinder,
        matching: find.byType(GestureDetector),
      );
      expect(gestureAncestor, findsNothing,
          reason: 'Kartu Total Pengguna harus statis dan tidak boleh dibungkus GestureDetector');
    });
  });
}
