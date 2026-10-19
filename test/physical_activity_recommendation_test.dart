import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obesight/models/user_model.dart';
import 'package:obesight/screens/progress/physical_activity_screen.dart';
import 'package:obesight/screens/skrining/skrining_models.dart';
import 'package:obesight/screens/skrining/skrining_recommendation_rules.dart';
import 'package:obesight/services/physical_activity_service.dart';
import 'package:obesight/services/screening_history_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('1. Category Normalization & Recommendation Mapping Tests', () {
    test('normalizeCategory maps all ML classes and clinical names correctly', () {
      expect(PhysicalActivityService.normalizeCategory('Underweight'), 'Underweight');
      expect(PhysicalActivityService.normalizeCategory('Insufficient_Weight'), 'Underweight');
      expect(PhysicalActivityService.normalizeCategory('Normal'), 'Normal');
      expect(PhysicalActivityService.normalizeCategory('Normal_Weight'), 'Normal');
      expect(PhysicalActivityService.normalizeCategory('Overweight'), 'Overweight');
      expect(PhysicalActivityService.normalizeCategory('Overweight_Level_I'), 'Overweight');
      expect(PhysicalActivityService.normalizeCategory('Overweight_Level_II'), 'Overweight');
      expect(PhysicalActivityService.normalizeCategory('Obesitas I'), 'Obesitas I');
      expect(PhysicalActivityService.normalizeCategory('Obesity_Type_I'), 'Obesitas I');
      expect(PhysicalActivityService.normalizeCategory('Obesitas II'), 'Obesitas II');
      expect(PhysicalActivityService.normalizeCategory('Obesity_Type_II'), 'Obesitas II');
      expect(PhysicalActivityService.normalizeCategory('Obesitas III'), 'Obesitas III');
      expect(PhysicalActivityService.normalizeCategory('Obesity_Type_III'), 'Obesitas III');
    });

    test('Each of the 6 categories produces specific, tailored activities', () {
      final categories = [
        'Underweight',
        'Normal',
        'Overweight',
        'Obesitas I',
        'Obesitas II',
        'Obesitas III',
      ];

      for (final cat in categories) {
        final activities = PhysicalActivityService.instance.getActivitiesForCategory(cat);
        expect(activities, isNotEmpty, reason: 'Activities for $cat should not be empty');
        expect(activities.length >= 4, true, reason: 'Activities for $cat should have at least 4 items');

        for (final act in activities) {
          expect(act['id'], isNotNull);
          expect(act['name'], isNotNull);
          expect(act['desc'], isNotNull);
          expect(act['duration'], isNotNull);
          expect(act['frequency'], isNotNull);
          expect(act['intensity'], isNotNull);
          expect(act['calories'], isNotNull);
          expect(act['benefits'], isNotEmpty);
          expect(act['specs'], isNotNull);
          expect(act['tips'], isNotEmpty);
        }
      }
    });

    test('Clinical special care categories include safety notes', () {
      final ob1 = PhysicalActivityService.instance.getActivitiesForCategory('Obesitas I');
      final ob2 = PhysicalActivityService.instance.getActivitiesForCategory('Obesitas II');
      final ob3 = PhysicalActivityService.instance.getActivitiesForCategory('Obesitas III');
      final under = PhysicalActivityService.instance.getActivitiesForCategory('Underweight');

      // Obesitas I, II, III must emphasize joint-friendly exercise and safety notes
      expect(ob1.any((a) => a['safetyNotes'] != null), true);
      expect(ob2.any((a) => a['safetyNotes'] != null), true);
      expect(ob3.any((a) => a['safetyNotes'] != null), true);
      expect(under.any((a) => a['safetyNotes'] != null), true);

      // Obesitas II & III must not prescribe high-impact jumping exercises
      expect(ob2.any((a) => a['id'] == 'hiit'), false);
      expect(ob3.any((a) => a['id'] == 'hiit'), false);
    });
  });

  group('2. SkriningData Integration & Fallback Tests', () {
    test('SkriningData with ML prediction determines correct physical activities', () {
      final data = SkriningData(
        gender: 'Laki-laki',
        age: 30,
        height: 170,
        weight: 85,
        aiCategoryKey: 'Obesitas I',
        isPredictionSuccess: true,
      );

      expect(data.classificationCategory, 'Obesitas I');
      final rec = SkriningRecommendationRules.getRecommendationByCategory(data.classificationCategory);
      expect(rec.categoryKey, 'Obesitas I');

      final activities = PhysicalActivityService.instance.getActivitiesForCategory(
        data.classificationCategory,
        skriningData: data,
      );

      // Obesitas I prioritizes non-weight bearing aquatic / aquarobics
      expect(activities.first['name'], contains('Berenang / Senam Air'));
      expect(activities.any((a) => a['id'] == 'obesitas1_stationary_bike'), true);
    });

    test('Habit tip personalizes tips based on user screening physicalActivity habit', () {
      final sedentaryData = SkriningData(
        height: 170,
        weight: 85,
        aiCategoryKey: 'Obesitas I',
        physicalActivity: 'Tidak pernah',
        isPredictionSuccess: true,
      );
      final activeData = SkriningData(
        height: 170,
        weight: 85,
        aiCategoryKey: 'Obesitas I',
        physicalActivity: '1-2 kali seminggu',
        isPredictionSuccess: true,
      );

      final sedentaryActs = PhysicalActivityService.instance.getActivitiesForCategory(
        'Obesitas I',
        skriningData: sedentaryData,
      );
      final activeActs = PhysicalActivityService.instance.getActivitiesForCategory(
        'Obesitas I',
        skriningData: activeData,
      );

      final sedentaryTips = (sedentaryActs.first['tips'] as List<dynamic>).cast<String>();
      final activeTips = (activeActs.first['tips'] as List<dynamic>).cast<String>();

      expect(sedentaryTips.first, contains('aktivitas awal belum rutin'));
      expect(activeTips.first, contains('Tetapkan jadwal 3-4 hari seminggu'));
    });

    test('All 6 categories have completely differentiated sports selections', () {
      final normalActs = PhysicalActivityService.instance.getActivitiesForCategory('Normal');
      final overActs = PhysicalActivityService.instance.getActivitiesForCategory('Overweight');
      final ob1Acts = PhysicalActivityService.instance.getActivitiesForCategory('Obesitas I');
      final ob2Acts = PhysicalActivityService.instance.getActivitiesForCategory('Obesitas II');
      final ob3Acts = PhysicalActivityService.instance.getActivitiesForCategory('Obesitas III');
      final underActs = PhysicalActivityService.instance.getActivitiesForCategory('Underweight');

      final normalIds = normalActs.map((a) => a['id']).toSet();
      final overIds = overActs.map((a) => a['id']).toSet();
      final ob1Ids = ob1Acts.map((a) => a['id']).toSet();
      final ob2Ids = ob2Acts.map((a) => a['id']).toSet();
      final ob3Ids = ob3Acts.map((a) => a['id']).toSet();
      final underIds = underActs.map((a) => a['id']).toSet();

      // Obesitas I, II, III and Underweight have dedicated clinical activity sets
      expect(ob1Ids.intersection(normalIds).isEmpty, true);
      expect(ob2Ids.intersection(normalIds).isEmpty, true);
      expect(ob3Ids.intersection(normalIds).isEmpty, true);
      expect(underIds.intersection(normalIds).isEmpty, true);

      // Obesitas III has unique hydrotherapy & recumbent & seated ROM IDs
      expect(ob3Ids.contains('obesitas3_hydrotherapy'), true);
      expect(ob3Ids.contains('obesitas3_recumbent_bike'), true);
      expect(ob3Ids.contains('obesitas3_seated_rom'), true);

      // Overweight has specialized joint-friendly cycling and walk-jog IDs
      expect(overIds.contains('overweight_cycling'), true);
      expect(overIds.contains('overweight_walk_jog'), true);

      // Underweight has unique hypertrophy and core IDs
      expect(underIds.contains('underweight_strength'), true);
      expect(underIds.contains('underweight_calisthenics'), true);
      expect(underIds.contains('underweight_core'), true);
    });

    test('SkriningData BMI fallback works when ML prediction is absent', () {
      // Height 170 cm, Weight 50 kg -> BMI ~ 17.3 (Underweight)
      final underData = SkriningData(
        height: 170,
        weight: 50,
        isPredictionSuccess: false,
      );
      expect(underData.classificationCategory, 'Underweight');

      final underActivities = PhysicalActivityService.instance.getActivitiesForCategory(
        underData.classificationCategory,
        skriningData: underData,
      );
      expect(underActivities.first['name'], contains('Latihan Beban'));

      // Height 170 cm, Weight 105 kg -> BMI ~ 36.3 (Obesitas III)
      final ob3Data = SkriningData(
        height: 170,
        weight: 105,
        isPredictionSuccess: false,
      );
      expect(ob3Data.classificationCategory, 'Obesitas III');

      final ob3Activities = PhysicalActivityService.instance.getActivitiesForCategory(
        ob3Data.classificationCategory,
        skriningData: ob3Data,
      );
      expect(ob3Activities.first['name'], contains('Terapi Gerak Air'));
    });
  });

  group('3. PhysicalActivityScreen UI & Empty State Tests', () {
    testWidgets('Displays empty state message when user has no screening history', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const testUser = UserModel(
        id: 'usr_new_test',
        name: 'User Baru',
        email: 'userbaru@example.com',
        username: 'userbaru',
        role: UserRole.user,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: PhysicalActivityScreen(user: testUser),
        ),
      );
      await tester.pumpAndSettle();

      // Should show clear empty state directing user to complete screening first
      expect(find.text('Belum Ada Hasil Skrining'), findsOneWidget);
      expect(
        find.text(
          'Rekomendasi aktivitas fisik dipersonalisasi berdasarkan hasil skrining kesehatan dan kategori IMT Anda.\nSilakan lakukan skrining terlebih dahulu.',
        ),
        findsOneWidget,
      );
      expect(find.text('Mulai Skrining Sekarang'), findsOneWidget);
    });

    testWidgets('Displays personalized activities and screening card when skriningData is provided', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final testData = SkriningData(
        gender: 'Perempuan',
        age: 24,
        height: 160,
        weight: 68,
        aiCategoryKey: 'Overweight',
        isPredictionSuccess: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PhysicalActivityScreen(skriningData: testData),
        ),
      );
      await tester.pumpAndSettle();

      // Screening header info
      expect(find.text('Hasil Skrining'), findsOneWidget);
      expect(find.text('Overweight (Kelebihan Berat Badan)'), findsOneWidget);
      expect(find.text('Pilihan Aktivitas Olahraga'), findsOneWidget);

      // Overweight activities present
      expect(find.text('Jalan Cepat (Brisk Walking)'), findsOneWidget);
      expect(find.text('Senam Aerobik Low-Impact'), findsOneWidget);
      expect(find.text('Bersepeda Teratur'), findsOneWidget);
      expect(find.text('Jogging Bertahap'), findsOneWidget);
    });

    testWidgets('Updates recommendations when user completes a new screening in history', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const testUser = UserModel(
        id: 'usr_repeat_screening',
        name: 'Budi Santoso',
        email: 'budi@example.com',
        username: 'budi',
        role: UserRole.user,
      );

      // 1. Initial screening: Normal
      final firstScreening = SkriningData(
        gender: 'Laki-laki',
        age: 28,
        height: 175,
        weight: 68,
        aiCategoryKey: 'Normal',
        isPredictionSuccess: true,
      );
      await ScreeningHistoryService.instance.addHistory(testUser.id, firstScreening);

      await tester.pumpWidget(
        const MaterialApp(
          home: PhysicalActivityScreen(user: testUser),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Berat Badan Normal'), findsOneWidget);
      expect(find.text('Jogging / Lari Santai'), findsOneWidget);

      // 2. User screens again after months: Obesitas I
      final secondScreening = SkriningData(
        gender: 'Laki-laki',
        age: 28,
        height: 175,
        weight: 88,
        aiCategoryKey: 'Obesitas I',
        isPredictionSuccess: true,
      );
      await ScreeningHistoryService.instance.addHistory(testUser.id, secondScreening);

      await tester.pumpAndSettle();

      // Screen must reactively update to latest screening result
      expect(find.text('Obesitas Tingkat I'), findsOneWidget);
      expect(find.text('Berenang / Senam Air'), findsOneWidget);
      expect(find.text('Bersepeda Statis'), findsOneWidget);
    });

    testWidgets('Revision Tests: Badge 0/4 Selesai is removed, Insufficient Weight is displayed, Checklist restricted to today', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final underData = SkriningData(
        gender: 'Perempuan',
        age: 22,
        height: 165,
        weight: 42,
        aiCategoryKey: 'Underweight',
        aiCategoryTitle: 'Insufficient\nWeight',
        isPredictionSuccess: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PhysicalActivityScreen(skriningData: underData),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Badge "0/4 Selesai" / "Selesai" badge on header is NOT found
      expect(find.textContaining('Selesai'), findsNothing);
      expect(find.text('Pilihan Aktivitas Olahraga'), findsOneWidget);

      // 2. Kategori "Insufficient Weight" tampil dengan benar, bukan "Underweight"
      expect(find.text('Insufficient Weight'), findsOneWidget);
      expect(find.text('Underweight'), findsNothing);

      // 3. Rekomendasi aktivitas underweight tampil
      expect(find.text('Latihan Beban & Kekuatan (Strength)'), findsOneWidget);

      // 4. Checklist pada hari ini aktif (onTap != null)
      final checkIconFinder = find.byIcon(Icons.radio_button_unchecked_rounded).first;
      final todayInkWell = tester.widget<InkWell>(
        find.ancestor(of: checkIconFinder, matching: find.byType(InkWell)).first,
      );
      expect(todayInkWell.onTap, isNotNull, reason: 'Checklist harus aktif pada hari ini');

      // 5. Pilih tanggal mendatang (besok)
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowStr = '${tomorrow.day}/${tomorrow.month}/${tomorrow.year.toString().substring(2)}';
      final tomorrowDateWidget = find.text(tomorrowStr);
      if (tomorrowDateWidget.evaluate().isNotEmpty) {
        await tester.tap(tomorrowDateWidget);
        await tester.pumpAndSettle();

        // Checklist pada tanggal mendatang nonaktif (onTap == null)
        final futureCheckIconFinder = find.byIcon(Icons.radio_button_unchecked_rounded).first;
        final futureInkWell = tester.widget<InkWell>(
          find.ancestor(of: futureCheckIconFinder, matching: find.byType(InkWell)).first,
        );
        expect(futureInkWell.onTap, isNull, reason: 'Checklist harus nonaktif pada tanggal masa depan');

        // 6. Kembali ke hari ini
        final todayFinder = find.text('Hari ini');
        expect(todayFinder, findsOneWidget);
        await tester.tap(todayFinder);
        await tester.pumpAndSettle();

        // Checklist aktif kembali pada hari ini
        final restoredCheckIcon = find.byIcon(Icons.radio_button_unchecked_rounded).first;
        final restoredInkWell = tester.widget<InkWell>(
          find.ancestor(of: restoredCheckIcon, matching: find.byType(InkWell)).first,
        );
        expect(restoredInkWell.onTap, isNotNull, reason: 'Checklist harus aktif kembali saat kembali ke hari ini');
      }
    });
  });
}
