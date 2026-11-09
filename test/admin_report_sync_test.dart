import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:obesight/models/screening_history_model.dart';
import 'package:obesight/models/user_model.dart';
import 'package:obesight/screens/home/admin_home_screen.dart';
import 'package:obesight/screens/skrining/skrining_models.dart';
import 'package:obesight/services/admin_report_service.dart';
import 'package:obesight/services/auth_service.dart';
import 'package:obesight/theme/app_theme.dart';
import 'package:obesight/widgets/curved_header_scaffold.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AdminReportService.instance.resetMockData();
  });

  tearDown(() {
    AdminReportService.instance.resetMockData();
  });

  group('TUGAS 4.1: Unit Test Fungsi Perhitungan & Validasi Dokumen', () {
    test('1. Total skrining, batas tanggal awal/akhir inklusif, rata-rata/hari', () {
      final user = UserModel(
        id: 'u_1',
        name: 'Pasien Satu',
        email: 'p1@mail.com',
        username: 'p1',
        role: UserRole.user,
        gender: 'Perempuan',
        createdAt: DateTime(2026, 8, 1),
      );

      final screenings = [
        ScreeningHistoryItem(
          id: 's_start',
          userId: 'u_1',
          date: DateTime(2026, 8, 1, 0, 0, 0),
          bmi: 22.0,
          risk: 'Rendah',
          category: 'Normal Weight',
          skriningData: SkriningData()..aiCategoryTitle = 'Normal Weight',
        ),
        ScreeningHistoryItem(
          id: 's_mid',
          userId: 'u_1',
          date: DateTime(2026, 8, 5, 12, 30, 0),
          bmi: 24.0,
          risk: 'Sedang',
          category: 'Overweight Level 1',
          skriningData: SkriningData()..aiCategoryTitle = 'Overweight Level 1',
        ),
        ScreeningHistoryItem(
          id: 's_end',
          userId: 'u_1',
          date: DateTime(2026, 8, 10, 23, 59, 59),
          bmi: 27.5,
          risk: 'Tinggi',
          category: 'Overweight Level 2',
          skriningData: SkriningData()..aiCategoryTitle = 'Overweight Level 2',
        ),
        ScreeningHistoryItem(
          id: 's_outside_before',
          userId: 'u_1',
          date: DateTime(2026, 7, 31, 23, 59, 59),
          bmi: 22.0,
          risk: 'Rendah',
          category: 'Normal Weight',
          skriningData: SkriningData(),
        ),
        ScreeningHistoryItem(
          id: 's_outside_after',
          userId: 'u_1',
          date: DateTime(2026, 8, 11, 0, 0, 1),
          bmi: 22.0,
          risk: 'Rendah',
          category: 'Normal Weight',
          skriningData: SkriningData(),
        ),
      ];

      final report = AdminReportService.computeReportData(
        users: [user],
        allScreenings: screenings,
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 10),
      );

      // Rentang 1-10 Agustus = 10 hari
      expect(report.totalScreenings, 3);
      // Rata-rata per hari: 3 / 10 = 0.3 -> round() = 0
      expect(report.screeningsPerDay, 0);
      expect(report.exactScreeningsPerDay, closeTo(0.3, 0.01));
    });

    test('2. Persentase perubahan dengan periode lalu bernilai 0 (anti divide-by-zero)', () {
      final badgeFromZero = AdminReportService.calculateChangeBadge(15, 0);
      expect(badgeFromZero.percentage, 0.0);
      expect(badgeFromZero.badgeText, '0%');
      expect(badgeFromZero.hasArrow, isTrue);
      expect(badgeFromZero.isUp, isTrue);

      final badgeZeroToZero = AdminReportService.calculateChangeBadge(0, 0);
      expect(badgeZeroToZero.percentage, 0.0);
      expect(badgeZeroToZero.badgeText, '0%');
      expect(badgeZeroToZero.hasArrow, isFalse);
    });

    test('3. Distribusi donat konsisten dengan Total Skrining', () {
      final user = UserModel(
        id: 'u_all',
        name: 'Pasien Serbaguna',
        email: 'ps@mail.com',
        username: 'ps',
        role: UserRole.user,
        gender: 'Laki-laki',
        createdAt: DateTime(2026, 8, 1),
      );

      final screenings = [
        ScreeningHistoryItem(
          id: 'scr_iw',
          userId: 'u_all',
          date: DateTime(2026, 8, 2),
          bmi: 17.5,
          risk: 'Rendah',
          category: 'Insufficient Weight',
          skriningData: SkriningData(),
        ),
        ScreeningHistoryItem(
          id: 'scr_nw',
          userId: 'u_all',
          date: DateTime(2026, 8, 3),
          bmi: 21.0,
          risk: 'Rendah',
          category: 'Normal Weight',
          skriningData: SkriningData(),
        ),
        ScreeningHistoryItem(
          id: 'scr_ow1',
          userId: 'u_all',
          date: DateTime(2026, 8, 4),
          bmi: 24.5,
          risk: 'Sedang',
          category: 'Overweight Level 1',
          skriningData: SkriningData(),
        ),
        ScreeningHistoryItem(
          id: 'scr_ow2',
          userId: 'u_all',
          date: DateTime(2026, 8, 5),
          bmi: 28.0,
          risk: 'Sedang',
          category: 'Overweight Level 2',
          skriningData: SkriningData(),
        ),
        ScreeningHistoryItem(
          id: 'scr_ob1',
          userId: 'u_all',
          date: DateTime(2026, 8, 6),
          bmi: 32.0,
          risk: 'Tinggi',
          category: 'Obesity Type 1',
          skriningData: SkriningData(),
        ),
        ScreeningHistoryItem(
          id: 'scr_ob2',
          userId: 'u_all',
          date: DateTime(2026, 8, 7),
          bmi: 37.0,
          risk: 'Tinggi',
          category: 'Obesity Type 2',
          skriningData: SkriningData(),
        ),
        ScreeningHistoryItem(
          id: 'scr_ob3',
          userId: 'u_all',
          date: DateTime(2026, 8, 8),
          bmi: 42.0,
          risk: 'Tinggi',
          category: 'Obesity Type 3',
          skriningData: SkriningData(),
        ),
      ];

      final report = AdminReportService.computeReportData(
        users: [user],
        allScreenings: screenings,
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 10),
      );

      expect(report.totalScreenings, 7);
      final sumDonut = report.screeningDistributionCounts.values.fold(0, (a, b) => a + b);
      expect(sumDonut, report.totalScreenings);
    });

    test('4. Jenis kelamin dengan variasi penulisan, kosong, dan konsistensi total pengguna', () {
      final testUsers = [
        UserModel(
          id: 'u_p1',
          name: 'Siti',
          email: 'siti@mail.com',
          username: 'siti',
          role: UserRole.user,
          gender: '  wanita  ',
          createdAt: DateTime(2026, 8, 2),
        ),
        UserModel(
          id: 'u_p2',
          name: 'Dewi',
          email: 'dewi@mail.com',
          username: 'dewi',
          role: UserRole.user,
          gender: 'female',
          createdAt: DateTime(2026, 8, 3),
        ),
        UserModel(
          id: 'u_l1',
          name: 'Ahmad',
          email: 'ahmad@mail.com',
          username: 'ahmad',
          role: UserRole.user,
          gender: 'pria',
          createdAt: DateTime(2026, 8, 4),
        ),
        UserModel(
          id: 'u_u1',
          name: 'Anonim Satu',
          email: 'anon1@mail.com',
          username: 'anon1',
          role: UserRole.user,
          gender: null,
          createdAt: DateTime(2026, 8, 5),
        ),
        UserModel(
          id: 'u_u2',
          name: 'Anonim Dua',
          email: 'anon2@mail.com',
          username: 'anon2',
          role: UserRole.user,
          gender: '   ',
          createdAt: DateTime(2026, 8, 6),
        ),
      ];

      final report = AdminReportService.computeReportData(
        users: testUsers,
        allScreenings: [],
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 10),
      );

      expect(report.totalPatients, 5);
      expect(report.genderCounts[AdminReportGender.perempuan], 2);
      expect(report.genderCounts[AdminReportGender.lakiLaki], 1);
      expect(report.genderCounts[AdminReportGender.tidakDiketahui], 2);

      final totalGender = report.genderCounts[AdminReportGender.perempuan]! +
          report.genderCounts[AdminReportGender.lakiLaki]! +
          report.genderCounts[AdminReportGender.tidakDiketahui]!;
      expect(totalGender, report.totalPatients);
    });

    test('5. Pengguna dengan banyak skrining dihitung satu kali berdasarkan skrining terbarunya', () {
      final user = UserModel(
        id: 'u_multi',
        name: 'Multi Skrining User',
        email: 'multi@mail.com',
        username: 'multi',
        role: UserRole.user,
        gender: 'Perempuan',
        createdAt: DateTime(2026, 8, 1),
      );

      final screenings = [
        ScreeningHistoryItem(
          id: 's_old',
          userId: 'u_multi',
          date: DateTime(2026, 8, 2),
          bmi: 20.0,
          risk: 'Rendah',
          category: 'Normal Weight',
          skriningData: SkriningData(),
        ),
        ScreeningHistoryItem(
          id: 's_newer',
          userId: 'u_multi',
          date: DateTime(2026, 8, 5),
          bmi: 24.0,
          risk: 'Sedang',
          category: 'Overweight Level 1',
          skriningData: SkriningData(),
        ),
        ScreeningHistoryItem(
          id: 's_latest',
          userId: 'u_multi',
          date: DateTime(2026, 8, 8),
          bmi: 31.0,
          risk: 'Tinggi',
          category: 'Obesity Type 1',
          skriningData: SkriningData(),
        ),
      ];

      final report = AdminReportService.computeReportData(
        users: [user],
        allScreenings: screenings,
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 10),
      );

      expect(report.totalPatients, 1);
      expect(report.totalScreenedPatients, 1);
      // Hasil kategori terbaru harus Obesity Type 1
      expect(report.obesityCounts[ObesityCategory.obesityType1], 1);
      expect(report.obesityCounts[ObesityCategory.overweightLevel1], 0);
      expect(report.obesityCounts[ObesityCategory.normalWeight], 0);

      final sumObesity = report.obesityCounts.values.fold(0, (a, b) => a + b);
      expect(sumObesity, report.totalPatients);
    });

    test('6. Dokumen tidak valid dan duplikat dilewati dengan aman tanpa crash', () {
      final users = [
        UserModel(
          id: 'u_valid',
          name: 'Valid User',
          email: 'valid@mail.com',
          username: 'valid',
          role: UserRole.user,
          gender: 'Laki-laki',
          createdAt: DateTime(2026, 8, 1),
        ),
        UserModel(
          id: 'u_valid', // Duplikat ID
          name: 'Valid User Duplikat',
          email: 'valid_dup@mail.com',
          username: 'valid_dup',
          role: UserRole.user,
          gender: 'Laki-laki',
          createdAt: DateTime(2026, 8, 1),
        ),
        UserModel(
          id: '', // ID kosong tidak valid
          name: 'Invalid User',
          email: 'inv@mail.com',
          username: 'inv',
          role: UserRole.user,
          gender: 'Laki-laki',
        ),
      ];

      final screenings = [
        ScreeningHistoryItem(
          id: 's_valid_1',
          userId: 'u_valid',
          date: DateTime(2026, 8, 2),
          bmi: 22.0,
          risk: 'Rendah',
          category: 'Normal Weight',
          skriningData: SkriningData(),
        ),
        ScreeningHistoryItem(
          id: 's_valid_1', // Duplikat ID skrining
          userId: 'u_valid',
          date: DateTime(2026, 8, 3),
          bmi: 22.0,
          risk: 'Rendah',
          category: 'Normal Weight',
          skriningData: SkriningData(),
        ),
        ScreeningHistoryItem(
          id: '', // ID kosong
          userId: 'u_valid',
          date: DateTime(2026, 8, 4),
          bmi: 22.0,
          risk: 'Rendah',
          category: 'Normal Weight',
          skriningData: SkriningData(),
        ),
      ];

      final report = AdminReportService.computeReportData(
        users: users,
        allScreenings: screenings,
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 10),
      );

      // Hanya 1 pengguna dan 1 skrining valid yang dihitung
      expect(report.totalPatients, 1);
      expect(report.totalScreenings, 1);
    });
  });

  group('TUGAS 4.2: Tes Sinkronisasi Reaktif Stream Data Laporan', () {
    test('Sinkronisasi reaktif: tambah skrining, ubah gender, hapus data, ubah filter, data kosong', () async {
      final service = AdminReportService.instance;

      final initialUsers = [
        UserModel(
          id: 'usr_alpha',
          name: 'Alpha Pasien',
          email: 'alpha@mail.com',
          username: 'alpha',
          role: UserRole.user,
          gender: 'Perempuan',
          createdAt: DateTime(2026, 8, 5),
        ),
        UserModel(
          id: 'usr_beta',
          name: 'Beta Pasien',
          email: 'beta@mail.com',
          username: 'beta',
          role: UserRole.user,
          gender: 'Laki-laki',
          createdAt: DateTime(2026, 8, 6),
        ),
      ];

      final initialScreenings = [
        ScreeningHistoryItem(
          id: 'scr_a1',
          userId: 'usr_alpha',
          date: DateTime(2026, 8, 7),
          bmi: 22.0,
          risk: 'Rendah',
          category: 'Normal Weight',
          skriningData: SkriningData(),
        ),
      ];

      service.setMockData(users: initialUsers, screenings: initialScreenings);

      final stream = service.streamReportData(
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 15),
      );

      final snapshots = <AdminReportData>[];
      final subscription = stream.listen((d) => snapshots.add(d));

      // Initial state
      await Future.delayed(const Duration(milliseconds: 10));
      expect(snapshots.length, 1);
      expect(snapshots.last.totalScreenings, 1);
      expect(snapshots.last.totalPatients, 2);
      expect(snapshots.last.genderCounts[AdminReportGender.perempuan], 1);
      expect(snapshots.last.genderCounts[AdminReportGender.lakiLaki], 1);

      // (a) Tambah skrining baru: angka Total Skrining bertambah
      service.addMockScreening(
        ScreeningHistoryItem(
          id: 'scr_b1',
          userId: 'usr_beta',
          date: DateTime(2026, 8, 8),
          bmi: 26.0,
          risk: 'Sedang',
          category: 'Overweight Level 1',
          skriningData: SkriningData(),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 10));
      expect(snapshots.last.totalScreenings, 2);

      // (b) Ubah jenis kelamin pengguna: jumlah Perempuan/Laki-laki berubah
      final updatedAlpha = UserModel(
        id: 'usr_alpha',
        name: 'Alpha Pasien',
        email: 'alpha@mail.com',
        username: 'alpha',
        role: UserRole.user,
        gender: 'Laki-laki', // Diubah dari Perempuan ke Laki-laki
        createdAt: DateTime(2026, 8, 5),
      );
      service.updateMockUser(updatedAlpha);
      await Future.delayed(const Duration(milliseconds: 10));
      expect(snapshots.last.genderCounts[AdminReportGender.perempuan], 0);
      expect(snapshots.last.genderCounts[AdminReportGender.lakiLaki], 2);

      // (c) Hapus data: angka berkurang
      service.removeMockScreening('scr_a1');
      await Future.delayed(const Duration(milliseconds: 10));
      expect(snapshots.last.totalScreenings, 1);

      // (d) Ubah filter tanggal: angka mengikuti
      final narrowReport = await service.fetchAdminReportData(
        startDate: DateTime(2026, 8, 10),
        endDate: DateTime(2026, 8, 20),
      );
      // Skrining scr_b1 pada tanggal 8 Agustus di luar rentang 10-20 Agustus
      expect(narrowReport.totalScreenings, 0);

      // (e) Data kosong menampilkan state kosong tanpa error
      service.setMockData(users: [], screenings: []);
      await Future.delayed(const Duration(milliseconds: 10));
      expect(snapshots.last.isEmpty, isTrue);
      expect(snapshots.last.totalPatients, 0);
      expect(snapshots.last.totalScreenings, 0);

      await subscription.cancel();
    });
  });

  group('TUGAS 4.3: Widget Test Tampilan & State Halaman Laporan', () {
    final adminUser = AuthService.defaultAdminAccount;

    testWidgets('Laporan menampilkan angka dari data uji, header pinned & radius 28 tetap persis', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final service = AdminReportService.instance;
      service.setMockData(
        users: [
          UserModel(
            id: 'u_test_1',
            name: 'Pasien Uji',
            email: 'pasienuji@mail.com',
            username: 'pasienuji',
            role: UserRole.user,
            gender: 'Perempuan',
            createdAt: DateTime(2026, 8, 5),
          ),
        ],
        screenings: [
          ScreeningHistoryItem(
            id: 'scr_test_1',
            userId: 'u_test_1',
            date: DateTime(2026, 8, 10),
            bmi: 21.5,
            risk: 'Rendah',
            category: 'Normal Weight',
            skriningData: SkriningData(),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: AdminHomeScreen(user: adminUser, initialIndex: 3),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Verifikasi header CurvedHeaderScaffold pinned title "Laporan"
      expect(find.byType(CurvedHeaderScaffold), findsOneWidget);
      expect(find.widgetWithText(CurvedHeaderScaffold, 'Laporan'), findsOneWidget);

      // 2. Verifikasi radius 28 lembaran putih/sheet
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

      // 3. Verifikasi RefreshIndicator terpasang
      expect(find.byType(RefreshIndicator), findsOneWidget);

      // 4. Verifikasi komponen kartu ringkasan, donat, jenis kelamin, dan kategori
      expect(find.text('Total Skrining'), findsOneWidget);
      expect(find.text('Pengguna Baru'), findsOneWidget);
      expect(find.textContaining('Rata-rata/Hari'), findsOneWidget);
      expect(find.text('Distribusi Hasil Skrining'), findsOneWidget);
      expect(find.text('Total Pengguna (Pasien)'), findsOneWidget);
      expect(find.text('Pengguna per Jenis Kelamin'), findsOneWidget);
      expect(find.text('Kategori Hasil Skrining Terbaru'), findsOneWidget);
    });

    testWidgets('State kosong menampilkan teks dan icon tanpa error', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final service = AdminReportService.instance;
      service.setMockData(users: [], screenings: []);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: AdminHomeScreen(user: adminUser, initialIndex: 3),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verifikasi empty state ter-render
      expect(find.byIcon(Icons.inbox_rounded), findsOneWidget);
      expect(find.text('Belum ada data pengguna pada rentang ini'), findsOneWidget);
      expect(find.text('Silakan pilih rentang tanggal lain untuk memuat data.'), findsOneWidget);
    });
  });
}
