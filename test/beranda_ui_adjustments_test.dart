import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obesight/models/user_model.dart';
import 'package:obesight/screens/home/user_home_screen.dart';
import 'package:obesight/screens/home/imt_form_screen.dart';
import 'package:obesight/screens/progress/progress_screen.dart';
import 'package:obesight/screens/progress/screening_history_screen.dart';
import 'package:obesight/theme/app_theme.dart';

void main() {
  const testUser = UserModel(
    id: 'user_beranda_test',
    name: 'Aisyah Putri',
    email: 'aisyah@gmail.com',
    username: 'aisyah',
    role: UserRole.user,
    dob: '2000-01-01',
    gender: 'Perempuan',
    phone: '081234567890',
    isBiodataComplete: true,
    bmiScore: 22.8,
    bmiCategory: 'Normal',
    obesityRisk: 'Rendah',
  );

  Widget createTestWidget() {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: const UserHomeScreen(user: testUser),
    );
  }

  void setPhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('1. Banner Skrining Risiko Obesitas is visual only and does not navigate on tap', (tester) async {
    setPhoneViewport(tester);
    await tester.pumpWidget(createTestWidget());
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Verify banner text is present
    expect(find.text('Skrining Risiko\nObesitas'), findsOneWidget);
    expect(find.text('Kenali tingkat risiko obesitas berdasarkan pola hidupmu.'), findsOneWidget);

    // Tap on the banner
    await tester.tap(find.text('Skrining Risiko\nObesitas'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Verify still on UserHomeScreen, not navigated to another screen
    expect(find.byType(UserHomeScreen), findsOneWidget);
  });

  testWidgets('2. Card Aktivitas Fisik is removed from Beranda', (tester) async {
    setPhoneViewport(tester);
    await tester.pumpWidget(createTestWidget());
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Aktivitas Fisik card texts must NOT be found in Beranda
    expect(find.text('Aktivitas Fisik'), findsNothing);
    expect(find.text('5 Latihan'), findsNothing);
    expect(find.text('Jogging, Sepeda, Gym, Yoga & HIIT.'), findsNothing);
    expect(find.text('Artikel Kesehatan'), findsOneWidget);
  });

  testWidgets('3. Status Kesehatan card is informational only and does not navigate on tap', (tester) async {
    setPhoneViewport(tester);
    await tester.pumpWidget(createTestWidget());
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Check health status information is displayed
    expect(find.text('Status Kesehatan'), findsOneWidget);
    expect(find.text('IMT'), findsOneWidget);
    expect(find.text('Risiko Obesitas'), findsOneWidget);

    // Tap on Status Kesehatan card
    await tester.tap(find.text('Status Kesehatan'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Verify no navigation happened (ImtFormScreen is NOT pushed)
    expect(find.byType(ImtFormScreen), findsNothing);
    expect(find.byType(UserHomeScreen), findsOneWidget);
  });

  testWidgets('4. Feature menu icons are updated and all 4 buttons navigate correctly', (tester) async {
    setPhoneViewport(tester);
    await tester.pumpWidget(createTestWidget());
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Verify the updated modern icons exist
    expect(find.byIcon(Icons.manage_search_rounded), findsOneWidget);
    expect(find.byIcon(Icons.calculate_rounded), findsOneWidget);
    expect(find.byIcon(Icons.trending_up_rounded), findsOneWidget);
    expect(find.byIcon(Icons.medical_information_rounded), findsOneWidget);

    // Test Kalkulator IMT menu button works
    await tester.tap(find.text('Kalkulator\nIMT'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.byType(ImtFormScreen), findsOneWidget);

    // Go back from ImtFormScreen (uses chevron_left_rounded)
    final backBtnImt = find.byIcon(Icons.chevron_left_rounded).first;
    await tester.tap(backBtnImt);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.byType(UserHomeScreen), findsOneWidget);

    // Test Progress menu button works
    await tester.tap(find.text('Progress'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.byType(ProgressScreen), findsOneWidget);

    // Go back from ProgressScreen (uses arrow_back_ios_new_rounded)
    final backBtnProgress = find.byIcon(Icons.arrow_back_ios_new_rounded).first;
    await tester.tap(backBtnProgress);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.byType(UserHomeScreen), findsOneWidget);

    // Test Riwayat Skrining menu button works
    await tester.tap(find.text('Riwayat\nSkrining'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.byType(ScreeningHistoryScreen), findsOneWidget);

    // Go back from ScreeningHistoryScreen (uses arrow_back_ios_new_rounded)
    final backBtnHistory = find.byIcon(Icons.arrow_back_ios_new_rounded).first;
    await tester.tap(backBtnHistory);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.byType(UserHomeScreen), findsOneWidget);
  });
}
