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

  group('Uji Komprehensif 5 Poin Perbaikan Modul Waktu Tidur Malam', () {
    // -------------------------------------------------------------------------
    // POIN 1: Perbaikan Header, Banner Ilustrasi, dan Collapsible Title Tanpa Judul Ganda
    // -------------------------------------------------------------------------
    testWidgets('Poin 1: Header banner ada, judul bertransisi, dan tidak ada judul ganda di body', (tester) async {
      setPhoneViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const NightSleepDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Tepat 1 widget teks "Waktu Tidur Malam" di seluruh layar (tidak ada judul ganda di body)
      expect(find.text('Waktu Tidur Malam'), findsOneWidget);

      // 2. Banner ilustrasi atas terpasang
      expect(find.byType(Image), findsOneWidget);

      // 3. Gulir ke atas
      final scrollFinder = find.byType(CustomScrollView);
      await tester.drag(scrollFinder, const Offset(0, -600));
      await tester.pumpAndSettle();

      // 4. Setelah digulir, judul tetap eksis dan menetap di pinned header app bar
      expect(find.text('Waktu Tidur Malam'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // POIN 2: Integrasi Rekam Aktivitas Tidur & Tombol "Catat waktu ini"
    // -------------------------------------------------------------------------
    testWidgets('Poin 2: Deteksi inaktivitas perangkat & tombol "Catat waktu ini" menyimpan data', (tester) async {
      setPhoneViewport(tester);

      final service = SleepTrackingService.instance;
      // Simulasi deteksi layar mati semalaman (7 jam 30 menit)
      service.simulateInactivity(durationMinutes: 450);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const NightSleepDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Memastikan kandidat otomatis muncul di Card 1
      expect(find.text('7 j 30 m'), findsOneWidget);
      expect(find.text('Catat waktu ini'), findsOneWidget);

      // Tekan tombol "Catat waktu ini"
      await tester.tap(find.text('Catat waktu ini'));
      await tester.pumpAndSettle();

      // Kandidat telah tercatat ke dalam daftar records
      expect(service.allRecords.length, 1);
      expect(service.allRecords.first.isAutomatic, isTrue);
      expect(service.allRecords.first.durationMinutes, 450);

      // Grafik langsung diperbarui menampilkan visual data
      expect(find.byKey(const ValueKey('daily_bars')), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // POIN 3: Pembersihan Filter Grafik di Halaman Utama & Navigasi ke Filter Lengkap
    // -------------------------------------------------------------------------
    testWidgets('Poin 3: Filter jam/minggu/bulan dihapus dari beranda, navigasi ke statistik lengkap', (tester) async {
      setPhoneViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const NightSleepDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verifikasi judul Card 2 adalah 'Waktu tidur selama 7 hari terakhir'
      expect(find.text('Waktu tidur selama 7 hari terakhir'), findsOneWidget);

      // 2. Verifikasi tombol filter 'Jam', 'Minggu', 'Bulan' TIDAK ADA di halaman utama
      expect(find.text('Jam'), findsNothing);
      expect(find.text('Minggu'), findsNothing);
      expect(find.text('Bulan'), findsNothing);

      // 3. State awal menampilkan data hari ini bersih (empty state)
      expect(find.text('Belum ada data tidur hari ini'), findsOneWidget);

      // 4. Klik judul navigasi card untuk membuka halaman statistik lengkap
      await tester.tap(find.text('Waktu tidur selama 7 hari terakhir'));
      await tester.pumpAndSettle();

      // 5. Di halaman SleepHistoryDetailScreen, filter lengkap tersedia
      expect(find.byType(SleepHistoryDetailScreen), findsOneWidget);
      expect(find.text('Jam'), findsOneWidget);
      expect(find.text('Hari'), findsOneWidget);
      expect(find.text('Minggu'), findsOneWidget);
      expect(find.text('Bulan'), findsOneWidget);

      // 6. Uji interaksi filter di halaman statistik lengkap
      await tester.tap(find.text('Jam'));
      await tester.pumpAndSettle();
      expect(find.text('Visualisasi jam tidur malam (20.00 – 08.00) secara kronologis untuk tanggal terpilih'), findsOneWidget);

      await tester.tap(find.text('Minggu'));
      await tester.pumpAndSettle();
      expect(find.text('Statistik tidur harian selama 1 minggu penuh (7 hari)'), findsOneWidget);

      await tester.tap(find.text('Bulan'));
      await tester.pumpAndSettle();
      expect(find.text('Akumulasi data tidur selama 1 bulan kalender penuh'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // POIN 4: Otomatisasi Pengingat Waktu Tidur Tanpa Tombol Uji Notifikasi
    // -------------------------------------------------------------------------
    testWidgets('Poin 4: Pengingat otomatis di latar belakang dan tombol "Uji Notifikasi Sekarang" telah dihapus', (tester) async {
      setPhoneViewport(tester);

      final service = SleepTrackingService.instance;
      service.reminderEnabled = true;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SleepHistoryDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verifikasi switch pengingat waktu tidur dan target waktu tidur ada
      expect(find.text('Pengingat Waktu Tidur'), findsOneWidget);
      expect(find.text('Target Waktu Tidur'), findsOneWidget);

      // 2. Verifikasi tombol "Uji Notifikasi Sekarang" sudah dihapus dari layar
      expect(find.text('Uji Notifikasi Sekarang'), findsNothing);

      // 3. Verifikasi info penjadwalan otomatis di latar belakang tampil
      expect(find.textContaining('Sistem pengingat aktif otomatis di latar belakang'), findsOneWidget);

      // 4. Toggle pengingat otomatis mengubah state dan menjadwalkan notifikasi
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();
      expect(service.reminderEnabled, isFalse);
    });

    // -------------------------------------------------------------------------
    // POIN 5: Validasi Data Unik pada Riwayat Catatan Tidur (1 Tanggal = 1 Data)
    // -------------------------------------------------------------------------
    testWidgets('Poin 5: Validasi 1 Tanggal = 1 Data unik (menimpa rekaman lama jika tanggal sama)', (tester) async {
      setPhoneViewport(tester);

      final service = SleepTrackingService.instance;
      final now = DateTime.now();
      final dateKey = SleepTrackingService.formatDateKey(now);

      // 1. Tambah record awal untuk hari ini (durasi 6 jam)
      await service.addRecord(
        SleepRecord(
          id: 'rec_today_v1',
          userId: 'user_test',
          date: dateKey,
          startTime: now.subtract(const Duration(hours: 6)),
          endTime: now,
          source: 'manual',
        ),
      );
      expect(service.allRecords.length, 1);
      expect(service.allRecords.first.durationMinutes, 360);

      // 2. Simpan record baru pada tanggal yang sama (misal hasil perbaikan / "Catat waktu ini" 8 jam)
      // Harus menimpa record sebelumnya, TIDAK menghasilkan 2 data pada 1 tanggal
      await service.addRecord(
        SleepRecord(
          id: 'rec_today_v2',
          userId: 'user_test',
          date: dateKey,
          startTime: now.subtract(const Duration(hours: 8)),
          endTime: now,
          source: 'automatic',
        ),
      );

      expect(service.allRecords.length, 1);
      expect(service.allRecords.first.id, 'rec_today_v2');
      expect(service.allRecords.first.durationMinutes, 480);
      expect(service.allRecords.first.isAutomatic, isTrue);

      // 3. Tambah record untuk tanggal berbeda (kemarin)
      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayKey = SleepTrackingService.formatDateKey(yesterday);
      await service.addRecord(
        SleepRecord(
          id: 'rec_yesterday',
          userId: 'user_test',
          date: yesterdayKey,
          startTime: yesterday.subtract(const Duration(hours: 7)),
          endTime: yesterday,
          source: 'manual',
        ),
      );

      // Total data harus tepat 2 (masing-masing tanggal unik)
      expect(service.allRecords.length, 2);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SleepHistoryDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi di UI bahwa 2 tanggal unik ditampilkan
      expect(find.text('Riwayat Catatan Tidur'), findsOneWidget);
      expect(find.text('2 catatan'), findsOneWidget);
      expect(find.byIcon(Icons.phone_android_rounded), findsOneWidget);
      expect(find.byIcon(Icons.edit_note_rounded), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // POIN 6: Penyempurnaan Logika Deteksi Tidur Otomatis
    // -------------------------------------------------------------------------
    testWidgets('Poin 6: Logika deteksi tidur otomatis berdasarkan inaktivitas layar dan transisi cahaya', (tester) async {
      final service = SleepTrackingService.instance;
      final now = DateTime.now();

      // Simulasi inaktivitas perangkat (tidur 7 jam)
      service.simulateInactivity(
        durationMinutes: 420,
        customStart: now.subtract(const Duration(hours: 7)),
        customEnd: now,
      );

      expect(service.pendingAutoDetectedRecord, isNotNull);
      expect(service.pendingAutoDetectedRecord!.durationMinutes, 420);

      // Terima kandidat otomatis
      await service.acceptPendingAutoRecord();
      expect(service.pendingAutoDetectedRecord, isNull);
      expect(service.allRecords.length, 1);
      expect(service.allRecords.first.isAutomatic, isTrue);
      expect(service.allRecords.first.durationMinutes, 420);
    });
  });
}
