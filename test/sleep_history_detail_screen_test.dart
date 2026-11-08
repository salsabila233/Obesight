import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:obesight/models/sleep_record_model.dart';
import 'package:obesight/screens/progress/night_sleep_detail_screen.dart';
import 'package:obesight/screens/progress/sleep_history_detail_screen.dart';
import 'package:obesight/services/sleep_tracking_service.dart';
import 'package:obesight/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SleepTrackingService.instance.clearAll();
  });

  group('SleepHistoryDetailScreen Curved Header, White Page Canvas & 1-Month Filter Tests', () {
    testWidgets('Renders curved green header with Radius 28 and clean white page canvas without green background', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SleepHistoryDetailScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // 1. Verify AppBar and Title
      expect(find.text('Riwayat Tidur'), findsOneWidget);

      // 2. Verify Scaffold background is pure white (pageColor), ensuring no green background leak
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.white);

      // 3. Verify Body Container has curved top border (Radius 28) with pure white background
      final containers = tester.widgetList<Container>(find.byType(Container));
      final curvedContainer = containers.firstWhere(
        (c) {
          final dec = c.decoration;
          if (dec is BoxDecoration && dec.borderRadius is BorderRadius) {
            final br = dec.borderRadius as BorderRadius;
            return br.topLeft.x == 28.0 && br.topRight.x == 28.0 && dec.color == Colors.white;
          }
          return false;
        },
      );
      expect(curvedContainer, isNotNull);

      // 4. Verify ClipRRect is used to clip contents to curved top
      expect(find.byType(ClipRRect), findsWidgets);

      // 5. Verify core sections are present inside the curved sheet
      expect(find.text('Jam'), findsOneWidget);
      expect(find.text('Hari'), findsOneWidget);
      expect(find.text('Minggu'), findsOneWidget);
      expect(find.text('Bulan'), findsOneWidget);
      expect(find.text('Riwayat Catatan Tidur'), findsOneWidget);
    });

    test('getPastMonthRecords enforces 1 record per day and strictly limits history to 1 month (30 days)', () async {
      final service = SleepTrackingService.instance;
      final refNow = DateTime(2026, 11, 8, 10, 0);

      // 1. Record for today (within 1 month)
      final recToday = SleepRecord(
        id: 'rec_today',
        userId: 'user_1',
        date: '2026-11-08',
        startTime: DateTime(2026, 11, 7, 23, 0),
        endTime: DateTime(2026, 11, 8, 7, 0),
        durationMinutes: 480,
        source: 'manual',
        isConfirmed: true,
      );

      // 2. Auto record for yesterday
      final recYesterdayAuto = SleepRecord(
        id: 'rec_yesterday_auto',
        userId: 'user_1',
        date: '2026-11-07',
        startTime: DateTime(2026, 11, 6, 23, 30),
        endTime: DateTime(2026, 11, 7, 6, 30),
        durationMinutes: 420,
        source: 'automatic',
        isConfirmed: false,
      );

      // 3. Manual confirmed record for yesterday (same day, should take precedence over auto)
      final recYesterdayManual = SleepRecord(
        id: 'rec_yesterday_manual',
        userId: 'user_1',
        date: '2026-11-07',
        startTime: DateTime(2026, 11, 6, 22, 0),
        endTime: DateTime(2026, 11, 7, 6, 30),
        durationMinutes: 510,
        source: 'manual',
        isConfirmed: true,
      );

      // 4. Record from 45 days ago (older than 1 month / 30 days)
      final recOld = SleepRecord(
        id: 'rec_old_45_days',
        userId: 'user_1',
        date: '2026-09-24',
        startTime: DateTime(2026, 9, 23, 23, 0),
        endTime: DateTime(2026, 9, 24, 7, 0),
        durationMinutes: 480,
        source: 'manual',
        isConfirmed: true,
      );

      await service.addRecord(recToday);
      await service.addRecord(recYesterdayAuto);
      await service.addRecord(recYesterdayManual);
      await service.addRecord(recOld);

      final pastMonth = service.getPastMonthRecords(referenceDate: refNow);

      // Past month should only contain 2 records: today and yesterday (recOld excluded)
      expect(pastMonth.length, 2);
      expect(pastMonth.any((r) => r.id == 'rec_old_45_days'), isFalse);

      // Rule: 1 hari 1 catatan tidur (prioritas manual terkonfirmasi)
      final yesterdayRecord = pastMonth.firstWhere((r) => r.date == '2026-11-07');
      expect(yesterdayRecord.id, 'rec_yesterday_manual');
      expect(yesterdayRecord.source, 'manual');
      expect(yesterdayRecord.durationMinutes, 510);
    });

    testWidgets('Header remains pinned/sticky when SingleChildScrollView is scrolled up with long content', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final service = SleepTrackingService.instance;
      for (int i = 0; i < 15; i++) {
        final d = DateTime.now().subtract(Duration(days: i));
        final dateStr = SleepTrackingService.formatDateKey(d);
        await service.addRecord(
          SleepRecord(
            id: 'rec_$i',
            userId: 'user_1',
            date: dateStr,
            startTime: d.subtract(const Duration(hours: 8)),
            endTime: d,
            durationMinutes: 480,
            source: 'manual',
            isConfirmed: true,
          ),
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SleepHistoryDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title is visible
      expect(find.text('Riwayat Tidur'), findsOneWidget);

      // Scroll up the content by 400 pixels
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();

      // Pinned AppBar header is still visible at the top
      expect(find.text('Riwayat Tidur'), findsOneWidget);
    });

    testWidgets('NightSleepDetailScreen has pure white background and pinned header on scroll', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const NightSleepDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.white);

      // Verify SliverPersistentHeader is pinned
      final headerFinder = find.byType(SliverPersistentHeader);
      expect(headerFinder, findsOneWidget);
      final headerWidget = tester.widget<SliverPersistentHeader>(headerFinder);
      expect(headerWidget.pinned, isTrue);

      // Scroll up the CustomScrollView
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // Pinned title "Waktu Tidur Malam" remains visible
      expect(find.text('Waktu Tidur Malam'), findsOneWidget);
    });
  });
}
