import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obesight/screens/auth/login_screen.dart';
import 'package:obesight/theme/app_theme.dart';

void main() {
  testWidgets('LoginScreen initial state renders all required elements', (WidgetTester tester) async {
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

    // Verify App Name
    expect(find.text('ObeSight'), findsWidgets);

    // Verify Title (2 lines)
    expect(find.text('Selamat Datang Kembali\ndi ObeSight!'), findsOneWidget);

    // Verify Input Labels
    expect(find.text('Nama Pengguna dan Email'), findsOneWidget);
    expect(find.text('Kata sandi'), findsOneWidget);

    // Verify Placeholders
    expect(find.text('Masukkan nama pengguna dan email'), findsOneWidget);
    expect(find.text('Masukkan kata sandi'), findsOneWidget);

    // Verify Links & Buttons
    expect(find.text('Lupa kata sandi?'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('atau'), findsOneWidget);
    expect(find.text('Lanjutkan dengan Google'), findsOneWidget);
    expect(find.text('Daftar'), findsOneWidget);
  });

  testWidgets('Validation error triggers when submitting empty form', (WidgetTester tester) async {
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
    await tester.pump(const Duration(milliseconds: 100));

    // Tap "Masuk" without entering credentials
    await tester.tap(find.text('Masuk'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Expect validation errors
    expect(find.text('Nama pengguna atau email wajib diisi'), findsOneWidget);
    expect(find.text('Kata sandi wajib diisi'), findsOneWidget);
  });

  testWidgets('Password visibility toggle changes state', (WidgetTester tester) async {
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
    await tester.pump(const Duration(milliseconds: 100));

    // Find password field IconButton
    final toggleButton = find.byType(IconButton);
    expect(toggleButton, findsWidgets);

    // Tap the toggle button to reveal password
    await tester.tap(toggleButton.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // The eye should now show visibility_outlined icon
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
  });

  testWidgets('User login with valid dummy account succeeds and enters UserHomeScreen', (WidgetTester tester) async {
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
    await tester.pump(const Duration(milliseconds: 100));

    // Enter User credentials directly into the unified login form
    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(0), 'zahraafitriana@gmail.com');
    await tester.enterText(textFields.at(1), 'Zahra1234');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Tap "Masuk"
    await tester.tap(find.text('Masuk'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 500));

    // Should navigate to User Dashboard
    expect(find.textContaining('Halo, Zahra'), findsOneWidget);
    expect(find.text('Status Kesehatan'), findsOneWidget);
  });

  testWidgets('Admin login with valid dummy account succeeds and enters AdminHomeScreen', (WidgetTester tester) async {
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
    await tester.pump(const Duration(milliseconds: 100));

    // Enter Admin credentials directly into the same unified login form
    final adminFields = find.byType(TextField);
    await tester.enterText(adminFields.at(0), 'admin@obesight.com');
    await tester.enterText(adminFields.at(1), 'admin123');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Tap "Masuk"
    await tester.tap(find.text('Masuk'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 500));

    // Should navigate to Admin Dashboard
    expect(find.text('PANEL ADMINISTRATOR'), findsOneWidget);
    expect(find.text('Dr. Hendra Wijaya, Sp.GK'), findsOneWidget);
    expect(find.text('Total Pasien'), findsOneWidget);
  });

  testWidgets('Google sign in opens account picker sheet', (WidgetTester tester) async {
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
    await tester.pump(const Duration(milliseconds: 100));

    // Tap "Lanjutkan dengan Google"
    await tester.tap(find.text('Lanjutkan dengan Google'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Expect Google Account Picker BottomSheet
    expect(find.text('Pilih akun Google'), findsOneWidget);
    expect(find.text('Zahra Fitriana'), findsOneWidget);
    expect(find.text('Dr. Hendra Wijaya, Sp.GK'), findsOneWidget);
  });

  testWidgets('Invalid credentials error banner only appears when credentials are wrong, and auto-dismisses on typing', (WidgetTester tester) async {
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
    await tester.pump(const Duration(milliseconds: 100));

    // Initially, error banner must NOT appear
    expect(find.text('Email atau kata sandi salah'), findsNothing);

    // Enter wrong credentials
    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(0), 'wrong@email.com');
    await tester.enterText(textFields.at(1), 'wrongpass');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Still must NOT appear before clicking Masuk
    expect(find.text('Email atau kata sandi salah'), findsNothing);

    // Tap "Masuk"
    await tester.tap(find.text('Masuk'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 200));

    // NOW it MUST appear!
    expect(find.text('Email atau kata sandi salah'), findsWidgets);

    // Now start typing to correct the email
    await tester.enterText(textFields.at(0), 'zahraafitriana@gmail.com');
    await tester.pump();

    // It must IMMEDIATELY DISAPPEAR on typing!
    expect(find.text('Email atau kata sandi salah'), findsNothing);
  });
}
