import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obesight/screens/progress/activity_timer_screen.dart';
import 'package:obesight/screens/progress/activity_duration_picker_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final strengthActivity = {
    'id': 'underweight_strength',
    'title': 'Latihan Beban & Angkat Beban (Strength Training)',
    'name': 'Latihan Beban & Kekuatan (Strength)',
    'targetText': '25-35 menit',
    'heroImg': 'assets/progress/clean/hero_bodyweight.png',
    'icon': 'assets/progress/clean/rec_icon_bodyweight.png',
  };

  final calisthenicsActivity = {
    'id': 'underweight_calisthenics',
    'title': 'Kalistenik Kompon (Push-up, Inverted Row & Squat)',
    'name': 'Kalistenik Kompon (Bodyweight)',
    'targetText': '20-30 menit',
    'heroImg': 'assets/progress/clean/hero_bodyweight.png',
    'icon': 'assets/progress/clean/rec_icon_bodyweight.png',
  };

  final recoveryActivity = {
    'id': 'underweight_recovery',
    'title': 'Peregangan Pemulihan & Mobilitas (Stretching & Light Walk)',
    'name': 'Peregangan Pemulihan & Mobilitas',
    'targetText': '15-20 menit',
    'heroImg': 'assets/progress/clean/hero_yoga.png',
    'icon': 'assets/progress/clean/rec_icon_yoga.png',
  };

  final joggingActivity = {
    'id': 'jogging',
    'title': 'Jogging',
    'name': 'Jogging',
    'targetText': '30-45 menit',
    'heroImg': 'assets/progress/clean/hero_jogging.png',
    'icon': 'assets/progress/clean/rec_icon_jogging.png',
  };

  final yogaActivity = {
    'id': 'yoga',
    'title': 'Yoga',
    'name': 'Yoga',
    'targetText': '20-30 menit',
    'heroImg': 'assets/progress/clean/hero_yoga.png',
    'icon': 'assets/progress/clean/rec_icon_yoga.png',
  };

  group('Header Alignment di ActivityTimerScreen untuk 3 Olahraga Target', () {
    final targetActivities = [
      {'name': 'Latihan Beban & Kekuatan', 'act': strengthActivity, 'expected': 'Latihan Beban &\nKekuatan'},
      {'name': 'Kalistenik Kompon (Bodyweight)', 'act': calisthenicsActivity, 'expected': 'Kalistenik Kompon\n(Bodyweight)'},
      {'name': 'Peregangan Pemulihan & Mobilitas', 'act': recoveryActivity, 'expected': 'Peregangan Pemulihan\n& Mobilitas'},
    ];

    for (final item in targetActivities) {
      testWidgets('Menampilkan judul rapi dan simetris untuk ${item['name']}', (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MaterialApp(
            home: ActivityTimerScreen(activity: item['act'] as Map<String, dynamic>),
          ),
        );
        await tester.pump();

        // Verifikasi teks header terformat 2 baris rapi
        expect(find.text(item['expected'] as String), findsOneWidget);

        // Verifikasi ada FittedBox untuk responsivitas layout
        expect(find.byType(FittedBox), findsWidgets);
      });
    }

    testWidgets('Posisi ikon konsisten pada ketiga halaman target di ActivityTimerScreen', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final positions = <Offset>[];

      for (final item in targetActivities) {
        await tester.pumpWidget(
          MaterialApp(
            home: ActivityTimerScreen(activity: item['act'] as Map<String, dynamic>),
          ),
        );
        await tester.pump();

        // Cari widget Container badge ikon di dalam FlexibleSpaceBar
        final flexibleFinder = find.byType(FlexibleSpaceBar);
        expect(flexibleFinder, findsOneWidget);

        final iconBadgeFinder = find.descendant(
          of: flexibleFinder,
          matching: find.byType(Icon),
        );
        expect(iconBadgeFinder, findsWidgets);

        final iconOffset = tester.getTopLeft(iconBadgeFinder.first);
        positions.add(iconOffset);
      }

      // Pastikan posisi horizontal (X) dan vertikal (Y) ikon identik di ketiga halaman
      expect(positions.length, equals(3));
      expect(positions[0].dx, equals(positions[1].dx));
      expect(positions[1].dx, equals(positions[2].dx));
      expect(positions[0].dy, equals(positions[1].dy));
      expect(positions[1].dy, equals(positions[2].dy));
    });

    testWidgets('Tidak terjadi overflow pada layar sempit (320px)', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      for (final item in targetActivities) {
        await tester.pumpWidget(
          MaterialApp(
            home: ActivityTimerScreen(activity: item['act'] as Map<String, dynamic>),
          ),
        );
        await tester.pump();

        // Tidak boleh ada exception render overflow
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('Olahraga non-target (Jogging & Yoga) tidak terpengaruh', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(home: ActivityTimerScreen(activity: joggingActivity)),
      );
      await tester.pump();
      expect(find.text('Jogging'), findsWidgets);

      await tester.pumpWidget(
        MaterialApp(home: ActivityTimerScreen(activity: yogaActivity)),
      );
      await tester.pump();
      expect(find.text('Yoga'), findsWidgets);
    });
  });

  group('Header Alignment di ActivityDurationPickerScreen untuk 3 Olahraga Target', () {
    final targetActivities = [
      {'name': 'Latihan Beban & Kekuatan', 'act': strengthActivity, 'expected': 'Latihan Beban &\nKekuatan'},
      {'name': 'Kalistenik Kompon (Bodyweight)', 'act': calisthenicsActivity, 'expected': 'Kalistenik Kompon\n(Bodyweight)'},
      {'name': 'Peregangan Pemulihan & Mobilitas', 'act': recoveryActivity, 'expected': 'Peregangan Pemulihan\n& Mobilitas'},
    ];

    for (final item in targetActivities) {
      testWidgets('Menampilkan judul simetris dan rapi di picker untuk ${item['name']}', (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MaterialApp(
            home: ActivityDurationPickerScreen(activity: item['act'] as Map<String, dynamic>),
          ),
        );
        await tester.pump();

        expect(find.text(item['expected'] as String), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Olahraga non-target (Jogging) di ActivityDurationPickerScreen tetap normal', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
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

      expect(find.text('Jogging'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
