import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:obesight/screens/admin/admin_login_screen.dart';
import 'package:obesight/screens/home/admin_home_screen.dart';
import 'package:obesight/services/auth_service.dart';
import 'package:obesight/theme/app_theme.dart';
import 'package:obesight/widgets/curved_header_scaffold.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppTheme.setThemeMode(ThemeMode.light);
  });

  group('Admin Settings (Pengaturan Admin) Widget Tests', () {
    final adminUser = AuthService.defaultAdminAccount;

    testWidgets('1. Navigasi ke Tab Pengaturan menampilkan 3 bagian utama (Keamanan, Tampilan, Informasi)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: AdminHomeScreen(user: adminUser),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Buka Tab Pengaturan (icon settings di capsule bottom nav)
      final settingsNavFinder = find.byIcon(Icons.settings_outlined);
      expect(settingsNavFinder, findsOneWidget);
      await tester.tap(settingsNavFinder);
      await tester.pumpAndSettle();

      // 1. Verifikasi CurvedHeaderScaffold terpasang dengan judul 'Pengaturan' dan lengkungan radius 28
      expect(find.byType(CurvedHeaderScaffold), findsOneWidget);
      expect(find.widgetWithText(CurvedHeaderScaffold, 'Pengaturan'), findsOneWidget);
      final containerWithRadius = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final dec = widget.decoration as BoxDecoration;
          if (dec.borderRadius is BorderRadius) {
            final br = dec.borderRadius as BorderRadius;
            return br.topLeft.x == 28.0 && br.topRight.x == 28.0;
          }
        }
        return false;
      });
      expect(containerWithRadius, findsWidgets);

      // 2. Verifikasi 3 Bagian Utama
      expect(find.text('Keamanan'), findsOneWidget);
      expect(find.text('Ubah Kata Sandi'), findsOneWidget);

      expect(find.text('Tampilan'), findsOneWidget);
      expect(find.text('Mode Gelap'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);

      expect(find.text('Informasi'), findsOneWidget);
      expect(find.text('Tentang Aplikasi'), findsOneWidget);
      expect(find.text('Keluar'), findsOneWidget);
    });

    testWidgets('2. Sub-view Ubah Kata Sandi: Form lengkap, checklist kriteria live, dan tombol Simpan', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: AdminHomeScreen(user: adminUser),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Buka Tab Pengaturan
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      // Klik 'Ubah Kata Sandi'
      await tester.tap(find.text('Ubah Kata Sandi'));
      await tester.pumpAndSettle();

      // 1. Verifikasi CurvedHeaderScaffold berubah judul menjadi 'Ubah Kata Sandi'
      expect(find.widgetWithText(CurvedHeaderScaffold, 'Ubah Kata Sandi'), findsOneWidget);

      // 2. Verifikasi 3 Input Field pill
      expect(find.text('Password lama'), findsOneWidget);
      expect(find.text('Password baru'), findsOneWidget);
      expect(find.text('Konfirmasi password baru'), findsOneWidget);

      // 3. Verifikasi 3 Checklist Kriteria Password
      expect(find.text('Minimum 8 karakter (maksimal 16)'), findsOneWidget);
      expect(find.text('Terdapat minimum 1 angka'), findsOneWidget);
      expect(find.text('Terdapat minimum 1 huruf besar dan 1 huruf kecil'), findsOneWidget);

      // 4. Verifikasi Tombol 'Simpan'
      expect(find.widgetWithText(ElevatedButton, 'Simpan'), findsOneWidget);

      // 5. Test Live Checklist: Masukkan password tidak lengkap
      final passwordBaruFinder = find.widgetWithText(TextField, 'Password baru');
      await tester.enterText(passwordBaruFinder, 'abc');
      await tester.pump();

      // Test Live Checklist: Masukkan password lengkap memenuhi kriteria (Admin123)
      await tester.enterText(passwordBaruFinder, 'Admin1234');
      await tester.pump();

      // Ikon checklist tercentang hijau
      expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(3));

      // 6. Test Tombol Back '<' kembali ke halaman utama Pengaturan
      final backButton = find.byIcon(Icons.arrow_back_ios_new_rounded);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Berhasil kembali ke Pengaturan utama
      expect(find.widgetWithText(CurvedHeaderScaffold, 'Pengaturan'), findsOneWidget);
      expect(find.text('Ubah Kata Sandi'), findsOneWidget);
    });

    testWidgets('3. Mode Gelap: Switch berfungsi dan mengubah preferensi tema secara global', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ValueListenableBuilder<ThemeMode>(
          valueListenable: AppTheme.themeModeNotifier,
          builder: (context, currentMode, _) {
            return MaterialApp(
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: currentMode,
              home: AdminHomeScreen(user: adminUser),
            );
          },
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Buka Tab Pengaturan
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      expect(AppTheme.isDark, isFalse);

      // Nyalakan Mode Gelap via Switch
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Mode gelap aktif
      expect(AppTheme.isDark, isTrue);
      expect(AppTheme.currentThemeMode, ThemeMode.dark);

      // Matikan kembali Mode Gelap
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(AppTheme.isDark, isFalse);
      expect(AppTheme.currentThemeMode, ThemeMode.light);
    });

    testWidgets('4. Sub-view Tentang Aplikasi: Menampilkan Logo, Visi, Fitur Utama, Catatan, dan Versi', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: AdminHomeScreen(user: adminUser),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Buka Tab Pengaturan
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      // Klik 'Tentang Aplikasi'
      await tester.tap(find.text('Tentang Aplikasi'));
      await tester.pumpAndSettle();

      // 1. Verifikasi CurvedHeaderScaffold berubah judul menjadi 'Tentang Aplikasi'
      expect(find.widgetWithText(CurvedHeaderScaffold, 'Tentang Aplikasi'), findsOneWidget);

      // 2. Verifikasi Nama & Tagline
      expect(find.text('OBESIGHT'), findsOneWidget);
      expect(find.text('Kenali Risiko, Jaga Masa Depanmu'), findsOneWidget);
      expect(find.textContaining('Obesight adalah aplikasi kesehatan yang membantu kamu'), findsOneWidget);

      // 3. Verifikasi Card Fitur Utama Obesight
      expect(find.text('Fitur Utama Obesight'), findsOneWidget);
      expect(find.text('Skrining Risiko'), findsOneWidget);
      expect(find.text('Monitoring Pola Hidup'), findsOneWidget);
      expect(find.text('Rekomendasi GAYA-SEHAT'), findsOneWidget);

      // 4. Verifikasi Catatan Box
      expect(find.text('Catatan:'), findsOneWidget);
      expect(find.textContaining('bukan alat untuk mendiagnosis secara medis'), findsOneWidget);

      // 5. Verifikasi Footer Versi
      expect(find.text('Versi 1.0.0'), findsOneWidget);
      expect(find.text('© 2026 Obesight. Semua hak dilindungi.'), findsOneWidget);

      // 6. Tombol back '<' kembali ke Pengaturan utama
      final backButton = find.byIcon(Icons.arrow_back_ios_new_rounded);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(CurvedHeaderScaffold, 'Pengaturan'), findsOneWidget);
    });

    testWidgets('5. Menu Keluar: Menampilkan dialog konfirmasi dengan tombol Batal dan Keluar', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: AdminHomeScreen(user: adminUser),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Buka Tab Pengaturan
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      // Klik 'Keluar'
      await tester.tap(find.text('Keluar'));
      await tester.pumpAndSettle();

      // 1. Verifikasi Dialog Konfirmasi muncul
      expect(find.text('Keluar dari akun?'), findsOneWidget);
      expect(find.text('Apakah kamu yakin ingin keluar dari akun Obesight?'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Batal'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Keluar'), findsOneWidget);

      // 2. Klik Batal: Dialog tertutup dan tetap berada di Pengaturan
      await tester.tap(find.widgetWithText(OutlinedButton, 'Batal'));
      await tester.pumpAndSettle();

      expect(find.text('Keluar dari akun?'), findsNothing);
      expect(find.widgetWithText(CurvedHeaderScaffold, 'Pengaturan'), findsOneWidget);

      // 3. Klik Keluar lagi lalu pilih tombol Keluar di dialog
      await tester.tap(find.text('Keluar'));
      await tester.pumpAndSettle();

      expect(find.text('Keluar dari akun?'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Keluar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Mengarahkan ke AdminLoginScreen
      expect(find.byType(AdminLoginScreen), findsOneWidget);
    });
  });
}
