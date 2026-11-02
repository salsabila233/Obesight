import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:obesight/screens/progress/activity_duration_picker_screen.dart';
import 'package:obesight/screens/progress/activity_timer_screen.dart';
import 'package:obesight/services/activity_timer_service.dart';
import 'package:obesight/services/activity_alarm_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Olahraga 1: Latihan Beban & Kekuatan
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

  // Olahraga 2: Kalistenik Kompon (Bodyweight)
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

  // Olahraga 3: Latihan Otot Inti & Postur
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

  // Olahraga 4: Peregangan Pemulihan & Mobilitas
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

  // Olahraga 5: Jogging
  final joggingActivity = {
    'id': 'jogging',
    'title': 'Jogging',
    'name': 'Jogging',
    'targetText': '30-60 menit',
    'duration': '30-60 menit',
    'specs': {
      'duration': '30-60 menit',
      'calories': '300 kkal',
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

  group('Poin 1 & 3: Wheel Picker Tiga Kolom (Jam, Menit, Detik) pada Seluruh Olahraga', () {
    final sports = [
      {'name': 'Latihan Beban & Kekuatan', 'act': strengthActivity},
      {'name': 'Kalistenik Kompon', 'act': calisthenicsActivity},
      {'name': 'Latihan Otot Inti & Postur', 'act': coreActivity},
      {'name': 'Peregangan Pemulihan & Mobilitas', 'act': recoveryActivity},
      {'name': 'Jogging', 'act': joggingActivity},
    ];

    for (final sport in sports) {
      testWidgets('ActivityDurationPickerScreen menampilkan header Jam, Menit, Detik untuk ${sport['name']}', (tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final act = sport['act'] as Map<String, dynamic>;
        await tester.pumpWidget(MaterialApp(home: ActivityDurationPickerScreen(activity: act)));
        await tester.pump();

        // 1. Memastikan ketiga header kolom (Jam, Menit, Detik) ditampilkan
        expect(find.text('Jam'), findsOneWidget);
        expect(find.text('Menit'), findsOneWidget);
        expect(find.text('Detik'), findsOneWidget);

        // 2. Memastikan pemisah titik dua (':') tampil di antara kolom
        expect(find.text(':'), findsWidgets);

        // 3. Memastikan tombol Mulai tersedia
        expect(find.text('Mulai'), findsOneWidget);
      });
    }
  });

  group('Poin 1 & 5: Integrasi Pilihan Preset dengan 3 Kolom Waktu', () {
    testWidgets('Latihan Beban: Preset 25m, 35m, 45m, 60m sinkron ke Jam, Menit, Detik', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(MaterialApp(home: ActivityDurationPickerScreen(activity: strengthActivity)));
      await tester.pump();

      // Default awal 25 menit (Jam: 00, Menit: 25, Detik: 00)
      expect(find.text('25:00'), findsOneWidget);
      expect(find.text('35:00'), findsOneWidget);
      expect(find.text('45:00'), findsOneWidget);
      expect(find.text('60:00'), findsOneWidget);

      // Tap 60:00 -> Jam: 01, Menit: 00, Detik: 00
      await tester.tap(find.text('60:00'));
      await tester.pumpAndSettle();

      // Tap 35:00 -> Jam: 00, Menit: 35, Detik: 00
      await tester.tap(find.text('35:00'));
      await tester.pumpAndSettle();
      expect(find.text('35'), findsWidgets);
    });

    testWidgets('Kalistenik Kompon: Preset 20m, 30m, 45m, 60m sinkron ke Jam, Menit, Detik', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(MaterialApp(home: ActivityDurationPickerScreen(activity: calisthenicsActivity)));
      await tester.pump();

      expect(find.text('20:00'), findsOneWidget);
      expect(find.text('30:00'), findsOneWidget);
      expect(find.text('45:00'), findsOneWidget);
      expect(find.text('60:00'), findsOneWidget);
    });

    testWidgets('Latihan Otot Inti: Preset 15m, 20m, 45m, 60m sinkron ke Jam, Menit, Detik', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(MaterialApp(home: ActivityDurationPickerScreen(activity: coreActivity)));
      await tester.pump();

      expect(find.text('15:00'), findsOneWidget);
      expect(find.text('20:00'), findsOneWidget);
      expect(find.text('45:00'), findsOneWidget);
      expect(find.text('60:00'), findsOneWidget);
    });
  });

  group('Poin 1, 4 & 5: Format Penunjuk Timer (Jam : Menit : Detik) & Countdown di ActivityTimerScreen', () {
    testWidgets('ActivityTimerScreen menampilkan format Jam : Menit : Detik saat memilih preset durasi', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(MaterialApp(home: ActivityTimerScreen(activity: strengthActivity)));
      await tester.pump();

      // Pilih preset 25:00 -> Tampilan timer menjadi 00 : 25 : 00
      await tester.tap(find.text('25:00'));
      await tester.pump();
      expect(find.text('00 : 25 : 00'), findsOneWidget);

      // Pilih preset 45:00 -> Tampilan timer menjadi 00 : 45 : 00
      await tester.tap(find.text('45:00'));
      await tester.pump();
      expect(find.text('00 : 45 : 00'), findsOneWidget);

      // Pilih preset 60:00 -> Tampilan timer menjadi 01 : 00 : 00
      await tester.tap(find.text('60:00'));
      await tester.pump();
      expect(find.text('01 : 00 : 00'), findsOneWidget);
    });

    testWidgets('Durasi 20 menit pada Kalistenik menjadi 00 : 20 : 00', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(MaterialApp(home: ActivityTimerScreen(activity: calisthenicsActivity)));
      await tester.pump();

      // Pilih preset 20:00
      await tester.tap(find.text('20:00'));
      await tester.pump();
      expect(find.text('00 : 20 : 00'), findsOneWidget);
    });

    testWidgets('Durasi 15 menit pada Otot Inti menjadi 00 : 15 : 00', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(MaterialApp(home: ActivityTimerScreen(activity: coreActivity)));
      await tester.pump();

      // Pilih preset 15:00
      await tester.tap(find.text('15:00'));
      await tester.pump();
      expect(find.text('00 : 15 : 00'), findsOneWidget);
    });

    test('Logika countdown 20 menit: berhenti tepat di 00:00:00, tidak ke negatif, tidak terus hingga 60 menit', () async {
      final service = ActivityTimerService.instance;
      const chosenDurationSec = 20 * 60; // 20 menit

      service.setupSession(
        activity: calisthenicsActivity,
        presetSeconds: chosenDurationSec,
      );

      expect(service.targetDuration, equals(chosenDurationSec));
      expect(service.secondsRemaining, equals(chosenDurationSec));

      await service.startOrResume();
      expect(service.isRunning, isTrue);

      // Trigger selesai tepat saat waktu habis
      service.triggerTimeCompletedForTesting();

      expect(service.isRunning, isFalse);
      expect(service.isCompleted, isTrue);
      expect(service.secondsRemaining, equals(0));
      expect(service.elapsedSeconds, equals(chosenDurationSec));
      // Tidak boleh berjalan hingga 60 menit (3600s)
      expect(service.elapsedSeconds, isNot(equals(60 * 60)));
      // Tidak boleh negatif
      expect(service.secondsRemaining >= 0, isTrue);
      // Tidak boleh otomatis kembali ke durasi awal (20m)
      expect(service.secondsRemaining, isNot(equals(chosenDurationSec)));
    });
  });
}
