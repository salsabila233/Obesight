import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obesight/models/user_model.dart';
import 'package:obesight/screens/home/imt_form_screen.dart';
import 'package:obesight/screens/home/imt_result_screen.dart';
import 'package:obesight/screens/progress/screening_history_screen.dart';
import 'package:obesight/theme/app_theme.dart';

void main() {
  const testUser = UserModel(
    id: 'test_user_ui_adj',
    name: 'Aisyah Putri',
    email: 'aisyah@gmail.com',
    username: 'aisyah',
    role: UserRole.user,
    gender: 'Perempuan',
    bmiScore: 33.1,
    bmiCategory: 'Obesitas',
    obesityRisk: 'Tinggi',
  );

  void setPhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('1. Halaman Riwayat Skrining - Bottom Navigation Removal', () {
    testWidgets('Riwayat Skrining does not render bottom navigation bar and green bottom banner', (tester) async {
      setPhoneViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ScreeningHistoryScreen(user: testUser),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Scaffold has NO bottomNavigationBar
      final scaffoldFinder = find.byType(Scaffold);
      expect(scaffoldFinder, findsOneWidget);
      final scaffoldWidget = tester.widget<Scaffold>(scaffoldFinder);
      expect(scaffoldWidget.bottomNavigationBar, isNull);

      // Verify bottom navigation icons are completely removed
      expect(find.byIcon(Icons.home_rounded), findsNothing);
      expect(find.byIcon(Icons.bar_chart_rounded), findsNothing);
      expect(find.byIcon(Icons.settings_rounded), findsNothing);

      // Verify all required content elements remain intact
      expect(find.text('Riwayat Skrining'), findsOneWidget);
      expect(find.text('Ringkasan'), findsOneWidget);
      expect(find.text('Total Skrining'), findsOneWidget);
      expect(find.text('Risiko Tinggi'), findsOneWidget);
      expect(find.text('Risiko Sedang'), findsOneWidget);
      expect(find.text('Risiko Rendah'), findsOneWidget);

      // Verify SingleChildScrollView padding is neat (bottom is 24, not 100)
      final scrollFinder = find.byType(SingleChildScrollView);
      expect(scrollFinder, findsOneWidget);
      final scrollWidget = tester.widget<SingleChildScrollView>(scrollFinder);
      expect(scrollWidget.padding, const EdgeInsets.fromLTRB(18, 22, 18, 24));
    });
  });

  group('2. Halaman Hitung IMT - Flat Banner Bottom & Rounded Top Content Panel', () {
    testWidgets('ImtFormScreen has flat banner bottom and rounded top content panel with Radius.circular(28)', (tester) async {
      setPhoneViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ImtFormScreen(user: testUser),
        ),
      );
      await tester.pumpAndSettle();

      // Verify AppBar has flat bottom (no RoundedRectangleBorder)
      final appBarFinder = find.byType(AppBar);
      expect(appBarFinder, findsOneWidget);
      final appBarWidget = tester.widget<AppBar>(appBarFinder);
      expect(appBarWidget.shape, isNull);

      // Verify Hero card container has flat bottom (no borderRadius)
      final heroFinder = find.ancestor(
        of: find.text('Hitung Indeks Massa Tubuhmu'),
        matching: find.byType(Container),
      ).first;
      final heroWidget = tester.widget<Container>(heroFinder);
      final heroDecoration = heroWidget.decoration as BoxDecoration?;
      expect(heroDecoration?.borderRadius, isNull);

      // Verify content panel container has rounded top corners with Radius.circular(28)
      final panelWidget = tester.widgetList<Container>(find.byType(Container)).firstWhere(
        (c) => c.decoration is BoxDecoration && (c.decoration as BoxDecoration).borderRadius != null,
      );
      final panelDecoration = panelWidget.decoration as BoxDecoration;
      expect(panelDecoration.borderRadius, isNotNull);
      final borderRadius = panelDecoration.borderRadius as BorderRadius;
      expect(borderRadius.topLeft, const Radius.circular(28));
      expect(borderRadius.topRight, const Radius.circular(28));
      expect(borderRadius.bottomLeft, Radius.zero);
      expect(borderRadius.bottomRight, Radius.zero);

      // Verify original elements are preserved
      expect(find.text('Hitung Indeks Masa Tubuh (IMT)'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
      expect(find.text('Hitung Indeks Massa Tubuhmu'), findsOneWidget);
      expect(find.textContaining('Ketahui status berat badan dan risiko kesehatan'), findsOneWidget);
      expect(find.text('Data Fisik Pengguna'), findsOneWidget);
      expect(find.text('Usia'), findsOneWidget);
      expect(find.text('Jenis Kelamin'), findsOneWidget);
      expect(find.text('Tinggi Badan'), findsOneWidget);
      expect(find.text('Berat Badan'), findsOneWidget);
      expect(find.text('Catatan Penting'), findsOneWidget);
      expect(find.text('Hitung IMT'), findsOneWidget);
    });
  });

  group('3. Halaman Hasil Perhitungan IMT - Flat Banner Bottom & Rounded Top Content Panel', () {
    testWidgets('ImtResultScreen has flat green hero bottom and rounded top content panel with Radius.circular(28)', (tester) async {
      setPhoneViewport(tester);

      await tester.pumpWidget(
        const MaterialApp(
          home: ImtResultScreen(
            bmi: 33.1,
            weight: 90,
            height: 165,
            gender: 'Perempuan',
            age: 22,
            category: 'Obesitas',
            risk: 'Tinggi',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Title and Header content are present
      expect(find.text('Hasil Perhitungan IMT anda'), findsOneWidget);
      expect(find.text('Indeks Masa Tubuh Anda'), findsOneWidget);
      expect(find.text('33,1'), findsOneWidget);
      expect(find.text('Obesitas'), findsWidgets);

      // Verify green hero container has flat bottom (no borderRadius in decoration)
      final heroContainerFinder = find.ancestor(
        of: find.text('Indeks Masa Tubuh Anda'),
        matching: find.byType(Container),
      ).first;
      final heroWidget = tester.widget<Container>(heroContainerFinder);
      final heroDecoration = heroWidget.decoration as BoxDecoration?;
      expect(heroDecoration?.borderRadius, isNull);

      // Verify content panel container has rounded top corners with Radius.circular(28)
      final panelWidget = tester.widgetList<Container>(find.byType(Container)).firstWhere(
        (c) {
          if (c.decoration is! BoxDecoration) return false;
          final border = (c.decoration as BoxDecoration).borderRadius;
          if (border is! BorderRadius) return false;
          return border.topLeft == const Radius.circular(28) && border.topRight == const Radius.circular(28);
        },
      );
      final panelDecoration = panelWidget.decoration as BoxDecoration;
      expect(panelDecoration.borderRadius, isNotNull);
      final borderRadius = panelDecoration.borderRadius as BorderRadius;
      expect(borderRadius.topLeft, const Radius.circular(28));
      expect(borderRadius.topRight, const Radius.circular(28));
      expect(borderRadius.bottomLeft, Radius.zero);
      expect(borderRadius.bottomRight, Radius.zero);

      // Verify content below header is preserved
      expect(find.textContaining('Berat Badan Anda Dalam Kategori Obesitas'), findsOneWidget);
      expect(find.text('Risiko Obesitas: Tinggi'), findsOneWidget);
      expect(find.text('Detail Data Anda'), findsOneWidget);
      expect(find.text('22 Tahun'), findsOneWidget);
      expect(find.text('Perempuan'), findsOneWidget);
      expect(find.text('165 CM'), findsOneWidget);
      expect(find.text('90 KG'), findsOneWidget);
      expect(find.text('Hitung Ulang'), findsOneWidget);
      expect(find.text('Kembali ke Beranda'), findsOneWidget);
    });
  });
}
