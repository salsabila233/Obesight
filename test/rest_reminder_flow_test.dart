import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obesight/screens/progress/day_rest_detail_screen.dart';
import 'package:obesight/screens/progress/rest_reminder_setting_screen.dart';
import 'package:obesight/services/rest_reminder_service.dart';
import 'package:obesight/theme/app_theme.dart';

void main() {
  setUp(() {
    RestReminderService.instance.reset();
  });

  testWidgets('Fitur Atur Pengingat: Istirahat Siang (Sun icon, Batal, Simpan & State update)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // 1. Render DayRestDetailScreen
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const DayRestDetailScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // 2. KONDISI 1: Sebelum data dimasukkan (Placeholder & Empty State Gambar 1)
    expect(find.text('-- j -- m'), findsOneWidget);
    expect(find.text('Belum ada data istirahat'), findsOneWidget);
    expect(find.text('Waktu istirahat'), findsOneWidget);
    expect(find.text('Waktu istirahat selama 7 hari terakhir'), findsOneWidget);

    // Pastikan menggunakan Icon Matahari, bukan bulan
    expect(find.byIcon(Icons.wb_sunny_rounded), findsWidgets);

    // 3. Klik "Atur Pengingat" -> Masuk ke Halaman Input (Gambar 2)
    final aturBtn = find.text('Atur pengingat');
    await tester.ensureVisible(aturBtn);
    await tester.tap(aturBtn);
    await tester.pumpAndSettle();

    expect(find.byType(RestReminderSettingScreen), findsOneWidget);
    expect(find.text('Masukkan Data Istirahat'), findsOneWidget);
    expect(find.text('Jam istirahat'), findsOneWidget);
    expect(find.text('Jam selesai'), findsOneWidget);
    expect(find.text('Simpan'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);

    // 4. Test Tombol "Batal" -> Kembali tanpa menyimpan
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(find.byType(DayRestDetailScreen), findsOneWidget);
    expect(find.text('-- j -- m'), findsOneWidget); // Tetap kosong

    // 5. Masuk lagi & Simpan
    await tester.ensureVisible(find.text('Atur pengingat'));
    await tester.tap(find.text('Atur pengingat'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    // 6. KONDISI 3: Data tersimpan (Gambar 3)
    expect(find.byType(DayRestDetailScreen), findsOneWidget);
    expect(find.text('1 j 0 m'), findsOneWidget);
    expect(find.text('13.00 - 14.00'), findsWidgets);
    expect(find.text('Waktu istirahat selama 7 hari terakhir'), findsOneWidget);
  });

  testWidgets('Fitur Atur Pengingat: Waktu Tidur Malam (Moon icon, Batal, Simpan & State update)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // 1. Render RestReminderSettingScreen untuk night
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const RestReminderSettingScreen(type: RestType.night),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RestReminderSettingScreen), findsOneWidget);
    expect(find.text('Masukkan Data Tidur'), findsOneWidget);
    expect(find.text('Jam tidur'), findsOneWidget);
    expect(find.text('Jam bangun'), findsOneWidget);
    expect(find.text('Simpan'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);

    // Icon Bulan untuk malam
    expect(find.byIcon(Icons.bed_rounded), findsWidgets);

    // Test Simpan
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    // Service ter-update dengan data malam
    final reminder = RestReminderService.instance.getReminder(RestType.night);
    expect(reminder, isNotNull);
    expect(reminder!.isSet, isTrue);
  });
}
