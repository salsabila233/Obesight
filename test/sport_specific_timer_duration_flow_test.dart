import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:obesight/screens/progress/activity_duration_picker_screen.dart';
import 'package:obesight/screens/progress/activity_timer_screen.dart';
import 'package:obesight/services/activity_timer_service.dart';
import 'package:obesight/services/activity_alarm_service.dart';
import 'package:obesight/services/activity_rest_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 1. Data Aktivitas Latihan Beban & Kekuatan
  final strengthActivity = {
    'id': 'underweight_strength',
    'title': 'Latihan Beban & Angkat Beban (Strength Training)',
    'name': 'Latihan Beban & Kekuatan (Strength)',
    'targetText': '25-35 menit',
    'duration': '25-35 menit',
    'specs': {
      'duration': '25-35 menit',
      'frequency': '3-4 kali/minggu',
      'intensity': 'Sedang (55-70% HRmax)',
      'calories': '130-220 kkal',
    },
    'isRest': false,
  };

  // 2. Data Aktivitas Kalistenik Kompon (Bodyweight)
  final calisthenicsActivity = {
    'id': 'underweight_calisthenics',
    'title': 'Kalistenik Kompon (Push-up, Inverted Row & Squat)',
    'name': 'Kalistenik Kompon (Bodyweight)',
    'targetText': '20-30 menit',
    'duration': '20-30 menit',
    'specs': {
      'duration': '20-30 menit',
      'frequency': '3 kali/minggu',
      'intensity': 'Sedang (50-65% HRmax)',
      'calories': '110-180 kkal',
    },
    'isRest': false,
  };

  // 3. Data Aktivitas Latihan Otot Inti & Postur
  final coreActivity = {
    'id': 'underweight_core',
    'title': 'Latihan Otot Inti & Stabilitas Postur (Core & Plank)',
    'name': 'Latihan Otot Inti & Postur',
    'targetText': '15-20 menit',
    'duration': '15-20 menit',
    'specs': {
      'duration': '15-20 menit',
      'frequency': '3 kali/minggu',
      'intensity': 'Sedang (50-65% HRmax)',
      'calories': '80-140 kkal',
    },
    'isRest': false,
  };

  // 4. Data Aktivitas Peregangan Pemulihan & Mobilitas
  final recoveryActivity = {
    'id': 'underweight_recovery',
    'title': 'Peregangan Pemulihan & Mobilitas (Stretching & Light Walk)',
    'name': 'Peregangan Pemulihan & Mobilitas',
    'targetText': '15-20 menit',
    'duration': '15-20 menit',
    'specs': {
      'duration': '15-20 menit',
      'frequency': '2-3 kali/minggu',
      'intensity': 'Ringan (35-45% HRmax)',
      'calories': '60-100 kkal',
    },
    'isRest': false,
  };

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ActivityAlarmService.isTestMode = true;
    ActivityTimerService.instance.cancelSession();
    ActivityAlarmService.instance.stopAlarm();
    ActivityTimerService.instance.setTimerScreenActive(false);
  });

  tearDown(() {
    ActivityTimerService.instance.cancelSession();
    ActivityAlarmService.instance.stopAlarm();
    ActivityAlarmService.isTestMode = false;
    ActivityTimerService.instance.setTimerScreenActive(false);
  });

  group('Poin 1 & 3: Konfigurasi Opsi Durasi Berdasarkan Jenis Olahraga', () {
    test('Latihan Beban & Kekuatan memiliki pilihan durasi 25, 35, 45, 60 menit', () {
      final options = ActivityRestHelper.getActivityDurationOptions(strengthActivity);
      expect(options, equals([25, 35, 45, 60]));
      expect(ActivityRestHelper.getMinActivityDuration(strengthActivity), equals(25));
      expect(ActivityRestHelper.getMaxActivityDuration(strengthActivity), equals(60));
    });

    test('Kalistenik Kompon (Bodyweight) memiliki pilihan durasi 20, 30, 45, 60 menit', () {
      final options = ActivityRestHelper.getActivityDurationOptions(calisthenicsActivity);
      expect(options, equals([20, 30, 45, 60]));
      expect(ActivityRestHelper.getMinActivityDuration(calisthenicsActivity), equals(20));
      expect(ActivityRestHelper.getMaxActivityDuration(calisthenicsActivity), equals(60));
    });

    test('Latihan Otot Inti & Postur memiliki pilihan durasi 15, 20, 45, 60 menit', () {
      final options = ActivityRestHelper.getActivityDurationOptions(coreActivity);
      expect(options, equals([15, 20, 45, 60]));
      expect(ActivityRestHelper.getMinActivityDuration(coreActivity), equals(15));
      expect(ActivityRestHelper.getMaxActivityDuration(coreActivity), equals(60));
    });

    test('Peregangan Pemulihan & Mobilitas memiliki pilihan durasi 15, 20, 45, 60 menit', () {
      final options = ActivityRestHelper.getActivityDurationOptions(recoveryActivity);
      expect(options, equals([15, 20, 45, 60]));
      expect(ActivityRestHelper.getMinActivityDuration(recoveryActivity), equals(15));
      expect(ActivityRestHelper.getMaxActivityDuration(recoveryActivity), equals(60));
    });
  });

  group('Poin 1: Tampilan UI Duration Picker & Wheel Sync Berdasarkan Jenis Olahraga', () {
    testWidgets('Latihan Beban menampilkan preset 25:00, 35:00, 45:00, 60:00 dan sync ke wheel picker', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(home: ActivityDurationPickerScreen(activity: strengthActivity)),
      );
      await tester.pump();

      // Memastikan seluruh 4 preset ditampilkan
      expect(find.text('25:00'), findsOneWidget);
      expect(find.text('35:00'), findsOneWidget);
      expect(find.text('45:00'), findsOneWidget);
      expect(find.text('60:00'), findsOneWidget);

      // Preset default awal adalah 25:00 (rekomendasi pertama)
      // Nilai pada wheel picker kiri (Jam) adalah 25
      expect(find.text('25'), findsWidgets);

      // Tap preset 35:00
      await tester.tap(find.text('35:00'));
      await tester.pumpAndSettle();

      // Nilai 35 sekarang aktif dan berada pada wheel picker
      expect(find.text('35'), findsWidgets);
    });

    testWidgets('Kalistenik Kompon menampilkan preset 20:00, 30:00, 45:00, 60:00', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(home: ActivityDurationPickerScreen(activity: calisthenicsActivity)),
      );
      await tester.pump();

      expect(find.text('20:00'), findsOneWidget);
      expect(find.text('30:00'), findsOneWidget);
      expect(find.text('45:00'), findsOneWidget);
      expect(find.text('60:00'), findsOneWidget);

      // Default awal 20
      expect(find.text('20'), findsWidgets);
    });

    testWidgets('Latihan Otot Inti & Postur menampilkan preset 15:00, 20:00, 45:00, 60:00', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(home: ActivityDurationPickerScreen(activity: coreActivity)),
      );
      await tester.pump();

      expect(find.text('15:00'), findsOneWidget);
      expect(find.text('20:00'), findsOneWidget);
      expect(find.text('45:00'), findsOneWidget);
      expect(find.text('60:00'), findsOneWidget);

      // Default awal 15
      expect(find.text('15'), findsWidgets);
    });

    testWidgets('Peregangan Pemulihan & Mobilitas menampilkan preset 15:00, 20:00, 45:00, 60:00', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(home: ActivityDurationPickerScreen(activity: recoveryActivity)),
      );
      await tester.pump();

      expect(find.text('15:00'), findsOneWidget);
      expect(find.text('20:00'), findsOneWidget);
      expect(find.text('45:00'), findsOneWidget);
      expect(find.text('60:00'), findsOneWidget);

      // Default awal 15
      expect(find.text('15'), findsWidgets);
    });
  });

  group('Poin 1 & 3: ActivityTimerScreen Menampilkan Preset Sesuai Jenis Olahraga', () {
    testWidgets('ActivityTimerScreen Latihan Beban menampilkan chip preset 25:00, 35:00, 45:00, 60:00', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(home: ActivityTimerScreen(activity: strengthActivity)),
      );
      await tester.pump();

      expect(find.text('25:00'), findsOneWidget);
      expect(find.text('35:00'), findsOneWidget);
      expect(find.text('45:00'), findsOneWidget);
      expect(find.text('60:00'), findsOneWidget);

      // Tap preset 25:00
      await tester.tap(find.text('25:00'));
      await tester.pump();

      expect(ActivityTimerService.instance.targetDuration, equals(25 * 60));
      expect(ActivityTimerService.instance.secondsRemaining, equals(25 * 60));
    });

    testWidgets('ActivityTimerScreen Otot Inti menampilkan chip preset 15:00, 20:00, 45:00, 60:00', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(home: ActivityTimerScreen(activity: coreActivity)),
      );
      await tester.pump();

      expect(find.text('15:00'), findsOneWidget);
      expect(find.text('20:00'), findsOneWidget);
      expect(find.text('45:00'), findsOneWidget);
      expect(find.text('60:00'), findsOneWidget);
    });
  });

  group('Poin 2: Verifikasi Mekanisme Countdown Timer Akurat pada Seluruh Durasi', () {
    final durationsToTest = [
      {'minutes': 15, 'seconds': 15 * 60, 'act': coreActivity},
      {'minutes': 20, 'seconds': 20 * 60, 'act': calisthenicsActivity},
      {'minutes': 25, 'seconds': 25 * 60, 'act': strengthActivity},
      {'minutes': 30, 'seconds': 30 * 60, 'act': calisthenicsActivity},
      {'minutes': 35, 'seconds': 35 * 60, 'act': strengthActivity},
      {'minutes': 45, 'seconds': 45 * 60, 'act': strengthActivity},
      {'minutes': 60, 'seconds': 60 * 60, 'act': strengthActivity},
    ];

    for (final item in durationsToTest) {
      final mins = item['minutes'] as int;
      final expectedSecs = item['seconds'] as int;
      final act = item['act'] as Map<String, dynamic>;

      test('Timer berhenti tepat pada durasi yang dipilih: $mins menit ($expectedSecs detik)', () async {
        final service = ActivityTimerService.instance;
        service.setupSession(
          activity: act,
          presetSeconds: expectedSecs,
        );

        // Memastikan countdown dimulai dari durasi yang dipilih
        expect(service.targetDuration, equals(expectedSecs));
        expect(service.secondsRemaining, equals(expectedSecs));
        expect(service.elapsedSeconds, equals(0));

        await service.startOrResume();
        expect(service.isRunning, isTrue);

        // Mensimulasikan penyelesaian timer secara natural tepat saat waktu habis
        service.triggerTimeCompletedForTesting();

        // Ketika countdown mencapai 00:00, timer langsung berhenti
        expect(service.isRunning, isFalse);
        expect(service.isCompleted, isTrue);

        // Timer tidak boleh berubah menjadi negatif
        expect(service.secondsRemaining, equals(0));
        expect(service.secondsRemaining >= 0, isTrue);

        // Timer tidak boleh terus berjalan setelah mencapai 00:00
        expect(service.elapsedSeconds, equals(expectedSecs));

        // Timer tidak boleh otomatis kembali ke durasi awal setelah selesai
        expect(service.secondsRemaining, equals(0));
        expect(service.secondsRemaining, isNot(equals(expectedSecs)));

        // Tombol togglePlayPause / startOrResume tidak boleh menjalankan timer yang sudah completed
        await service.togglePlayPause();
        expect(service.isRunning, isFalse);
        expect(service.isCompleted, isTrue);
      });
    }

    test('Tidak ada timer ganda saat startOrResume dipanggil berkali-kali secara bersamaan', () async {
      final service = ActivityTimerService.instance;
      service.setupSession(
        activity: strengthActivity,
        presetSeconds: 25 * 60,
      );

      // Panggil startOrResume beberapa kali secara simultan
      await Future.wait([
        service.startOrResume(),
        service.startOrResume(),
        service.startOrResume(),
      ]);

      expect(service.isRunning, isTrue);
      expect(service.targetDuration, equals(25 * 60));

      // Pause dan resume tetap berjalan normal
      service.pause();
      expect(service.isPaused, isTrue);
      expect(service.isRunning, isFalse);

      await service.startOrResume();
      expect(service.isRunning, isTrue);

      service.cancelSession();
      expect(service.isIdle, isTrue);
      expect(service.secondsRemaining, equals(0));
    });
  });
}
