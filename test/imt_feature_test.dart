import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obesight/models/user_model.dart';
import 'package:obesight/screens/home/imt_form_screen.dart';
import 'package:obesight/screens/home/imt_result_screen.dart';
import 'package:obesight/services/auth_service.dart';
import 'package:obesight/theme/app_theme.dart';

void main() {
  const dummyUser = UserModel(
    id: 'test_user_imt_001',
    name: 'Zahra Fitriana',
    email: 'zahra@example.com',
    username: 'zahra',
    role: UserRole.user,
  );

  setUp(() {
    AuthService().updateUserBmi(
      userId: dummyUser.id,
      bmi: 21.3,
      category: 'Normal',
      risk: 'Rendah',
      weight: 58.0,
      height: 165.0,
      gender: 'Perempuan',
      age: 22,
    );
  });

  testWidgets('ImtFormScreen renders all revised Figma components correctly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const ImtFormScreen(user: dummyUser),
      ),
    );
    await tester.pumpAndSettle();

    // 1. AppBar
    expect(find.text('Hitung IMT'), findsWidgets);
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

    // 2. Hero Card
    expect(find.text('Hitung Indeks Massa Tubuhmu'), findsOneWidget);
    expect(find.textContaining('Ketahui status berat badan dan risiko kesehatan'), findsOneWidget);

    // 3. Section Data Fisik Pengguna
    expect(find.text('Data Fisik Pengguna'), findsOneWidget);

    // 4. Physical Cards & Labels
    expect(find.text('Usia'), findsOneWidget);
    expect(find.text('Tahun'), findsOneWidget);
    expect(find.textContaining('Laki-laki'), findsOneWidget);
    expect(find.textContaining('Perempuan'), findsOneWidget);
    expect(find.text('Berat Badan'), findsOneWidget);
    expect(find.text('Tinggi Badan'), findsOneWidget);

    // 5. Catatan Penting
    expect(find.text('Catatan Penting'), findsOneWidget);

    // 6. Action Button
    expect(find.widgetWithText(ElevatedButton, 'Hitung IMT'), findsOneWidget);
  });

  testWidgets('ImtFormScreen langsung navigasi ke ImtResultScreen 1 kali tekan tombol Hitung IMT tanpa modal dialog', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const ImtFormScreen(user: dummyUser),
      ),
    );
    await tester.pumpAndSettle();

    // Input: Weight 60, Height 160 -> IMT = 60 / (1.6*1.6) = 23.4375 -> 23,4 (Normal)
    final textFields = find.byType(TextField);
    // Usia is at index 0, Tinggi Badan is at index 1, Berat Badan is at index 2
    await tester.enterText(textFields.at(1), '160');
    await tester.enterText(textFields.at(2), '60');
    await tester.pumpAndSettle();

    // Scroll to and tap action button
    final hitungBtn = find.widgetWithText(ElevatedButton, 'Hitung IMT');
    await tester.ensureVisible(hitungBtn);
    await tester.tap(hitungBtn);
    await tester.pumpAndSettle();

    // Langsung berada pada ImtResultScreen tanpa dialog konfirmasi
    expect(find.byType(ImtResultScreen), findsOneWidget);
    expect(find.text('Hasil Perhitungan IMT'), findsOneWidget);
    expect(find.text('Indeks Masa Tubuh Anda'), findsOneWidget);
    expect(find.text('23,4'), findsOneWidget);
    expect(find.text('Detail Data Anda'), findsOneWidget);
    expect(find.text('Rekomendasi Gaya Hidup & Aktivitas'), findsOneWidget);
    expect(find.text('Hitung Ulang'), findsOneWidget);

    // Verify AuthService was updated
    final updatedBmi = AuthService().getUserBmi(dummyUser.id);
    expect(updatedBmi['bmi'], 23.4);
    expect(updatedBmi['category'], 'Normal');
  });

  testWidgets('ImtResultScreen renders details and allows Hitung Ulang back to form', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: ImtResultScreen(
          bmi: 21.3,
          weight: 58,
          height: 165,
          gender: 'Perempuan',
          age: 22,
          category: 'Normal',
          risk: 'Rendah',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hasil Perhitungan IMT'), findsOneWidget);
    expect(find.text('21,3'), findsOneWidget);
    expect(find.text('Normal'), findsWidgets);
    expect(find.text('58 KG'), findsOneWidget);
    expect(find.text('165 CM'), findsOneWidget);
    expect(find.text('Hitung Ulang'), findsOneWidget);
  });
}
