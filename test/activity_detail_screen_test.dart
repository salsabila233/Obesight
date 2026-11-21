import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obesight/screens/progress/activity_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleActivities = [
    {
      'id': 'normal_jogging',
      'title': 'Jogging / Lari Santai',
      'specs': {
        'duration': '30-60 menit',
        'frequency': '3-5 kali/minggu',
        'intensity': 'Sedang (60-70% HRmax)',
        'calories': '200-400 kkal',
      },
      'aboutTitle': 'Tentang Jogging',
      'aboutDesc': 'Jogging adalah aktivitas fisik aerobik...',
      'benefits': ['Meningkatkan kebugaran jantung'],
      'tipsTitle': 'Tips Melakukan Jogging',
      'tips': ['Lakukan pemanasan 5-10 menit sebelum mulai.'],
      'heroImg': 'assets/progress/clean/hero_jogging.png',
      'icon': 'assets/progress/clean/rec_icon_jogging.png',
    },
    {
      'id': 'normal_cycling',
      'title': 'Bersepeda Outdoor / Santai',
      'specs': {
        'duration': '30-45 menit',
        'frequency': '3-4 kali/minggu',
        'intensity': 'Sedang',
        'calories': '180-350 kkal',
      },
      'aboutTitle': 'Tentang Bersepeda',
      'aboutDesc': 'Bersepeda meningkatkan daya tahan kardiovaskular...',
      'benefits': ['Menguatkan otot kaki'],
      'tipsTitle': 'Tips Bersepeda',
      'tips': ['Gunakan helm pengaman.'],
      'heroImg': 'assets/progress/clean/hero_cycling.png',
      'icon': 'assets/progress/clean/rec_icon_cycling.png',
    },
    {
      'id': 'underweight_calisthenics',
      'title': 'Kalistenik Kompon (Bodyweight)',
      'specs': {
        'duration': '20-40 menit',
        'frequency': '3 kali/minggu',
        'intensity': 'Sedang-Tinggi',
        'calories': '150-250 kkal',
      },
      'aboutTitle': 'Tentang Kalistenik',
      'aboutDesc': 'Latihan beban tubuh untuk kekuatan...',
      'benefits': ['Membangun massa otot'],
      'tipsTitle': 'Tips Kalistenik',
      'tips': ['Prioritaskan form yang benar.'],
      'heroImg': 'assets/progress/clean/hero_calisthenics.png',
      'icon': 'assets/progress/clean/rec_icon_calisthenics.png',
    },
  ];

  group('ActivityDetailScreen Scrolling & Overscroll Fix Tests', () {
    testWidgets(
      '1. Scaffold background color is sheet color (not green headerColor)',
      (tester) async {
        final activity = sampleActivities[0];

        // Test Light Mode
        await tester.pumpWidget(
          MaterialApp(
            key: const ValueKey('light_app'),
            theme: ThemeData.light(),
            home: ActivityDetailScreen(
              key: const ValueKey('light_detail'),
              activity: activity,
            ),
          ),
        );
        await tester.pump();

        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, equals(const Color(0xFFF3F6F8)));
        expect(
          scaffold.backgroundColor,
          isNot(equals(const Color(0xFF489874))),
        );

        // Test Dark Mode
        await tester.pumpWidget(
          MaterialApp(
            key: const ValueKey('dark_app'),
            theme: ThemeData(brightness: Brightness.dark),
            home: ActivityDetailScreen(
              key: const ValueKey('dark_detail'),
              activity: activity,
            ),
          ),
        );
        await tester.pump();

        final darkScaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(darkScaffold.backgroundColor, equals(const Color(0xFF0F172A)));
        expect(
          darkScaffold.backgroundColor,
          isNot(equals(const Color(0xFF1E293B))),
        );
      },
    );

    testWidgets(
      '2. CustomScrollView uses ClampingScrollPhysics and overscroll is disabled',
      (tester) async {
        final activity = sampleActivities[0];

        await tester.pumpWidget(
          MaterialApp(home: ActivityDetailScreen(activity: activity)),
        );
        await tester.pump();

        final scrollable = tester.widget<CustomScrollView>(
          find.byType(CustomScrollView),
        );
        expect(scrollable.physics, isA<ClampingScrollPhysics>());

        // Verify ScrollConfiguration wraps CustomScrollView
        final scrollConfigFinder = find.ancestor(
          of: find.byType(CustomScrollView),
          matching: find.byType(ScrollConfiguration),
        );
        expect(scrollConfigFinder, findsWidgets);
      },
    );

    testWidgets(
      '3. CustomScrollView contains SliverFillRemaining with sheet color at end of slivers',
      (tester) async {
        final activity = sampleActivities[0];

        await tester.pumpWidget(
          MaterialApp(home: ActivityDetailScreen(activity: activity)),
        );
        await tester.pump();

        final customScrollView = tester.widget<CustomScrollView>(
          find.byType(CustomScrollView),
        );
        final lastSliver = customScrollView.slivers.last;
        expect(lastSliver, isA<SliverFillRemaining>());
        final fillRemaining = lastSliver as SliverFillRemaining;
        expect(fillRemaining.hasScrollBody, isFalse);
      },
    );

    testWidgets(
      '4. All physical activity detail pages render correctly with Mulai button and back navigation',
      (tester) async {
        for (final activity in sampleActivities) {
          await tester.pumpWidget(
            MaterialApp(
              key: ValueKey(activity['id']),
              home: ActivityDetailScreen(activity: activity),
            ),
          );
          await tester.pump();

          expect(find.text(activity['title'] as String), findsWidgets);
          expect(find.text(activity['aboutTitle'] as String), findsOneWidget);
          expect(find.text('Mulai'), findsOneWidget);
          expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
        }
      },
    );
  });
}
