import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:obesight/screens/auth/forgot_password_screen.dart';
import 'package:obesight/screens/auth/verify_otp_screen.dart';
import 'package:obesight/screens/auth/reset_password_screen.dart';
import 'package:obesight/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await AuthService().logout();
  });

  group('Custom OTP Email Flow & Password Reset Tests', () {
    const testEmail = 'user_reset_test@obesight.com';
    const oldPassword = 'OldPassword123';
    const newPassword = 'NewSecretPassword456';

    test('Full Cycle: Register -> Login (old) -> Request OTP -> Verify OTP -> Reset Password -> Login (new)', () async {
      final auth = AuthService();

      // 1. Setup user awal via registerWithEmailPassword
      final regRes = await auth.registerWithEmailPassword(
        name: 'User Reset Test',
        email: testEmail,
        password: oldPassword,
      );
      expect(regRes.isSuccess, isTrue);

      // Login awal dengan password lama berhasil
      final initialLogin = await auth.login(
        identifier: testEmail,
        password: oldPassword,
      );
      expect(initialLogin.isSuccess, isTrue);
      await auth.logout();

      // 2. Request OTP
      final otpRes = await auth.generateAndSendOtp(testEmail);
      expect(otpRes.isSuccess, isTrue);
      expect(otpRes.otp, isNotNull);
      expect(otpRes.otp!.length, equals(6));

      // 3. Verifikasi OTP
      final wrongVerify = await auth.verifyOtp(email: testEmail, otp: '111111');
      if (otpRes.otp != '111111') {
        expect(wrongVerify.isSuccess, isFalse);
      }

      final rightVerify = await auth.verifyOtp(email: testEmail, otp: otpRes.otp!);
      expect(rightVerify.isSuccess, isTrue);

      // 4. Reset Kata Sandi
      final resetRes = await auth.resetPasswordWithOtp(
        email: testEmail,
        newPassword: newPassword,
      );
      expect(resetRes.isSuccess, isTrue);

      // 5. Login dengan password lama harus gagal
      final failLogin = await auth.login(
        identifier: testEmail,
        password: oldPassword,
      );
      expect(failLogin.isSuccess, isFalse);

      // 6. Login dengan password baru harus berhasil
      final successLogin = await auth.login(
        identifier: testEmail,
        password: newPassword,
      );
      expect(successLogin.isSuccess, isTrue);
      expect(successLogin.user?.email, equals(testEmail));
    });

    testWidgets('ForgotPasswordScreen SnackBar confirms OTP email sent without leaking code', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/': (_) => const ForgotPasswordScreen(),
            '/verify-otp': (_) => const Scaffold(body: Text('Halaman Verifikasi OTP')),
          },
        ),
      );
      await tester.pumpAndSettle();

      final inputField = find.byType(TextFormField);
      await tester.enterText(inputField, 'tester_mail@obesight.com');
      await tester.pumpAndSettle();

      final submitBtn = find.text('Kirim Kode Verifikasi');
      await tester.tap(submitBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // SnackBar harus menampilkan informasi terkirim ke email tanpa membocorkan kode
      expect(find.textContaining('Kode verifikasi 6-digit telah dikirim ke email tester_mail@obesight.com'), findsOneWidget);
    });

    testWidgets('VerifyOtpScreen input rejects less than 6 digits and submits when complete', (tester) async {
      final auth = AuthService();
      final otpRes = await auth.generateAndSendOtp(testEmail);
      final validOtp = otpRes.otp!;

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) {
            if (settings.name == '/verify-otp') {
              return MaterialPageRoute(
                settings: const RouteSettings(
                  name: '/verify-otp',
                  arguments: {'email': testEmail},
                ),
                builder: (_) => const VerifyOtpScreen(),
              );
            }
            if (settings.name == '/reset-password') {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const ResetPasswordScreen(),
              );
            }
            return null;
          },
          initialRoute: '/verify-otp',
        ),
      );
      await tester.pumpAndSettle();

      // Tap verifikasi sebelum input -> error message
      final verifyBtn = find.text('Verifikasi');
      await tester.tap(verifyBtn);
      await tester.pumpAndSettle();
      expect(find.text('Masukkan lengkap 6 digit kode verifikasi.'), findsOneWidget);

      // Masukkan 6 digit
      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(6));
      for (int i = 0; i < 6; i++) {
        await tester.enterText(textFields.at(i), validOtp[i]);
      }
      await tester.pumpAndSettle();

      await tester.tap(verifyBtn);
      await tester.pumpAndSettle();

      // Navigasi ke halaman Buat Kata Sandi Baru
      expect(find.text('Buat Kata Sandi Baru'), findsOneWidget);
    });
  });
}
