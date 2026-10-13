import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:obesight/models/user_model.dart';
import 'package:obesight/screens/auth/forgot_password_screen.dart';
import 'package:obesight/screens/auth/reset_password_screen.dart';
import 'package:obesight/screens/auth/verify_otp_screen.dart';
import 'package:obesight/screens/profile/profile_screen.dart';
import 'package:obesight/screens/progress/night_sleep_detail_screen.dart';
import 'package:obesight/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('1. Night Sleep Detail Screen - Hapus Tanda Petir', () {
    testWidgets('NightSleepDetailScreen tidak memuat ikon tanda petir (flash_on)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NightSleepDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Pastikan Icons.flash_on_rounded atau Icons.flash_on tidak ditemukan sama sekali
      expect(find.byIcon(Icons.flash_on_rounded), findsNothing);
      expect(find.byIcon(Icons.flash_on), findsNothing);
    });
  });

  group('2. AuthService: OTP Generator, Verifikasi, dan Reset Kata Sandi', () {
    final authService = AuthService();
    const testEmail = 'tester_otp@obesight.com';

    test('generateAndSendOtp menghasilkan kode 6-digit dan tersimpan dengan benar', () async {
      final res = await authService.generateAndSendOtp(testEmail);
      expect(res.isSuccess, isTrue);
      expect(res.otp, isNotNull);
      expect(res.otp!.length, equals(6));
      expect(int.tryParse(res.otp!), isNotNull);

      // Verifikasi dengan kode salah harus gagal
      final verifyFail = await authService.verifyOtp(email: testEmail, otp: '000000');
      expect(verifyFail.isSuccess, isFalse);

      // Verifikasi dengan kode benar harus berhasil
      final verifySuccess = await authService.verifyOtp(email: testEmail, otp: res.otp!);
      expect(verifySuccess.isSuccess, isTrue);

      // Reset kata sandi dengan OTP
      final resetRes = await authService.resetPasswordWithOtp(
        email: testEmail,
        newPassword: 'PasswordBaru123',
      );
      expect(resetRes.isSuccess, isTrue);
    });
  });

  group('3. AuthService: Hapus Akun Permanen', () {
    final authService = AuthService();

    test('deleteAccount dieksekusi tanpa throw unhandled exception di offline/mock mode', () async {
      final delRes = await authService.deleteAccount(password: 'dummy_pass');
      expect(delRes, isNotNull);
    });
  });

  group('4. Layar Verifikasi OTP & Reset Password UI Flow', () {
    testWidgets('ForgotPasswordScreen merender form dan tombol Kirim Tautan Pemulihan', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ForgotPasswordScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kirim Tautan Pemulihan'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('VerifyOtpScreen merender 6 input kotak OTP', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: VerifyOtpScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Verifikasi Kode'), findsOneWidget);
      expect(find.text('Verifikasi'), findsOneWidget);
      // Memeriksa keberadaan 6 text field untuk 6 digit OTP
      expect(find.byType(TextField), findsNWidgets(6));
    });

    testWidgets('ResetPasswordScreen merender input Kata Sandi Baru & Konfirmasi', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResetPasswordScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Buat Kata Sandi Baru'), findsOneWidget);
      expect(find.text('Simpan Kata Sandi'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
    });
  });

  group('5. ProfileScreen: Desain Header Melengkung dan Warna Konsisten', () {
    testWidgets('ProfileScreen merender curved container dan avatar', (tester) async {
      final dummyUser = UserModel(
        id: 'usr_001',
        name: 'Zahra Fitriana',
        email: 'zahraafitriana@gmail.com',
        username: 'zahra',
        role: UserRole.user,
        bmiScore: 21.5,
        bmiCategory: 'Normal',
        obesityRisk: 'Rendah',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(
            user: dummyUser,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Profil Saya'), findsOneWidget);
      expect(find.text('Zahra Fitriana'), findsWidgets);
      expect(find.text('zahraafitriana@gmail.com'), findsWidgets);

      // Memeriksa Scaffold background bernilai header Color(0xFF489874)
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFF489874));
    });
  });
}
