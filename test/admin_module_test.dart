import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:obesight/screens/admin/admin_change_password_sheet.dart';
import 'package:obesight/screens/admin/admin_login_screen.dart';
import 'package:obesight/screens/auth/login_screen.dart';
import 'package:obesight/screens/home/admin_home_screen.dart';
import 'package:obesight/services/auth_service.dart';
import 'package:obesight/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await AuthService().logout();
  });

  group('Admin Module Comprehensive Tests', () {
    testWidgets('1. LoginScreen contains link to Administrator Portal', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoginScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Masuk sebagai Administrator'), findsOneWidget);
    });

    testWidgets('2. AdminLoginScreen renders all required portal elements and branding', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AdminLoginScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('PORTAL ADMINISTRATOR'), findsOneWidget);
      expect(find.text('Masuk Admin'), findsOneWidget);
      expect(find.text('Email Administrator'), findsOneWidget);
      expect(find.text('Kata Sandi'), findsOneWidget);
      expect(find.text('Masuk sebagai Admin'), findsOneWidget);
      expect(find.text('Masuk Pengguna', findRichText: true), findsOneWidget);
    });

    testWidgets('3. AdminLoginScreen input validation triggers on empty submit', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AdminLoginScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Masuk sebagai Admin'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Email administrator wajib diisi'), findsOneWidget);
      expect(find.text('Kata sandi wajib diisi'), findsOneWidget);
    });

    testWidgets('4. Admin login with dummy admin account navigates to AdminHomeScreen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AdminLoginScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'adminobesight@gmail.com');
      await tester.enterText(textFields.at(1), 'admin123');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Masuk sebagai Admin'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 300));

      // Verified on Admin Dashboard
      expect(find.text('Beranda'), findsWidgets);
      expect(find.textContaining('Selamat datang'), findsOneWidget);
      expect(find.text('Total Pengguna'), findsOneWidget);
      expect(find.text('Total Artikel'), findsOneWidget);
    });

    testWidgets('5. AdminHomeScreen matches reference design and supports 5 bottom nav tabs', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final adminUser = AuthService.defaultAdminAccount;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: AdminHomeScreen(user: adminUser),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Reference Elements
      expect(find.text('ObeSight'), findsOneWidget);
      expect(find.text('Beranda'), findsWidgets);
      expect(find.textContaining('Selamat datang'), findsOneWidget);
      expect(find.text('Total Pengguna'), findsOneWidget);
      expect(find.text('Total Artikel'), findsOneWidget);
      expect(find.text('Statistik Pengguna'), findsOneWidget);
      expect(find.text('Aktivitas Terbaru'), findsOneWidget);

      // Bottom nav items
      expect(find.text('Pengguna'), findsWidgets);
      expect(find.text('Artikel'), findsWidgets);
      expect(find.text('Laporan'), findsWidgets);
      expect(find.text('Pengaturan'), findsWidgets);

      // Existing test compatibility
      expect(find.text('PANEL ADMINISTRATOR'), findsOneWidget);
      expect(find.text('Dr. Hendra Wijaya, Sp.GK'), findsOneWidget);
      expect(find.text('Total Pasien'), findsOneWidget);

      // Test tapping Pengguna in bottom nav switches to Pengguna tab
      await tester.tap(find.byIcon(Icons.people_alt_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Kelola Pengguna'), findsOneWidget);

      // Test tapping Artikel bottom nav switches to Artikel tab
      await tester.tap(find.byIcon(Icons.article_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Artikel Edukasi Kesehatan'), findsOneWidget);

      // Test tapping Laporan bottom nav switches to Laporan tab
      await tester.tap(find.byIcon(Icons.bar_chart_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Laporan & Analitik'), findsOneWidget);

      // Test tapping Pengaturan bottom nav switches to Pengaturan tab
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('ADMINISTRATOR SISTEM'), findsOneWidget);
      expect(find.text('Email Administrator (Read-Only)'), findsOneWidget);
      expect(find.text('adminobesight@gmail.com'), findsWidgets);
      expect(find.text('TETAP'), findsOneWidget);
      expect(find.text('Ubah Kata Sandi'), findsOneWidget);
    });

    testWidgets('6. AdminChangePasswordSheet enforces password criteria and validation', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AdminChangePasswordSheet(adminEmail: 'adminobesight@gmail.com'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Ubah Kata Sandi Admin'), findsOneWidget);
      expect(find.text('Kata Sandi Saat Ini (Lama)'), findsOneWidget);
      expect(find.text('Kata Sandi Baru'), findsOneWidget);
      expect(find.text('Konfirmasi Kata Sandi Baru'), findsOneWidget);

      // Submit empty
      await tester.tap(find.text('Simpan Kata Sandi'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Kata sandi saat ini wajib diisi untuk verifikasi keamanan.'), findsOneWidget);
    });
  });
}
