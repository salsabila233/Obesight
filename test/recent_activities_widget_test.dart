import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:obesight/screens/admin/admin_activity_list_screen.dart';
import 'package:obesight/screens/home/admin_home_screen.dart';
import 'package:obesight/services/auth_service.dart';
import 'package:obesight/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Verifikasi Navigasi & Tampilan Cari-Filter Riwayat Aktivitas Persis Halaman Artikel', () {
    final adminUser = AuthService.defaultAdminAccount;

    testWidgets('1. Tombol "Lihat semua" membuka Halaman Riwayat Aktivitas (AdminActivityListScreen), BUKAN daftar pengguna', (WidgetTester tester) async {
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

      // Verifikasi Widget Aktivitas Terbaru & Tombol Lihat semua hadir
      expect(find.text('Aktivitas Terbaru'), findsOneWidget);
      final lihatSemuaFinder = find.text('Lihat semua');
      expect(lihatSemuaFinder, findsOneWidget);

      // Scroll ke tombol "Lihat semua" jika diperlukan
      await tester.ensureVisible(lihatSemuaFinder);
      await tester.pumpAndSettle();

      // Klik tombol "Lihat semua"
      await tester.tap(lihatSemuaFinder);
      await tester.pumpAndSettle();

      // Memastikan halaman yang terbuka adalah Halaman Khusus AdminActivityListScreen
      expect(find.byType(AdminActivityListScreen), findsOneWidget);
      expect(find.text('Riwayat Aktivitas'), findsOneWidget);

      // Memastikan BUKAN daftar pengguna (AdminUserListScreen)
      expect(find.text('Daftar Pengguna'), findsNothing);

      // Verifikasi 3 Tab Kategori: Semua, Pengguna, Artikel
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Pengguna'), findsWidgets);
      expect(find.text('Artikel'), findsWidgets);

      // Search field "Cari" hadir di bawah tab filter
      expect(find.widgetWithText(TextField, 'Cari'), findsOneWidget);

      // Verifikasi tombol kembali (back button) berfungsi
      final backButtonFinder = find.byIcon(Icons.arrow_back_ios_new_rounded);
      expect(backButtonFinder, findsOneWidget);
      await tester.tap(backButtonFinder);
      await tester.pumpAndSettle();

      // Kembali ke beranda admin
      expect(find.byType(AdminActivityListScreen), findsNothing);
      expect(find.text('Aktivitas Terbaru'), findsOneWidget);
    });

    testWidgets('2. Item daftar aktivitas terbaru tidak memiliki ikon panah (">") dan nonaktif (statis)', (WidgetTester tester) async {
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

      // Pastikan ada item aktivitas
      final activityItemFinder = find.text('Pengguna baru terdaftar');
      expect(activityItemFinder, findsWidgets);

      // Cari baris item aktivitas
      final rowFinder = find.ancestor(of: activityItemFinder.first, matching: find.byType(Row)).first;

      // Temukan semua icon di dalam item aktivitas
      // Ikon panah kanan (">") tidak boleh ada di baris item aktivitas
      final chevronFinder = find.descendant(
        of: rowFinder,
        matching: find.byIcon(Icons.chevron_right_rounded),
      );
      expect(chevronFinder, findsNothing);

      // Pastikan baris item tidak dibungkus oleh InkWell aktif (murni statis)
      final inkWellOnItem = find.descendant(
        of: find.ancestor(of: activityItemFinder.first, matching: find.byType(Material)).first,
        matching: find.byType(InkWell),
      );
      expect(inkWellOnItem, findsNothing);
    });

    testWidgets('3. Tab Filter 3 Kategori (Semua, Pengguna, Artikel) & Kolom Pencarian "Cari" berfungsi sesuai spesifikasi', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminActivityListScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verifikasi posisi: Tab Filter di atas, Kolom Pencarian di bawahnya
      final filterSemua = find.text('Semua');
      final filterPengguna = find.text('Pengguna');
      final filterArtikel = find.text('Artikel');
      final searchBar = find.byType(TextField);

      expect(filterSemua, findsOneWidget);
      expect(filterPengguna, findsOneWidget);
      expect(filterArtikel, findsOneWidget);
      expect(searchBar, findsOneWidget);

      final filterSemuaY = tester.getTopLeft(filterSemua).dy;
      final searchBarY = tester.getTopLeft(searchBar).dy;
      // Tab filter harus berada di atas Kolom Pencarian
      expect(filterSemuaY < searchBarY, isTrue);

      // 2. Tab "Semua" menampilkan seluruh riwayat aktivitas
      expect(find.text('Perekaman Tidur Otomatis'), findsOneWidget);

      // 3. Klik tab "Pengguna": hanya memfilter daftar aktivitas terkait pengguna
      await tester.tap(filterPengguna);
      await tester.pumpAndSettle();

      // Aktivitas pengguna tampil (atau empty state jika belum ada data stream pengguna)
      expect(find.text('Perekaman Tidur Otomatis'), findsNothing);

      // 4. Klik tab "Artikel": hanya memfilter daftar aktivitas terkait artikel
      await tester.tap(filterArtikel);
      await tester.pumpAndSettle();

      expect(find.text('Perekaman Tidur Otomatis'), findsNothing);

      // 5. Kembali ke tab "Semua" dan uji Kolom Pencarian (Search Bar)
      await tester.tap(filterSemua);
      await tester.pumpAndSettle();

      expect(find.text('Perekaman Tidur Otomatis'), findsOneWidget);

      await tester.enterText(searchBar, 'Tidur');
      await tester.pumpAndSettle();

      expect(find.text('Perekaman Tidur Otomatis'), findsOneWidget);

      // 6. Pencarian kata kunci yang tidak ada
      await tester.enterText(searchBar, 'KeywordNotExist999');
      await tester.pumpAndSettle();

      expect(find.text('Belum ada riwayat aktivitas'), findsOneWidget);
    });
  });
}
