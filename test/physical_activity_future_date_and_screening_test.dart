import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:obesight/services/physical_activity_service.dart';
import 'package:obesight/services/activity_timer_service.dart';
import 'package:obesight/services/screening_history_service.dart';
import 'package:obesight/models/screening_history_model.dart';
import 'package:obesight/screens/skrining/skrining_models.dart';
import 'package:obesight/screens/skrining/skrining_recommendation_rules.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ActivityTimerService.instance.cancelSession();
  });

  tearDown(() {
    ActivityTimerService.instance.cancelSession();
  });

  group('Physical Activity Future Date & Screening Logic Tests', () {
    final service = PhysicalActivityService.instance;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayKey = service.todayKey;
    final tomorrow = today.add(const Duration(days: 1));
    final tomorrowKey = service.formatDateKey(tomorrow);
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayKey = service.formatDateKey(yesterday);

    test('Calendar date normalization and future date checks', () {
      expect(PhysicalActivityService.isToday(today), isTrue);
      expect(PhysicalActivityService.isTodayDateKey(todayKey), isTrue);

      expect(PhysicalActivityService.isFutureDate(today), isFalse);
      expect(PhysicalActivityService.isFutureDateKey(todayKey), isFalse);

      expect(PhysicalActivityService.isFutureDate(yesterday), isFalse);
      expect(PhysicalActivityService.isFutureDateKey(yesterdayKey), isFalse);

      expect(PhysicalActivityService.isFutureDate(tomorrow), isTrue);
      expect(PhysicalActivityService.isFutureDateKey(tomorrowKey), isTrue);

      // Verify that time components do not cause false positives
      final todayLate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      expect(PhysicalActivityService.isFutureDate(todayLate), isFalse);
      expect(PhysicalActivityService.isToday(todayLate), isTrue);
    });

    test('Skenario A — Hari ini: Checklist, latihan, dan progres berjalan normal', () async {
      final act = service.getActivitiesForCategory('Normal').first;
      final actId = act['id'] as String;

      expect(service.isCompleted(todayKey, actId), isFalse);

      // Toggle checklist menjadi selesai
      await service.toggleActivity(dateKey: todayKey, activity: act);
      expect(service.isCompleted(todayKey, actId), isTrue);
      expect(service.getCompletedCountForDate(todayKey), greaterThan(0));

      // Toggle checklist kembali menjadi belum selesai
      await service.toggleActivity(dateKey: todayKey, activity: act);
      expect(service.isCompleted(todayKey, actId), isFalse);

      // Complete activity langsung
      final completed = await service.completeActivity(todayKey, actId, activity: act);
      expect(completed, isTrue);
      expect(service.isCompleted(todayKey, actId), isTrue);

      // Uncomplete activity
      final uncompleted = await service.uncompleteActivity(todayKey, actId, activity: act);
      expect(uncompleted, isTrue);
      expect(service.isCompleted(todayKey, actId), isFalse);
    });

    test('Skenario B — Tanggal mendatang: Semua interaksi pencatatan ditolak mutlak', () async {
      final act = service.getActivitiesForCategory('Normal').first;
      final actId = act['id'] as String;

      // 1. completeActivity ditolak
      final completeRes = await service.completeActivity(tomorrowKey, actId, activity: act);
      expect(completeRes, isFalse);
      expect(service.isCompleted(tomorrowKey, actId), isFalse);

      // 2. toggleActivity ditolak
      await service.toggleActivity(dateKey: tomorrowKey, activity: act);
      expect(service.isCompleted(tomorrowKey, actId), isFalse);

      // 3. uncompleteActivity ditolak
      final uncompleteRes = await service.uncompleteActivity(tomorrowKey, actId, activity: act);
      expect(uncompleteRes, isFalse);

      // 4. startSession ditolak
      final sessionId = await service.startSession(activity: act, dateKey: tomorrowKey);
      expect(sessionId, isNull);

      // 5. finishSession ditolak
      final finishRes = await service.finishSession(
        sessionId: 'dummy_session',
        activity: act,
        elapsedSeconds: 1800,
        dateKey: tomorrowKey,
      );
      expect(finishRes, isFalse);

      // 6. ActivityTimerService finishManually ditolak untuk tanggal mendatang
      final timerService = ActivityTimerService.instance;
      timerService.setupSession(
        activity: act,
        presetSeconds: 30 * 60,
        dateKey: tomorrowKey,
      );
      final finishManuallyRes = await timerService.finishManually();
      expect(finishManuallyRes, isFalse);
      expect(service.isCompleted(tomorrowKey, actId), isFalse);

      // 7. Jumlah selesai dan fraksi progres tetap 0
      expect(service.getCompletedCountForDate(tomorrowKey), 0);
      final normalActs = service.getActivitiesForCategory('Normal');
      expect(service.getProgressFractionForDate(tomorrowKey, normalActs), '0/${normalActs.length}');

      // 8. Rekomendasi olahraga tetap dapat dilihat
      expect(normalActs, isNotEmpty);
      expect(normalActs.first['name'], isNotNull);
    });

    test('Skenario C — Berpindah tanggal: Progres aktif di hari ini dan nonaktif di tanggal mendatang', () async {
      final act = service.getActivitiesForCategory('Overweight').first;
      final actId = act['id'] as String;

      // Berpindah ke tanggal mendatang -> ditolak
      await service.toggleActivity(dateKey: tomorrowKey, activity: act);
      expect(service.isCompleted(tomorrowKey, actId), isFalse);

      // Berpindah kembali ke hari ini -> berhasil
      await service.toggleActivity(dateKey: todayKey, activity: act);
      expect(service.isCompleted(todayKey, actId), isTrue);

      // Berpindah ke tanggal mendatang -> tetap tidak ada progres yang tercatat
      expect(service.isCompleted(tomorrowKey, actId), isFalse);

      // Bersihkan hari ini
      await service.uncompleteActivity(todayKey, actId, activity: act);
      expect(service.isCompleted(todayKey, actId), isFalse);
    });

    test('Skenario D — Skrining ulang: Periode tanggal dimulai dari skrining terbaru & rekomendasi disinkronkan', () {
      final screening1Date = today.subtract(const Duration(days: 9)); // 9 hari lalu (misal 10 Okt)
      final screening2Date = today; // Hari ini (misal 19 Okt)

      final scrData1 = SkriningData(
        age: 25,
        gender: 'Laki-laki',
        height: 170,
        weight: 85,
        date: screening1Date,
        isPredictionSuccess: true,
        aiCategoryKey: 'Obesitas I',
        aiCategoryTitle: 'Obesitas Tingkat I',
      );

      final scrData2 = SkriningData(
        age: 25,
        gender: 'Laki-laki',
        height: 170,
        weight: 70,
        date: screening2Date,
        isPredictionSuccess: true,
        aiCategoryKey: 'Overweight',
        aiCategoryTitle: 'Kelebihan Berat Badan',
      );

      final historyItem1 = ScreeningHistoryItem(
        id: 'scr_old_1',
        userId: 'usr_test_1',
        date: screening1Date,
        bmi: 29.4,
        risk: 'Tinggi',
        category: 'Obesitas (IMT > 27)',
        skriningData: scrData1,
      );

      final historyItem2 = ScreeningHistoryItem(
        id: 'scr_latest_2',
        userId: 'usr_test_1',
        date: screening2Date,
        bmi: 24.2,
        risk: 'Sedang',
        category: 'Overweight (IMT 25–27)',
        skriningData: scrData2,
      );

      final history = [historyItem2, historyItem1];

      // Ambil skrining terbaru dengan komparasi tanggal
      final latest = history.reduce((curr, next) => curr.date.isAfter(next.date) ? curr : next);
      expect(latest.id, 'scr_latest_2');
      expect(latest.skriningData.classificationCategory, 'Overweight');

      // Evaluasi penentuan periode tanggal scroller
      final rawScreeningDate = latest.date;
      final screeningDate = PhysicalActivityService.normalizeDate(rawScreeningDate);
      final startDate = screeningDate.isAfter(today) ? today : screeningDate;

      expect(startDate, equals(today));
      final pastDays = today.difference(startDate).inDays;
      expect(pastDays, equals(0)); // Tanggal sebelum skrining terbaru (9 hari lalu) TIDAK ADA di periode baru

      // Sinkronisasi rekomendasi dengan skrining terbaru
      final rec = SkriningRecommendationRules.getRecommendationByCategory(latest.skriningData.classificationCategory);
      expect(rec.categoryKey, 'Overweight');

      final activities = service.getActivitiesForCategory(latest.skriningData.classificationCategory, skriningData: latest.skriningData);
      expect(activities, isNotEmpty);
      expect(activities.any((a) => (a['name'] as String).toLowerCase().contains('jalan')), isTrue);
    });

    test('Skenario E — Regresi fitur: Semua 6 kategori rekomendasi klinis tetap valid dan lengkap', () {
      final categories = ['Underweight', 'Normal', 'Overweight', 'Obesitas I', 'Obesitas II', 'Obesitas III'];

      for (final cat in categories) {
        final acts = service.getActivitiesForCategory(cat);
        expect(acts, isNotEmpty, reason: '$cat harus memiliki daftar aktivitas');
        for (final act in acts) {
          expect(act['id'], isNotNull);
          expect(act['name'], isNotNull);
          expect(act['duration'], isNotNull);
          expect(act['calories'], isNotNull);
        }
      }
    });
  });
}
