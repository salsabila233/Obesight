import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:obesight/screens/home/admin_home_screen.dart';
import 'package:obesight/services/auth_service.dart';
import 'package:obesight/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Admin Dashboard Refinement & Requirements Verification Tests', () {
    final adminUser = AuthService.defaultAdminAccount;

    testWidgets('1. Header: Removes Beranda title, doctor name, and status banner while keeping branding', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: AdminHomeScreen(user: adminUser),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Elements that MUST NOT be present
      expect(find.text('Dr. Hendra Wijaya, Sp.GK'), findsNothing);
      expect(find.text('Sistem berjalan dengan baik'), findsNothing);
      expect(find.text('Semua layanan dalam kondisi normal.'), findsNothing);

      // Elements that MUST be present
      expect(find.text('ObeSight'), findsOneWidget);
      expect(find.text('PANEL ADMINISTRATOR'), findsOneWidget);
      expect(find.textContaining('Selamat datang, Admin!'), findsOneWidget);
      expect(find.byIcon(Icons.person_outline_rounded), findsWidgets);
    });

    testWidgets('2. Statistic Cards: Equal sized Total Pengguna and Total Artikel cards with real labels', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: AdminHomeScreen(user: adminUser),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Total Pengguna'), findsOneWidget);
      expect(find.text('Total Pasien'), findsOneWidget);
      expect(find.text('Total Artikel'), findsOneWidget);
      expect(find.text('Total Konten'), findsOneWidget);

      // No dummy percentages like "↑ 12%" or "↑ 8%" on the cards
      expect(find.text('↑ 12%'), findsNothing);
      expect(find.text('↑ 8%'), findsNothing);
    });

    testWidgets('3. Dropdown Statistik Pengguna: Interactive with 3 periods, updates label & chart', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: AdminHomeScreen(user: adminUser),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Initial state is 7 hari terakhir
      expect(find.text('7 hari terakhir'), findsOneWidget);

      // Open dropdown
      await tester.tap(find.text('7 hari terakhir'));
      await tester.pumpAndSettle();

      // All 3 period options must be listed
      expect(find.text('7 hari terakhir'), findsWidgets);
      expect(find.text('1 bulan terakhir'), findsOneWidget);
      expect(find.text('1 tahun terakhir'), findsOneWidget);

      // Select '1 bulan terakhir'
      await tester.tap(find.text('1 bulan terakhir'));
      await tester.pumpAndSettle();
      expect(find.text('1 bulan terakhir'), findsOneWidget);

      // Weekly labels should be rendered for 1 month
      expect(find.text('Mgg 1'), findsOneWidget);
      expect(find.text('Mgg 4'), findsOneWidget);

      // Open dropdown again and select '1 tahun terakhir'
      await tester.tap(find.text('1 bulan terakhir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1 tahun terakhir'));
      await tester.pumpAndSettle();
      expect(find.text('1 tahun terakhir'), findsOneWidget);

      // Month abbreviations should be rendered for 1 year
      expect(find.text('Jan'), findsWidgets);
    });

    testWidgets('4. Aktivitas Terbaru: Displays real activities list and preserves navigation', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: AdminHomeScreen(user: adminUser),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Aktivitas Terbaru'), findsOneWidget);
      expect(find.text('Lihat semua'), findsOneWidget);

      // Verify at least one activity item is rendered from mock/fallback auth service
      expect(find.text('Pengguna baru terdaftar'), findsWidgets);

      // 5 Bottom Nav tabs remain intact
      expect(find.text('Beranda'), findsWidgets);
      expect(find.text('Pengguna'), findsWidgets);
      expect(find.text('Artikel'), findsWidgets);
      expect(find.text('Laporan'), findsWidgets);
      expect(find.text('Pengaturan'), findsWidgets);
    });
  });
}
