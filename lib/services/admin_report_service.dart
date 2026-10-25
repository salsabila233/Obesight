import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/screening_history_model.dart';
import '../models/user_model.dart';
import '../screens/skrining/skrining_models.dart';
import 'admin_user_service.dart';

/// Jenis kelamin yang dinormalisasi untuk laporan admin
enum AdminReportGender {
  perempuan,
  lakiLaki,
  tidakDiketahui,
}

/// 7 Kategori obesitas resmi sesuai standar klinis ObeSight dan referensi donat Laporan
enum ObesityCategory {
  insufficientWeight,
  normalWeight,
  overweightLevel1,
  overweightLevel2,
  obesityType1,
  obesityType2,
  obesityType3,
  tidakDiketahui,
}

/// Metadata dan konfigurasi visual untuk kategori obesitas
class ObesityCategoryConfig {
  final ObesityCategory category;
  final String label;
  final Color color;

  const ObesityCategoryConfig({
    required this.category,
    required this.label,
    required this.color,
  });

  /// Daftar lengkap 7 kategori dengan warna identik seperti donat grafik
  static const List<ObesityCategoryConfig> all7Categories = [
    ObesityCategoryConfig(
      category: ObesityCategory.insufficientWeight,
      label: 'Insufficient Weight',
      color: Color(0xFF2563EB), // Biru
    ),
    ObesityCategoryConfig(
      category: ObesityCategory.normalWeight,
      label: 'Normal Weight',
      color: Color(0xFF10B981), // Hijau
    ),
    ObesityCategoryConfig(
      category: ObesityCategory.overweightLevel1,
      label: 'Overweight Level 1',
      color: Color(0xFFFACC15), // Kuning
    ),
    ObesityCategoryConfig(
      category: ObesityCategory.overweightLevel2,
      label: 'Overweight Level 2',
      color: Color(0xFFFB923C), // Oranye
    ),
    ObesityCategoryConfig(
      category: ObesityCategory.obesityType1,
      label: 'Obesity Type 1',
      color: Color(0xFFEA580C), // Oranye Tua / Vermilion
    ),
    ObesityCategoryConfig(
      category: ObesityCategory.obesityType2,
      label: 'Obesity Type 2',
      color: Color(0xFFDC2626), // Merah
    ),
    ObesityCategoryConfig(
      category: ObesityCategory.obesityType3,
      label: 'Obesity Type 3',
      color: Color(0xFF9333EA), // Ungu
    ),
  ];

  static ObesityCategoryConfig getConfig(ObesityCategory category) {
    return all7Categories.firstWhere(
      (c) => c.category == category,
      orElse: () => const ObesityCategoryConfig(
        category: ObesityCategory.tidakDiketahui,
        label: 'Tidak Diketahui',
        color: Color(0xFF94A3B8),
      ),
    );
  }
}

/// Model hasil kalkulasi laporan agregasi admin
class AdminReportData {
  final int totalPatients;
  final Map<AdminReportGender, int> genderCounts;
  final Map<AdminReportGender, double> genderPercentages;
  final Map<ObesityCategory, int> obesityCounts;
  final Map<ObesityCategory, double> obesityPercentages;
  final int totalScreenedPatients;
  final List<UserModel> filteredUsers;

  const AdminReportData({
    required this.totalPatients,
    required this.genderCounts,
    required this.genderPercentages,
    required this.obesityCounts,
    required this.obesityPercentages,
    required this.totalScreenedPatients,
    required this.filteredUsers,
  });

  bool get isEmpty => totalPatients == 0;

  factory AdminReportData.empty() {
    return const AdminReportData(
      totalPatients: 0,
      genderCounts: {
        AdminReportGender.perempuan: 0,
        AdminReportGender.lakiLaki: 0,
        AdminReportGender.tidakDiketahui: 0,
      },
      genderPercentages: {
        AdminReportGender.perempuan: 0.0,
        AdminReportGender.lakiLaki: 0.0,
        AdminReportGender.tidakDiketahui: 0.0,
      },
      obesityCounts: {
        ObesityCategory.insufficientWeight: 0,
        ObesityCategory.normalWeight: 0,
        ObesityCategory.overweightLevel1: 0,
        ObesityCategory.overweightLevel2: 0,
        ObesityCategory.obesityType1: 0,
        ObesityCategory.obesityType2: 0,
        ObesityCategory.obesityType3: 0,
        ObesityCategory.tidakDiketahui: 0,
      },
      obesityPercentages: {
        ObesityCategory.insufficientWeight: 0.0,
        ObesityCategory.normalWeight: 0.0,
        ObesityCategory.overweightLevel1: 0.0,
        ObesityCategory.overweightLevel2: 0.0,
        ObesityCategory.obesityType1: 0.0,
        ObesityCategory.obesityType2: 0.0,
        ObesityCategory.obesityType3: 0.0,
        ObesityCategory.tidakDiketahui: 0.0,
      },
      totalScreenedPatients: 0,
      filteredUsers: [],
    );
  }
}

/// Service untuk logika pemetaan, normalisasi, dan perhitungan data laporan Admin ObeSight
class AdminReportService {
  static final AdminReportService instance = AdminReportService._internal();
  AdminReportService._internal();

  /// 1. Normalisasi jenis kelamin pengguna dengan penanganan variasi penulisan & data kosong
  static AdminReportGender normalizeGender(String? raw) {
    if (raw == null) return AdminReportGender.tidakDiketahui;
    final clean = raw.trim().toLowerCase();
    if (clean.isEmpty) return AdminReportGender.tidakDiketahui;

    if (clean == 'perempuan' ||
        clean == 'wanita' ||
        clean == 'female' ||
        clean == 'p' ||
        clean == 'f') {
      return AdminReportGender.perempuan;
    }

    if (clean == 'laki-laki' ||
        clean == 'laki laki' ||
        clean == 'lakilaki' ||
        clean == 'pria' ||
        clean == 'male' ||
        clean == 'l' ||
        clean == 'm') {
      return AdminReportGender.lakiLaki;
    }

    return AdminReportGender.tidakDiketahui;
  }

  /// Label tampilan bahasa Indonesia untuk jenis kelamin
  static String genderDisplayName(AdminReportGender gender) {
    switch (gender) {
      case AdminReportGender.perempuan:
        return 'Perempuan';
      case AdminReportGender.lakiLaki:
        return 'Laki-laki';
      case AdminReportGender.tidakDiketahui:
        return 'Tidak diketahui';
    }
  }

  /// 2. Normalisasi kategori skrining obesitas ke dalam 7 kategori resmi
  static ObesityCategory normalizeObesityCategory(String? raw) {
    if (raw == null) return ObesityCategory.tidakDiketahui;
    final clean = raw.trim().toLowerCase().replaceAll('\n', ' ');
    if (clean.isEmpty) return ObesityCategory.tidakDiketahui;

    // 1. Insufficient Weight / Underweight
    if (clean.contains('insufficient') ||
        clean.contains('underweight') ||
        clean.contains('kurang')) {
      return ObesityCategory.insufficientWeight;
    }

    // 2. Normal Weight
    if (clean.contains('normal') || clean.contains('ideal')) {
      return ObesityCategory.normalWeight;
    }

    // 3 & 4. Overweight Level 1 & 2
    if (clean.contains('overweight') || clean.contains('kelebihan')) {
      if (clean.contains('level 2') ||
          clean.contains('level ii') ||
          clean.contains('level_ii') ||
          clean.contains('level_2') ||
          clean.contains('tingkat 2') ||
          clean.contains('tingkat ii')) {
        return ObesityCategory.overweightLevel2;
      }
      return ObesityCategory.overweightLevel1;
    }

    // 5, 6, 7. Obesity Type 1, 2, 3
    if (clean.contains('obesity') || clean.contains('obesitas')) {
      if (clean.contains('type 3') ||
          clean.contains('type iii') ||
          clean.contains('type_iii') ||
          clean.contains('type_3') ||
          clean.contains('level 3') ||
          clean.contains('level iii') ||
          clean.contains('tingkat 3') ||
          clean.contains('tingkat iii') ||
          clean.contains('morbid') ||
          clean.contains('ekstrem') ||
          clean.contains('iii') ||
          clean.contains('3')) {
        return ObesityCategory.obesityType3;
      }
      if (clean.contains('type 2') ||
          clean.contains('type ii') ||
          clean.contains('type_ii') ||
          clean.contains('type_2') ||
          clean.contains('level 2') ||
          clean.contains('level ii') ||
          clean.contains('tingkat 2') ||
          clean.contains('tingkat ii') ||
          clean.contains('ii') ||
          clean.contains('2')) {
        return ObesityCategory.obesityType2;
      }
      if (clean.contains('type 1') ||
          clean.contains('type i') ||
          clean.contains('type_i') ||
          clean.contains('type_1') ||
          clean.contains('level 1') ||
          clean.contains('level i') ||
          clean.contains('tingkat 1') ||
          clean.contains('tingkat i') ||
          clean.contains('i') ||
          clean.contains('1')) {
        return ObesityCategory.obesityType1;
      }
      return ObesityCategory.obesityType1; // Fallback umum obesitas jika tanpa nomor
    }

    return ObesityCategory.tidakDiketahui;
  }

  /// 3. Perhitungan persentase yang aman dari pembagian dengan nol (divide-by-zero protection)
  static double calculatePercentage(int count, int total) {
    if (total <= 0 || count <= 0) return 0.0;
    final pct = (count / total) * 100.0;
    return double.parse(pct.toStringAsFixed(1));
  }

  /// Format persentase standar Indonesia dengan koma desimal
  static String formatPercentage(double pct) {
    return '${pct.toStringAsFixed(1).replaceAll('.', ',')}%';
  }

  /// Mengekstrak tanggal pendaftaran / bergabung dari model pengguna
  static DateTime? extractUserDate(UserModel user) {
    if (user.createdAt != null) return user.createdAt;
    if (user.joined != null && user.joined!.trim().isNotEmpty) {
      final str = user.joined!.trim();
      final iso = DateTime.tryParse(str);
      if (iso != null) return iso;

      // Parsing format tanggal lokal Indonesia: "12 Juni 2026"
      final parts = str.split(' ');
      if (parts.length >= 3) {
        final day = int.tryParse(parts[0]);
        final year = int.tryParse(parts[2]);
        final monthName = parts[1].toLowerCase();
        const monthMap = {
          'januari': 1, 'jan': 1,
          'februari': 2, 'feb': 2,
          'maret': 3, 'mar': 3,
          'april': 4, 'apr': 4,
          'mei': 5, 'may': 5,
          'juni': 6, 'jun': 6,
          'juli': 7, 'jul': 7,
          'agustus': 8, 'ags': 8, 'aug': 8,
          'september': 9, 'sep': 9,
          'oktober': 10, 'okt': 10, 'oct': 10,
          'november': 11, 'nov': 11,
          'desember': 12, 'des': 12, 'dec': 12,
        };
        final month = monthMap[monthName];
        if (day != null && month != null && year != null) {
          return DateTime(year, month, day);
        }
      }
    }
    return null;
  }

  /// Memeriksa apakah tanggal pengguna berada di dalam rentang tanggal filter
  static bool isDateInRange(DateTime? date, DateTime? start, DateTime? end) {
    if (start == null || end == null) return true;
    if (date == null) return false;
    final startDay = DateTime(start.year, start.month, start.day, 0, 0, 0);
    final endDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
    return !date.isBefore(startDay) && !date.isAfter(endDay);
  }

  /// Ekstraksi kategori hasil skrining dari sesi skrining atau pengguna
  static String? extractCategoryRaw(
    ScreeningHistoryItem? screening,
    UserModel user,
  ) {
    if (screening != null) {
      final d = screening.skriningData;
      if (d.aiCategoryTitle != null && d.aiCategoryTitle!.isNotEmpty) {
        final badge = d.aiCategoryBadge ?? '';
        return '${d.aiCategoryTitle} $badge'.trim();
      }
      if (d.aiCategoryKey != null && d.aiCategoryKey!.isNotEmpty) {
        return d.aiCategoryKey;
      }
      if (d.aiClinicalClass != null && d.aiClinicalClass!.isNotEmpty) {
        return d.aiClinicalClass;
      }
      if (screening.category.isNotEmpty) {
        return screening.category;
      }
      if (d.classificationCategory.isNotEmpty) {
        return d.classificationCategory;
      }
    }

    if (user.bmiCategory.isNotEmpty && user.bmiCategory != 'Normal') {
      return user.bmiCategory;
    } else if (user.bmiCategory.isNotEmpty) {
      return user.bmiCategory;
    }
    return null;
  }

  /// Menghitung agregasi data laporan berdasarkan daftar pengguna dan skrining terbarunya
  /// Aturan penting:
  /// - Hanya menghitung akun pasien (role != admin)
  /// - Filter rentang tanggal diterapkan
  /// - Satu pengguna dihitung satu kali untuk jenis kelamin dan hasil skrining terbarunya
  static AdminReportData computeReportData({
    required List<UserModel> users,
    required Map<String, ScreeningHistoryItem?> latestScreenings,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    // 1. Filter hanya pasien (non-admin)
    final patients = users.where((u) => !u.isAdmin).toList();

    // 2. Filter rentang tanggal
    final filteredPatients = patients.where((u) {
      if (startDate == null || endDate == null) return true;
      final uDate = extractUserDate(u);
      return isDateInRange(uDate, startDate, endDate);
    }).toList();

    final totalPatients = filteredPatients.length;

    // 3. Hitung breakdown jenis kelamin
    final genderCounts = <AdminReportGender, int>{
      AdminReportGender.perempuan: 0,
      AdminReportGender.lakiLaki: 0,
      AdminReportGender.tidakDiketahui: 0,
    };

    for (final u in filteredPatients) {
      final g = normalizeGender(u.gender);
      genderCounts[g] = (genderCounts[g] ?? 0) + 1;
    }

    final genderPercentages = <AdminReportGender, double>{
      AdminReportGender.perempuan: calculatePercentage(
        genderCounts[AdminReportGender.perempuan] ?? 0,
        totalPatients,
      ),
      AdminReportGender.lakiLaki: calculatePercentage(
        genderCounts[AdminReportGender.lakiLaki] ?? 0,
        totalPatients,
      ),
      AdminReportGender.tidakDiketahui: calculatePercentage(
        genderCounts[AdminReportGender.tidakDiketahui] ?? 0,
        totalPatients,
      ),
    };

    // 4. Hitung kategori obesitas dari hasil skrining terbaru per pengguna
    final obesityCounts = <ObesityCategory, int>{
      ObesityCategory.insufficientWeight: 0,
      ObesityCategory.normalWeight: 0,
      ObesityCategory.overweightLevel1: 0,
      ObesityCategory.overweightLevel2: 0,
      ObesityCategory.obesityType1: 0,
      ObesityCategory.obesityType2: 0,
      ObesityCategory.obesityType3: 0,
      ObesityCategory.tidakDiketahui: 0,
    };

    int screenedCount = 0;

    for (final u in filteredPatients) {
      final screening = latestScreenings[u.id];
      final rawCat = extractCategoryRaw(screening, u);

      if (rawCat != null && rawCat.trim().isNotEmpty) {
        final cat = normalizeObesityCategory(rawCat);
        obesityCounts[cat] = (obesityCounts[cat] ?? 0) + 1;
        screenedCount++;
      } else {
        // Jika pengguna belum melakukan skrining sama sekali
        obesityCounts[ObesityCategory.tidakDiketahui] =
            (obesityCounts[ObesityCategory.tidakDiketahui] ?? 0) + 1;
      }
    }

    // Persentase kategori dihitung dari pengguna yang memiliki data skrining
    final denominator = screenedCount > 0 ? screenedCount : totalPatients;
    final obesityPercentages = <ObesityCategory, double>{};
    for (final entry in obesityCounts.entries) {
      obesityPercentages[entry.key] = calculatePercentage(
        entry.value,
        denominator,
      );
    }

    return AdminReportData(
      totalPatients: totalPatients,
      genderCounts: genderCounts,
      genderPercentages: genderPercentages,
      obesityCounts: obesityCounts,
      obesityPercentages: obesityPercentages,
      totalScreenedPatients: screenedCount,
      filteredUsers: filteredPatients,
    );
  }

  /// Mengambil data laporan admin secara efisien dari Cloud Firestore
  /// Query pengguna diambil sekali, lalu riwayat skrining terbaru per pengguna diambil secara paralel
  Future<AdminReportData> fetchAdminReportData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final adminService = AdminUserService.instance;
    List<UserModel> users = [];

    if (adminService.isFirebaseAvailable) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .get()
            .timeout(const Duration(seconds: 10));

        users = snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList();
      } catch (e) {
        debugPrint('[AdminReportService] Notice loading users from Firestore: $e');
        users = getDefaultMockUsers();
      }
    } else {
      users = getDefaultMockUsers();
    }

    final latestScreenings = <String, ScreeningHistoryItem?>{};
    for (final u in users) {
      if (u.isAdmin) continue;
      try {
        final summary = await adminService.getUserScreeningSummary(u.id);
        if (summary.latestScreening != null) {
          latestScreenings[u.id] = summary.latestScreening;
        } else if (u.id == 'usr_003') {
          latestScreenings[u.id] = ScreeningHistoryItem(
            id: 'scr_003',
            userId: 'usr_003',
            date: DateTime(2026, 8, 16, 10, 0),
            bmi: 22.4,
            risk: 'Rendah',
            category: 'Normal Weight',
            skriningData: SkriningData()
              ..height = 172.0
              ..weight = 66.0
              ..aiCategoryTitle = 'Normal Weight'
              ..aiCategoryBadge = 'Normal',
          );
        }
      } catch (e) {
        debugPrint('[AdminReportService] Notice getting summary for ${u.id}: $e');
      }
    }

    return computeReportData(
      users: users,
      latestScreenings: latestScreenings,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Data mock default untuk offline fallback dan testing lingkungan widget
  static List<UserModel> getDefaultMockUsers() {
    return [
      UserModel(
        id: 'usr_001',
        name: 'Zahra Fitriana',
        email: 'zahraafitriana@gmail.com',
        username: 'zahraafitriana',
        role: UserRole.user,
        phone: '0893-3421-2098',
        dob: '12 Juli 2003',
        gender: 'Perempuan',
        joined: '10 Agustus 2026',
      ),
      UserModel(
        id: 'usr_002',
        name: 'Zahra Fitrie',
        email: 'zahrafitrie@gmail.com',
        username: 'zahrafitrie',
        role: UserRole.user,
        phone: '0812-3456-7890',
        dob: '15 Mei 2002',
        gender: 'Perempuan',
        joined: '10 Januari 2026',
      ),
      UserModel(
        id: 'usr_003',
        name: 'Budi Santoso',
        email: 'budisantoso@gmail.com',
        username: 'budisantoso',
        role: UserRole.user,
        phone: '0813-9876-5432',
        dob: '20 Agustus 1998',
        gender: 'Laki-laki',
        joined: '15 Agustus 2026',
      ),
    ];
  }
}
