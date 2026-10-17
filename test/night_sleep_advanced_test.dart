import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:obesight/screens/progress/night_sleep_detail_screen.dart';
import 'package:obesight/screens/progress/sleep_history_detail_screen.dart';
import 'package:obesight/screens/progress/sleep_record_form_screen.dart';
import 'package:obesight/services/sleep_tracking_service.dart';
import 'package:obesight/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SleepTrackingService.instance.clearAll();
    // Simulasi deteksi waktu tidak aktif HP 5 jam 10 menit
    SleepTrackingService.instance.simulateInactivity(
      durationMinutes: 310,
    );
  });

  testWidgets('Waktu Tidur Malam: Desain Awal, Sticky Header, Opsi Grafik & Catat Otomatis', (WidgetTester tester) async {
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

    // 1. Verifikasi Judul & Subtitle
    expect(find.text('Waktu Tidur Malam'), findsWidgets);
    expect(find.text('Tidur yang cukup dan teratur membantu metabolisme tubuh tetap seimbang.'), findsOneWidget);

    // 2. Verifikasi Card 1: Waktu Tidur Hari ini (Kandidat otomatis 5 j 10 m & tombol Catat waktu ini)
    expect(find.text('Waktu Tidur'), findsWidgets);
    expect(find.text('5 j 10 m'), findsOneWidget);
    expect(find.text('Catat waktu ini'), findsOneWidget);

    // 3. Verifikasi Card 2: Hari Ini State Awal (Belum ada data tidur hari ini)
    expect(find.text('Waktu tidur selama 7 hari terakhir'), findsOneWidget);
    expect(find.text('Belum ada data tidur hari ini'), findsOneWidget);

    // 4. Verifikasi Tombol Bawah: Masukkan data
    expect(find.text('Masukkan data'), findsOneWidget);

    // 5. Verifikasi Tombol "Atur Pengingat" & Filter Jam/Minggu/Bulan telah dihapus dari Beranda
    expect(find.text('Atur pengingat'), findsNothing);
    expect(find.text('Jam'), findsNothing);
    expect(find.text('Minggu'), findsNothing);
    expect(find.text('Bulan'), findsNothing);

    // 6. Test Catat Waktu Ini (Otomatis)
    final catatWaktuFinder = find.text('Catat waktu ini');
    await tester.ensureVisible(catatWaktuFinder);
    await tester.pumpAndSettle();
    await tester.tap(catatWaktuFinder);
    await tester.pumpAndSettle();

    // Setelah dicatat, Card 2 menampilkan visual data hari ini tanpa overflow
    expect(find.byKey(const ValueKey('daily_bars')), findsOneWidget);

    // 7. Test Navigasi ke Halaman Riwayat/Statistik Lengkap
    final historyCardFinder = find.text('Waktu tidur selama 7 hari terakhir');
    await tester.ensureVisible(historyCardFinder);
    await tester.pumpAndSettle();
    await tester.tap(historyCardFinder);
    await tester.pumpAndSettle();

    // Di halaman SleepHistoryDetailScreen, seluruh opsi filter tersedia
    expect(find.text('Jam'), findsOneWidget);
    expect(find.text('Hari'), findsOneWidget);
    expect(find.text('Minggu'), findsOneWidget);
    expect(find.text('Bulan'), findsOneWidget);

    // Kembali ke layar utama
    final backBtn = find.byTooltip('Back').evaluate().isNotEmpty
        ? find.byTooltip('Back')
        : find.byType(BackButton);
    if (backBtn.evaluate().isNotEmpty) {
      await tester.tap(backBtn.first);
      await tester.pumpAndSettle();
    } else {
      Navigator.of(tester.element(find.byType(SleepHistoryDetailScreen))).pop();
      await tester.pumpAndSettle();
    }

    // 8. Test Efek Sticky Header saat Di-scroll
    final scrollFinder = find.byType(CustomScrollView);
    await tester.drag(scrollFinder, const Offset(0, -600));
    await tester.pumpAndSettle();

    // Judul "Waktu Tidur Malam" tetap menetap (stick) di atas header
    expect(find.text('Waktu Tidur Malam'), findsWidgets);

    // Selesaikan durasi SnackBar agar tidak menutupi tombol bawah
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // 9. Test Klik Tombol Masukkan Data -> Buka Form Input Manual
    final masukkanDataBtn = find.text('Masukkan data');
    await tester.ensureVisible(masukkanDataBtn);
    await tester.pumpAndSettle();
    await tester.tap(masukkanDataBtn);
    await tester.pumpAndSettle();

    expect(find.byType(SleepRecordFormScreen), findsOneWidget);
  });
}
