import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:obesight/screens/home/admin_home_screen.dart';
import 'package:obesight/services/auth_service.dart';
import 'package:obesight/theme/app_theme.dart';
import 'package:obesight/widgets/curved_header_scaffold.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Admin Navigation & Laporan Comprehensive Widget Tests', () {
    final adminUser = AuthService.defaultAdminAccount;

    testWidgets('1. Navigasi Beranda: Kartu Statistik Pengguna bisa diklik dan beralih ke tab Laporan', (WidgetTester tester) async {
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
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Verifikasi berada di Beranda
      expect(find.text('Statistik Pengguna'), findsOneWidget);
      expect(find.textContaining('Selamat datang, Admin'), findsOneWidget);

      // 2. Klik kartu Statistik Pengguna
      final statsCardFinder = find.text('Statistik Pengguna');
      await tester.tap(statsCardFinder);
      await tester.pumpAndSettle();

      // 3. Verifikasi telah berpindah ke tab Laporan
      expect(find.text('Distribusi Hasil Skrining'), findsOneWidget);
      expect(find.text('Total Skrining'), findsOneWidget);
      expect(find.text('Total Pengguna (Pasien)'), findsOneWidget);
    });

    testWidgets('2. Dropdown periode "7 hari terakhir" tetap bekerja mandiri tanpa berpindah tab', (WidgetTester tester) async {
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
      await tester.pump(const Duration(milliseconds: 300));

      // Klik dropdown "7 hari terakhir"
      final dropdownFinder = find.text('7 hari terakhir');
      expect(dropdownFinder, findsOneWidget);
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      // Menu dropdown terbuka, tetap berada di tab Beranda (bukan tab Laporan)
      expect(find.text('1 bulan terakhir'), findsOneWidget);
      expect(find.text('1 tahun terakhir'), findsOneWidget);
      expect(find.text('Distribusi Hasil Skrining'), findsNothing);
    });

    testWidgets('3. Halaman Laporan: CurvedHeaderScaffold pinned header (title: Laporan) & radius 28', (WidgetTester tester) async {
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
      await tester.pump(const Duration(milliseconds: 300));

      // Pindah ke tab Laporan via bottom nav
      await tester.tap(find.byIcon(Icons.bar_chart_outlined));
      await tester.pumpAndSettle();

      // 1. Verifikasi komponen CurvedHeaderScaffold terpasang
      expect(find.byType(CurvedHeaderScaffold), findsOneWidget);

      // 2. Verifikasi judul "Laporan" pada header sticky
      expect(find.widgetWithText(CurvedHeaderScaffold, 'Laporan'), findsOneWidget);

      // 3. Verifikasi bentuk lengkungan sudut atas radius 28
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

      // 4. Test Scroll: Header sticky tetap pinned di atas
      final scrollFinder = find.byType(SingleChildScrollView);
      await tester.drag(scrollFinder.first, const Offset(0, -600));
      await tester.pumpAndSettle();

      // Tombol back dan judul Laporan tetap terlihat dan bisa ditekan saat di-scroll
      final backButton = find.byIcon(Icons.arrow_back_ios_new_rounded);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Setelah tombol back ditekan, kembali ke tab Beranda
      expect(find.textContaining('Selamat datang, Admin'), findsOneWidget);
    });

    testWidgets('4. Halaman Laporan: Menampilkan kartu ringkasan statis dan bagian baru dari Firestore', (WidgetTester tester) async {
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
      await tester.pump(const Duration(milliseconds: 300));

      // Buka tab Laporan
      await tester.tap(find.byIcon(Icons.bar_chart_outlined));
      await tester.pumpAndSettle();

      // a) Filter Tanggal
      expect(find.text('29/07/2026 - 29/08/2026'), findsOneWidget);

      // b) 3 Kartu Ringkasan Skrining Statis
      expect(find.text('Total Skrining'), findsOneWidget);
      expect(find.text('3.456'), findsOneWidget);
      expect(find.text('Pengguna Baru'), findsOneWidget);
      expect(find.text('234'), findsOneWidget);
      expect(find.textContaining('Rata-rata/Hari'), findsOneWidget);
      expect(find.text('115'), findsOneWidget);

      // c) Card Donut "Distribusi Hasil Skrining"
      expect(find.text('Distribusi Hasil Skrining'), findsOneWidget);
      expect(find.text('Insufficient Weight'), findsWidgets);
      expect(find.text('Normal Weight'), findsWidgets);
      expect(find.text('Overweight Level 1'), findsWidgets);
      expect(find.text('Overweight Level 2'), findsWidgets);
      expect(find.text('Obesity Type 1'), findsWidgets);
      expect(find.text('Obesity Type 2'), findsWidgets);
      expect(find.text('Obesity Type 3'), findsWidgets);

      // d) Bagian Baru: Jumlah Pengguna (Pasien)
      expect(find.text('Total Pengguna (Pasien)'), findsOneWidget);

      // e) Bagian Baru: Pengguna per Jenis Kelamin
      expect(find.text('Pengguna per Jenis Kelamin'), findsOneWidget);
      expect(find.text('Perempuan'), findsWidgets);
      expect(find.text('Laki-laki'), findsWidgets);

      // f) Bagian Baru: Kategori Hasil Skrining Terbaru
      expect(find.text('Kategori Hasil Skrining Terbaru'), findsOneWidget);
      expect(find.text('Satu pengguna dihitung satu kali berdasarkan hasil skrining terbarunya'), findsOneWidget);
    });

    testWidgets('5. Halaman Laporan: State Kosong dan Loading ter-render rapi tanpa crash', (WidgetTester tester) async {
      FlutterErrorDetails? caughtDetails;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        caughtDetails = details;
        originalOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalOnError);

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
      await tester.pump(const Duration(milliseconds: 300));

      // Buka tab Laporan
      await tester.tap(find.byIcon(Icons.bar_chart_outlined));
      await tester.pumpAndSettle();

      // Ubah filter tanggal ke opsi yang membuat data kosong atau memicu fetch
      await tester.tap(find.text('29/07/2026 - 29/08/2026'));
      await tester.pumpAndSettle();

      // Pilih "Semua waktu"
      expect(find.text('Semua waktu'), findsOneWidget);
      await tester.tap(find.text('Semua waktu'));
      await tester.pumpAndSettle();

      expect(find.text('Semua waktu'), findsOneWidget);
      expect(caughtDetails, isNull);
    });
  });
}
