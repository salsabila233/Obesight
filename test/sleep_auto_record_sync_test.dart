import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:obesight/models/sleep_record_model.dart';
import 'package:obesight/screens/progress/night_sleep_detail_screen.dart';
import 'package:obesight/services/sleep_tracking_service.dart';
import 'package:obesight/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SleepTrackingService.instance.clearAll();
  });

  void setPhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('Verifikasi Perbaikan Modul Waktu Tidur: "Catat waktu ini" vs Manual', () {
    test('1. Struktur Data & Field Tombol "Catat waktu ini" Identik dengan Input Manual', () async {
      final service = SleepTrackingService.instance;
      final now = DateTime.now();
      final dateKey = SleepTrackingService.formatDateKey(now);

      // Simulasikan kandidat otomatis (22:30 -> 06:15, 465 menit)
      final autoStart = DateTime(now.year, now.month, now.day - 1, 22, 30);
      final autoEnd = DateTime(now.year, now.month, now.day, 6, 15);

      service.setPendingAutoRecord(
        SleepRecord(
          id: 'candidate_auto_test',
          userId: service.currentUserId,
          date: dateKey,
          startTime: autoStart,
          endTime: autoEnd,
          durationMinutes: 465,
          source: 'automatic',
          isConfirmed: false,
        ),
      );

      // Simpan via acceptPendingAutoRecord ("Catat waktu ini")
      final accepted = await service.acceptPendingAutoRecord(targetDate: now);
      expect(accepted, isTrue);

      final autoSaved = service.getRecordsForDate(now).first;

      // Verifikasi model SleepRecord
      expect(autoSaved.userId, service.currentUserId);
      expect(autoSaved.date, dateKey);
      expect(autoSaved.startTime, autoStart);
      expect(autoSaved.endTime, autoEnd);
      expect(autoSaved.durationMinutes, 465);
      expect(autoSaved.isConfirmed, isTrue);
      expect(autoSaved.source, 'automatic');

      // Verifikasi struktur map Firestore: field 'date', 'startTime', 'endTime', 'durationMinutes', 'isConfirmed'
      final firestoreMap = autoSaved.toFirestoreMap();
      expect(firestoreMap.containsKey('date'), isTrue);
      expect(firestoreMap.containsKey('startTime'), isTrue);
      expect(firestoreMap.containsKey('endTime'), isTrue);
      expect(firestoreMap.containsKey('durationMinutes'), isTrue);
      expect(firestoreMap.containsKey('isConfirmed'), isTrue);
      expect(firestoreMap['isConfirmed'], isTrue);
      expect(firestoreMap['durationMinutes'], 465);
      expect(firestoreMap['startTime'], isA<Timestamp>());
      expect(firestoreMap['endTime'], isA<Timestamp>());

      // Verifikasi struktur map Local Storage (toMap)
      final localMap = autoSaved.toMap();
      expect(localMap['date'], dateKey);
      expect(localMap['durationMinutes'], 465);
      expect(localMap['isConfirmed'], isTrue);
      expect(localMap['status'], 'confirmed');
    });

    testWidgets('2. Sinkronisasi Kueri Grafik & Real-time State setelah "Catat waktu ini"', (tester) async {
      setPhoneViewport(tester);

      final service = SleepTrackingService.instance;
      final now = DateTime.now();

      // State awal: tidak ada data, muncul pesan empty state
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const NightSleepDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Belum ada data tidur hari ini'), findsOneWidget);
      expect(find.byKey(const ValueKey('daily_bars')), findsNothing);

      // Siapkan kandidat
      service.setPendingAutoRecord(
        SleepRecord(
          id: 'candidate_sync_chart',
          userId: service.currentUserId,
          date: SleepTrackingService.formatDateKey(now),
          startTime: DateTime(now.year, now.month, now.day - 1, 22, 0),
          endTime: DateTime(now.year, now.month, now.day, 6, 0),
          durationMinutes: 480,
          source: 'automatic',
          isConfirmed: false,
        ),
      );
      await tester.pumpAndSettle();

      // Klik tombol "Catat waktu ini"
      await tester.tap(find.text('Catat waktu ini'));
      await tester.pumpAndSettle();

      // Grafik langsung ter-render secara real-time tanpa perlu restart
      expect(find.text('Belum ada data tidur hari ini'), findsNothing);
      expect(find.byKey(const ValueKey('daily_bars')), findsOneWidget);
      expect(find.text('8j 0m'), findsOneWidget);
      expect(find.text('8 j 0 m'), findsOneWidget);
    });

    testWidgets('3. Status Tombol berubah menjadi "Sudah Dicatat" dengan Centang dan Anti Duplikasi', (tester) async {
      setPhoneViewport(tester);

      final service = SleepTrackingService.instance;
      final now = DateTime.now();

      service.setPendingAutoRecord(
        SleepRecord(
          id: 'candidate_status_test',
          userId: service.currentUserId,
          date: SleepTrackingService.formatDateKey(now),
          startTime: DateTime(now.year, now.month, now.day - 1, 23, 0),
          endTime: DateTime(now.year, now.month, now.day, 6, 30),
          durationMinutes: 450,
          source: 'automatic',
          isConfirmed: false,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const NightSleepDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi sebelum dicatat: tombol "Catat waktu ini" tampil
      expect(find.text('Catat waktu ini'), findsOneWidget);
      expect(find.text('Sudah Dicatat'), findsNothing);

      // Klik tombol
      await tester.tap(find.text('Catat waktu ini'));
      await tester.pumpAndSettle();

      // Tombol berubah status menjadi "Sudah Dicatat" dengan ikon centang
      expect(find.text('Sudah Dicatat'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsWidgets);
      expect(find.text('Catat waktu ini'), findsNothing);

      // Ketuk kembali status "Sudah Dicatat": tidak dapat di-tap & tidak menduplikasi data
      await tester.tap(find.text('Sudah Dicatat'));
      await tester.pumpAndSettle();
      expect(service.allRecords.length, 1);
    });
  });
}
