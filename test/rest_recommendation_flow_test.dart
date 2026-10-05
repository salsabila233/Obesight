import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obesight/models/user_model.dart';
import 'package:obesight/screens/progress/progress_screen.dart';
import 'package:obesight/screens/progress/night_sleep_detail_screen.dart';
import 'package:obesight/theme/app_theme.dart';

void main() {
  final testUser = UserModel(
    id: 'user_1',
    name: 'Zahra',
    email: 'zahra@example.com',
    username: 'zahra',
    role: UserRole.user,
  );

  testWidgets('Navigation Flow: Progress -> Waktu Tidur -> NightSleepDetailScreen -> Back to Progress', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // 1. Render ProgressScreen
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: ProgressScreen(user: testUser),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Progress Screen elements
    expect(find.text('Progress'), findsOneWidget);

    // 2. Click "Waktu Tidur" -> Langsung navigasi ke Halaman Waktu Tidur Malam
    final waktuTidurFinder = find.text('Waktu Tidur');
    await tester.ensureVisible(waktuTidurFinder);
    await tester.pumpAndSettle();
    expect(waktuTidurFinder, findsOneWidget);
    await tester.tap(waktuTidurFinder);
    await tester.pumpAndSettle();

    // 3. Verifikasi halaman Waktu Tidur Malam
    expect(find.byType(NightSleepDetailScreen), findsOneWidget);
    expect(find.text('Waktu Tidur Malam'), findsWidgets);
    expect(find.text('Tidur yang cukup dan teratur membantu metabolisme tubuh tetap seimbang.'), findsOneWidget);
    expect(find.text('Masukkan data'), findsOneWidget);

    // Verifikasi tombol "Atur pengingat" sudah dihapus
    expect(find.text('Atur pengingat'), findsNothing);

    // Verifikasi opsi filter grafik ada
    expect(find.text('Jam'), findsOneWidget);
    expect(find.text('Hari'), findsOneWidget);
    expect(find.text('Minggu'), findsOneWidget);
    expect(find.text('Bulan'), findsOneWidget);

    // 4. Test tombol Back -> Harus kembali ke ProgressScreen
    final backBtn = find.byIcon(Icons.arrow_back_ios_new_rounded).first;
    await tester.tap(backBtn);
    await tester.pumpAndSettle();

    expect(find.byType(ProgressScreen), findsOneWidget);
    expect(find.byType(NightSleepDetailScreen), findsNothing);
  });
}
