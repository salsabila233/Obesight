import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obesight/models/user_model.dart';
import 'package:obesight/screens/auth/auth_wrapper.dart';
import 'package:obesight/screens/splash/splash_screen.dart';
import 'package:obesight/services/auth_service.dart';
import 'package:obesight/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void setPhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  tearDown(() async {
    await AuthService().logout();
  });

  group('Persistent Auth & Gating Tests', () {
    testWidgets('AuthWrapper renders WelcomeScreen when no user is logged in', (tester) async {
      setPhoneViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AuthWrapper(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Mulai kenali risiko obesitas sejak sekarang'), findsOneWidget);
      expect(find.text('Masuk'), findsOneWidget);
      expect(find.text('Lanjutkan dengan Google'), findsOneWidget);
    });

    testWidgets('AuthWrapper routes to CompleteProfileScreen when user has incomplete profile', (tester) async {
      setPhoneViewport(tester);

      // Login akun dengan data profil belum lengkap
      const incompleteUser = UserModel(
        id: 'usr_incomplete_auth',
        name: 'Pengguna Baru',
        email: 'penggunabaru@gmail.com',
        username: 'penggunabaru',
        role: UserRole.user,
        dob: '',
        gender: '',
        phone: '',
        isBiodataComplete: false,
      );
      await AuthService().loginWithGoogleAccount(incompleteUser);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AuthWrapper(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Lengkapi Profil'), findsOneWidget);
      expect(find.text('Persyaratan Skrining Obesitas'), findsOneWidget);
    });

    testWidgets('AuthWrapper routes directly to UserHomeScreen when user has complete profile', (tester) async {
      setPhoneViewport(tester);

      // Login akun dengan data profil lengkap
      const completeUser = UserModel(
        id: 'usr_complete_auth',
        name: 'Siti Rahma',
        email: 'sitirahma@gmail.com',
        username: 'sitirahma',
        role: UserRole.user,
        dob: '10 Agustus 2001',
        gender: 'Perempuan',
        phone: '081298765432',
        isBiodataComplete: true,
      );
      await AuthService().loginWithGoogleAccount(completeUser);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AuthWrapper(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Status Kesehatan'), findsOneWidget);
      expect(find.textContaining('Halo, Siti'), findsOneWidget);
      // Memastikan halaman login tidak pernah ditampilkan
      expect(find.text('Lanjutkan dengan Google'), findsNothing);
    });

    testWidgets('SplashScreen navigates directly to UserHomeScreen on cold start if already logged in with complete profile', (tester) async {
      setPhoneViewport(tester);

      const completeUser = UserModel(
        id: 'usr_cold_start',
        name: 'Budi Santoso',
        email: 'budisantoso@gmail.com',
        username: 'budisantoso',
        role: UserRole.user,
        dob: '15 Maret 1999',
        gender: 'Laki-laki',
        phone: '081311223344',
        isBiodataComplete: true,
      );
      await AuthService().loginWithGoogleAccount(completeUser);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SplashScreen(),
        ),
      );
      await tester.pump();

      // Fase splash screen berjalan
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump(const Duration(milliseconds: 750));
      await tester.pump(const Duration(milliseconds: 1550));
      await tester.pump(const Duration(milliseconds: 550));

      // Langsung masuk ke Beranda tanpa meminta login ulang
      expect(find.text('Status Kesehatan'), findsOneWidget);
      expect(find.textContaining('Halo, Budi'), findsOneWidget);
      expect(find.text('Lanjutkan dengan Google'), findsNothing);
    });
  });
}
