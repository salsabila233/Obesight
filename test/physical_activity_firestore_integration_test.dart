import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:obesight/services/physical_activity_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Physical Activity Firestore & Progress Tests', () {
    test('sanitizeDocId handles empty strings, slashes, and special whitespace', () {
      final service = PhysicalActivityService.instance;

      expect(service.sanitizeDocId(''), 'Pengguna');
      expect(service.sanitizeDocId('   '), 'Pengguna');
      expect(service.sanitizeDocId('David'), 'David');
      expect(service.sanitizeDocId('David/Prasetyo'), 'David_Prasetyo');
      expect(service.sanitizeDocId('John   Doe'), 'John_Doe');
      expect(service.sanitizeDocId('User / 01'), 'User___01');
    });

    test('Daily progress fraction correctly calculates 0/4 to 4/4 for 4-target categories', () {
      final service = PhysicalActivityService.instance;
      final dateKey = '2026-10-17';

      // Obesitas I has 4 target activities
      final obesitas1Acts = service.getActivitiesForCategory('Obesitas I');
      expect(obesitas1Acts.length, 4, reason: 'Obesitas I should have exactly 4 target activities');

      // Initial progress: 0/4
      expect(service.getProgressFractionForDate(dateKey, obesitas1Acts), '0/4');

      // Complete 1 activity
      final act1 = obesitas1Acts[0];
      final act1Id = act1['id'] as String;
      service.completeActivity(dateKey, act1Id, activity: act1);
      expect(service.isCompleted(dateKey, act1Id), true);
      expect(service.getProgressFractionForDate(dateKey, obesitas1Acts), '1/4');

      // Complete 2nd activity
      final act2 = obesitas1Acts[1];
      final act2Id = act2['id'] as String;
      service.completeActivity(dateKey, act2Id, activity: act2);
      expect(service.getProgressFractionForDate(dateKey, obesitas1Acts), '2/4');

      // Complete 3rd activity
      final act3 = obesitas1Acts[2];
      final act3Id = act3['id'] as String;
      service.completeActivity(dateKey, act3Id, activity: act3);
      expect(service.getProgressFractionForDate(dateKey, obesitas1Acts), '3/4');

      // Complete 4th activity
      final act4 = obesitas1Acts[3];
      final act4Id = act4['id'] as String;
      service.completeActivity(dateKey, act4Id, activity: act4);
      expect(service.getProgressFractionForDate(dateKey, obesitas1Acts), '4/4');

      // Toggle 4th activity back to uncompleted -> becomes 3/4
      service.uncompleteActivity(dateKey, act4Id, activity: act4);
      expect(service.isCompleted(dateKey, act4Id), false);
      expect(service.getProgressFractionForDate(dateKey, obesitas1Acts), '3/4');
    });

    test('Daily progress fraction correctly calculates 0/5 to 5/5 for Normal category', () {
      final service = PhysicalActivityService.instance;
      final dateKey = '2026-10-18';

      final normalActs = service.getActivitiesForCategory('Normal');
      expect(normalActs.length, 5, reason: 'Normal should have 5 target activities');

      expect(service.getProgressFractionForDate(dateKey, normalActs), '0/5');

      for (int i = 0; i < normalActs.length; i++) {
        final act = normalActs[i];
        service.completeActivity(dateKey, act['id'] as String, activity: act);
        expect(service.getProgressFractionForDate(dateKey, normalActs), '${i + 1}/5');
      }
    });

    test('toggleActivity toggles completion status safely', () async {
      final service = PhysicalActivityService.instance;
      final dateKey = '2026-10-19';
      final act = service.getActivitiesForCategory('Obesitas II').first;
      final actId = act['id'] as String;

      expect(service.isCompleted(dateKey, actId), false);

      // Toggle from false -> true
      await service.toggleActivity(dateKey: dateKey, activity: act);
      expect(service.isCompleted(dateKey, actId), true);

      // Toggle from true -> false
      await service.toggleActivity(dateKey: dateKey, activity: act);
      expect(service.isCompleted(dateKey, actId), false);
    });

    test('Unauthenticated user is handled safely without throwing or creating fake UIDs', () async {
      final service = PhysicalActivityService.instance;
      final dateKey = service.todayKey;
      final act = service.getActivitiesForCategory('Underweight').first;

      // When Firebase.apps is empty and no user is logged in, completing an activity
      // should persist locally without any crash or fake UID creation
      await expectLater(
        service.completeActivity(dateKey, act['id'] as String, activity: act),
        completes,
      );

      expect(service.isCompleted(dateKey, act['id'] as String), true);
    });

    test('startSession and finishSession safely handle unauthenticated state', () async {
      final service = PhysicalActivityService.instance;
      final act = service.getActivitiesForCategory('Obesitas I').first;

      // Calling startSession without authenticated user returns null safely
      final sessionId = await service.startSession(activity: act);
      expect(sessionId, isNull);

      // Calling finishSession without authenticated user returns false safely
      final result = await service.finishSession(
        sessionId: 'dummy_session_id',
        activity: act,
        elapsedSeconds: 1800,
      );
      expect(result, isFalse);

      // Calling cancelSession without authenticated user completes safely without exception
      await expectLater(
        service.cancelSession(sessionId: 'dummy_session_id'),
        completes,
      );

      // Calling ensureUserMainDoc without authenticated user returns null safely
      final mainDocRef = await service.ensureUserMainDoc();
      expect(mainDocRef, isNull);

      // Calling listenToFirestoreSessions without authenticated user completes safely
      await expectLater(
        service.listenToFirestoreSessions('2026-10-20'),
        completes,
      );
      service.stopListeningToSessions();
    });
  });
}
