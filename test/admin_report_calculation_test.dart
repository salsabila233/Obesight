import 'package:flutter_test/flutter_test.dart';
import 'package:obesight/models/screening_history_model.dart';
import 'package:obesight/models/user_model.dart';
import 'package:obesight/screens/skrining/skrining_models.dart';
import 'package:obesight/services/admin_report_service.dart';

void main() {
  group('AdminReportService - Normalisasi Jenis Kelamin & Data Kosong', () {
    test('1. Normalisasi variasi perempuan menghasilkan AdminReportGender.perempuan', () {
      const femaleVariants = [
        'Perempuan',
        'perempuan',
        'PEREMPUAN',
        'wanita',
        'WANITA',
        'female',
        'Female',
        'FEMALE',
        'p',
        'P',
        'f',
        'F',
        '  perempuan  ',
        '  Female  ',
      ];

      for (final variant in femaleVariants) {
        expect(
          AdminReportService.normalizeGender(variant),
          AdminReportGender.perempuan,
          reason: 'Gagal menormalisasi variasi perempuan: "$variant"',
        );
      }
    });

    test('2. Normalisasi variasi laki-laki menghasilkan AdminReportGender.lakiLaki', () {
      const maleVariants = [
        'Laki-laki',
        'laki-laki',
        'Laki-Laki',
        'laki laki',
        'lakilaki',
        'LAKILAKI',
        'pria',
        'PRIA',
        'male',
        'Male',
        'MALE',
        'l',
        'L',
        'm',
        'M',
        '  laki-laki  ',
        '  Male  ',
      ];

      for (final variant in maleVariants) {
        expect(
          AdminReportService.normalizeGender(variant),
          AdminReportGender.lakiLaki,
          reason: 'Gagal menormalisasi variasi laki-laki: "$variant"',
        );
      }
    });

    test('3. Data kosong, null, atau tidak dikenal menghasilkan AdminReportGender.tidakDiketahui', () {
      const unknownVariants = [
        null,
        '',
        '   ',
        '-',
        'unknown',
        'tidak tahu',
        'other',
      ];

      for (final variant in unknownVariants) {
        expect(
          AdminReportService.normalizeGender(variant),
          AdminReportGender.tidakDiketahui,
          reason: 'Gagal menangani nilai kosong/tidak dikenal: "$variant"',
        );
      }
    });
  });

  group('AdminReportService - Normalisasi 7 Kategori Obesitas', () {
    test('1. Insufficient Weight / Underweight', () {
      const variants = [
        'Insufficient Weight',
        'insufficient_weight',
        'INSUFFICIENT WEIGHT',
        'Underweight',
        'underweight',
        'Underweight Level I',
        'Berat badan kurang',
      ];
      for (final v in variants) {
        expect(
          AdminReportService.normalizeObesityCategory(v),
          ObesityCategory.insufficientWeight,
          reason: 'Gagal pada: $v',
        );
      }
    });

    test('2. Normal Weight', () {
      const variants = [
        'Normal Weight',
        'normal_weight',
        'Normal',
        'normal',
        'Berat badan ideal',
      ];
      for (final v in variants) {
        expect(
          AdminReportService.normalizeObesityCategory(v),
          ObesityCategory.normalWeight,
          reason: 'Gagal pada: $v',
        );
      }
    });

    test('3. Overweight Level 1', () {
      const variants = [
        'Overweight Level 1',
        'Overweight Level I',
        'overweight_level_i',
        'Overweight_Level_1',
        'Overweight',
        'Kelebihan berat badan',
        'Kelebihan berat badan tingkat 1',
      ];
      for (final v in variants) {
        expect(
          AdminReportService.normalizeObesityCategory(v),
          ObesityCategory.overweightLevel1,
          reason: 'Gagal pada: $v',
        );
      }
    });

    test('4. Overweight Level 2', () {
      const variants = [
        'Overweight Level 2',
        'Overweight Level II',
        'overweight_level_ii',
        'Overweight_Level_2',
        'Kelebihan berat badan tingkat 2',
        'Kelebihan berat badan tingkat ii',
      ];
      for (final v in variants) {
        expect(
          AdminReportService.normalizeObesityCategory(v),
          ObesityCategory.overweightLevel2,
          reason: 'Gagal pada: $v',
        );
      }
    });

    test('5. Obesity Type 1', () {
      const variants = [
        'Obesity Type 1',
        'Obesity Type I',
        'Obesity_Type_I',
        'Obesity_Type_1',
        'Obesity Level I',
        'Obesitas I',
        'Obesitas tingkat 1',
      ];
      for (final v in variants) {
        expect(
          AdminReportService.normalizeObesityCategory(v),
          ObesityCategory.obesityType1,
          reason: 'Gagal pada: $v',
        );
      }
    });

    test('6. Obesity Type 2', () {
      const variants = [
        'Obesity Type 2',
        'Obesity Type II',
        'Obesity_Type_II',
        'Obesity_Type_2',
        'Obesity Level II',
        'Obesitas II',
        'Obesitas tingkat 2',
      ];
      for (final v in variants) {
        expect(
          AdminReportService.normalizeObesityCategory(v),
          ObesityCategory.obesityType2,
          reason: 'Gagal pada: $v',
        );
      }
    });

    test('7. Obesity Type 3', () {
      const variants = [
        'Obesity Type 3',
        'Obesity Type III',
        'Obesity_Type_III',
        'Obesity_Type_3',
        'Obesity Level III',
        'Obesitas III',
        'Obesitas morbid',
        'Obesitas ekstrem',
      ];
      for (final v in variants) {
        expect(
          AdminReportService.normalizeObesityCategory(v),
          ObesityCategory.obesityType3,
          reason: 'Gagal pada: $v',
        );
      }
    });

    test('8. Nilai null atau kosong menghasilkan ObesityCategory.tidakDiketahui', () {
      expect(AdminReportService.normalizeObesityCategory(null), ObesityCategory.tidakDiketahui);
      expect(AdminReportService.normalizeObesityCategory(''), ObesityCategory.tidakDiketahui);
      expect(AdminReportService.normalizeObesityCategory('   '), ObesityCategory.tidakDiketahui);
      expect(AdminReportService.normalizeObesityCategory('xyz abc'), ObesityCategory.tidakDiketahui);
    });
  });

  group('AdminReportService - Perhitungan Persentase Aman (Anti Divide-by-Zero)', () {
    test('1. Total 0 mengembalikan 0.0 tanpa error runtime atau NaN/Infinity', () {
      expect(AdminReportService.calculatePercentage(0, 0), 0.0);
      expect(AdminReportService.calculatePercentage(5, 0), 0.0);
      expect(AdminReportService.calculatePercentage(-1, 0), 0.0);
    });

    test('2. Perhitungan pecahan standar dengan pembulatan 1 desimal', () {
      expect(AdminReportService.calculatePercentage(1, 3), 33.3);
      expect(AdminReportService.calculatePercentage(2, 3), 66.7);
      expect(AdminReportService.calculatePercentage(1, 2), 50.0);
      expect(AdminReportService.calculatePercentage(5, 5), 100.0);
    });

    test('3. Format persentase standar dengan tanda koma desimal', () {
      expect(AdminReportService.formatPercentage(33.3), '33,3%');
      expect(AdminReportService.formatPercentage(100.0), '100,0%');
      expect(AdminReportService.formatPercentage(0.0), '0,0%');
    });
  });

  group('AdminReportService - Agregasi Laporan: 1 Pengguna Dihitung 1 Kali & Filter Rentang Tanggal', () {
    test('1. Satu pengguna dihitung satu kali berdasarkan hasil skrining terbarunya', () {
      final user1 = UserModel(
        id: 'u1',
        name: 'User Satu',
        email: 'u1@test.com',
        username: 'u1',
        role: UserRole.user,
        gender: 'Perempuan',
        joined: '10 Agustus 2026',
      );

      final user2 = UserModel(
        id: 'u2',
        name: 'User Dua',
        email: 'u2@test.com',
        username: 'u2',
        role: UserRole.user,
        gender: 'Laki-laki',
        joined: '12 Agustus 2026',
      );

      // User 1 memiliki skrining terbaru: Normal Weight
      final screeningU1 = ScreeningHistoryItem(
        id: 'scr_1',
        userId: 'u1',
        date: DateTime(2026, 8, 15),
        bmi: 21.5,
        risk: 'Rendah',
        category: 'Normal (IMT 18.5–22.9)',
        skriningData: SkriningData()..aiCategoryTitle = 'Normal Weight',
      );

      // User 2 memiliki skrining terbaru: Obesity Type 1
      final screeningU2 = ScreeningHistoryItem(
        id: 'scr_2',
        userId: 'u2',
        date: DateTime(2026, 8, 16),
        bmi: 28.5,
        risk: 'Tinggi',
        category: 'Obesitas (IMT > 27)',
        skriningData: SkriningData()..aiCategoryTitle = 'Obesity Type 1',
      );

      final report = AdminReportService.computeReportData(
        users: [user1, user2],
        latestScreenings: {
          'u1': screeningU1,
          'u2': screeningU2,
        },
      );

      expect(report.totalPatients, 2);
      expect(report.genderCounts[AdminReportGender.perempuan], 1);
      expect(report.genderCounts[AdminReportGender.lakiLaki], 1);
      expect(report.genderPercentages[AdminReportGender.perempuan], 50.0);
      expect(report.genderPercentages[AdminReportGender.lakiLaki], 50.0);

      // Kategori obesitas masing-masing dihitung tepat 1 kali
      expect(report.obesityCounts[ObesityCategory.normalWeight], 1);
      expect(report.obesityCounts[ObesityCategory.obesityType1], 1);
      expect(report.obesityCounts[ObesityCategory.obesityType2], 0);
      expect(report.totalScreenedPatients, 2);
    });

    test('2. Filter tanggal membatasi pengguna hanya pada rentang yang dipilih', () {
      final userInside = UserModel(
        id: 'u_in',
        name: 'User Inside',
        email: 'in@test.com',
        username: 'in',
        role: UserRole.user,
        gender: 'Perempuan',
        joined: '15 Agustus 2026',
      );

      final userOutside = UserModel(
        id: 'u_out',
        name: 'User Outside',
        email: 'out@test.com',
        username: 'out',
        role: UserRole.user,
        gender: 'Laki-laki',
        joined: '10 Mei 2026', // Di luar rentang Juli - Agustus 2026
      );

      final report = AdminReportService.computeReportData(
        users: [userInside, userOutside],
        latestScreenings: {},
        startDate: DateTime(2026, 7, 29),
        endDate: DateTime(2026, 8, 29),
      );

      expect(report.totalPatients, 1);
      expect(report.filteredUsers.first.id, 'u_in');
      expect(report.genderCounts[AdminReportGender.perempuan], 1);
      expect(report.genderCounts[AdminReportGender.lakiLaki], 0);
    });

    test('3. State kosong ketika tidak ada pengguna dalam rentang tanggal', () {
      final report = AdminReportService.computeReportData(
        users: [],
        latestScreenings: {},
      );

      expect(report.totalPatients, 0);
      expect(report.isEmpty, isTrue);
      expect(report.genderPercentages[AdminReportGender.perempuan], 0.0);
      expect(report.genderPercentages[AdminReportGender.lakiLaki], 0.0);
      expect(report.genderPercentages[AdminReportGender.tidakDiketahui], 0.0);
      expect(report.obesityCounts[ObesityCategory.normalWeight], 0);
    });
  });
}
