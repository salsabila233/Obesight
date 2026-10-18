import 'package:cloud_firestore/cloud_firestore.dart';
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

  void setPhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('Pengujian Komprehensif Logika Tidur Ala Samsung Health, Status Tombol & Sinkronisasi Grafik', () {
    // =========================================================================
    // 1. LOGIKA PENCATATAN WAKTU TIDUR (LINTAS HARI & NO NEGATIVE DURATION)
    // =========================================================================
    test('1.1 Kalkulasi durasi lintas hari mendeteksi tengah malam & tidak pernah bernilai negatif', () {
      final t18 = DateTime(2026, 10, 18, 22, 0); // 22:00 tgl 18
      final t19 = DateTime(2026, 10, 19, 6, 0);  // 06:00 tgl 19

      // Skenario A: Waktu bangun di hari berikutnya (tgl 19)
      final durationMinutes1 = SleepRecord.calculateDurationMinutes(t18, t19);
      expect(durationMinutes1, 480); // 8 jam

      // Skenario B: Waktu bangun 06:00 dimasukkan tanpa tanggal hari esok (jam lebih kecil)
      final t18Wake = DateTime(2026, 10, 18, 6, 0);
      final durationMinutes2 = SleepRecord.calculateDurationMinutes(t18, t18Wake);
      expect(durationMinutes2, 480); // Otomatis +24 jam, durasi 8 jam positif

      // Skenario C: Model SleepRecord secara otomatis menyesuaikan endTime dan durasi
      final record = SleepRecord(
        id: 'test_midnight_1',
        userId: 'user_1',
        date: '2026-10-18',
        startTime: t18,
        endTime: t18Wake, // 06:00 hari yang sama
      );

      expect(record.endTime.day, 19); // Menjadi tanggal 19
      expect(record.durationMinutes, 480);
      expect(record.durationHours, 8);
      expect(record.durationRemainingMinutes, 0);
      expect(record.durationFormatted, '8 jam');
      expect(record.shortDurationFormatted, '8j');
    });

    // =========================================================================
    // 2. SISTEM UPSERT (1 DATA PER HARI - NO DUPLICATION)
    // =========================================================================
    test('1.2 Sistem upsert memperbarui data pada hari yang sama dan mencegah data ganda', () async {
      final service = SleepTrackingService.instance;
      final now = DateTime.now();
      final dateKey = SleepTrackingService.formatDateKey(now);

      // Data pertama: Tidur 6 jam (23:00 - 05:00)
      final record1 = SleepRecord(
        id: 'rec_day_initial',
        userId: service.currentUserId,
        date: dateKey,
        startTime: DateTime(now.year, now.month, now.day, 23, 0),
        endTime: DateTime(now.year, now.month, now.day + 1, 5, 0),
        source: 'manual',
      );
      await service.addRecord(record1);

      expect(service.todayRecords.length, 1);
      expect(service.todayTotalMinutes, 360);

      // Data kedua untuk hari yang sama (misal revisi tidur 8 jam: 22:00 - 06:00)
      final record2 = SleepRecord(
        id: 'rec_day_updated',
        userId: service.currentUserId,
        date: dateKey,
        startTime: DateTime(now.year, now.month, now.day, 22, 0),
        endTime: DateTime(now.year, now.month, now.day + 1, 6, 0),
        source: 'automatic',
      );
      await service.addRecord(record2);

      // Jumlah data tetap 1 (ter-upsert/diperbarui), tidak tumpang tindih
      expect(service.todayRecords.length, 1);
      expect(service.todayRecords.first.id, 'rec_day_updated');
      expect(service.todayTotalMinutes, 480);
      expect(service.allRecords.length, 1);
    });

    // =========================================================================
    // 3. SINKRONISASI WAKTU LOKAL (UTC TIMESTAMP & LOCAL TIMEZONE CONVERSION)
    // =========================================================================
    test('1.3 Konversi waktu lokal ke Timestamp UTC dan sebaliknya tidak mengalami pergeseran timezone', () {
      final localStart = DateTime(2026, 10, 18, 22, 30);
      final localEnd = DateTime(2026, 10, 19, 6, 15);

      final record = SleepRecord(
        id: 'tz_test_1',
        userId: 'user_tz',
        date: '2026-10-18',
        startTime: localStart,
        endTime: localEnd,
      );

      // 1. Simpan ke map Firestore (menyimpan Timestamp UTC)
      final firestoreMap = record.toFirestoreMap();
      expect(firestoreMap['waktu_mulai'], isA<Timestamp>());
      expect(firestoreMap['waktu_bangun'], isA<Timestamp>());

      // 2. Baca kembali dari Firestore map
      final restored = SleepRecord.fromMap(firestoreMap);

      // Jam dan menit lokal harus tepat sama dengan waktu lokal pengguna semula
      expect(restored.startTime.hour, localStart.hour);
      expect(restored.startTime.minute, localStart.minute);
      expect(restored.endTime.hour, localEnd.hour);
      expect(restored.endTime.minute, localEnd.minute);
      expect(restored.durationMinutes, 465); // 7 jam 45 menit
    });

    // =========================================================================
    // 4. PERBAIKAN STATUS TOMBOL "Catat waktu ini" -> "Tersimpan" & CARD TETAP ADA
    // =========================================================================
    testWidgets('2. Tombol "Catat waktu ini" berubah jadi "Tersimpan", dinonaktifkan, dan card estimasi tetap terlihat', (tester) async {
      setPhoneViewport(tester);

      final service = SleepTrackingService.instance;
      final now = DateTime.now();

      // Buat kandidat deteksi otomatis: 7 jam 30 menit (22:30 -> 06:00)
      final candidateStart = DateTime(now.year, now.month, now.day - 1, 22, 30);
      final candidateEnd = DateTime(now.year, now.month, now.day, 6, 0);

      service.setPendingAutoRecord(
        SleepRecord(
          id: 'auto_candidate_1',
          userId: service.currentUserId,
          date: SleepTrackingService.formatDateKey(now),
          startTime: candidateStart,
          endTime: candidateEnd,
          durationMinutes: 450,
          source: 'automatic',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const NightSleepDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi status awal: durasi estimasi terlihat dan tombol "Catat waktu ini" aktif
      expect(find.text('7 j 30 m'), findsOneWidget);
      expect(find.text('Catat waktu ini'), findsOneWidget);
      expect(find.text('Sudah Dicatat'), findsNothing);

      // Tekan tombol "Catat waktu ini"
      await tester.tap(find.text('Catat waktu ini'));
      await tester.pumpAndSettle();

      // Card estimasi waktu tidur TETAP TERLIHAT (durasi & jam tetap eksis)
      expect(find.text('7 j 30 m'), findsOneWidget);

      // Tombol berubah menjadi status "Sudah Dicatat" dengan ikon ceklis
      expect(find.text('Sudah Dicatat'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsWidgets);
      expect(find.text('Catat waktu ini'), findsNothing);

      // Mengetuk status "Sudah Dicatat" tidak menduplikasi data
      await tester.tap(find.text('Sudah Dicatat'));
      await tester.pumpAndSettle();
      expect(service.allRecords.length, 1);
    });

    // =========================================================================
    // 5. STATUS KONSISTEN "Sudah Dicatat" SAAT HALAMAN DIBUKA ULANG
    // =========================================================================
    testWidgets('2.1 Status tombol tetap konsisten "Sudah Dicatat" saat halaman dibuka kembali', (tester) async {
      setPhoneViewport(tester);

      final service = SleepTrackingService.instance;
      final now = DateTime.now();
      final dateKey = SleepTrackingService.formatDateKey(now);

      // Simulasikan data tidur yang sudah ada di database/local storage
      await service.addRecord(
        SleepRecord(
          id: 'rec_saved_prior',
          userId: service.currentUserId,
          date: dateKey,
          startTime: DateTime(now.year, now.month, now.day, 22, 0),
          endTime: DateTime(now.year, now.month, now.day + 1, 6, 0),
          durationMinutes: 480,
          source: 'automatic',
        ),
      );

      // Buka halaman NightSleepDetailScreen
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const NightSleepDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Status langsung terdeteksi sebagai "Sudah Dicatat" berdasarkan data di DB
      expect(find.text('Sudah Dicatat'), findsOneWidget);
      expect(find.text('Catat waktu ini'), findsNothing);
      expect(find.text('8 j 0 m'), findsOneWidget);
    });

    // =========================================================================
    // 6. SINKRONISASI GRAFIK SECARA OTOMATIS (REAL DATA & EMPTY STATE HILANG)
    // =========================================================================
    testWidgets('3. Grafik hari ini otomatis diperbarui, pesan empty state hilang, data sinkron ke riwayat', (tester) async {
      setPhoneViewport(tester);

      final service = SleepTrackingService.instance;
      final now = DateTime.now();

      // State awal tanpa data
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const NightSleepDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi pesan empty state ada
      expect(find.text('Belum ada data tidur hari ini'), findsOneWidget);

      // Buat kandidat dan tekan catat
      service.setPendingAutoRecord(
        SleepRecord(
          id: 'cand_sync_1',
          userId: service.currentUserId,
          date: SleepTrackingService.formatDateKey(now),
          startTime: DateTime(now.year, now.month, now.day, 22, 30),
          endTime: DateTime(now.year, now.month, now.day + 1, 6, 15),
          durationMinutes: 465,
          source: 'automatic',
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Catat waktu ini'));
      await tester.pumpAndSettle();

      // 1. Pesan "Belum ada data tidur hari ini" HILANG
      expect(find.text('Belum ada data tidur hari ini'), findsNothing);

      // 2. Grafik batang hari ini (daily_bars) MUNCUL
      expect(find.byKey(const ValueKey('daily_bars')), findsOneWidget);

      // 3. Informasi riil waktu tidur, waktu bangun, dan durasi tampil
      expect(find.textContaining('Tidur: 22:30'), findsOneWidget);
      expect(find.textContaining('Bangun: 06:15'), findsOneWidget);
      expect(find.text('7j 45m'), findsWidgets);

      // 4. Buka halaman riwayat lengkap (Single Source of Truth)
      await tester.tap(find.text('Waktu tidur selama 7 hari terakhir'));
      await tester.pumpAndSettle();

      expect(find.byType(SleepHistoryDetailScreen), findsOneWidget);

      // Tab Hari: menampilkan data 7j 45m yang baru saja disimpan
      expect(find.text('Hari'), findsOneWidget);
      expect(find.textContaining('7j 45m'), findsWidgets);

      // Tab Jam: menampilkan visualisasi jam kronologis
      await tester.tap(find.text('Jam'));
      await tester.pumpAndSettle();
      expect(find.textContaining('22.30 - 06.15'), findsOneWidget);

      // Tab Minggu & Bulan: data terintegrasi dari sumber data tunggal yang sama
      await tester.tap(find.text('Minggu'));
      await tester.pumpAndSettle();
      expect(find.textContaining('7.8j'), findsWidgets);

      await tester.tap(find.text('Bulan'));
      await tester.pumpAndSettle();
      expect(find.textContaining('7.8j'), findsWidgets);
      expect(find.textContaining('7j 45m'), findsWidgets);
    });
  });
}
