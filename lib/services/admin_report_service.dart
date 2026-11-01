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

  // 1. Kartu Ringkasan: Total Skrining
  final int totalScreenings;
  final int previousPeriodTotalScreenings;
  final double totalScreeningsChangePercentage;
  final bool totalScreeningsHasArrow;
  final bool totalScreeningsIsUp;
  final String totalScreeningsBadgeText;

  // 2. Kartu Ringkasan: Pengguna Baru
  final int newUsersCount;
  final int previousPeriodNewUsersCount;
  final double newUsersChangePercentage;
  final bool newUsersHasArrow;
  final bool newUsersIsUp;
  final String newUsersBadgeText;

  // 3. Kartu Ringkasan: Skrining Rata-rata/Hari
  final int screeningsPerDay;
  final double exactScreeningsPerDay;
  final double screeningsPerDayChangePercentage;
  final bool screeningsPerDayHasArrow;
  final bool screeningsPerDayIsUp;
  final String screeningsPerDayBadgeText;

  // 4. Donut Chart: Distribusi Hasil Skrining (7 Kategori)
  final Map<ObesityCategory, int> screeningDistributionCounts;
  final Map<ObesityCategory, double> screeningDistributionPercentages;

  const AdminReportData({
    required this.totalPatients,
    required this.genderCounts,
    required this.genderPercentages,
    required this.obesityCounts,
    required this.obesityPercentages,
    required this.totalScreenedPatients,
    required this.filteredUsers,
    this.totalScreenings = 0,
    this.previousPeriodTotalScreenings = 0,
    this.totalScreeningsChangePercentage = 0.0,
    this.totalScreeningsHasArrow = false,
    this.totalScreeningsIsUp = true,
    this.totalScreeningsBadgeText = '0%',
    this.newUsersCount = 0,
    this.previousPeriodNewUsersCount = 0,
    this.newUsersChangePercentage = 0.0,
    this.newUsersHasArrow = false,
    this.newUsersIsUp = true,
    this.newUsersBadgeText = '0%',
    this.screeningsPerDay = 0,
    this.exactScreeningsPerDay = 0.0,
    this.screeningsPerDayChangePercentage = 0.0,
    this.screeningsPerDayHasArrow = false,
    this.screeningsPerDayIsUp = true,
    this.screeningsPerDayBadgeText = '0%',
    this.screeningDistributionCounts = const {},
    this.screeningDistributionPercentages = const {},
  });

  bool get isEmpty => totalPatients == 0 && totalScreenings == 0;

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
      totalScreenings: 0,
      previousPeriodTotalScreenings: 0,
      totalScreeningsChangePercentage: 0.0,
      totalScreeningsHasArrow: false,
      totalScreeningsIsUp: true,
      totalScreeningsBadgeText: '0%',
      newUsersCount: 0,
      previousPeriodNewUsersCount: 0,
      newUsersChangePercentage: 0.0,
      newUsersHasArrow: false,
      newUsersIsUp: true,
      newUsersBadgeText: '0%',
      screeningsPerDay: 0,
      exactScreeningsPerDay: 0.0,
      screeningsPerDayChangePercentage: 0.0,
      screeningsPerDayHasArrow: false,
      screeningsPerDayIsUp: true,
      screeningsPerDayBadgeText: '0%',
      screeningDistributionCounts: {
        ObesityCategory.insufficientWeight: 0,
        ObesityCategory.normalWeight: 0,
        ObesityCategory.overweightLevel1: 0,
        ObesityCategory.overweightLevel2: 0,
        ObesityCategory.obesityType1: 0,
        ObesityCategory.obesityType2: 0,
        ObesityCategory.obesityType3: 0,
      },
      screeningDistributionPercentages: {
        ObesityCategory.insufficientWeight: 0.0,
        ObesityCategory.normalWeight: 0.0,
        ObesityCategory.overweightLevel1: 0.0,
        ObesityCategory.overweightLevel2: 0.0,
        ObesityCategory.obesityType1: 0.0,
        ObesityCategory.obesityType2: 0.0,
        ObesityCategory.obesityType3: 0.0,
      },
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

  /// Format angka bilangan bulat standar Indonesia dengan titik sebagai pemisah ribuan
  static String formatNumber(num number) {
    final intVal = number.round();
    final str = intVal.toString();
    return str.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  /// Menghitung rentang tanggal periode sebelumnya dengan durasi hari yang persis sama
  static ({DateTime start, DateTime end})? calculatePreviousPeriod(
    DateTime? start,
    DateTime? end,
  ) {
    if (start == null || end == null) return null;
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    final int daysCount = endDay.difference(startDay).inDays + 1;
    if (daysCount <= 0) return null;

    final prevEndDay = startDay.subtract(const Duration(days: 1));
    final prevStartDay = prevEndDay.subtract(Duration(days: daysCount - 1));
    return (
      start: DateTime(prevStartDay.year, prevStartDay.month, prevStartDay.day, 0, 0, 0),
      end: DateTime(prevEndDay.year, prevEndDay.month, prevEndDay.day, 23, 59, 59, 999),
    );
  }

  /// Menghitung persentase perubahan periode ini dibanding periode lalu secara aman (anti divide-by-zero)
  static ({
    double percentage,
    bool hasArrow,
    bool isUp,
    String badgeText,
  }) calculateChangeBadge(num current, num previous) {
    if (previous <= 0) {
      if (current > 0) {
        return (
          percentage: 0.0,
          hasArrow: true,
          isUp: true,
          badgeText: '0%',
        );
      }
      return (
        percentage: 0.0,
        hasArrow: false,
        isUp: true,
        badgeText: '0%',
      );
    }

    final diff = current - previous;
    final pct = (diff / previous) * 100.0;
    final roundedPct = double.parse(pct.toStringAsFixed(1));

    if (roundedPct > 0) {
      return (
        percentage: roundedPct,
        hasArrow: true,
        isUp: true,
        badgeText: formatPercentage(roundedPct),
      );
    } else if (roundedPct < 0) {
      return (
        percentage: roundedPct,
        hasArrow: true,
        isUp: false,
        badgeText: formatPercentage(roundedPct.abs()),
      );
    } else {
      return (
        percentage: 0.0,
        hasArrow: false,
        isUp: true,
        badgeText: '0%',
      );
    }
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

  /// Memeriksa apakah tanggal berada di dalam rentang tanggal filter (inklusif penuh hari awal dan akhir)
  static bool isDateInRange(DateTime? date, DateTime? start, DateTime? end) {
    if (date == null) return false;
    if (start == null && end == null) return true;
    if (start != null) {
      final startDay = DateTime(start.year, start.month, start.day, 0, 0, 0);
      if (date.isBefore(startDay)) return false;
    }
    if (end != null) {
      final endDay = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
      if (date.isAfter(endDay)) return false;
    }
    return true;
  }

  /// Ekstraksi kategori hasil skrining dari sesi skrining atau pengguna
  static String? extractCategoryRaw(
    ScreeningHistoryItem? screening, [
    UserModel? user,
  ]) {
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

    if (user != null) {
      if (user.bmiCategory.isNotEmpty && user.bmiCategory != 'Normal') {
        return user.bmiCategory;
      } else if (user.bmiCategory.isNotEmpty) {
        return user.bmiCategory;
      }
    }
    return null;
  }

  /// Menghitung seluruh data laporan admin secara bersama di sisi client (pure & testable):
  /// 1. Total Skrining: jumlah skrining pada rentang + persentase perbandingan periode lalu
  /// 2. Pengguna Baru: jumlah pasien baru pada rentang + persentase perbandingan periode lalu
  /// 3. Skrining Rata-rata/Hari: total skrining / jumlah hari rentang (inklusif, min 1)
  /// 4. Distribusi Hasil Skrining: donat 7 kategori perbandingan total skrining
  /// 5. Statistik Pasien: jumlah pasien, breakdown jenis kelamin, kategori obesitas terbaru
  static AdminReportData computeReportData({
    required List<UserModel> users,
    Map<String, ScreeningHistoryItem?>? latestScreenings,
    List<ScreeningHistoryItem>? allScreenings,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    // 1. Filter hanya pasien (non-admin)
    final patients = users.where((u) => !u.isAdmin).toList();

    // 2. Filter rentang tanggal untuk pendaftaran pengguna
    final filteredPatients = patients.where((u) {
      if (startDate == null || endDate == null) return true;
      final uDate = extractUserDate(u);
      return isDateInRange(uDate, startDate, endDate);
    }).toList();

    final totalPatients = filteredPatients.length;

    // 3. Breakdown jenis kelamin pasien
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

    // 4. Kumpulkan seluruh dokumen skrining
    List<ScreeningHistoryItem> allScreeningsList = allScreenings != null
        ? List<ScreeningHistoryItem>.from(allScreenings)
        : (latestScreenings != null
            ? latestScreenings.values.whereType<ScreeningHistoryItem>().toList()
            : <ScreeningHistoryItem>[]);

    // 5. Hitung rentang periode sebelumnya yang panjangnya sama
    final prevPeriod = calculatePreviousPeriod(startDate, endDate);

    // 6. Filter dokumen skrining periode ini dan periode sebelumnya
    final screeningsInPeriod = allScreeningsList
        .where((s) => isDateInRange(s.date, startDate, endDate))
        .toList();

    final prevScreenings = prevPeriod != null
        ? allScreeningsList
            .where((s) => isDateInRange(s.date, prevPeriod.start, prevPeriod.end))
            .toList()
        : <ScreeningHistoryItem>[];

    // a) Total Skrining
    final totalScreenings = screeningsInPeriod.length;
    final prevTotalScreenings = prevScreenings.length;
    final totalScreeningsBadge = calculateChangeBadge(
      totalScreenings,
      prevTotalScreenings,
    );

    // b) Pengguna Baru
    final newUsersCount = filteredPatients.length;
    final prevNewUsers = prevPeriod != null
        ? patients
            .where((u) => isDateInRange(extractUserDate(u), prevPeriod.start, prevPeriod.end))
            .toList()
        : <UserModel>[];
    final prevNewUsersCount = prevNewUsers.length;
    final newUsersBadge = calculateChangeBadge(
      newUsersCount,
      prevNewUsersCount,
    );

    // c) Skrining Rata-rata/Hari (inklusif, minimal 1 hari)
    int daysInRange = 1;
    if (startDate != null && endDate != null) {
      final startDay = DateTime(startDate.year, startDate.month, startDate.day);
      final endDay = DateTime(endDate.year, endDate.month, endDate.day);
      daysInRange = endDay.difference(startDay).inDays + 1;
      if (daysInRange < 1) daysInRange = 1;
    } else {
      // "Semua waktu"
      if (screeningsInPeriod.isNotEmpty) {
        DateTime earliest = screeningsInPeriod.first.date;
        for (final s in screeningsInPeriod) {
          if (s.date.isBefore(earliest)) earliest = s.date;
        }
        daysInRange = DateTime.now().difference(earliest).inDays + 1;
        if (daysInRange < 1) daysInRange = 1;
      }
    }

    final double exactAvg = totalScreenings / daysInRange;
    final int avgPerDay = exactAvg.round();
    final double prevExactAvg = (prevPeriod != null && daysInRange > 0)
        ? (prevTotalScreenings / daysInRange)
        : 0.0;
    final avgBadge = calculateChangeBadge(exactAvg, prevExactAvg);

    // d) Distribusi Hasil Skrining (Donut Chart 7 Kategori)
    final screeningDistributionCounts = <ObesityCategory, int>{
      for (final cfg in ObesityCategoryConfig.all7Categories)
        cfg.category: 0,
    };

    for (final s in screeningsInPeriod) {
      final cat = normalizeObesityCategory(extractCategoryRaw(s));
      if (screeningDistributionCounts.containsKey(cat)) {
        screeningDistributionCounts[cat] =
            (screeningDistributionCounts[cat] ?? 0) + 1;
      }
    }

    final screeningDistributionPercentages = <ObesityCategory, double>{};
    for (final cfg in ObesityCategoryConfig.all7Categories) {
      screeningDistributionPercentages[cfg.category] = calculatePercentage(
        screeningDistributionCounts[cfg.category] ?? 0,
        totalScreenings,
      );
    }

    // e) Kategori Obesitas Terbaru per Pengguna (Bottom Section)
    final latestScreeningsMap = Map<String, ScreeningHistoryItem?>.from(
      latestScreenings ?? {},
    );
    if (latestScreenings == null && allScreenings != null) {
      for (final u in filteredPatients) {
        final userScreenings = allScreeningsList
            .where((s) => s.userId == u.id)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        if (userScreenings.isNotEmpty) {
          latestScreeningsMap[u.id] = userScreenings.first;
        }
      }
    }

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
      final screening = latestScreeningsMap[u.id];
      final rawCat = extractCategoryRaw(screening, u);

      if (rawCat != null && rawCat.trim().isNotEmpty) {
        final cat = normalizeObesityCategory(rawCat);
        obesityCounts[cat] = (obesityCounts[cat] ?? 0) + 1;
        screenedCount++;
      } else {
        obesityCounts[ObesityCategory.tidakDiketahui] =
            (obesityCounts[ObesityCategory.tidakDiketahui] ?? 0) + 1;
      }
    }

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
      totalScreenings: totalScreenings,
      previousPeriodTotalScreenings: prevTotalScreenings,
      totalScreeningsChangePercentage: totalScreeningsBadge.percentage,
      totalScreeningsHasArrow: totalScreeningsBadge.hasArrow,
      totalScreeningsIsUp: totalScreeningsBadge.isUp,
      totalScreeningsBadgeText: totalScreeningsBadge.badgeText,
      newUsersCount: newUsersCount,
      previousPeriodNewUsersCount: prevNewUsersCount,
      newUsersChangePercentage: newUsersBadge.percentage,
      newUsersHasArrow: newUsersBadge.hasArrow,
      newUsersIsUp: newUsersBadge.isUp,
      newUsersBadgeText: newUsersBadge.badgeText,
      screeningsPerDay: avgPerDay,
      exactScreeningsPerDay: exactAvg,
      screeningsPerDayChangePercentage: avgBadge.percentage,
      screeningsPerDayHasArrow: avgBadge.hasArrow,
      screeningsPerDayIsUp: avgBadge.isUp,
      screeningsPerDayBadgeText: avgBadge.badgeText,
      screeningDistributionCounts: screeningDistributionCounts,
      screeningDistributionPercentages: screeningDistributionPercentages,
    );
  }

  // In-memory cache untuk dokumen mentah Firestore
  List<UserModel>? _cachedUsers;
  List<ScreeningHistoryItem>? _cachedScreenings;

  // Mock data untuk pengujian unit & widget
  List<UserModel>? _mockUsers;
  List<ScreeningHistoryItem>? _mockScreenings;

  @visibleForTesting
  void setMockData({
    List<UserModel>? users,
    List<ScreeningHistoryItem>? screenings,
  }) {
    _mockUsers = users != null ? List<UserModel>.from(users) : null;
    _mockScreenings = screenings != null ? List<ScreeningHistoryItem>.from(screenings) : null;
  }

  @visibleForTesting
  void resetMockData() {
    _mockUsers = null;
    _mockScreenings = null;
    _cachedUsers = null;
    _cachedScreenings = null;
  }

  /// Mengambil data laporan admin secara efisien dari Cloud Firestore:
  /// - Dokumen diambil sekali dan di-cache dalam memori
  /// - Riwayat skrining pengguna diambil secara paralel
  Future<AdminReportData> fetchAdminReportData({
    DateTime? startDate,
    DateTime? endDate,
    bool forceRefresh = false,
  }) async {
    final adminService = AdminUserService.instance;
    List<UserModel> users = [];
    List<ScreeningHistoryItem> allScreenings = [];

    if (_mockUsers != null) {
      users = List<UserModel>.from(_mockUsers!);
      allScreenings = _mockScreenings != null
          ? List<ScreeningHistoryItem>.from(_mockScreenings!)
          : getDefaultMockScreenings();
    } else if (adminService.isFirebaseAvailable) {
      if (_cachedUsers != null && _cachedScreenings != null && !forceRefresh) {
        users = _cachedUsers!;
        allScreenings = _cachedScreenings!;
      } else {
        try {
          final snap = await FirebaseFirestore.instance
              .collection('users')
              .get()
              .timeout(const Duration(seconds: 10));

          users = snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList();

          final patients = users.where((u) => !u.isAdmin).toList();
          final screeningFutures = patients.map((u) => adminService.fetchAllScreeningsForUser(u.id));
          final screeningResults = await Future.wait(screeningFutures);
          allScreenings = screeningResults.expand((list) => list).toList();

          _cachedUsers = users;
          _cachedScreenings = allScreenings;
        } catch (e) {
          debugPrint('[AdminReportService] Notice loading data from Firestore: $e');
          users = getDefaultMockUsers();
          allScreenings = getDefaultMockScreenings();
        }
      }
    } else {
      users = getDefaultMockUsers();
      allScreenings = getDefaultMockScreenings();
    }

    return computeReportData(
      users: users,
      allScreenings: allScreenings,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Data mock skrining default untuk offline fallback dan testing lingkungan widget
  static List<ScreeningHistoryItem> getDefaultMockScreenings() {
    return [
      ScreeningHistoryItem(
        id: 'scr_001',
        userId: 'usr_001',
        date: DateTime(2026, 8, 10, 10, 0),
        bmi: 21.8,
        risk: 'Rendah',
        category: 'Normal Weight',
        skriningData: SkriningData()
          ..height = 160.0
          ..weight = 56.0
          ..aiCategoryTitle = 'Normal Weight'
          ..aiCategoryBadge = 'Normal',
      ),
      ScreeningHistoryItem(
        id: 'scr_002',
        userId: 'usr_002',
        date: DateTime(2026, 8, 12, 14, 30),
        bmi: 26.1,
        risk: 'Sedang',
        category: 'Overweight Level 1',
        skriningData: SkriningData()
          ..height = 165.0
          ..weight = 71.0
          ..aiCategoryTitle = 'Overweight Level 1'
          ..aiCategoryBadge = 'Tingkat 1',
      ),
      ScreeningHistoryItem(
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
      ),
    ];
  }

  /// Data mock default pengguna untuk offline fallback dan testing lingkungan widget
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
