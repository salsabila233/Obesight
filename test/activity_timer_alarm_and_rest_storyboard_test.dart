import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:obesight/screens/progress/activity_timer_screen.dart';
import 'package:obesight/screens/progress/activity_duration_picker_screen.dart';
import 'package:obesight/services/activity_timer_service.dart';
import 'package:obesight/services/activity_alarm_service.dart';
import 'package:obesight/services/activity_rest_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ActivityAlarmService.isTestMode = true;
    ActivityTimerService.instance.cancelSession();
    ActivityAlarmService.instance.stopAlarm();
  });

  tearDown(() {
    ActivityTimerService.instance.cancelSession();
    ActivityAlarmService.instance.stopAlarm();
    ActivityAlarmService.isTestMode = false;
  });

  group('ActivityRestHelper & Recommendation Unit Tests', () {
    test('Clamps activity duration between 15 and 60 minutes correctly', () {
      expect(ActivityRestHelper.clampActivityDuration(10), equals(15));
      expect(ActivityRestHelper.clampActivityDuration(14), equals(15));
      expect(ActivityRestHelper.clampActivityDuration(15), equals(15));
      expect(ActivityRestHelper.clampActivityDuration(35), equals(35));
      expect(ActivityRestHelper.clampActivityDuration(60), equals(60));
      expect(ActivityRestHelper.clampActivityDuration(90), equals(60));
    });

    test('ActivityTimerService setDurationMinutes validates and updates target duration', () {
      final service = ActivityTimerService.instance;
      service.setupSession(activity: {'id': 'jalan_cepat', 'title': 'Jalan Cepat'});

      // Set valid duration (e.g. 25 minutes)
      service.setDurationMinutes(25);
      expect(service.targetDuration, equals(25 * 60));
      expect(service.selectedPreset, equals(25 * 60));

      // Set out-of-bounds duration clamped to min 15
      service.setDurationMinutes(8);
      expect(service.targetDuration, equals(15 * 60));

      // Set out-of-bounds duration clamped to max 60
      service.setDurationMinutes(99);
      expect(service.targetDuration, equals(60 * 60));
    });
  });

  group('Storyboard Panel 5: ActivityDurationPickerScreen Widget Tests', () {
    testWidgets('Renders number picker wheel, helper text, and activity card', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        ActivityTimerService.instance.cancelSession();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final activity = {
        'id': 'jalan_cepat',
        'title': 'Jalan Cepat',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: ActivityDurationPickerScreen(activity: activity),
        ),
      );
      await tester.pump();

      // Header & Target
      expect(find.text('Target'), findsOneWidget);
      expect(find.text('Jalan Cepat'), findsOneWidget);

      // Tombol Mulai
      expect(find.text('Mulai'), findsOneWidget);

      // Tap Mulai sets the timer and navigates to ActivityTimerScreen
      await tester.tap(find.text('Mulai'));
      await tester.pumpAndSettle();

      expect(ActivityTimerService.instance.isRunning, isTrue);
      expect(ActivityTimerService.instance.targetDuration >= 15 * 60, isTrue);
      expect(find.byType(ActivityTimerScreen), findsOneWidget);

      // Clean up running timer before test completes
      ActivityTimerService.instance.cancelSession();
      await tester.pump();
    });
  });

  group('Storyboard Panel 3: Alarm & Completion Dialog Widget Tests', () {
    testWidgets('Timer completion displays explicit 00:00 and single Selesai button', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        ActivityTimerService.instance.cancelSession();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final activity = {
        'id': 'jalan_cepat',
        'title': 'Jalan Cepat',
        'isRest': false,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: ActivityTimerScreen(activity: activity),
        ),
      );
      await tester.pump();

      // Trigger timer natural completion (00:00)
      ActivityTimerService.instance.triggerTimeCompletedForTesting();
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify Alarm sound was triggered
      expect(ActivityAlarmService.instance.isPlaying, isTrue);
      expect(ActivityAlarmService.instance.currentAlarmType, equals('activity'));

      // Verify Dialog Elements from Storyboard Panel 3
      expect(find.text('Waktu Aktivitas Habis'), findsOneWidget);
      expect(find.text('00:00'), findsWidgets); // Dialog explicit 00:00
      expect(find.text('Selesai'), findsOneWidget);

      // Tapping "Selesai" stops alarm and cleans timer session
      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();

      expect(ActivityAlarmService.instance.isPlaying, isFalse);
      expect(ActivityTimerService.instance.isIdle, isTrue);
    });
  });
}
