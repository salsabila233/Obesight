import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:obesight/screens/progress/activity_detail_screen.dart';
import 'package:obesight/screens/progress/activity_timer_screen.dart';
import 'package:obesight/screens/progress/activity_duration_picker_screen.dart';
import 'package:obesight/screens/progress/activity_rest_detail_screen.dart';
import 'package:obesight/services/activity_timer_service.dart';
import 'package:obesight/services/activity_alarm_service.dart';
import 'package:obesight/services/activity_rest_helper.dart';
import 'package:obesight/widgets/global_floating_timer_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final joggingActivity = {
    'id': 'normal_jogging',
    'title': 'Jogging / Lari Santai',
    'name': 'Jogging',
    'targetText': '30-60 menit',
    'duration': '30-60 menit',
    'specs': {
      'duration': '30-60 menit',
      'frequency': '3-5 kali/minggu',
      'intensity': 'Sedang (60-70% HRmax)',
      'calories': '200-400 kkal',
    },
    'aboutTitle': 'Tentang Jogging',
    'aboutDesc': 'Jogging merupakan salah satu jenis latihan aerobik...',
    'benefits': ['Meningkatkan kebugaran jantung'],
    'tipsTitle': 'Tips Melakukan Jogging',
    'tips': ['Lakukan pemanasan 5-10 menit sebelum mulai.'],
    'isRest': false,
  };

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ActivityAlarmService.isTestMode = true;
    ActivityTimerService.instance.cancelSession();
    ActivityAlarmService.instance.stopAlarm();
    GlobalFloatingTimerOverlay.isGlobalOverlayMounted = false;
    ActivityTimerService.instance.setTimerScreenActive(false);
  });

  tearDown(() {
    ActivityTimerService.instance.cancelSession();
    ActivityAlarmService.instance.stopAlarm();
    ActivityAlarmService.isTestMode = false;
    GlobalFloatingTimerOverlay.isGlobalOverlayMounted = false;
    ActivityTimerService.instance.setTimerScreenActive(false);
  });

  group('Jogging Duration Minimum & Helper Tests', () {
    test('Extracts minimum 30 minutes from jogging activity specs', () {
      final minDur = ActivityRestHelper.getMinActivityDuration(joggingActivity);
      final maxDur = ActivityRestHelper.getMaxActivityDuration(joggingActivity);
      expect(minDur, equals(30));
      expect(maxDur, equals(60));
    });

    test('Validates that duration cannot be set lower than 30 minutes for jogging', () {
      final clamped = ActivityRestHelper.clampActivityDuration(15, joggingActivity);
      expect(clamped, equals(30));

      final clampedMax = ActivityRestHelper.clampActivityDuration(90, joggingActivity);
      expect(clampedMax, equals(60));
    });
  });

  group('Jogging Duration Picker Screen Tests (Image 1)', () {
    testWidgets('Renders Target, Jam/Menit labels, and 30:00, 45:00, 60:00 presets', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ActivityDurationPickerScreen(activity: joggingActivity),
        ),
      );
      await tester.pump();

      expect(find.text('Target'), findsOneWidget);
      expect(find.text('30-60 menit'), findsOneWidget);
      expect(find.text('Jam'), findsOneWidget);
      expect(find.text('Menit'), findsOneWidget);

      // Presets 30:00, 45:00, 60:00
      expect(find.text('30:00'), findsOneWidget);
      expect(find.text('45:00'), findsOneWidget);
      expect(find.text('60:00'), findsOneWidget);

      // Tombol Mulai
      expect(find.text('Mulai'), findsOneWidget);

      // Tap Preset 60:00
      await tester.tap(find.text('60:00'));
      await tester.pumpAndSettle();

      // Tap Mulai sets session to 60 minutes and navigates to ActivityTimerScreen
      await tester.tap(find.text('Mulai'));
      await tester.pumpAndSettle();

      expect(ActivityTimerService.instance.isRunning, isTrue);
      expect(ActivityTimerService.instance.targetDuration, equals(60 * 60));
      expect(find.byType(ActivityTimerScreen), findsOneWidget);

      ActivityTimerService.instance.cancelSession();
      await tester.pump();
    });

    testWidgets('Full flow: Detail -> DurationPicker -> Mulai -> TimerScreen -> Back -> Detail with mini timer & no clock icon', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ActivityDetailScreen(activity: joggingActivity),
        ),
      );
      await tester.pump();

      // Tap Mulai on detail screen
      await tester.tap(find.text('Mulai').last);
      await tester.pumpAndSettle();

      // On ActivityDurationPickerScreen
      expect(find.byType(ActivityDurationPickerScreen), findsOneWidget);

      // Tap Mulai on duration picker
      await tester.tap(find.text('Mulai').last);
      await tester.pumpAndSettle();

      // Navigates to ActivityTimerScreen (halaman durasi)
      expect(find.byType(ActivityTimerScreen), findsOneWidget);

      // Clock icon is removed from the circular progress
      expect(find.byIcon(Icons.access_time_rounded), findsNothing);

      // Tap back button on ActivityTimerScreen
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded).last);
      await tester.pumpAndSettle();

      // Returned to ActivityDetailScreen (halaman penjelasan aktivitas fisik)
      expect(find.byType(ActivityDetailScreen), findsOneWidget);
      expect(find.byType(ActivityTimerScreen), findsNothing);

      // Floating mini timer is visible in header
      final sec = ActivityTimerService.instance.secondsRemaining;
      final m = (sec ~/ 60).toString().padLeft(2, '0');
      final s = (sec % 60).toString().padLeft(2, '0');
      expect(find.text('$m:$s'), findsOneWidget);

      ActivityTimerService.instance.cancelSession();
      await tester.pump();
    });
  });

  group('Jogging Mini Timer & Large Card Header Flow (Images 3 & 4)', () {
    testWidgets('Shows mini timer in header when running, expands on click, and can navigate to main timer', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Start a 60 min session
      ActivityTimerService.instance.setupSession(
        activity: joggingActivity,
        presetSeconds: 60 * 60,
      );
      await ActivityTimerService.instance.startOrResume();

      await tester.pumpWidget(
        MaterialApp(
          home: ActivityDetailScreen(activity: joggingActivity),
        ),
      );
      await tester.pump();

      // Mini timer is displayed in top right header
      expect(find.text('60:00'), findsOneWidget);

      // Tap mini timer to expand into larger card
      await tester.tap(find.text('60:00'));
      await tester.pumpAndSettle();

      // Now larger card is visible with expand icon and linear progress bar
      expect(find.byIcon(Icons.open_in_full_rounded), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Tap expand icon to open ActivityTimerScreen
      await tester.tap(find.byIcon(Icons.open_in_full_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(ActivityTimerScreen), findsOneWidget);
      expect(find.text('Selesaikan Aktivitas'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);

      // Pop back from ActivityTimerScreen
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      // Returned to ActivityDetailScreen, timer is STILL running without reset
      expect(find.byType(ActivityDetailScreen), findsOneWidget);
      expect(ActivityTimerService.instance.isRunning, isTrue);

      ActivityTimerService.instance.cancelSession();
      await tester.pump();
    });
  });

  group('Alarm & Dialog Waktu Aktivitas Habis Tests (Image 5)', () {
    testWidgets('Shows dialog with 00:00, clock icon, Lanjutkan istirahat, and Batal dan Selesai', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      ActivityTimerService.instance.setupSession(
        activity: joggingActivity,
        presetSeconds: 30 * 60,
      );
      await ActivityTimerService.instance.startOrResume();

      await tester.pumpWidget(
        MaterialApp(
          home: ActivityDetailScreen(activity: joggingActivity),
        ),
      );
      await tester.pump();

      // Trigger 00:00 completion
      ActivityTimerService.instance.triggerTimeCompletedForTesting();
      await tester.pump();
      await tester.pumpAndSettle();

      // Alarm is playing
      expect(ActivityAlarmService.instance.isPlaying, isTrue);

      // Dialog is displayed
      expect(find.text('Waktu Aktivitas Habis'), findsOneWidget);
      expect(find.text('00:00'), findsWidgets);
      expect(find.text('Lanjutkan istirahat'), findsOneWidget);
      expect(find.text('Batal dan Selesai'), findsOneWidget);

      // Tapping "Lanjutkan istirahat" stops alarm and navigates to rest screen
      await tester.tap(find.text('Lanjutkan istirahat'));
      await tester.pumpAndSettle();

      expect(ActivityAlarmService.instance.isPlaying, isFalse);
      expect(find.byType(ActivityRestDetailScreen), findsOneWidget);
    });

    testWidgets('Tapping Batal dan Selesai stops alarm and cancels session', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      ActivityTimerService.instance.setupSession(
        activity: joggingActivity,
        presetSeconds: 30 * 60,
      );
      await ActivityTimerService.instance.startOrResume();

      await tester.pumpWidget(
        MaterialApp(
          home: ActivityDetailScreen(activity: joggingActivity),
        ),
      );
      await tester.pump();

      ActivityTimerService.instance.triggerTimeCompletedForTesting();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Batal dan Selesai'), findsOneWidget);

      await tester.tap(find.text('Batal dan Selesai'));
      await tester.pumpAndSettle();

      expect(ActivityAlarmService.instance.isPlaying, isFalse);
      expect(ActivityTimerService.instance.isIdle, isTrue);
    });
  });

  group('Global Floating Timer Overlay Multi-page Flow', () {
    testWidgets('Timer stays floating when navigating from Detail back to Beranda/Home', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // App with Beranda and ability to push ActivityDetailScreen
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: ActivityTimerService.navigatorKey,
          builder: (context, child) => GlobalFloatingTimerOverlay(child: child!),
          home: Builder(
            builder: (ctx) => Scaffold(
              appBar: AppBar(title: const Text('Beranda Obesight')),
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).push(
                      MaterialPageRoute(
                        builder: (_) => ActivityDetailScreen(activity: joggingActivity),
                      ),
                    );
                  },
                  child: const Text('Buka Detail Jogging'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No timer yet
      expect(find.byType(GlobalFloatingTimerOverlay), findsOneWidget);
      expect(find.text('30:00'), findsNothing);

      // Open Detail
      await tester.tap(find.text('Buka Detail Jogging'));
      await tester.pumpAndSettle();
      expect(find.byType(ActivityDetailScreen), findsOneWidget);

      // Tap Mulai on detail -> opens duration picker
      await tester.tap(find.text('Mulai').last);
      await tester.pumpAndSettle();
      expect(find.byType(ActivityDurationPickerScreen), findsOneWidget);

      // Tap Mulai on picker -> starts timer and replaces with ActivityTimerScreen
      await tester.tap(find.text('Mulai').last);
      await tester.pumpAndSettle();
      expect(find.byType(ActivityTimerScreen), findsOneWidget);

      // Back from ActivityTimerScreen -> back to ActivityDetailScreen
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded).last);
      await tester.pumpAndSettle();
      expect(find.byType(ActivityDetailScreen), findsOneWidget);

      // Floating timer pill is visible
      int sec = ActivityTimerService.instance.secondsRemaining;
      String formatted = '${(sec ~/ 60).toString().padLeft(2, '0')}:${(sec % 60).toString().padLeft(2, '0')}';
      expect(find.text(formatted), findsOneWidget);

      // Pop ActivityDetailScreen -> back to Beranda!
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded).last);
      await tester.pumpAndSettle();

      // Now on Beranda, floating timer is STILL VISIBLE!
      expect(find.text('Beranda Obesight'), findsOneWidget);
      sec = ActivityTimerService.instance.secondsRemaining;
      formatted = '${(sec ~/ 60).toString().padLeft(2, '0')}:${(sec % 60).toString().padLeft(2, '0')}';
      expect(find.text(formatted), findsOneWidget);

      // Tap floating pill on Beranda -> expands into card
      await tester.tap(find.text(formatted));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.open_in_full_rounded), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Tap expand icon from Beranda -> opens ActivityTimerScreen!
      await tester.tap(find.byIcon(Icons.open_in_full_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(ActivityTimerScreen), findsOneWidget);

      ActivityTimerService.instance.cancelSession();
      await tester.pump();
    });
  });
}
