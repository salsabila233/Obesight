import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:obesight/screens/progress/activity_timer_screen.dart';
import 'package:obesight/screens/progress/activity_duration_picker_screen.dart';
import 'package:obesight/screens/progress/activity_rest_detail_screen.dart';
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

    test('Provides contextual rest recommendation based on activity type and intensity', () {
      // 1. Jalan Cepat -> 10 menit
      expect(
        ActivityRestHelper.getRecommendedRestMinutes(
          activity: {'id': 'jalan_cepat', 'title': 'Jalan Cepat'},
        ),
        equals(10),
      );

      // 2. Yoga / Stretching -> 5 menit (atau 10 menit jika durasi latihan > 30m)
      expect(
        ActivityRestHelper.getRecommendedRestMinutes(
          activity: {'id': 'yoga', 'title': 'Yoga'},
          completedDurationMinutes: 20,
        ),
        equals(5),
      );
      expect(
        ActivityRestHelper.getRecommendedRestMinutes(
          activity: {'id': 'yoga', 'title': 'Yoga'},
          completedDurationMinutes: 40,
        ),
        equals(10),
      );

      // 3. Senam Ringan -> 15 menit
      expect(
        ActivityRestHelper.getRecommendedRestMinutes(
          activity: {'id': 'senam', 'title': 'Senam Ringan'},
        ),
        equals(15),
      );

      // 4. Bersepeda Ringan -> 15 menit
      expect(
        ActivityRestHelper.getRecommendedRestMinutes(
          activity: {'id': 'cycling', 'title': 'Bersepeda Ringan'},
        ),
        equals(15),
      );

      // 5. Lari / HIIT Ringan -> 20 menit (atau 30m jika >= 45m)
      expect(
        ActivityRestHelper.getRecommendedRestMinutes(
          activity: {'id': 'hiit', 'title': 'High-Intensity Interval Training'},
          completedDurationMinutes: 20,
        ),
        equals(20),
      );
      expect(
        ActivityRestHelper.getRecommendedRestMinutes(
          activity: {'id': 'hiit', 'title': 'High-Intensity Interval Training'},
          completedDurationMinutes: 50,
        ),
        equals(30),
      );

      // 6. Latihan Intensitas Tinggi -> 30 menit
      expect(
        ActivityRestHelper.getRecommendedRestMinutes(
          activity: {'id': 'bodyweight', 'title': 'Latihan Intensitas Tinggi'},
        ),
        equals(30),
      );
    });

    test('Filters available rest options according to activity intensity', () {
      // Jalan cepat: 5, 10, 15, 20, 30 menit
      final jalanOptions = ActivityRestHelper.getAvailableRestOptions({'title': 'Jalan Cepat'});
      expect(jalanOptions.map((o) => o.minutes).toList(), equals([5, 10, 15, 20, 30]));

      // HIIT: 10, 15, 20, 30 menit
      final hiitOptions = ActivityRestHelper.getAvailableRestOptions({'title': 'HIIT'});
      expect(hiitOptions.map((o) => o.minutes).toList(), equals([10, 15, 20, 30]));

      // Latihan Intensitas Tinggi: 15, 20, 30 menit
      final tinggiOptions = ActivityRestHelper.getAvailableRestOptions({'title': 'Latihan Intensitas Tinggi'});
      expect(tinggiOptions.map((o) => o.minutes).toList(), equals([15, 20, 30]));
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

      // Header
      expect(find.text('Mulai Timer'), findsOneWidget);
      expect(find.text('Atur durasi aktivitas fisik sesuai kebutuhanmu.'), findsOneWidget);

      // Helper Text
      expect(find.text('Durasi minimal 15 menit dan maksimal 60 menit.'), findsOneWidget);

      // Card Aktivitas Fisik
      expect(find.text('Aktivitas Fisik'), findsOneWidget);
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

  group('Storyboard Panel 4: ActivityRestDetailScreen Widget Tests', () {
    testWidgets('Renders rest selection page with 5 duration cards and contextual recommendation', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        ActivityTimerService.instance.cancelSession();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final previousActivity = {
        'id': 'jalan_cepat',
        'title': 'Jalan Cepat',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: ActivityRestDetailScreen(
            previousActivity: previousActivity,
            completedDurationMinutes: 30,
          ),
        ),
      );
      await tester.pump();

      // Title & Subtitle
      expect(find.text('Waktu Istirahat'), findsWidgets);
      expect(find.text('Istirahat membantu tubuh pulih dan mengurangi risiko cedera.'), findsOneWidget);
      expect(find.text('Pilih Durasi Istirahat'), findsOneWidget);

      // 5 Duration options
      expect(find.text('5 menit'), findsOneWidget);
      expect(find.text('10 menit'), findsOneWidget);
      expect(find.text('15 menit'), findsOneWidget);
      expect(find.text('20 menit'), findsOneWidget);
      expect(find.text('30 menit'), findsOneWidget);

      // Contextual recommendation badge for Jalan Cepat is 10 menit
      expect(find.text('Rekomendasi'), findsOneWidget);

      // Tombol Mulai Istirahat
      expect(find.text('Mulai Istirahat'), findsOneWidget);

      // Tap "Mulai Istirahat" initiates rest timer
      await tester.tap(find.text('Mulai Istirahat'));
      await tester.pumpAndSettle();

      expect(ActivityTimerService.instance.isRunning, isTrue);
      expect(ActivityTimerService.instance.activeActivity?['isRest'], isTrue);
      expect(find.byType(ActivityTimerScreen), findsOneWidget);

      // Clean up running timer before test completes
      ActivityTimerService.instance.cancelSession();
      await tester.pump();
    });
  });

  group('Storyboard Panel 3: Alarm & Completion Dialog Widget Tests', () {
    testWidgets('Timer completion displays explicit 00:00, Selesai, and Lanjut Istirahat buttons', (WidgetTester tester) async {
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
      expect(find.text('Aktivitas Fisik Selesai!'), findsOneWidget);
      expect(find.text('00:00'), findsWidgets); // Dialog explicit 00:00
      expect(find.text('Selesai'), findsOneWidget);
      expect(find.text('Lanjut Istirahat'), findsOneWidget);

      // Tapping "Lanjut Istirahat" stops alarm and navigates to ActivityRestDetailScreen
      await tester.tap(find.text('Lanjut Istirahat'));
      await tester.pumpAndSettle();

      expect(ActivityAlarmService.instance.isPlaying, isFalse);
      expect(find.byType(ActivityRestDetailScreen), findsOneWidget);
    });

    testWidgets('Tapping Selesai stops alarm and cleans timer session', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        ActivityTimerService.instance.cancelSession();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final activity = {
        'id': 'cycling',
        'title': 'Bersepeda',
        'isRest': false,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: ActivityTimerScreen(activity: activity),
        ),
      );
      await tester.pump();

      ActivityTimerService.instance.triggerTimeCompletedForTesting();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Selesai'), findsOneWidget);

      // Tap "Selesai"
      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();

      expect(ActivityAlarmService.instance.isPlaying, isFalse);
      expect(ActivityTimerService.instance.isIdle, isTrue);
    });
  });
}
