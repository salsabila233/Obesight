import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obesight/models/user_model.dart';
import 'package:obesight/screens/home/bmi_calculation_screen.dart';
import 'package:obesight/screens/home/bmi_result_screen.dart';
import 'package:obesight/services/auth_service.dart';
import 'package:obesight/theme/app_theme.dart';

void main() {
  const dummyUser = UserModel(
    id: 'test_usr_001',
    name: 'Zahra Fitriana',
    email: 'zahraafitriana@gmail.com',
    username: 'zahraafitriana',
    role: UserRole.user,
  );

  setUp(() {
    AuthService().updateUserBmi(
      userId: dummyUser.id,
      bmi: 22.8,
      category: 'Normal',
      risk: 'Rendah',
      weight: 58.0,
      height: 165.0,
      gender: 'Perempuan',
      age: 22,
    );
  });

  testWidgets('BmiCalculationScreen renders all visual sections and elements correctly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const BmiCalculationScreen(user: dummyUser),
      ),
    );
    await tester.pumpAndSettle();

    // A. Header
    expect(find.text('Perhitungan IMT'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

    // B. Area Informasi Banner
    expect(find.textContaining('Hitung Indeks Massa'), findsOneWidget);

    // D. Pilihan Jenis Kelamin
    expect(find.text('Laki-laki'), findsOneWidget);
    expect(find.text('Perempuan'), findsOneWidget);

    // C. Input Cards
    expect(find.text('Berat Badan'), findsOneWidget);
    expect(find.text('Tinggi Badan'), findsOneWidget);
    expect(find.text('Usia'), findsOneWidget);
    expect(find.text('kg'), findsOneWidget);
    expect(find.text('cm'), findsOneWidget);
    expect(find.text('Tahun'), findsOneWidget);

    // E. Card Informasi IMT
    expect(find.text('Catatan Penting'), findsOneWidget);

    // F. Button
    expect(find.text('Simpan Perubahan'), findsOneWidget);
  });

  testWidgets('Gender selection toggles state correctly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const BmiCalculationScreen(user: dummyUser),
      ),
    );
    await tester.pumpAndSettle();

    // Initially "Perempuan" is selected
    await tester.tap(find.text('Laki-laki'));
    await tester.pumpAndSettle();

    // Both chips remain visible and interactive
    expect(find.text('Laki-laki'), findsOneWidget);
    expect(find.text('Perempuan'), findsOneWidget);
  });

  testWidgets('Pressing Simpan Perubahan directly saves and navigates to BmiResultScreen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const BmiCalculationScreen(user: dummyUser),
      ),
    );
    await tester.pumpAndSettle();

    // Enter Weight = 60 kg, Height = 160 cm -> IMT = 60 / (1.6 * 1.6) = 23.4375 -> 23,4 (Kelebihan Berat Badan)
    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(0), '60');
    await tester.enterText(textFields.at(1), '160');
    await tester.pumpAndSettle();

    // Tap "Simpan Perubahan"
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();

    // Directly on BmiResultScreen without confirmation dialog
    expect(find.byType(BmiResultScreen), findsOneWidget);
    expect(find.text('Hasil Perhitungan IMT'), findsOneWidget);

    // Should now be on BmiResultScreen
    expect(find.byType(BmiResultScreen), findsOneWidget);
    expect(find.text('Hasil Perhitungan IMT'), findsOneWidget);

    // Check large score: 23,4 (Indonesian comma formatting)
    expect(find.text('23,4'), findsOneWidget);

    // Check status badge
    expect(find.text('Kelebihan Berat Badan'), findsWidgets);

    // Check data rows
    expect(find.text('60.0 kg'), findsOneWidget);
    expect(find.text('160 cm'), findsOneWidget);

    // Check action buttons
    expect(find.text('Kembali ke Beranda'), findsOneWidget);
    expect(find.text('Hitung Ulang'), findsOneWidget);

    // Verify AuthService was updated
    final updatedBmi = AuthService().getUserBmi(dummyUser.id);
    expect(updatedBmi['bmi'], 23.4);
    expect(updatedBmi['category'], 'Kelebihan Berat Badan');
  });

  testWidgets('BmiResultScreen with Normal BMI renders normal category and recommendations', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const BmiResultScreen(
          bmi: 21.3,
          weight: 58,
          height: 165,
          gender: 'Perempuan',
          category: 'Normal',
          risk: 'Rendah',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hasil Perhitungan IMT'), findsOneWidget);
    expect(find.text('21,3'), findsOneWidget);
    expect(find.text('Normal'), findsWidgets);
    expect(find.text('Rekomendasi Pola Hidup'), findsOneWidget);
    expect(find.text('Kembali ke Beranda'), findsOneWidget);
    expect(find.text('Hitung Ulang'), findsOneWidget);
  });
}
