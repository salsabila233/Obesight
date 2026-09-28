import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obesight/models/user_model.dart';
import 'package:obesight/screens/progress/progress_screen.dart';
import 'package:obesight/screens/progress/rest_recommendation_screen.dart';
import 'package:obesight/screens/progress/day_rest_detail_screen.dart';
import 'package:obesight/screens/progress/night_sleep_detail_screen.dart';
import 'package:obesight/screens/progress/rest_reminder_setting_screen.dart';
import 'package:obesight/services/rest_reminder_service.dart';
import 'package:obesight/theme/app_theme.dart';

void main() {
  final testUser = UserModel(
    id: 'user_1',
    name: 'Zahra',
    email: 'zahra@example.com',
    username: 'zahra',
    role: UserRole.user,
  );

  setUp(() {
    RestReminderService.instance.reset();
  });

  testWidgets('Fitur Atur Pengingat: Istirahat Siang (Sun icon, Batal, Simpan & State update)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // 1. Render Progress Screen -> Navigate to Rekomendasi Waktu Istirahat -> Istirahat Siang
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: ProgressScreen(user: testUser),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Waktu Istirahat'));
    await tester.pumpAndSettle();
    expect(find.byType(RestRecommendationScreen), findsOneWidget);

    await tester.tap(find.text('Istirahat Siang'));
    await tester.pumpAndSettle();
    expect(find.byType(DayRestDetailScreen), findsOneWidget);

    // 2. KONDISI 1: Sebelum data dimasukkan (Placeholder & Empty State Gambar 1)
    expect(find.text('-- j -- m'), findsOneWidget);
    expect(find.text('Belum ada data istirahat'), findsOneWidget);
    expect(find.text('Waktu istirahat'), findsOneWidget);
    expect(find.text('Waktu istirahat selama 7 hari terakhir'), findsOneWidget);

    // Pastikan menggunakan Icon Matahari, bukan bulan
    expect(find.byIcon(Icons.wb_sunny_rounded), findsWidgets);

    // 3. Klik "Atur Pengingat" (via tombol atau status card) -> Masuk ke Halaman Input (Gambar 2)
    final aturBtn = find.text('Atur pengingat');
    await tester.ensureVisible(aturBtn);
    await tester.tap(aturBtn);
    await tester.pumpAndSettle();

    expect(find.byType(RestReminderSettingScreen), findsOneWidget);
    expect(find.text('Masukkan Data Istirahat'), findsOneWidget);
    expect(find.text('Waktu Istirahat'), findsOneWidget);
    expect(find.text('Jam istirahat'), findsOneWidget);
    expect(find.text('Jam selesai'), findsOneWidget);
    expect(find.text('Durasi istirahat'), findsOneWidget);
    expect(find.text('13.00'), findsWidgets);
    expect(find.text('14.00'), findsWidgets);
    expect(find.text('1 jam'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);
    expect(find.text('Simpan'), findsOneWidget);

    // 4. Test Tombol "Batal": Tidak menyimpan perubahan & kembali ke DayRestDetailScreen
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(find.byType(DayRestDetailScreen), findsOneWidget);
    expect(find.byType(RestReminderSettingScreen), findsNothing);
    // Masih dalam kondisi sebelum data dimasukkan
    expect(find.text('-- j -- m'), findsOneWidget);
    expect(find.text('Belum ada data istirahat'), findsOneWidget);

    // 5. Klik status card atau "Atur Pengingat" lagi -> Simpan data
    await tester.ensureVisible(aturBtn);
    await tester.tap(aturBtn);
    await tester.pumpAndSettle();
    expect(find.byType(RestReminderSettingScreen), findsOneWidget);

    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    // 6. KONDISI 3: Setelah data disimpan (Gambar 3)
    expect(find.byType(DayRestDetailScreen), findsOneWidget);
    expect(find.byType(RestReminderSettingScreen), findsNothing);

    // Data tersimpan ditampilkan: 1 j 0 m & 13.00 - 14.00
    expect(find.text('1 j 0 m'), findsOneWidget);
    expect(find.text('13.00 - 14.00'), findsWidgets);
    expect(find.text('Belum ada data istirahat'), findsNothing);
    expect(find.text('Waktu istirahat selama 7 hari terakhir'), findsOneWidget);
  });

  testWidgets('Fitur Atur Pengingat: Waktu Tidur Malam (Moon icon, Batal, Simpan & State update)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // 1. Render Progress Screen -> Navigate to Rekomendasi Waktu Istirahat -> Waktu Tidur Malam
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: ProgressScreen(user: testUser),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Waktu Istirahat'));
    await tester.pumpAndSettle();
    expect(find.byType(RestRecommendationScreen), findsOneWidget);

    await tester.tap(find.text('Waktu Tidur Malam'));
    await tester.pumpAndSettle();
    expect(find.byType(NightSleepDetailScreen), findsOneWidget);

    // 2. KONDISI 1: Sebelum data dimasukkan (Placeholder & Empty State Gambar 1)
    expect(find.text('-- j -- m'), findsOneWidget);
    expect(find.text('Belum ada data tidur'), findsOneWidget);
    expect(find.text('Waktu tidur'), findsOneWidget);
    expect(find.text('Waktu tidur selama 7 hari terakhir'), findsOneWidget);

    // Pastikan menggunakan Icon Bulan
    expect(find.byIcon(Icons.nightlight_round), findsWidgets);

    // 3. Klik "Atur Pengingat" -> Masuk ke Halaman Input (Gambar 2)
    final aturBtn = find.text('Atur pengingat');
    await tester.ensureVisible(aturBtn);
    await tester.tap(aturBtn);
    await tester.pumpAndSettle();

    expect(find.byType(RestReminderSettingScreen), findsOneWidget);
    expect(find.text('Masukkan Data Tidur'), findsOneWidget);
    expect(find.text('Waktu Tidur'), findsOneWidget);
    expect(find.text('Jam tidur'), findsOneWidget);
    expect(find.text('Jam bangun'), findsOneWidget);
    expect(find.text('Durasi tidur'), findsOneWidget);
    expect(find.text('22.00'), findsWidgets);
    expect(find.text('05.00'), findsWidgets);
    expect(find.text('7 jam'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);
    expect(find.text('Simpan'), findsOneWidget);

    // 4. Test Tombol "Batal": Kembali ke NightSleepDetailScreen tanpa perubahan
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(find.byType(NightSleepDetailScreen), findsOneWidget);
    expect(find.byType(RestReminderSettingScreen), findsNothing);
    expect(find.text('-- j -- m'), findsOneWidget);
    expect(find.text('Belum ada data tidur'), findsOneWidget);

    // 5. Klik "Atur Pengingat" lagi -> Simpan data
    await tester.ensureVisible(aturBtn);
    await tester.tap(aturBtn);
    await tester.pumpAndSettle();
    expect(find.byType(RestReminderSettingScreen), findsOneWidget);

    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    // 6. KONDISI 3: Setelah data disimpan (Gambar 3)
    expect(find.byType(NightSleepDetailScreen), findsOneWidget);
    expect(find.byType(RestReminderSettingScreen), findsNothing);

    // Data tersimpan ditampilkan: 7 j 0 m & 22.00 - 05.00
    expect(find.text('7 j 0 m'), findsOneWidget);
    expect(find.text('22.00 - 05.00'), findsOneWidget);
    expect(find.text('Belum ada data tidur'), findsNothing);
    expect(find.text('Waktu tidur selama 7 hari terakhir'), findsOneWidget);

    // 7. EDIT DATA: Klik "Atur pengingat" lagi, data terakhir harus dimuat
    await tester.ensureVisible(aturBtn);
    await tester.tap(aturBtn);
    await tester.pumpAndSettle();

    expect(find.byType(RestReminderSettingScreen), findsOneWidget);
    expect(find.text('22.00'), findsWidgets);
    expect(find.text('05.00'), findsWidgets);
    expect(find.text('7 jam'), findsOneWidget);

    // Kembali via panah ← kiri atas
    final backArrow = find.byIcon(Icons.arrow_back_ios_new_rounded);
    await tester.tap(backArrow);
    await tester.pumpAndSettle();

    expect(find.byType(NightSleepDetailScreen), findsOneWidget);
  });
}
