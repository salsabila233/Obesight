import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obesight/screens/progress/night_sleep_detail_screen.dart';
import 'package:obesight/screens/progress/sleep_record_form_screen.dart';
import 'package:obesight/services/sleep_tracking_service.dart';
import 'package:obesight/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Reset service state before each test
    SleepTrackingService.instance.initialize();
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

    // 3. Verifikasi Card 2: 7 Hari Terakhir State Awal (Belum ada data tidur hari ini)
    expect(find.text('Waktu tidur selama 7 hari terakhir'), findsOneWidget);
    expect(find.text('Belum ada data tidur hari ini'), findsOneWidget);

    // 4. Verifikasi Tombol Bawah: Masukkan data
    expect(find.text('Masukkan data'), findsOneWidget);

    // 5. Verifikasi Tombol "Atur Pengingat" telah dihapus
    expect(find.text('Atur pengingat'), findsNothing);

    // 6. Test Opsi Tampilan Grafik: Jam, Hari, Minggu, Bulan
    final jamFinder = find.text('Jam');
    await tester.ensureVisible(jamFinder);
    await tester.pumpAndSettle();

    // Test Tab Jam
    await tester.tap(jamFinder);
    await tester.pumpAndSettle();
    expect(find.text('Distribusi tidur per jam hari ini'), findsOneWidget);
    expect(find.byKey(const ValueKey('hourly_chart')), findsOneWidget);

    // Test Tab Minggu
    final mingguFinder = find.text('Minggu');
    await tester.tap(mingguFinder);
    await tester.pumpAndSettle();
    expect(find.text('Waktu tidur selama 4 minggu terakhir'), findsOneWidget);
    expect(find.byKey(const ValueKey('weekly_chart')), findsOneWidget);

    // Test Tab Bulan
    final bulanFinder = find.text('Bulan');
    await tester.tap(bulanFinder);
    await tester.pumpAndSettle();
    expect(find.text('Waktu tidur selama 6 bulan terakhir'), findsOneWidget);
    expect(find.byKey(const ValueKey('monthly_chart')), findsOneWidget);

    // Kembalikan ke Tab Hari
    final hariFinder = find.text('Hari');
    await tester.tap(hariFinder);
    await tester.pumpAndSettle();

    // 7. Test Catat Waktu Ini (Otomatis)
    final catatWaktuFinder = find.text('Catat waktu ini');
    await tester.ensureVisible(catatWaktuFinder);
    await tester.pumpAndSettle();
    await tester.tap(catatWaktuFinder);
    await tester.pumpAndSettle();

    // Setelah dicatat, Card 2 menampilkan grafik batangan 7 hari tanpa overflow
    expect(find.byKey(const ValueKey('daily_bars')), findsOneWidget);

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
