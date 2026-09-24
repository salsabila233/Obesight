import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obesight/models/user_model.dart';
import 'package:obesight/screens/progress/progress_screen.dart';
import 'package:obesight/screens/progress/rest_recommendation_screen.dart';
import 'package:obesight/screens/progress/day_rest_detail_screen.dart';
import 'package:obesight/screens/progress/night_sleep_detail_screen.dart';
import 'package:obesight/screens/progress/activity_rest_detail_screen.dart';
import 'package:obesight/theme/app_theme.dart';

void main() {
  final testUser = UserModel(
    id: 'user_1',
    name: 'Zahra',
    email: 'zahra@example.com',
    username: 'zahra',
    role: UserRole.user,
  );

  testWidgets('Navigation Flow: Progress -> Waktu Istirahat -> Rekomendasi Waktu Istirahat -> Details & Back', (WidgetTester tester) async {
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
    expect(find.text('Waktu Istirahat'), findsOneWidget);

    // 2. Click "Waktu Istirahat" -> Navigate to Rekomendasi Waktu Istirahat
    await tester.tap(find.text('Waktu Istirahat'));
    await tester.pumpAndSettle();

    // Verify Rekomendasi Waktu Istirahat Screen elements
    expect(find.byType(RestRecommendationScreen), findsOneWidget);
    expect(find.text('Rekomendasi Waktu Istirahat'), findsOneWidget);
    expect(find.text('Istirahat Siang'), findsOneWidget);
    expect(find.text('Waktu Tidur Malam'), findsOneWidget);
    expect(find.text('Istirahat Setelah Aktivitas'), findsOneWidget);
    expect(find.textContaining('Rekomendasi ini dibuat berdasarkan pola hidup sehat'), findsOneWidget);

    // 3. Test Istirahat Siang Detail & Back
    await tester.tap(find.text('Istirahat Siang'));
    await tester.pumpAndSettle();

    expect(find.byType(DayRestDetailScreen), findsOneWidget);
    expect(find.text('Waktu Istirahat yang Disarankan'), findsOneWidget);
    expect(find.text('13.00 - 14.00'), findsOneWidget);
    expect(find.text('20 - 30 menit'), findsOneWidget);
    expect(find.text('Atur pengingat'), findsOneWidget);

    // Press Back Button (←) -> Should return to Rekomendasi Waktu Istirahat, NOT Progress!
    final backBtn1 = find.byIcon(Icons.arrow_back_ios_new_rounded);
    await tester.tap(backBtn1);
    await tester.pumpAndSettle();

    expect(find.byType(RestRecommendationScreen), findsOneWidget);
    expect(find.byType(DayRestDetailScreen), findsNothing);

    // 4. Test Waktu Tidur Malam Detail & Back
    await tester.tap(find.text('Waktu Tidur Malam'));
    await tester.pumpAndSettle();

    expect(find.byType(NightSleepDetailScreen), findsOneWidget);
    expect(find.text('Waktu Tidur Malam'), findsOneWidget);
    expect(find.text('22.00 - 23.00'), findsOneWidget);
    expect(find.text('05.00 - 06.00'), findsOneWidget);
    expect(find.text('7 - 8 jam'), findsOneWidget);
    expect(find.text('Atur pengingat'), findsOneWidget);

    // Press Back Button (←) -> Should return to Rekomendasi Waktu Istirahat
    final backBtn2 = find.byIcon(Icons.arrow_back_ios_new_rounded);
    await tester.tap(backBtn2);
    await tester.pumpAndSettle();

    expect(find.byType(RestRecommendationScreen), findsOneWidget);
    expect(find.byType(NightSleepDetailScreen), findsNothing);

    // 5. Test Istirahat Setelah Aktivitas Detail & Back
    await tester.tap(find.text('Istirahat Setelah Aktivitas'));
    await tester.pumpAndSettle();

    expect(find.byType(ActivityRestDetailScreen), findsOneWidget);
    expect(find.text('Istirahat Setelah Aktivitas'), findsOneWidget);
    expect(find.text('15 - 30 menit'), findsOneWidget);
    expect(find.text('Mulai Istirahat'), findsOneWidget);

    // Press Back Button (←) -> Should return to Rekomendasi Waktu Istirahat
    final backBtn3 = find.byIcon(Icons.arrow_back_ios_new_rounded);
    await tester.tap(backBtn3);
    await tester.pumpAndSettle();

    expect(find.byType(RestRecommendationScreen), findsOneWidget);
    expect(find.byType(ActivityRestDetailScreen), findsNothing);

    // 6. Test Back Button from Rekomendasi Waktu Istirahat -> Should return to ProgressScreen
    final backToProgressBtn = find.byIcon(Icons.arrow_back_ios_new_rounded);
    await tester.tap(backToProgressBtn);
    await tester.pumpAndSettle();

    expect(find.byType(ProgressScreen), findsOneWidget);
    expect(find.byType(RestRecommendationScreen), findsNothing);
  });
}
