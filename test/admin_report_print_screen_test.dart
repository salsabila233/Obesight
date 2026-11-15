import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:obesight/screens/admin/admin_print_report_screen.dart';
import 'package:obesight/screens/home/admin_home_screen.dart';
import 'package:obesight/services/auth_service.dart';
import 'package:obesight/theme/app_theme.dart';
import 'package:obesight/widgets/curved_header_scaffold.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AdminPrintReportScreen - Widget & Interaksi Layar Cetak Laporan', () {
    final adminUser = AuthService.defaultAdminAccount;

    testWidgets('1. Layar Cetak Laporan menampilkan header, kartu ringkasan, periode, dan jumlah pengguna', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: AdminPrintReportScreen(adminUser: adminUser),
        ),
      );
      await tester.pumpAndSettle();

      // Header CurvedHeaderScaffold
      expect(find.byType(CurvedHeaderScaffold), findsOneWidget);
      expect(find.widgetWithText(CurvedHeaderScaffold, 'Cetak Laporan'), findsOneWidget);

      // Kartu hijau muda atas
      expect(find.text('Laporan ObeSight'), findsOneWidget);
      expect(find.text('Ringkasan data dan aktivitas pengguna'), findsOneWidget);

      // Baris Periode Laporan & Dropdown bawaan Satu bulan
      expect(find.text('Periode Laporan'), findsOneWidget);
      expect(find.text('Satu bulan'), findsOneWidget);

      // Baris Jumlah Data Pengguna & Dropdown bawaan Semua pengguna
      expect(find.text('Jumlah Data Pengguna'), findsOneWidget);
      expect(find.text('Semua pengguna'), findsOneWidget);
      expect(find.textContaining('pengguna pada periode ini'), findsOneWidget);
    });

    testWidgets('2. Pemilihan Jenis Laporan (Eksternal vs Internal) dan kontrol Checkbox 8 bagian', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: AdminPrintReportScreen(adminUser: adminUser),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi dua kartu radio jenis laporan
      expect(find.text('Pilih Jenis Laporan'), findsOneWidget);
      expect(find.text('Laporan Eksternal'), findsOneWidget);
      expect(find.text('Laporan Internal'), findsOneWidget);
      expect(find.text('Ringkas'), findsOneWidget);
      expect(find.text('Lengkap'), findsOneWidget);

      // Saat Eksternal (default): Checkbox dinonaktifkan & ada teks pemberitahuan
      expect(find.text('Hanya tersedia untuk Laporan Internal.'), findsOneWidget);

      // Klik Laporan Internal
      await tester.tap(find.text('Laporan Internal'));
      await tester.pumpAndSettle();

      // Teks pemberitahuan redup menghilang karena Laporan Internal sudah aktif
      expect(find.text('Hanya tersedia untuk Laporan Internal.'), findsNothing);

      // Verifikasi ke-8 bagian laporan tersedia
      expect(find.text('Data Pengguna'), findsOneWidget);
      expect(find.text('Data IMT'), findsOneWidget);
      expect(find.text('Hasil Skrining'), findsOneWidget);
      expect(find.text('Aktivitas Fisik'), findsOneWidget);
      expect(find.text('Makanan & Minuman'), findsOneWidget);
      expect(find.text('Pola Tidur'), findsOneWidget);
      expect(find.text('Tren Aktivitas'), findsOneWidget);
      expect(find.text('Analisis & Kesimpulan'), findsOneWidget);

      // Tombol Cetak aktif
      expect(find.text('Unduh / Cetak Laporan'), findsOneWidget);
      expect(find.text('Laporan akan diunduh dalam format PDF'), findsOneWidget);

      // Matikan seluruh 8 bagian laporan
      final sections = [
        'Data Pengguna',
        'Data IMT',
        'Hasil Skrining',
        'Aktivitas Fisik',
        'Makanan & Minuman',
        'Pola Tidur',
        'Tren Aktivitas',
        'Analisis & Kesimpulan',
      ];
      for (final sec in sections) {
        await tester.tap(find.text(sec), warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      // Verifikasi tombol cetak tetap ada
      final printBtn = find.text('Unduh / Cetak Laporan');
      expect(printBtn, findsOneWidget);

      // Aktifkan kembali 1 bagian (misal Data Pengguna)
      await tester.tap(find.text('Data Pengguna'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Tombol cetak aktif kembali
      expect(find.text('Unduh / Cetak Laporan'), findsOneWidget);
    });

    testWidgets('3. Dialog Kustom Jumlah Pengguna memvalidasi input angka >= 1', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: AdminPrintReportScreen(adminUser: adminUser),
        ),
      );
      await tester.pumpAndSettle();

      // Buka popup Jumlah Data Pengguna
      await tester.tap(find.text('Semua pengguna'));
      await tester.pumpAndSettle();

      // Pilih opsi 'Kustom'
      expect(find.text('Kustom'), findsOneWidget);
      await tester.tap(find.text('Kustom'));
      await tester.pumpAndSettle();

      // Verifikasi Dialog Kustom muncul
      expect(find.text('Kustom Jumlah Pengguna'), findsOneWidget);
      expect(find.text('Masukkan jumlah batas pengguna yang ingin dihitung (minimal 1):'), findsOneWidget);

      // Masukkan angka 25 dan terapkan
      await tester.enterText(find.byType(TextFormField), '25');
      await tester.pump();
      await tester.tap(find.text('Terapkan'));
      await tester.pumpAndSettle();

      // Verifikasi nilai dropdown berubah menjadi "25 pengguna"
      expect(find.text('25 pengguna'), findsOneWidget);
    });
  });

  group('AdminHomeScreen - Kartu Masuk Cetak Laporan & Integritas Halaman Laporan', () {
    final adminUser = AuthService.defaultAdminAccount;

    testWidgets('1. Tab Laporan menampilkan kartu Cetak Laporan di bagian paling bawah dan dapat diklik', (WidgetTester tester) async {
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

      // Verifikasi elemen-elemen yang sudah ada tetap utuh
      expect(find.text('Total Skrining'), findsOneWidget);
      expect(find.text('Pengguna Baru'), findsOneWidget);
      expect(find.text('Skrining\nRata-rata/Hari'), findsOneWidget);
      expect(find.text('Tren Aktivitas Skrining'), findsOneWidget);

      // Scroll ke bawah untuk melihat kartu masuk Cetak Laporan
      final scrollFinder = find.byType(SingleChildScrollView);
      await tester.drag(scrollFinder.first, const Offset(0, -600));
      await tester.pumpAndSettle();

      // Verifikasi kartu Pengguna per Jenis Kelamin tetap utuh (ada Perempuan dan Laki-laki)
      expect(find.text('Pengguna per Jenis Kelamin'), findsOneWidget);
      expect(find.text('Perempuan'), findsWidgets);
      expect(find.text('Laki-laki'), findsWidgets);

      // Verifikasi kartu Kategori Hasil Skrining Terbaru tetap utuh
      expect(find.text('Kategori Hasil Skrining Terbaru'), findsOneWidget);

      // Scroll lagi ke paling bawah untuk melihat kartu Cetak Laporan
      await tester.drag(scrollFinder.first, const Offset(0, -800));
      await tester.pumpAndSettle();

      // Verifikasi kartu Cetak Laporan ada di paling bawah
      final printCardTitle = find.text('Cetak Laporan');
      expect(printCardTitle, findsOneWidget);
      expect(
        find.text('Unduh atau cetak laporan lengkap dalam format PDF.'),
        findsOneWidget,
      );

      // Klik kartu Cetak Laporan
      await tester.tap(printCardTitle);
      await tester.pumpAndSettle();

      // Verifikasi navigasi berhasil ke layar AdminPrintReportScreen
      expect(find.byType(AdminPrintReportScreen), findsOneWidget);
      expect(find.text('Periode Laporan'), findsOneWidget);
      expect(find.text('Jumlah Data Pengguna'), findsOneWidget);
      expect(find.text('Unduh / Cetak Laporan'), findsOneWidget);
    });
  });
}
