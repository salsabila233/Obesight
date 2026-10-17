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
    // POIN 3: Penyesuaian Grafik & Opsi Filter (Default: Hari Ini Saja)
    // -------------------------------------------------------------------------
    testWidgets('Poin 3: Opsi filter grafik (Default: Hari ini saja, Jam, Minggu, Bulan)', (tester) async {
      setPhoneViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const NightSleepDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Default awal adalah Tab Hari (fokus hari ini saja)
      expect(find.text('Waktu tidur hari ini'), findsOneWidget);

      // Pindah ke tab Jam
      final jamTab = find.text('Jam');
      await tester.tap(jamTab);
      await tester.pumpAndSettle();
      expect(find.text('Distribusi tidur per jam hari ini'), findsOneWidget);
      expect(find.byKey(const ValueKey('hourly_chart')), findsOneWidget);

      // Pindah ke tab Minggu (rentang 7 hari)
      final mingguTab = find.text('Minggu');
      await tester.tap(mingguTab);
      await tester.pumpAndSettle();
      expect(find.text('Waktu tidur selama 1 minggu (7 hari)'), findsOneWidget);
      expect(find.byKey(const ValueKey('weekly_chart')), findsOneWidget);

      // Pindah ke tab Bulan (1 bulan kalender)
      final bulanTab = find.text('Bulan');
      await tester.tap(bulanTab);
      await tester.pumpAndSettle();
      expect(find.text('Waktu tidur selama 1 bulan kalender'), findsOneWidget);
      expect(find.byKey(const ValueKey('monthly_chart')), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // POIN 4: Pengingat Waktu Tidur & Notifikasi Sistem
    // -------------------------------------------------------------------------
    testWidgets('Poin 4: Pengaturan pengingat dan tombol Uji Notifikasi Sekarang', (tester) async {
      setPhoneViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SleepHistoryDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi switch pengingat waktu tidur ada
      expect(find.text('Pengingat Waktu Tidur'), findsOneWidget);
      expect(find.text('Target Waktu Tidur'), findsOneWidget);

      // Verifikasi tombol "Uji Notifikasi Sekarang" tersedia
      final testBtn = find.text('Uji Notifikasi Sekarang');
      expect(testBtn, findsOneWidget);

      // Mengetuk tombol uji notifikasi
      await tester.ensureVisible(testBtn);
      await tester.tap(testBtn);
      await tester.pumpAndSettle();

      // SnackBar konfirmasi muncul
      expect(find.text('Notifikasi pengingat tidur telah dikirim ke status bar!'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // POIN 5: Menampilkan Seluruh Riwayat Catatan Tidur (Otomatis & Manual)
    // -------------------------------------------------------------------------
    testWidgets('Poin 5: Menampilkan seluruh riwayat tidur dari rekaman otomatis dan input manual', (tester) async {
      setPhoneViewport(tester);

      final service = SleepTrackingService.instance;
      final now = DateTime.now();

      // 1. Tambah record otomatis
      await service.addRecord(
        SleepRecord(
          id: 'auto_rec_1',
          userId: 'user_test',
          date: SleepTrackingService.formatDateKey(now),
          startTime: now.subtract(const Duration(hours: 8)),
          endTime: now,
          source: 'automatic',
        ),
      );

      // 2. Tambah record manual kemarin
      final yesterday = now.subtract(const Duration(days: 1));
      await service.addRecord(
        SleepRecord(
          id: 'manual_rec_2',
          userId: 'user_test',
          date: SleepTrackingService.formatDateKey(yesterday),
          startTime: yesterday.subtract(const Duration(hours: 7)),
          endTime: yesterday,
          source: 'manual',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SleepHistoryDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi section Riwayat Catatan Tidur
      expect(find.text('Riwayat Catatan Tidur'), findsOneWidget);
      expect(find.text('2 catatan'), findsOneWidget);

      // Ikon ponsel (otomatis) dan ikon pensil (manual) muncul
      expect(find.byIcon(Icons.phone_android_rounded), findsOneWidget);
      expect(find.byIcon(Icons.edit_note_rounded), findsOneWidget);
    });
  });
}
