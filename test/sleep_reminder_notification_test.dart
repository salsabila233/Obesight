import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:obesight/screens/progress/night_sleep_detail_screen.dart';
import 'package:obesight/screens/progress/sleep_history_detail_screen.dart';
import 'package:obesight/services/sleep_tracking_service.dart';
import 'package:obesight/theme/app_theme.dart';

void setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Uji Fitur Pengingat Waktu Tidur & Notifikasi Push Lokal', () {
    late SleepTrackingService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = SleepTrackingService.instance;
      await service.clearAll();
      service.bedtimeTarget = const TimeOfDay(hour: 22, minute: 30);
      service.reminderMinutesBefore = 60;
      service.reminderEnabled = true;
    });

    test('1. Perhitungan Jadwal Notifikasi Target Waktu Tidur (1 Jam Sebelumnya)', () {
      expect(service.bedtimeTarget.hour, 22);
      expect(service.bedtimeTarget.minute, 30);
      expect(service.reminderMinutesBefore, 60);

      // Reminder time = 22:30 - 60 menit = 21:30
      expect(service.reminderTime.hour, 21);
      expect(service.reminderTime.minute, 30);
      expect(SleepTrackingService.formatTimeOfDay(service.reminderTime), '21:30');
      expect(SleepTrackingService.formatTimeOfDay(service.bedtimeTarget), '22:30');
    });

    testWidgets('2. UI Halaman Waktu Tidur Malam mencerminkan status pengingat aktif secara real-time', (tester) async {
      setPhoneViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const NightSleepDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Card Pengingat Waktu Tidur tampil
      expect(find.text('Pengingat Waktu Tidur'), findsOneWidget);
      expect(find.text('Target Waktu Tidur'), findsOneWidget);
      expect(find.text('22:30'), findsOneWidget);

      // Keterangan status aktif real-time di background tampil dengan jam yang tepat
      expect(
        find.textContaining('Sistem pengingat aktif otomatis di latar belakang. Anda akan menerima notifikasi setiap malam pukul 21:30'),
        findsOneWidget,
      );

      // Pastikan tombol manual uji coba sudah dibuang sepenuhnya (tampilan bersih)
      expect(find.text('Uji Coba Notifikasi di HP Sekarang'), findsNothing);
    });

    testWidgets('3. Sinkronisasi toggle Switch dan perubahan status informasi real-time', (tester) async {
      setPhoneViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const NightSleepDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      await tester.ensureVisible(switchFinder);
      await tester.pumpAndSettle();

      // Matikan switch pengingat
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(service.reminderEnabled, isFalse);
      expect(
        find.textContaining('Pengingat waktu tidur nonaktif. Aktifkan switch di atas untuk menjadwalkan notifikasi harian otomatis di sistem perangkat Anda.'),
        findsOneWidget,
      );

      // Nyalakan kembali switch pengingat
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(service.reminderEnabled, isTrue);
      expect(
        find.textContaining('Sistem pengingat aktif otomatis di latar belakang. Anda akan menerima notifikasi setiap malam pukul 21:30'),
        findsOneWidget,
      );
    });

    testWidgets('4. Pengingat waktu tidur dihapus dari SleepHistoryDetailScreen (halaman riwayat tidur)', (tester) async {
      setPhoneViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SleepHistoryDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Pengingat waktu tidur dipastikan TIDAK ADA di halaman riwayat tidur
      expect(find.text('Pengingat Waktu Tidur'), findsNothing);
      expect(find.byType(Switch), findsNothing);
    });
  });
}
