import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obesight/screens/progress/activity_rest_detail_screen.dart';
import 'package:obesight/screens/progress/activity_timer_screen.dart';
import 'package:obesight/screens/progress/activity_detail_screen.dart';
import 'package:obesight/services/activity_timer_service.dart';
import 'package:obesight/services/activity_alarm_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ActivityAlarmService.isTestMode = true;
    ActivityTimerService.instance.cancelSession();
    ActivityAlarmService.instance.stopAlarm();
  });

  tearDown(() {
    ActivityTimerService.instance.cancelSession();
    ActivityAlarmService.instance.stopAlarm();
    ActivityAlarmService.isTestMode = false;
  });

  group('Perbaikan Halaman Waktu Istirahat & Alarm', () {
    testWidgets('1. ActivityRestDetailScreen memiliki background utama bersih tanpa background hijau ganda',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ActivityRestDetailScreen(),
        ),
      );
      await tester.pump();

      // Periksa Scaffold background color
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(Colors.white));

      // Pastikan elemen penting tetap ada
      expect(find.text('Waktu Istirahat'), findsWidgets);
      expect(find.text('Pilih Durasi Istirahat'), findsOneWidget);
      expect(find.text('Mulai Istirahat'), findsOneWidget);
      expect(find.text('Tips Pemulihan Optimal'), findsOneWidget);
    });

    testWidgets('2. Timer istirahat selesai memicu alarm otomatis dan menampilkan dialog dengan 2 opsi',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final service = ActivityTimerService.instance;
      final alarmService = ActivityAlarmService.instance;

      final previousActivity = {
        'id': 'jogging',
        'title': 'Jogging Santai',
        'isRest': false,
        'targetText': '30 menit',
      };

      final restActivity = {
        'id': 'rest_activity',
        'title': 'Istirahat Setelah Aktivitas',
        'heroImg': 'assets/progress/rest/hero_aktivitas_clean.png',
        'isRest': true,
        'targetText': '15 menit',
        'previousActivity': previousActivity,
      };

      service.setupSession(
        activity: restActivity,
        presetSeconds: 15 * 60,
      );
      await service.startOrResume();

      await tester.pumpWidget(
        MaterialApp(
          home: ActivityTimerScreen(
            activity: restActivity,
            previousActivity: previousActivity,
          ),
        ),
      );
      await tester.pump();

      expect(alarmService.isPlaying, isFalse);

      // Simulasikan waktu istirahat habis (00:00:00)
      service.triggerTimeCompletedForTesting();
      await tester.pumpAndSettle();

      // Verifikasi alarm otomatis berbunyi
      expect(service.isCompleted, isTrue);
      expect(alarmService.isPlaying, isTrue);
      expect(alarmService.currentAlarmType, equals('rest'));

      // Verifikasi Dialog muncul dengan teks dan 2 pilihan
      expect(find.text('Istirahat Selesai! 🌿'), findsOneWidget);
      expect(find.descendant(of: find.byType(Dialog), matching: find.text('00 : 00 : 00')), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);
      expect(find.text('Lanjutkan Aktivitas'), findsOneWidget);

      // Uji opsi A: Tekan "Selesai"
      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();

      // Verifikasi alarm berhenti dan sesi istirahat selesai
      expect(alarmService.isPlaying, isFalse);
      expect(service.isIdle, isTrue);
    });

    testWidgets('3. Opsi "Lanjutkan Aktivitas" menghentikan alarm, mengakhiri istirahat, dan kembali ke aktivitas sebelumnya',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final service = ActivityTimerService.instance;
      final alarmService = ActivityAlarmService.instance;

      final previousActivity = {
        'id': 'jogging',
        'title': 'Jogging',
        'name': 'Jogging',
        'type': 'aerobic',
        'category': 'Kardio Ringan',
        'durationMinutes': 30,
        'durationText': '30-45 menit',
        'targetText': '30 menit',
        'calPerMinute': 8.0,
        'heroImg': 'assets/progress/clean/hero_jogging.png',
        'iconImg': 'assets/progress/icons/ic_jogging.png',
        'thumbImg': 'assets/progress/clean/hero_jogging.png',
        'isRest': false,
      };

      final restActivity = {
        'id': 'rest_activity',
        'title': 'Istirahat Setelah Aktivitas',
        'heroImg': 'assets/progress/rest/hero_aktivitas_clean.png',
        'isRest': true,
        'targetText': '10 menit',
        'previousActivity': previousActivity,
      };

      service.setupSession(
        activity: restActivity,
        presetSeconds: 10 * 60,
      );
      await service.startOrResume();

      await tester.pumpWidget(
        MaterialApp(
          home: ActivityTimerScreen(
            activity: restActivity,
            previousActivity: previousActivity,
          ),
        ),
      );
      await tester.pump();

      // Selesaikan waktu istirahat
      service.triggerTimeCompletedForTesting();
      await tester.pumpAndSettle();

      expect(alarmService.isPlaying, isTrue);

      // Tekan tombol "Lanjutkan Aktivitas"
      await tester.tap(find.text('Lanjutkan Aktivitas'));
      await tester.pumpAndSettle();

      // Verifikasi alarm berhenti dan sesi istirahat diakhiri
      expect(alarmService.isPlaying, isFalse);
      expect(service.isIdle, isTrue);

      // Verifikasi layar berpindah ke ActivityDetailScreen untuk aktivitas sebelumnya
      expect(find.byType(ActivityDetailScreen), findsOneWidget);
      expect(find.text('Jogging'), findsWidgets);
    });

    test('4. Mode alarm istirahat dan aktivitas fisik berjalan terkendali satu kali per sesi', () async {
      final service = ActivityTimerService.instance;
      final alarmService = ActivityAlarmService.instance;

      service.setupSession(
        activity: {'id': 'rest_activity', 'title': 'Istirahat', 'isRest': true},
        presetSeconds: 5 * 60,
      );
      await service.startOrResume();

      // Memicu selesai
      service.triggerTimeCompletedForTesting();
      expect(service.alarmTriggeredForSession, isTrue);
      expect(alarmService.isPlaying, isTrue);

      // Panggilan berulang tidak menyebabkan alarm berdering ganda
      service.triggerTimeCompletedForTesting();
      expect(service.alarmTriggeredForSession, isTrue);

      // Stop alarm
      await alarmService.stopAlarm();
      expect(alarmService.isPlaying, isFalse);
    });
  });
}

