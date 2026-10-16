import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obesight/screens/progress/activity_timer_screen.dart';
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

  group('ActivityTimerService & Alarm Unit Tests', () {
    test('Timer initializes idle with zero duration and clamped seconds', () {
      final service = ActivityTimerService.instance;
      expect(service.isIdle, isTrue);
      expect(service.isRunning, isFalse);
      expect(service.secondsRemaining, equals(0));
      expect(service.elapsedSeconds, equals(0));
      expect(service.alarmTriggeredForSession, isFalse);
    });

    test('Presets (15-60 mins) set target duration properly without negative values', () {
      final service = ActivityTimerService.instance;
      service.setupSession(
        activity: {'id': 'jogging', 'title': 'Jogging'},
        presetSeconds: 30 * 60,
      );

      expect(service.targetDuration, equals(1800));
      expect(service.secondsRemaining, equals(1800));
      expect(service.secondsRemaining >= 0, isTrue);

      service.setPreset(45 * 60);
      expect(service.targetDuration, equals(2700));
      expect(service.secondsRemaining, equals(2700));

      service.setPreset(60 * 60);
      expect(service.targetDuration, equals(3600));
      expect(service.secondsRemaining, equals(3600));
    });

    test('Activity alarm triggers exactly once per session when completed', () async {
      final service = ActivityTimerService.instance;
      final alarmService = ActivityAlarmService.instance;

      service.setupSession(
        activity: {'id': 'jogging', 'title': 'Jogging', 'isRest': false},
        presetSeconds: 15 * 60,
      );

      expect(service.alarmTriggeredForSession, isFalse);
      expect(alarmService.isPlaying, isFalse);

      await service.startOrResume();
      expect(service.isRunning, isTrue);

      // Simulasikan timer mencapai 00:00
      service.triggerTimeCompletedForTesting();
      expect(service.isCompleted, isTrue);
      expect(service.alarmTriggeredForSession, isTrue);
      expect(alarmService.isPlaying, isTrue);
      expect(alarmService.currentAlarmType, equals('activity'));

      // Panggilan berulang tidak memicu alarm kedua
      service.triggerTimeCompletedForTesting();
      expect(service.alarmTriggeredForSession, isTrue);

      // Cancel session harus menghentikan alarm dan mereset sesi
      service.cancelSession();
      expect(service.isIdle, isTrue);
      expect(service.alarmTriggeredForSession, isFalse);
      expect(alarmService.isPlaying, isFalse);
    });

    test('Rest alarm triggers with rest sound when completed', () async {
      final service = ActivityTimerService.instance;
      final alarmService = ActivityAlarmService.instance;

      service.setupSession(
        activity: {'id': 'rest_activity', 'title': 'Istirahat Setelah Aktivitas', 'isRest': true},
        presetSeconds: 10 * 60,
      );

      await service.startOrResume();
      expect(service.isRunning, isTrue);

      // Simulasikan timer istirahat mencapai 00:00
      service.triggerTimeCompletedForTesting();
      expect(service.isCompleted, isTrue);
      expect(service.alarmTriggeredForSession, isTrue);
      expect(alarmService.isPlaying, isTrue);
      expect(alarmService.currentAlarmType, equals('rest'));

      // Hentikan alarm
      await alarmService.stopAlarm();
      expect(alarmService.isPlaying, isFalse);
    });

    test('Rest timer and physical activity timer do not run concurrently', () async {
      final service = ActivityTimerService.instance;

      // Start physical activity
      service.setupSession(
        activity: {'id': 'yoga', 'title': 'Yoga', 'isRest': false},
        presetSeconds: 15 * 60,
      );
      await service.startOrResume();
      expect(service.isRunning, isTrue);
      expect(service.activeActivity?['isRest'], isFalse);

      // Setup rest activity cancels/replaces previous running activity
      service.setupSession(
        activity: {'id': 'rest_activity', 'title': 'Istirahat Setelah Aktivitas', 'isRest': true},
        presetSeconds: 15 * 60,
      );

      // The new session is fresh and idle until started
      expect(service.isIdle, isTrue);
      expect(service.isRunning, isFalse);
      expect(service.activeActivity?['isRest'], isTrue);
    });

    test('ActivityAlarmService play and stop methods operate safely', () async {
      final alarmService = ActivityAlarmService.instance;

      // Play activity alarm
      await alarmService.playActivityAlarm();
      expect(alarmService.currentAlarmType, equals('activity'));

      // Stop alarm
      await alarmService.stopAlarm();
      expect(alarmService.isPlaying, isFalse);
      expect(alarmService.currentAlarmType, isNull);

      // Play rest alarm
      await alarmService.playRestAlarm();
      expect(alarmService.currentAlarmType, equals('rest'));

      // Stop alarm again
      await alarmService.stopAlarm();
      expect(alarmService.isPlaying, isFalse);
      expect(alarmService.currentAlarmType, isNull);
    });
  });

  group('ActivityTimerScreen Widget Tests', () {
    testWidgets('Renders activity timer screen with presets and controls', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final activity = {
        'id': 'jogging',
        'title': 'Jogging',
        'targetText': '30-60 menit',
        'heroImg': 'assets/progress/clean/hero_jogging.png',
        'isRest': false,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: ActivityTimerScreen(activity: activity),
        ),
      );
      await tester.pump();

      expect(find.text('Jogging'), findsWidgets);
      expect(find.text('30-60 menit'), findsOneWidget);
      expect(find.text('30:00'), findsOneWidget);
      expect(find.text('45:00'), findsOneWidget);
      expect(find.text('60:00'), findsOneWidget);
      expect(find.text('Selesaikan Aktivitas'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);

      // Test preset selection
      await tester.tap(find.text('30:00'));
      await tester.pump();
      expect(find.text('30:00'), findsNWidgets(2)); // Preset button and large circle

      // Test Batal stops session and alarm
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(ActivityTimerService.instance.isIdle, isTrue);
    });

    testWidgets('Renders rest timer screen with rest presets (10, 15, 20 mins)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final restActivity = {
        'id': 'rest_activity',
        'title': 'Istirahat Setelah Aktivitas',
        'heroImg': 'assets/progress/rest/hero_aktivitas.png',
        'isRest': true,
        'targetText': '15 menit',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: ActivityTimerScreen(activity: restActivity),
        ),
      );
      await tester.pump();

      expect(find.text('Istirahat Setelah\nAktivitas'), findsOneWidget);
      expect(find.text('Durasi Istirahat'), findsOneWidget);
      expect(find.text('15 menit'), findsOneWidget);

      // Rest presets: 10:00, 15:00, 20:00
      expect(find.text('10:00'), findsOneWidget);
      expect(find.text('15:00'), findsNWidgets(2)); // preset & default display
      expect(find.text('20:00'), findsOneWidget);
      expect(find.text('Selesaikan Istirahat'), findsOneWidget);
    });
  });
}
