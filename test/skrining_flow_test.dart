import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obesight/models/user_model.dart';
import 'package:obesight/screens/skrining/skrining_landing_screen.dart';
import 'package:obesight/screens/skrining/skrining_models.dart';
import 'package:obesight/screens/skrining/skrining_result_screen.dart';
import 'package:obesight/screens/skrining/skrining_wizard_screen.dart';
import 'package:obesight/services/auth_service.dart';
import 'package:obesight/theme/app_theme.dart';

void main() {
  const dummyUser = UserModel(
    id: 'test_usr_skrining',
    name: 'Zahra Fitriana',
    email: 'zahraafitriana@gmail.com',
    username: 'zahraafitriana',
    role: UserRole.user,
  );

  setUp(() {
    AuthService().updateUserBmi(
      userId: dummyUser.id,
      bmi: 26.8,
      category: 'Overweight Level I',
      risk: 'Risiko Meningkat',
      weight: 72.0,
      height: 165.0,
      gender: 'Perempuan',
      age: 23,
    );
  });

  testWidgets('SkriningLandingScreen renders landing page as FIRST screen in flow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const SkriningLandingScreen(user: dummyUser),
      ),
    );
    await tester.pumpAndSettle();

    // 1. App Title & Subtitle
    expect(find.text('ObeSight'), findsOneWidget);
    expect(find.text('Kenali Risiko, Jaga Masa Depanmu'), findsOneWidget);

    // 2. Character Illustration & Headings
    expect(find.text('Kenali dirimu,'), findsOneWidget);
    expect(find.text('Kendalikan'), findsOneWidget);
    expect(find.text('risiko obesitas'), findsOneWidget);

    // 3. Short description
    expect(
      find.text('Skrining ini membantu kamu mengetahui risiko obesitas berdasarkan pola hidup dan kebiasaan sehari-hari.'),
      findsOneWidget,
    );

    // 4. "Mulai Skrining ->" button
    expect(find.text('Mulai Skrining'), findsOneWidget);
  });

  testWidgets('SkriningWizardScreen renders 5-step stepper and validates button states', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const SkriningWizardScreen(user: dummyUser),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Header & Stepper
    expect(find.text('Skrining Obesitas'), findsOneWidget);
    expect(find.text('Langkah 1 dari 5'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);

    // 2. Step 1 (Data Diri) questions
    expect(find.text('Data Diri'), findsOneWidget);
    expect(find.text('Jenis Kelamin'), findsOneWidget);
    expect(find.text('Usia'), findsOneWidget);
    expect(find.text('Tinggi Badan'), findsOneWidget);
    expect(find.text('Berat Badan'), findsOneWidget);

    // Button "Berikutnya" should be enabled since data is pre-filled with valid values
    final nextBtn = find.widgetWithText(ElevatedButton, 'Berikutnya');
    expect(nextBtn, findsOneWidget);
    final elevatedButton = tester.widget<ElevatedButton>(nextBtn);
    expect(elevatedButton.onPressed, isNotNull);
  });

  testWidgets('SkriningResultScreen renders all reference components accurately', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final testData = SkriningData(
      gender: 'Perempuan',
      age: 23,
      height: 165,
      weight: 72,
      physicalActivity: 'Kadang-kadang',
      highCalorieFood: 'Ya',
      vegetableIntake: 'Jarang',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: SkriningResultScreen(data: testData, user: dummyUser),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Header & Profile Card
    expect(find.text('Hasil Skrining'), findsOneWidget);
    expect(find.text('Nama'), findsOneWidget);
    expect(find.text('Zahra Fitriana'), findsOneWidget);
    expect(find.text('Tanggal'), findsOneWidget);

    // 2. Status / Category Section
    expect(find.text('Overweight\nLevel I'), findsOneWidget);
    expect(find.text('Berat badan sedikit diatas rentang ideal'), findsOneWidget);

    // 3. Metric Stats Card (Tinggi Badan, Berat Badan, BMI)
    expect(find.text('Tinggi Badan'), findsOneWidget);
    expect(find.text('165 cm'), findsOneWidget);
    expect(find.text('Berat Badan'), findsOneWidget);
    expect(find.text('72 Kg'), findsOneWidget);
    expect(find.text('BMI'), findsOneWidget);

    // 4. Hasil Analisis Risiko Warning Card
    expect(find.text('Hasil Analisis Risiko'), findsOneWidget);
    expect(find.text('Risiko Meningkat'), findsOneWidget);
    expect(
      find.text('Anda memiliki risiko sedang terhadap obesitas. Beberapa kebiasaan Anda sudah cukup baik, namun masih ada yang perlu ditingkatkan agar risiko obesitas tidak bertambah.'),
      findsOneWidget,
    );

    // 5. Detail Points: Risiko yang dapat terjadi & Faktor yang perlu diperhatikan
    expect(find.text('Risiko yang dapat terjadi:'), findsOneWidget);
    expect(find.text('Lemak tubuh meningkat'), findsOneWidget);
    expect(find.text('Risiko tekanan darah tinggi'), findsOneWidget);
    expect(find.text('Faktor yang perlu diperhatikan'), findsOneWidget);
    expect(find.text('Aktifitas fisik rendah'), findsOneWidget);
    expect(find.text('Konsumsi makanan tinggi kalori yang sering'), findsOneWidget);
    expect(find.text('Konsumsi sayur yang kurang'), findsOneWidget);

    // 6. Action button
    expect(find.text('Kembali ke Beranda'), findsOneWidget);
  });
}
