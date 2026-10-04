import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obesight/models/user_model.dart';
import 'package:obesight/screens/auth/login_screen.dart';
import 'package:obesight/screens/profile/complete_profile_screen.dart';
import 'package:obesight/screens/skrining/skrining_landing_screen.dart';
import 'package:obesight/screens/splash/splash_screen.dart';
import 'package:obesight/services/auth_service.dart';
import 'package:obesight/theme/app_colors.dart';
import 'package:obesight/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void setPhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('Poin 1: Google Sign-In Native & No Custom Mock Sheet', () {
    testWidgets('LoginScreen shows "Masuk dengan Google" button and never renders custom mock sheet', (tester) async {
      setPhoneViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoginScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('Masuk dengan Google'), findsOneWidget);

      await tester.tap(find.text('Masuk dengan Google'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verifikasi bahwa widget bottom sheet custom buatan sendiri telah hilang total
      expect(find.text('Zahra Cantik'), findsNothing);
      expect(find.text('Aku Zahra'), findsNothing);
      expect(find.text('Gunakan akun lain'), findsNothing);
    });
  });

  group('Poin 2: CompleteProfileScreen saves profile and navigates to Home without black screen', () {
    testWidgets('CompleteProfileScreen renders fields and successfully saves to Home', (tester) async {
      setPhoneViewport(tester);

      const testUser = UserModel(
        id: 'usr_test_google',
        name: 'Google User Test',
        email: 'googletest@gmail.com',
        username: 'googletest',
        role: UserRole.user,
        dob: '',
        gender: '',
        phone: '',
        isBiodataComplete: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CompleteProfileScreen(
            user: testUser,
            isGatedFlow: false,
            redirectToHomeAfterSave: true,
          ),
        ),
      );
      await tester.pump();

      // Nama dan Email terisi otomatis dari Google di field
      expect(
        find.byWidgetPredicate(
          (w) => w is EditableText && w.controller.text == 'Google User Test',
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is EditableText && w.controller.text == 'googletest@gmail.com',
        ),
        findsOneWidget,
      );

      // Cari input Nomor Telepon dan masukkan nomor yang valid
      final phoneField = find.widgetWithText(TextFormField, 'Contoh: 081234567890');
      expect(phoneField, findsOneWidget);
      await tester.enterText(phoneField, '081234567890');
      await tester.pump();

      // Isi Tanggal Lahir langsung ke controller
      final dobField = find.widgetWithText(TextFormField, 'Contoh: 12 Juli 2003');
      expect(dobField, findsOneWidget);
      final dobState = tester.state<FormFieldState<String>>(dobField);
      dobState.didChange('12 Juli 2003');
      await tester.pump();

      // Pilih Jenis Kelamin Perempuan
      await tester.tap(find.text('Perempuan'));
      await tester.pump();

      // Klik tombol Simpan
      final saveButton = find.text('Simpan & Masuk ke Beranda');
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Verifikasi notifikasi Snackbar Berhasil menyimpan profil muncul
      expect(find.text('Berhasil menyimpan profil'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Verifikasi bahwa user berpindah ke Beranda (UserHomeScreen) tanpa layar hitam
      expect(find.text('Status Kesehatan'), findsOneWidget);
    });
  });

  group('Poin 3: Skrining Gating Validation', () {
    testWidgets('SkriningLandingScreen guards incomplete profile on Mulai Skrining and redirects to CompleteProfileScreen', (tester) async {
      setPhoneViewport(tester);

      const incompleteUser = UserModel(
        id: 'usr_incomplete_test',
        name: 'Incomplete User',
        email: 'incomplete@gmail.com',
        username: 'incomplete',
        role: UserRole.user,
        dob: '',
        gender: '',
        phone: '',
        isBiodataComplete: false,
      );

      // Reset cache untuk memastikan data belum lengkap
      AuthService().updateUserProfile(
        userId: incompleteUser.id,
        name: incompleteUser.name,
        email: incompleteUser.email,
        dob: '',
        gender: '',
        phone: '',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SkriningLandingScreen(user: incompleteUser),
        ),
      );
      await tester.pump();

      // Menampilkan banner peringatan bahwa profil belum lengkap
      expect(find.text('Lengkapi profil terlebih dahulu!'), findsOneWidget);

      // Scroll dan klik Mulai Skrining saat data belum lengkap
      final mulaiSkriningButton = find.text('Mulai Skrining');
      await tester.ensureVisible(mulaiSkriningButton);
      await tester.tap(mulaiSkriningButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Pengguna diarahkan ke halaman Lengkapi Profil
      expect(find.text('Lengkapi Profil'), findsOneWidget);
      expect(find.text('Persyaratan Skrining Obesitas'), findsOneWidget);
    });
  });

  group('Poin 4: Splash Screen Sequence (Hijau Tua -> Putih -> Login)', () {
    testWidgets('SplashScreen starts on dark green background, transitions to white with title, then navigates to WelcomeScreen', (tester) async {
      setPhoneViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SplashScreen(),
        ),
      );
      await tester.pump();

      // Tahap 1: Latar belakang dimulai dengan hijau tua ObeSight
      final animatedContainerFinder = find.byType(AnimatedContainer);
      expect(animatedContainerFinder, findsOneWidget);
      final initialContainer = tester.widget<AnimatedContainer>(animatedContainerFinder);
      expect((initialContainer.decoration as BoxDecoration?)?.color, AppColors.darkGreen);

      // Logo tampil di tengah
      expect(find.byType(Image), findsOneWidget);

      // Tahap 2: Setelah 1.2 detik, background bertransisi ke putih dan teks "ObeSight" muncul
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pump(const Duration(milliseconds: 450));

      final whiteContainer = tester.widget<AnimatedContainer>(animatedContainerFinder);
      expect((whiteContainer.decoration as BoxDecoration?)?.color, Colors.white);
      expect(find.text('ObeSight'), findsOneWidget);

      // Jalankan animasi teks fade forward (700ms)
      await tester.pump(const Duration(milliseconds: 750));
      // Selesaikan jeda tayang brand identity (1500ms)
      await tester.pump(const Duration(milliseconds: 1550));
      // Transisi rute halaman WelcomeScreen (500ms)
      await tester.pump(const Duration(milliseconds: 550));

      // Berpindah ke WelcomeScreen
      expect(find.text('Mulai kenali risiko obesitas sejak sekarang'), findsOneWidget);
    });
  });
}
