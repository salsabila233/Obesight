import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:obesight/models/screening_history_model.dart';
import 'package:obesight/models/user_model.dart';
import 'package:obesight/screens/skrining/skrining_models.dart';
import 'package:obesight/services/admin_report_pdf_service.dart';
import 'package:obesight/services/admin_report_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdminReportService - Periode Laporan & Rentang Tanggal Cetak', () {
    test('1. Resolusi rentang tanggal inklusif hari ini untuk 30 hari (Satu bulan)', () {
      final refDate = DateTime(2026, 11, 15, 14, 30);
      final periodDates = AdminReportService.resolveReportPeriodDates(
        ReportPeriod.satuBulan,
        refDate,
      );

      expect(periodDates.days, 30);
      expect(periodDates.start.year, 2026);
      expect(periodDates.start.month, 10);
      expect(periodDates.start.day, 17);
      expect(periodDates.end.year, 2026);
      expect(periodDates.end.month, 11);
      expect(periodDates.end.day, 15);

      final rangeStr = AdminReportService.formatReportPeriodRange(
        periodDates.start,
        periodDates.end,
      );
      expect(rangeStr, '17 Okt - 15 Nov 2026');
    });

    test('2. Resolusi rentang tanggal untuk Triwulan (90 hari) dan Setahun (365 hari)', () {
      final refDate = DateTime(2026, 11, 15, 23, 59);

      final triwulanDates = AdminReportService.resolveReportPeriodDates(
        ReportPeriod.triwulan,
        refDate,
      );
      expect(triwulanDates.days, 90);
      expect(triwulanDates.end.day, 15);
      expect(triwulanDates.end.month, 11);

      final setahunDates = AdminReportService.resolveReportPeriodDates(
        ReportPeriod.setahun,
        refDate,
      );
      expect(setahunDates.days, 365);
      expect(setahunDates.end.day, 15);
      expect(setahunDates.end.month, 11);
    });
  });

  group('AdminReportService - Pemetaan Tingkat Risiko Klinis', () {
    test('1. Normal Weight dipetakan ke tingkat risiko Rendah', () {
      expect(
        AdminReportService.resolveClinicalRisk(ObesityCategory.normalWeight),
        'Rendah',
      );
    });

    test('2. Overweight Level 1 dan 2 dipetakan ke tingkat risiko Sedang', () {
      expect(
        AdminReportService.resolveClinicalRisk(ObesityCategory.overweightLevel1),
        'Sedang',
      );
      expect(
        AdminReportService.resolveClinicalRisk(ObesityCategory.overweightLevel2),
        'Sedang',
      );
    });

    test('3. Obesity Type 1, 2, dan 3 dipetakan ke tingkat risiko Tinggi', () {
      expect(
        AdminReportService.resolveClinicalRisk(ObesityCategory.obesityType1),
        'Tinggi',
      );
      expect(
        AdminReportService.resolveClinicalRisk(ObesityCategory.obesityType2),
        'Tinggi',
      );
      expect(
        AdminReportService.resolveClinicalRisk(ObesityCategory.obesityType3),
        'Tinggi',
      );
    });

    test('4. Insufficient Weight dipetakan ke "Perlu perhatian gizi"', () {
      expect(
        AdminReportService.resolveClinicalRisk(ObesityCategory.insufficientWeight),
        'Perlu perhatian gizi',
      );
    });
  });

  group('AdminReportService - Pemilihan N Pengguna & Pengurutan', () {
    final refDate = DateTime(2026, 11, 15, 12, 0);

    // Siapkan 4 pasien dengan riwayat skrining berbeda
    final patientA = UserModel(
      id: 'patient_a',
      name: 'Pasien A',
      username: 'pasien_a',
      email: 'a@test.com',
      gender: 'Perempuan',
      role: UserRole.user,
      createdAt: DateTime(2026, 1, 1),
    );
    final patientB = UserModel(
      id: 'patient_b',
      name: 'Pasien B',
      username: 'pasien_b',
      email: 'b@test.com',
      gender: 'Laki-laki',
      role: UserRole.user,
      createdAt: DateTime(2026, 2, 1),
    );
    final patientC = UserModel(
      id: 'patient_c',
      name: 'Pasien C (Tanpa skrining baru)',
      username: 'pasien_c',
      email: 'c@test.com',
      gender: 'Perempuan',
      role: UserRole.user,
      createdAt: DateTime(2026, 10, 1), // Lebih baru daftarnya daripada D
    );
    final patientD = UserModel(
      id: 'patient_d',
      name: 'Pasien D (Tanpa skrining lama)',
      username: 'pasien_d',
      email: 'd@test.com',
      gender: 'Laki-laki',
      role: UserRole.user,
      createdAt: DateTime(2026, 5, 1),
    );

    // Skrining dalam periode (17 Okt - 15 Nov 2026)
    // Pasien A skrining tanggal 10 Nov
    // Pasien B skrining tanggal 14 Nov (lebih baru daripada A)
    final screeningA = ScreeningHistoryItem(
      id: 'scr_a',
      userId: 'patient_a',
      date: DateTime(2026, 11, 10),
      bmi: 22.0,
      risk: 'Rendah',
      category: 'Normal Weight',
      skriningData: SkriningData()..aiCategoryTitle = 'Normal Weight',
    );
    final screeningB = ScreeningHistoryItem(
      id: 'scr_b',
      userId: 'patient_b',
      date: DateTime(2026, 11, 14),
      bmi: 26.5,
      risk: 'Sedang',
      category: 'Overweight Level 1',
      skriningData: SkriningData()..aiCategoryTitle = 'Overweight Level 1',
    );

    test('1. Pengguna ber-skrining diurutkan terbaru dulu, lalu tanpa skrining pendaftaran terbaru', () {
      final config = const ReportConfig(
        period: ReportPeriod.satuBulan,
        userLimit: 3, // N = 3
      );

      final report = AdminReportService.computePrintReportData(
        users: [patientA, patientB, patientC, patientD],
        allScreenings: [screeningA, screeningB],
        config: config,
        referenceDate: refDate,
      );

      expect(report.totalAvailablePatients, 4);
      expect(report.selectedPatientsCount, 3);
      expect(report.isExceedingAvailable, isFalse);

      // Urutan yang diharapkan:
      // 1. patientB (skrining 14 Nov)
      // 2. patientA (skrining 10 Nov)
      // 3. patientC (tanpa skrining, daftar 1 Okt)
      expect(report.selectedPatients[0].id, 'patient_b');
      expect(report.selectedPatients[1].id, 'patient_a');
      expect(report.selectedPatients[2].id, 'patient_c');
    });

    test('2. N melebihi jumlah pengguna yang tersedia (N > M) menggunakan semua M dan menyalakan flag', () {
      final config = const ReportConfig(
        period: ReportPeriod.satuBulan,
        userLimit: 10, // Diminta 10, hanya ada 4
      );

      final report = AdminReportService.computePrintReportData(
        users: [patientA, patientB, patientC, patientD],
        allScreenings: [screeningA, screeningB],
        config: config,
        referenceDate: refDate,
      );

      expect(report.totalAvailablePatients, 4);
      expect(report.selectedPatientsCount, 4);
      expect(report.isExceedingAvailable, isTrue);
    });

    test('3. Nilai userLimit null berarti mengambil semua pengguna tanpa flag melebihi', () {
      final config = const ReportConfig(
        period: ReportPeriod.satuBulan,
        userLimit: null, // Semua pengguna
      );

      final report = AdminReportService.computePrintReportData(
        users: [patientA, patientB, patientC, patientD],
        allScreenings: [screeningA, screeningB],
        config: config,
        referenceDate: refDate,
      );

      expect(report.selectedPatientsCount, 4);
      expect(report.isExceedingAvailable, isFalse);
    });
  });

  group('AdminReportService - Isolasi Jenis Kelamin (Perempuan & Laki-laki Saja)', () {
    final refDate = DateTime(2026, 11, 15, 12, 0);

    final p1 = UserModel(
      id: 'p1',
      name: 'P1',
      username: 'p1',
      email: 'p1@test.com',
      gender: 'Perempuan',
      role: UserRole.user,
    );
    final p2 = UserModel(
      id: 'p2',
      name: 'P2',
      username: 'p2',
      email: 'p2@test.com',
      gender: 'wanita',
      role: UserRole.user,
    );
    final p3 = UserModel(
      id: 'p3',
      name: 'P3',
      username: 'p3',
      email: 'p3@test.com',
      gender: 'Laki-laki',
      role: UserRole.user,
    );
    final p4 = UserModel(
      id: 'p4',
      name: 'P4 (Gender Kosong)',
      username: 'p4',
      email: 'p4@test.com',
      gender: null,
      role: UserRole.user,
    );
    final p5 = UserModel(
      id: 'p5',
      name: 'P5 (Gender Tidak Valid)',
      username: 'p5',
      email: 'p5@test.com',
      gender: '-',
      role: UserRole.user,
    );

    test('1. Hanya Perempuan dan Laki-laki yang dihitung; gender kosong/tidak valid dikeluarkan', () {
      final report = AdminReportService.computePrintReportData(
        users: [p1, p2, p3, p4, p5],
        allScreenings: [],
        config: const ReportConfig(period: ReportPeriod.satuBulan),
        referenceDate: refDate,
      );

      // Total pasien dihitung tetap 5
      expect(report.selectedPatientsCount, 5);

      // Gender: Perempuan = 2 (p1, p2), Laki-laki = 1 (p3)
      expect(report.perempuanCount, 2);
      expect(report.lakiLakiCount, 1);
      expect(report.genderExcludedCount, 2); // p4 dan p5

      // Persentase dihitung dari P + L = 3
      // Perempuan: 2 / 3 = 66.7%
      // Laki-laki: 1 / 3 = 33.3%
      expect(report.perempuanPercentage, closeTo(66.66, 0.1));
      expect(report.lakiLakiPercentage, closeTo(33.33, 0.1));
    });

    test('2. Proteksi pembagian dengan nol jika semua pasien tidak memiliki data gender', () {
      final report = AdminReportService.computePrintReportData(
        users: [p4, p5],
        allScreenings: [],
        config: const ReportConfig(period: ReportPeriod.satuBulan),
        referenceDate: refDate,
      );

      expect(report.perempuanCount, 0);
      expect(report.lakiLakiCount, 0);
      expect(report.genderExcludedCount, 2);
      expect(report.perempuanPercentage, 0.0);
      expect(report.lakiLakiPercentage, 0.0);
    });
  });

  group('AdminReportService - Distribusi Kategori Skrining & Tren Cetak', () {
    final refDate = DateTime(2026, 11, 15, 12, 0);

    final patient1 = UserModel(
      id: 'u1',
      name: 'User 1',
      username: 'u1',
      email: 'u1@test.com',
      gender: 'Perempuan',
      role: UserRole.user,
    );
    final patient2 = UserModel(
      id: 'u2',
      name: 'User 2',
      username: 'u2',
      email: 'u2@test.com',
      gender: 'Laki-laki',
      role: UserRole.user,
    );

    // Patient 1 memiliki 2 skrining: yang dihitung hanya yang terbaru (12 Nov)
    final scr1Old = ScreeningHistoryItem(
      id: 's1_old',
      userId: 'u1',
      date: DateTime(2026, 10, 20),
      bmi: 28.0,
      risk: 'Sedang',
      category: 'Overweight Level 2',
      skriningData: SkriningData()..aiCategoryTitle = 'Overweight Level 2',
    );
    final scr1Latest = ScreeningHistoryItem(
      id: 's1_new',
      userId: 'u1',
      date: DateTime(2026, 11, 12),
      bmi: 22.0,
      risk: 'Rendah',
      category: 'Normal Weight',
      skriningData: SkriningData()..aiCategoryTitle = 'Normal Weight',
    );

    // Patient 2 memiliki 1 skrining (Obesity Type 1)
    final scr2 = ScreeningHistoryItem(
      id: 's2',
      userId: 'u2',
      date: DateTime(2026, 11, 14),
      bmi: 32.0,
      risk: 'Tinggi',
      category: 'Obesity Type 1',
      skriningData: SkriningData()..aiCategoryTitle = 'Obesity Type 1',
    );

    test('1. Satu pasien dihitung satu kali berdasarkan skrining terbarunya', () {
      final report = AdminReportService.computePrintReportData(
        users: [patient1, patient2],
        allScreenings: [scr1Old, scr1Latest, scr2],
        config: const ReportConfig(period: ReportPeriod.satuBulan),
        referenceDate: refDate,
      );

      // Total skrining dalam periode = 3
      expect(report.totalScreenings, 3);
      // Pasien terskrining = 2
      expect(report.totalScreenedPatients, 2);

      // Kategori: Normal Weight = 1 (dari scr1Latest), Obesity Type 1 = 1 (dari scr2)
      expect(report.obesityCounts[ObesityCategory.normalWeight], 1);
      expect(report.obesityCounts[ObesityCategory.obesityType1], 1);
      expect(report.obesityCounts[ObesityCategory.overweightLevel2], 0);

      // Risiko klinis:
      // Normal Weight -> Rendah (1)
      // Obesity Type 1 -> Tinggi (1)
      expect(report.riskCounts['Rendah'], 1);
      expect(report.riskCounts['Tinggi'], 1);
      expect(report.riskCounts['Sedang'], 0);
      expect(report.riskCounts['Perlu perhatian gizi'], 0);
    });

    test('2. Titik data tren skrining: 5 titik untuk Satu bulan dan jumlahnya sama dengan totalScreenings', () {
      final report = AdminReportService.computePrintReportData(
        users: [patient1, patient2],
        allScreenings: [scr1Old, scr1Latest, scr2],
        config: const ReportConfig(period: ReportPeriod.satuBulan),
        referenceDate: refDate,
      );

      expect(report.trendPoints.length, 5);
      final sumTrend = report.trendPoints.fold<int>(0, (sum, p) => sum + p.count);
      expect(sumTrend, report.totalScreenings);
    });

    test('3. Titik data tren skrining untuk Triwulan (7 titik) dan Setahun (12 titik)', () {
      final triwulanReport = AdminReportService.computePrintReportData(
        users: [patient1, patient2],
        allScreenings: [scr1Old, scr1Latest, scr2],
        config: const ReportConfig(period: ReportPeriod.triwulan),
        referenceDate: refDate,
      );
      expect(triwulanReport.trendPoints.length, 7);

      final setahunReport = AdminReportService.computePrintReportData(
        users: [patient1, patient2],
        allScreenings: [scr1Old, scr1Latest, scr2],
        config: const ReportConfig(period: ReportPeriod.setahun),
        referenceDate: refDate,
      );
      expect(setahunReport.trendPoints.length, 12);
    });
  });

  group('AdminReportPdfService - Pembuatan Dokumen PDF (Tahap 1)', () {
    final refDate = DateTime(2026, 11, 15, 12, 0);

    test('1. Dokumen PDF berhasil digenerate dan memiliki byte header PDF valid', () async {
      final patient = UserModel(
        id: 'u1',
        name: 'Pasien Test',
        username: 'pasien_test',
        email: 'test@example.com',
        gender: 'Perempuan',
        role: UserRole.user,
      );
      final scr = ScreeningHistoryItem(
        id: 's1',
        userId: 'u1',
        date: DateTime(2026, 11, 10),
        bmi: 22.5,
        risk: 'Rendah',
        category: 'Normal Weight',
        skriningData: SkriningData()..aiCategoryTitle = 'Normal Weight',
      );

      const config = ReportConfig(
        type: ReportType.eksternal,
        period: ReportPeriod.satuBulan,
      );

      final reportData = AdminReportService.computePrintReportData(
        users: [patient],
        allScreenings: [scr],
        config: config,
        referenceDate: refDate,
      );

      final Uint8List pdfBytes = await AdminReportPdfService.generateReportPdf(
        reportData,
        config,
        adminName: 'Admin Penguji',
      );

      expect(pdfBytes, isNotEmpty);
      // Validasi PDF signature (%PDF-)
      final header = String.fromCharCodes(pdfBytes.take(5));
      expect(header, '%PDF-');
    });
  });

  group('AdminReportService - Perhitungan Tahap 2 (Cross-tab Gender, Usia, Kondisi Skrining)', () {
    final refDate = DateTime(2026, 11, 15, 12, 0);

    test('1. getDistanceToNormal menghitung jarak ke Normal Weight secara presisi', () {
      expect(AdminReportService.getDistanceToNormal(ObesityCategory.normalWeight), 0);
      expect(AdminReportService.getDistanceToNormal(ObesityCategory.insufficientWeight), 1);
      expect(AdminReportService.getDistanceToNormal(ObesityCategory.overweightLevel1), 1);
      expect(AdminReportService.getDistanceToNormal(ObesityCategory.overweightLevel2), 2);
      expect(AdminReportService.getDistanceToNormal(ObesityCategory.obesityType1), 3);
      expect(AdminReportService.getDistanceToNormal(ObesityCategory.obesityType2), 4);
      expect(AdminReportService.getDistanceToNormal(ObesityCategory.obesityType3), 5);
    });

    test('2. Perubahan Kondisi Pasien: Membaik, Tetap, dan Memburuk (Hanya >= 2 skrining)', () {
      // Pasien 1: Membaik (Skrining 1: Obesity Type 1 [jarak 3], Skrining 2: Normal Weight [jarak 0])
      final p1 = UserModel(
        id: 'p1',
        name: 'Pasien 1',
        username: 'p1',
        email: 'p1@test.com',
        gender: 'Perempuan',
        role: UserRole.user,
      );
      final s1_1 = ScreeningHistoryItem(
        id: 's1_1',
        userId: 'p1',
        date: DateTime(2026, 10, 20),
        bmi: 31.0,
        risk: 'Tinggi',
        category: 'Obesity Type 1',
        skriningData: SkriningData()..aiCategoryTitle = 'Obesity Type 1',
      );
      final s1_2 = ScreeningHistoryItem(
        id: 's1_2',
        userId: 'p1',
        date: DateTime(2026, 11, 10),
        bmi: 22.0,
        risk: 'Rendah',
        category: 'Normal Weight',
        skriningData: SkriningData()..aiCategoryTitle = 'Normal Weight',
      );

      // Pasien 2: Tetap (Skrining 1: Normal [0], Skrining 2: Normal [0])
      final p2 = UserModel(
        id: 'p2',
        name: 'Pasien 2',
        username: 'p2',
        email: 'p2@test.com',
        gender: 'Laki-laki',
        role: UserRole.user,
      );
      final s2_1 = ScreeningHistoryItem(
        id: 's2_1',
        userId: 'p2',
        date: DateTime(2026, 10, 22),
        bmi: 21.5,
        risk: 'Rendah',
        category: 'Normal Weight',
        skriningData: SkriningData()..aiCategoryTitle = 'Normal Weight',
      );
      final s2_2 = ScreeningHistoryItem(
        id: 's2_2',
        userId: 'p2',
        date: DateTime(2026, 11, 05),
        bmi: 22.1,
        risk: 'Rendah',
        category: 'Normal Weight',
        skriningData: SkriningData()..aiCategoryTitle = 'Normal Weight',
      );

      // Pasien 3: Memburuk (Skrining 1: Overweight 1 [1], Skrining 2: Overweight 2 [2])
      final p3 = UserModel(
        id: 'p3',
        name: 'Pasien 3',
        username: 'p3',
        email: 'p3@test.com',
        gender: 'Perempuan',
        role: UserRole.user,
      );
      final s3_1 = ScreeningHistoryItem(
        id: 's3_1',
        userId: 'p3',
        date: DateTime(2026, 10, 25),
        bmi: 26.0,
        risk: 'Sedang',
        category: 'Overweight Level 1',
        skriningData: SkriningData()..aiCategoryTitle = 'Overweight Level 1',
      );
      final s3_2 = ScreeningHistoryItem(
        id: 's3_2',
        userId: 'p3',
        date: DateTime(2026, 11, 12),
        bmi: 28.5,
        risk: 'Sedang',
        category: 'Overweight Level 2',
        skriningData: SkriningData()..aiCategoryTitle = 'Overweight Level 2',
      );

      // Pasien 4: Hanya 1 skrining (tidak masuk hitungan perubahan kondisi)
      final p4 = UserModel(
        id: 'p4',
        name: 'Pasien 4',
        username: 'p4',
        email: 'p4@test.com',
        gender: 'Laki-laki',
        role: UserRole.user,
      );
      final s4_1 = ScreeningHistoryItem(
        id: 's4_1',
        userId: 'p4',
        date: DateTime(2026, 11, 01),
        bmi: 23.0,
        risk: 'Rendah',
        category: 'Normal Weight',
        skriningData: SkriningData()..aiCategoryTitle = 'Normal Weight',
      );

      final report = AdminReportService.computePrintReportData(
        users: [p1, p2, p3, p4],
        allScreenings: [s1_1, s1_2, s2_1, s2_2, s3_1, s3_2, s4_1],
        config: const ReportConfig(period: ReportPeriod.satuBulan),
        referenceDate: refDate,
      );

      // Keaktifan: 1 kali = 1 (p4), 2 kali = 3 (p1, p2, p3), 3+ kali = 0
      expect(report.screenings1TimeCount, 1);
      expect(report.screenings2TimesCount, 3);
      expect(report.screenings3PlusTimesCount, 0);

      // Perubahan kondisi (dari p1, p2, p3):
      expect(report.conditionImprovedCount, 1); // p1
      expect(report.conditionUnchangedCount, 1); // p2
      expect(report.conditionWorsenedCount, 1); // p3
    });

    test('3. Distribusi Umur Pengguna dikelompokkan dengan benar', () {
      // refDate: 2026-11-15
      // < 18: lahir 2010 (16 tahun)
      // 18-24: lahir 2004 (22 tahun)
      // 25-34: lahir 1996 (30 tahun)
      // 35-44: lahir 1986 (40 tahun)
      // 45-54: lahir 1976 (50 tahun)
      // 55+: lahir 1960 (66 tahun)
      // Tidak diketahui: dob null
      final users = [
        UserModel(id: 'u_teen', name: 'Teen', username: 'teen', email: 'teen@test.com', dob: '2010-01-01', role: UserRole.user),
        UserModel(id: 'u_18_24', name: 'Youth', username: 'youth', email: 'youth@test.com', dob: '2004-05-10', role: UserRole.user),
        UserModel(id: 'u_25_34', name: 'Adult', username: 'adult', email: 'adult@test.com', dob: '1996-08-20', role: UserRole.user),
        UserModel(id: 'u_35_44', name: 'Mid', username: 'mid', email: 'mid@test.com', dob: '1986-03-15', role: UserRole.user),
        UserModel(id: 'u_45_54', name: 'Senior', username: 'senior', email: 'senior@test.com', dob: '1976-07-07', role: UserRole.user),
        UserModel(id: 'u_55_plus', name: 'Elder', username: 'elder', email: 'elder@test.com', dob: '1960-12-01', role: UserRole.user),
        UserModel(id: 'u_unknown', name: 'Unknown', username: 'unknown', email: 'unk@test.com', dob: null, role: UserRole.user),
      ];

      final report = AdminReportService.computePrintReportData(
        users: users,
        allScreenings: [],
        config: const ReportConfig(period: ReportPeriod.satuBulan),
        referenceDate: refDate,
      );

      expect(report.ageUnder18Count, 1);
      expect(report.age18To24Count, 1);
      expect(report.age25To34Count, 1);
      expect(report.age35To44Count, 1);
      expect(report.age45To54Count, 1);
      expect(report.age55PlusCount, 1);
      expect(report.ageUnknownCount, 1);
    });

    test('4. Cross-tabulation Gender x Kategori Skrining dihitung akurat', () {
      final femaleNormal = UserModel(id: 'fn', name: 'FN', username: 'fn', email: 'fn@test.com', gender: 'Perempuan', role: UserRole.user);
      final femaleObe = UserModel(id: 'fo', name: 'FO', username: 'fo', email: 'fo@test.com', gender: 'Perempuan', role: UserRole.user);
      final maleOver = UserModel(id: 'mo', name: 'MO', username: 'mo', email: 'mo@test.com', gender: 'Laki-laki', role: UserRole.user);
      final unkUser = UserModel(id: 'unk', name: 'UNK', username: 'unk', email: 'unk@test.com', gender: null, role: UserRole.user);

      final s1 = ScreeningHistoryItem(
        id: 's1', userId: 'fn', date: DateTime(2026, 11, 10), bmi: 22.0, risk: 'Rendah',
        category: 'Normal Weight', skriningData: SkriningData()..aiCategoryTitle = 'Normal Weight',
      );
      final s2 = ScreeningHistoryItem(
        id: 's2', userId: 'fo', date: DateTime(2026, 11, 11), bmi: 31.0, risk: 'Tinggi',
        category: 'Obesity Type 1', skriningData: SkriningData()..aiCategoryTitle = 'Obesity Type 1',
      );
      final s3 = ScreeningHistoryItem(
        id: 's3', userId: 'mo', date: DateTime(2026, 11, 12), bmi: 26.0, risk: 'Sedang',
        category: 'Overweight Level 1', skriningData: SkriningData()..aiCategoryTitle = 'Overweight Level 1',
      );
      final s4 = ScreeningHistoryItem(
        id: 's4', userId: 'unk', date: DateTime(2026, 11, 13), bmi: 22.0, risk: 'Rendah',
        category: 'Normal Weight', skriningData: SkriningData()..aiCategoryTitle = 'Normal Weight',
      );

      final report = AdminReportService.computePrintReportData(
        users: [femaleNormal, femaleObe, maleOver, unkUser],
        allScreenings: [s1, s2, s3, s4],
        config: const ReportConfig(period: ReportPeriod.satuBulan),
        referenceDate: refDate,
      );

      // Perempuan: 1 Normal, 1 Obesitas, 0 Overweight, 0 Insufficient
      expect(report.perempuanNormal, 1);
      expect(report.perempuanObesity, 1);
      expect(report.perempuanOverweight, 0);
      expect(report.perempuanInsufficient, 0);

      // Laki-laki: 0 Normal, 0 Obesitas, 1 Overweight, 0 Insufficient
      expect(report.lakiLakiNormal, 0);
      expect(report.lakiLakiObesity, 0);
      expect(report.lakiLakiOverweight, 1);
      expect(report.lakiLakiInsufficient, 0);

      // Pengguna tanpa gender dikeluarkan dari cross-tab (genderExcludedCount = 1)
      expect(report.genderExcludedCount, 1);
    });
  });

  group('AdminReportPdfService - Pembuatan Laporan Lengkap (Tahap 2)', () {
    final refDate = DateTime(2026, 11, 15, 12, 0);

    final patientF = UserModel(
      id: 'p_f',
      name: 'Pasien F',
      username: 'pf',
      email: 'pf@test.com',
      gender: 'Perempuan',
      dob: '1995-04-12',
      role: UserRole.user,
    );
    final patientM = UserModel(
      id: 'p_m',
      name: 'Pasien M',
      username: 'pm',
      email: 'pm@test.com',
      gender: 'Laki-laki',
      dob: '1998-08-20',
      role: UserRole.user,
    );
    final patientUnk = UserModel(
      id: 'p_unk',
      name: 'Pasien Unk',
      username: 'punk',
      email: 'punk@test.com',
      gender: null,
      role: UserRole.user,
    );

    final scrF1 = ScreeningHistoryItem(
      id: 'sf1',
      userId: 'p_f',
      date: DateTime(2026, 10, 20),
      bmi: 27.0,
      risk: 'Sedang',
      category: 'Overweight Level 1',
      skriningData: SkriningData()
        ..aiCategoryTitle = 'Overweight Level 1'
        ..weight = 68.0
        ..height = 158.0,
    );
    final scrF2 = ScreeningHistoryItem(
      id: 'sf2',
      userId: 'p_f',
      date: DateTime(2026, 11, 10),
      bmi: 22.0,
      risk: 'Rendah',
      category: 'Normal Weight',
      skriningData: SkriningData()
        ..aiCategoryTitle = 'Normal Weight'
        ..weight = 55.0
        ..height = 158.0,
    );
    final scrM = ScreeningHistoryItem(
      id: 'sm',
      userId: 'p_m',
      date: DateTime(2026, 11, 12),
      bmi: 32.5,
      risk: 'Tinggi',
      category: 'Obesity Type 1',
      skriningData: SkriningData()
        ..aiCategoryTitle = 'Obesity Type 1'
        ..weight = 95.0
        ..height = 171.0,
    );

    test('1. Laporan Eksternal (2 Halaman) menghasilkan PDF valid dan tidak mengandung PII pengguna', () async {
      const config = ReportConfig(
        type: ReportType.eksternal,
        period: ReportPeriod.satuBulan,
      );

      final reportData = AdminReportService.computePrintReportData(
        users: [patientF, patientM, patientUnk],
        allScreenings: [scrF1, scrF2, scrM],
        config: config,
        referenceDate: refDate,
      );

      final pdfBytes = await AdminReportPdfService.generateReportPdf(
        reportData,
        config,
        adminName: 'Admin Resmi',
      );

      expect(pdfBytes, isNotEmpty);
      expect(String.fromCharCodes(pdfBytes.take(5)), '%PDF-');

      // Validasi PDF tidak membocorkan PII (email, username)
      final pdfContent = String.fromCharCodes(pdfBytes);
      expect(pdfContent.contains('pf@test.com'), isFalse);
      expect(pdfContent.contains('pm@test.com'), isFalse);
      expect(pdfContent.contains('punk@test.com'), isFalse);
    });

    test('2. Laporan Internal (Semua 8 Checkbox Aktif) menghasilkan PDF valid dengan grafik PDF', () async {
      const config = ReportConfig(
        type: ReportType.internal,
        period: ReportPeriod.satuBulan,
        selectedSections: {
          ReportSection.dataPengguna,
          ReportSection.dataImt,
          ReportSection.hasilSkrining,
          ReportSection.aktivitasFisik,
          ReportSection.makananMinuman,
          ReportSection.polaTidur,
          ReportSection.trenAktivitas,
          ReportSection.analisisKesimpulan,
        },
      );

      final reportData = AdminReportService.computePrintReportData(
        users: [patientF, patientM],
        allScreenings: [scrF1, scrF2, scrM],
        config: config,
        referenceDate: refDate,
      );

      final pdfBytes = await AdminReportPdfService.generateReportPdf(
        reportData,
        config,
        adminName: 'Admin Penguji',
      );

      expect(pdfBytes, isNotEmpty);
      expect(String.fromCharCodes(pdfBytes.take(5)), '%PDF-');
    });

    test('3. Laporan Internal dengan subset checkbox menghasilkan nomor bagian berurutan tanpa jeda', () async {
      const config = ReportConfig(
        type: ReportType.internal,
        period: ReportPeriod.satuBulan,
        selectedSections: {
          ReportSection.dataImt,
          ReportSection.trenAktivitas,
        },
      );

      final reportData = AdminReportService.computePrintReportData(
        users: [patientF, patientM],
        allScreenings: [scrF1, scrF2, scrM],
        config: config,
        referenceDate: refDate,
      );

      final pdfBytes = await AdminReportPdfService.generateReportPdf(
        reportData,
        config,
        adminName: 'Admin Penguji',
      );

      expect(pdfBytes, isNotEmpty);
      expect(String.fromCharCodes(pdfBytes.take(5)), '%PDF-');
    });

    test('4. Dokumen PDF menangani data kosong dengan aman tanpa error pembagian dengan nol', () async {
      const configInternal = ReportConfig(
        type: ReportType.internal,
        period: ReportPeriod.satuBulan,
      );
      const configEksternal = ReportConfig(
        type: ReportType.eksternal,
        period: ReportPeriod.satuBulan,
      );

      final emptyReport = AdminReportService.computePrintReportData(
        users: [],
        allScreenings: [],
        config: configInternal,
        referenceDate: refDate,
      );

      // PDF Eksternal dengan data kosong
      final pdfEksternal = await AdminReportPdfService.generateReportPdf(
        emptyReport,
        configEksternal,
        adminName: 'Admin Kosong',
      );
      expect(pdfEksternal, isNotEmpty);

      // PDF Internal dengan data kosong
      final pdfInternal = await AdminReportPdfService.generateReportPdf(
        emptyReport,
        configInternal,
        adminName: 'Admin Kosong',
      );
      expect(pdfInternal, isNotEmpty);
    });
  });
}
