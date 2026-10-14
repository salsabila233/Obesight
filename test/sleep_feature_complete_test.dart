import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:obesight/models/sleep_record_model.dart';
import 'package:obesight/screens/progress/night_sleep_detail_screen.dart';
import 'package:obesight/screens/progress/sleep_record_form_screen.dart';
import 'package:obesight/services/sleep_tracking_service.dart';
import 'package:obesight/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SleepTrackingService.instance.clearAll();
  });

  group('Uji Kelayakan 11 Skenario Fitur Waktu Tidur & Grafik Riwayat', () {
    // -------------------------------------------------------------------------
    // Skenario 1: Pengguna belum memiliki data tidur: kartu dan grafik kondisi kosong
    // -------------------------------------------------------------------------
    testWidgets('1. Pengguna belum memiliki data tidur: kartu dan grafik kondisi kosong', (tester) async {
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

      // Kartu Waktu Tidur menampilkan status kosong
      expect(find.text('Waktu Tidur'), findsWidgets);
      expect(find.text('-- j -- m'), findsOneWidget);

      // Grafik 7 hari menampilkan empty state ilustrasi & teks "Belum ada data tidur hari ini"
      expect(find.text('Belum ada data tidur hari ini'), findsOneWidget);
      expect(find.byKey(const ValueKey('daily_empty')), findsOneWidget);
      expect(find.byKey(const ValueKey('daily_bars')), findsNothing);
    });

    // -------------------------------------------------------------------------
    // Skenario 2: Waktu tidur 22.00 dan bangun 06.00: durasi menjadi 8 jam
    // -------------------------------------------------------------------------
    test('2. Waktu tidur 22.00 dan bangun 06.00 menghasilkan durasi tepat 8 jam', () {
      final start = DateTime(2026, 10, 14, 22, 0);
      final end = DateTime(2026, 10, 15, 6, 0);
      final record = SleepRecord(
        id: 'test_rec_22_06',
        userId: 'user_1',
        date: '2026-10-15',
        startTime: start,
        endTime: end,
      );

      expect(record.durationMinutes, 480); // 8 * 60 = 480
      expect(record.durationHours, 8);
      expect(record.durationRemainingMinutes, 0);
      expect(record.durationFormatted, '8 jam');
      expect(record.shortDurationFormatted, '8j');
    });

    // -------------------------------------------------------------------------
    // Skenario 3: Waktu tidur 23.30 dan bangun 05.00: durasi menjadi 5 jam 30 menit
    // -------------------------------------------------------------------------
    test('3. Waktu tidur 23.30 dan bangun 05.00 menghasilkan durasi tepat 5 jam 30 menit', () {
      final start = DateTime(2026, 10, 14, 23, 30);
      final end = DateTime(2026, 10, 15, 5, 0);
      final record = SleepRecord(
        id: 'test_rec_2330_0500',
        userId: 'user_1',
        date: '2026-10-15',
        startTime: start,
        endTime: end,
      );

      expect(record.durationMinutes, 330); // 5 * 60 + 30 = 330
      expect(record.durationHours, 5);
      expect(record.durationRemainingMinutes, 30);
      expect(record.durationFormatted, '5 jam 30 menit');
      expect(record.shortDurationFormatted, '5j 30m');
    });

    // -------------------------------------------------------------------------
    // Skenario 4: Pengguna menyimpan data manual: data muncul pada kartu dan grafik
    // -------------------------------------------------------------------------
    testWidgets('4. Pengguna menyimpan data manual: data muncul pada kartu dan grafik', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final now = DateTime.now();
      final dateKey = SleepTrackingService.formatDateKey(now);
      final service = SleepTrackingService.instance;

      // Simpan data tidur manual 7 jam
      final manualRecord = SleepRecord(
        id: 'manual_rec_today',
        userId: service.currentUserId,
        date: dateKey,
        startTime: DateTime(now.year, now.month, now.day, 23, 0),
        endTime: DateTime(now.year, now.month, now.day, 6, 0),
        durationMinutes: 420,
        source: 'manual',
      );
      await service.addRecord(manualRecord);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const NightSleepDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Kartu waktu tidur menampilkan durasi 7 j 0 m
      expect(find.text('7 j 0 m'), findsOneWidget);
      expect(find.text('23.00 - 06.00'), findsOneWidget);

      // Grafik bar 7 hari langsung muncul (bukan kondisi kosong)
      expect(find.byKey(const ValueKey('daily_bars')), findsOneWidget);
      expect(find.byKey(const ValueKey('daily_empty')), findsNothing);
    });

    // -------------------------------------------------------------------------
    // Skenario 5: Pengguna menekan Catat waktu ini: data valid tersimpan dan grafik diperbarui
    // -------------------------------------------------------------------------
    testWidgets('5. Pengguna menekan Catat waktu ini: kandidat tersimpan dan grafik diperbarui', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final now = DateTime.now();
      final service = SleepTrackingService.instance;
      // Simulasi kandidat deteksi otomatis perangkat: 5 jam 10 menit
      final candidateEnd = DateTime(now.year, now.month, now.day, 4, 10);
      final candidateStart = candidateEnd.subtract(const Duration(hours: 5, minutes: 10));

      final candidate = SleepRecord(
        id: 'candidate_auto_1',
        userId: service.currentUserId,
        date: SleepTrackingService.formatDateKey(now),
        startTime: candidateStart,
        endTime: candidateEnd,
        durationMinutes: 310,
        source: 'automatic',
      );
      service.setPendingAutoRecord(candidate);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const NightSleepDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Kandidat otomatis terlihat pada kartu
      expect(find.text('5 j 10 m'), findsOneWidget);
      final catatBtn = find.text('Catat waktu ini');
      expect(catatBtn, findsOneWidget);

      // Tekan tombol Catat waktu ini
      await tester.tap(catatBtn);
      await tester.pumpAndSettle();

      // Data tersimpan dan kandidat pending di-clear
      expect(service.pendingAutoDetectedRecord, isNull);
      expect(service.todayRecords.length, 1);
      expect(service.todayTotalMinutes, 310);

      // Grafik menampilkan batang 7 hari
      expect(find.byKey(const ValueKey('daily_bars')), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Skenario 6: Pengguna menutup dan membuka kembali aplikasi: data lokal persisten
    // -------------------------------------------------------------------------
    test('6. Data tidur tersimpan di SharedPreferences dan tetap ada saat aplikasi dibuka kembali', () async {
      final now = DateTime.now();
      final dateKey = SleepTrackingService.formatDateKey(now);
      final service = SleepTrackingService.instance;

      final record = SleepRecord(
        id: 'persist_rec_1',
        userId: service.currentUserId,
        date: dateKey,
        startTime: DateTime(now.year, now.month, now.day, 22, 0),
        endTime: DateTime(now.year, now.month, now.day, 6, 0),
        durationMinutes: 480,
        source: 'manual',
      );

      // Simpan record
      await service.addRecord(record);

      // Periksa isi SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final storedJson = prefs.getString('obesight_sleep_records_v1');
      expect(storedJson, isNotNull);
      expect(storedJson!.contains('persist_rec_1'), isTrue);
      expect(storedJson.contains('480'), isTrue);

      // Simulasi inisialisasi ulang service (aplikasi dibuka kembali)
      final reloadedService = SleepTrackingService();
      await reloadedService.initialize();

      expect(reloadedService.todayRecords.isNotEmpty, isTrue);
      expect(reloadedService.todayRecords.first.id, 'persist_rec_1');
      expect(reloadedService.todayTotalMinutes, 480);
    });

    // -------------------------------------------------------------------------
    // Skenario 7: Validasi penyimpanan data yang belum lengkap
    // -------------------------------------------------------------------------
    testWidgets('7. Validasi: menekan Catat waktu ini tanpa data memunculkan pesan validasi', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Pastikan service kosong tanpa data dan tanpa kandidat
      await SleepTrackingService.instance.clearAll();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const NightSleepDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final catatBtn = find.text('Catat waktu ini');
      expect(catatBtn, findsOneWidget);

      await tester.tap(catatBtn);
      await tester.pump();

      // Muncul SnackBar peringatan bahwa data belum lengkap/tersedia
      expect(find.textContaining('Data perkiraan waktu tidur belum tersedia'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Skenario 8: Mencegah duplikasi data pada tanggal yang sama
    // -------------------------------------------------------------------------
    test('8. Pencegahan duplikasi data pada tanggal yang sama', () async {
      final now = DateTime.now();
      final dateKey = SleepTrackingService.formatDateKey(now);
      final service = SleepTrackingService.instance;

      final rec1 = SleepRecord(
        id: 'dup_rec_1',
        userId: service.currentUserId,
        date: dateKey,
        startTime: DateTime(now.year, now.month, now.day, 22, 0),
        endTime: DateTime(now.year, now.month, now.day, 6, 0),
      );
      await service.addRecord(rec1);

      // Coba tambah data dengan rentang yang tumpang tindih
      final overlap = service.findOverlappingRecord(
        DateTime(now.year, now.month, now.day, 22, 30),
        DateTime(now.year, now.month, now.day, 5, 30),
        dateKey,
      );
      expect(overlap, isNotNull);
      expect(overlap!.id, 'dup_rec_1');

      // Saat pengguna memilih ganti data (replace)
      final rec2 = SleepRecord(
        id: 'dup_rec_2',
        userId: service.currentUserId,
        date: dateKey,
        startTime: DateTime(now.year, now.month, now.day, 23, 0),
        endTime: DateTime(now.year, now.month, now.day, 7, 0),
      );
      await service.replaceRecord('dup_rec_1', rec2);

      final currentRecs = service.getRecordsForDate(now);
      expect(currentRecs.length, 1);
      expect(currentRecs.first.id, 'dup_rec_2');
    });

    // -------------------------------------------------------------------------
    // Skenario 9: Data dari tanggal yang berbeda muncul pada posisi tanggal yang benar
    // -------------------------------------------------------------------------
    test('9. Data tanggal berbeda terpetakan dengan benar di ringkasan 7 hari', () async {
      final now = DateTime.now();
      final service = SleepTrackingService.instance;

      // Catat data untuk kemarin (H-1)
      final yesterday = now.subtract(const Duration(days: 1));
      final recYesterday = SleepRecord(
        id: 'rec_yesterday',
        userId: service.currentUserId,
        date: SleepTrackingService.formatDateKey(yesterday),
        startTime: DateTime(yesterday.year, yesterday.month, yesterday.day, 22, 0),
        endTime: DateTime(yesterday.year, yesterday.month, yesterday.day, 6, 0),
        durationMinutes: 480,
      );
      await service.addRecord(recYesterday);

      // Catat data untuk 3 hari lalu (H-3)
      final dayMinus3 = now.subtract(const Duration(days: 3));
      final recMinus3 = SleepRecord(
        id: 'rec_minus3',
        userId: service.currentUserId,
        date: SleepTrackingService.formatDateKey(dayMinus3),
        startTime: DateTime(dayMinus3.year, dayMinus3.month, dayMinus3.day, 23, 0),
        endTime: DateTime(dayMinus3.year, dayMinus3.month, dayMinus3.day, 5, 0),
        durationMinutes: 360,
      );
      await service.addRecord(recMinus3);

      final summaries = service.getPast7DaysSummaries(now);
      expect(summaries.length, 7);

      // Hari ini (indeks 6 / terakhir) belum ada data
      expect(summaries.last.hasData, isFalse);
      expect(summaries.last.totalMinutes, 0);

      // Kemarin (indeks 5) memiliki durasi 480 menit (8 jam)
      expect(summaries[5].hasData, isTrue);
      expect(summaries[5].totalMinutes, 480);
      expect(summaries[5].dayNumber, yesterday.day.toString());

      // H-3 (indeks 3) memiliki durasi 360 menit (6 jam)
      expect(summaries[3].hasData, isTrue);
      expect(summaries[3].totalMinutes, 360);
      expect(summaries[3].dayNumber, dayMinus3.day.toString());
    });

    // -------------------------------------------------------------------------
    // Skenario 10: Banner HD tidur berkualitas tinggi
    // -------------------------------------------------------------------------
    test('10. File aset banner HD hero_malam_hd.jpg tersedia dan beresolusi tinggi', () {
      final file = File('d:\\Obesight\\assets\\progress\\rest\\hero_malam_hd.jpg');
      expect(file.existsSync(), isTrue);
      // Ukuran file lebih dari 200KB (menandakan gambar HD tajam, bukan kompresi pecah)
      expect(file.lengthSync(), greaterThan(200000));
    });

    // -------------------------------------------------------------------------
    // Skenario 11: Navigasi ke Form Masukkan data berjalan lancar
    // -------------------------------------------------------------------------
    testWidgets('11. Tombol Masukkan data membuka SleepRecordFormScreen dengan benar', (tester) async {
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

      final masukkanDataBtn = find.text('Masukkan data');
      await tester.ensureVisible(masukkanDataBtn);
      await tester.pumpAndSettle();
      await tester.tap(masukkanDataBtn);
      await tester.pumpAndSettle();

      expect(find.byType(SleepRecordFormScreen), findsOneWidget);
      expect(find.text('Jam istirahat'), findsOneWidget);
      expect(find.text('Jam selesai'), findsOneWidget);
      expect(find.text('Durasi istirahat'), findsOneWidget);
      expect(find.text('Simpan'), findsOneWidget);
    });
  });
}
