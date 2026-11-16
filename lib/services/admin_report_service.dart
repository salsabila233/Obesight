import 'dart:async';
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

/// Model representasi titik data tren aktivitas skrining
class ScreeningTrendPoint {
  final String label; // "Sen", "Sel", dst. atau "Mgg 1", "Mgg 2", dst.
  final int count;
  final DateTime startDate;
  final DateTime endDate;

  const ScreeningTrendPoint({
    required this.label,
    required this.count,
    required this.startDate,
    required this.endDate,
  });

  @override
  String toString() => 'ScreeningTrendPoint(label: $label, count: $count)';
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
  final String formattedScreeningsPerDay;
  final double screeningsPerDayChangePercentage;
  final bool screeningsPerDayHasArrow;
  final bool screeningsPerDayIsUp;
  final String screeningsPerDayBadgeText;

  // 4. Tren Aktivitas Skrining (Grafik Garis Halus & Area Transparan)
  final List<ScreeningTrendPoint> trendPoints;

  // 5. Donut Chart: Distribusi Hasil Skrining (7 Kategori) - Kompatibilitas
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
    this.formattedScreeningsPerDay = '0',
    this.screeningsPerDayChangePercentage = 0.0,
    this.screeningsPerDayHasArrow = false,
    this.screeningsPerDayIsUp = true,
    this.screeningsPerDayBadgeText = '0%',
    this.trendPoints = const [],
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
      },
      genderPercentages: {
        AdminReportGender.perempuan: 0.0,
        AdminReportGender.lakiLaki: 0.0,
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
      formattedScreeningsPerDay: '0',
      screeningsPerDayChangePercentage: 0.0,
      screeningsPerDayHasArrow: false,
      screeningsPerDayIsUp: true,
      screeningsPerDayBadgeText: '0%',
      trendPoints: [],
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

/// Jenis laporan cetak: Eksternal (Ringkas) atau Internal (Lengkap)
enum ReportType {
  eksternal,
  internal,
}

extension ReportTypeExtension on ReportType {
  String get title {
    switch (this) {
      case ReportType.eksternal:
        return 'Laporan Eksternal';
      case ReportType.internal:
        return 'Laporan Internal';
    }
  }

  String get shortTitle {
    switch (this) {
      case ReportType.eksternal:
        return 'Cetak Laporan Ringkas';
      case ReportType.internal:
        return 'Cetak Laporan Lengkap';
    }
  }

  String get description {
    switch (this) {
      case ReportType.eksternal:
        return 'Ringkas untuk pihak luar: distribusi IMT, rekapitulasi skrining, tingkat risiko, dan perbedaan jenis kelamin.';
      case ReportType.internal:
        return 'Lengkap untuk pengelola: 15 bagian mulai dari pengguna, IMT, skrining, aktivitas, makanan, tidur, hingga analisis.';
    }
  }
}

/// Pilihan rentang periode cetak laporan
enum ReportPeriod {
  satuBulan, // 30 hari terakhir
  triwulan,  // 90 hari terakhir
  setahun,   // 365 hari terakhir
}

extension ReportPeriodExtension on ReportPeriod {
  String get label {
    switch (this) {
      case ReportPeriod.satuBulan:
        return 'Satu bulan';
      case ReportPeriod.triwulan:
        return 'Triwulan';
      case ReportPeriod.setahun:
        return 'Setahun';
    }
  }

  int get daysCount {
    switch (this) {
      case ReportPeriod.satuBulan:
        return 30;
      case ReportPeriod.triwulan:
        return 90;
      case ReportPeriod.setahun:
        return 365;
    }
  }
}

/// 8 Bagian laporan yang dapat dipilih untuk Laporan Internal
enum ReportSection {
  dataPengguna,
  aktivitasFisik,
  trenAktivitas,
  dataImt,
  makananMinuman,
  analisisKesimpulan,
  hasilSkrining,
  polaTidur,
}

extension ReportSectionExtension on ReportSection {
  String get label {
    switch (this) {
      case ReportSection.dataPengguna:
        return 'Data Pengguna';
      case ReportSection.aktivitasFisik:
        return 'Aktivitas Fisik';
      case ReportSection.trenAktivitas:
        return 'Tren Aktivitas';
      case ReportSection.dataImt:
        return 'Data IMT';
      case ReportSection.makananMinuman:
        return 'Makanan & Minuman';
      case ReportSection.analisisKesimpulan:
        return 'Analisis & Kesimpulan';
      case ReportSection.hasilSkrining:
        return 'Hasil Skrining';
      case ReportSection.polaTidur:
        return 'Pola Tidur';
    }
  }
}

/// Objek konfigurasi parameter cetak laporan
class ReportConfig {
  final ReportType type;
  final ReportPeriod period;
  final int? userLimit; // null = Semua pengguna
  final Set<ReportSection> selectedSections;

  const ReportConfig({
    this.type = ReportType.eksternal,
    this.period = ReportPeriod.satuBulan,
    this.userLimit,
    this.selectedSections = const {
      ReportSection.dataPengguna,
      ReportSection.aktivitasFisik,
      ReportSection.trenAktivitas,
      ReportSection.dataImt,
      ReportSection.makananMinuman,
      ReportSection.analisisKesimpulan,
      ReportSection.hasilSkrining,
      ReportSection.polaTidur,
    },
  });

  ReportConfig copyWith({
    ReportType? type,
    ReportPeriod? period,
    int? Function()? userLimit,
    Set<ReportSection>? selectedSections,
  }) {
    return ReportConfig(
      type: type ?? this.type,
      period: period ?? this.period,
      userLimit: userLimit != null ? userLimit() : this.userLimit,
      selectedSections: selectedSections ?? this.selectedSections,
    );
  }
}

/// Model agregasi komprehensif data untuk dicetak dalam PDF
class ReportData {
  final ReportConfig config;
  final DateTime startDate;
  final DateTime endDate;
  final int daysCount;
  final int totalAvailablePatients; // M
  final int selectedPatientsCount;   // N
  final List<UserModel> selectedPatients;
  final List<ScreeningHistoryItem> selectedScreenings;

  // Skrining
  final int totalScreenings;
  final double exactScreeningsPerDay;
  final String formattedScreeningsPerDay;
  final String screeningsPerDayBadgeText;
  final bool screeningsPerDayHasArrow;
  final bool screeningsPerDayIsUp;

  // Gender (Hanya Perempuan & Laki-laki, tanpa "Tidak diketahui")
  final int perempuanCount;
  final int lakiLakiCount;
  final double perempuanPercentage;
  final double lakiLakiPercentage;
  final int genderExcludedCount; // Pengguna yang jenis kelaminnya tidak valid/kosong

  // Kategori Obesitas (1 pengguna dihitung 1 kali berdasarkan skrining terbarunya)
  final int totalScreenedPatients;
  final Map<ObesityCategory, int> obesityCounts;
  final Map<ObesityCategory, double> obesityPercentages;

  // Tingkat Risiko (Rendah, Sedang, Tinggi, Perlu perhatian gizi)
  final Map<String, int> riskCounts;
  final Map<String, double> riskPercentages;

  // Tren Skrining
  final List<ScreeningTrendPoint> trendPoints;

  // Status jika userLimit melebihi pengguna yang tersedia
  final bool isExceedingAvailable;

  // ================= TAHAP 2 DATA TAMBAHAN =================
  // 1. Cross-Tab Gender x Kategori (Laporan Eksternal Bagian III.4)
  final int perempuanInsufficient;
  final int perempuanNormal;
  final int perempuanOverweight;
  final int perempuanObesity;
  final int lakiLakiInsufficient;
  final int lakiLakiNormal;
  final int lakiLakiOverweight;
  final int lakiLakiObesity;

  // 2. Data Pengguna Baru & Pertumbuhan (Internal Bagian 2 & 4)
  final int newUsersCount;
  final List<ScreeningTrendPoint> newUserTrendPoints;
  final String screeningsComparisonText;

  // 3. Distribusi Usia (Internal Bagian 3)
  final int ageUnder18Count;
  final int age18To24Count;
  final int age25To34Count;
  final int age35To44Count;
  final int age45To54Count;
  final int age55PlusCount;
  final int ageUnknownCount;

  // 4. Data Perhitungan IMT (Internal Bagian 5)
  final double? avgBmi;
  final double? minBmi;
  final double? maxBmi;
  final double? avgWeight;
  final double? avgHeight;

  // 5. Riwayat Hasil Skrining: Keaktifan & Perubahan Kondisi (Internal Bagian 10)
  final int screenings1TimeCount;
  final int screenings2TimesCount;
  final int screenings3PlusTimesCount;
  final int conditionImprovedCount;
  final int conditionUnchangedCount;
  final int conditionWorsenedCount;

  // 6. Aktivitas Fisik, Nutrisi, Tidur (Internal Bagian 11, 12, 13)
  final bool hasPhysicalActivityData;
  final int physicalActivityUsersCount;
  final int physicalActivityTotalMinutes;
  final String physicalActivityTopName;

  final bool hasNutritionData;
  final int nutritionUsersCount;
  final double nutritionAvgMealsPerDay;
  final double nutritionAvgWaterGlassesPerDay;

  final bool hasSleepData;
  final int sleepAvgDurationMinutes;
  final double sleepUnder7HoursPct;
  final int sleepActiveRestReminderCount;

  const ReportData({
    required this.config,
    required this.startDate,
    required this.endDate,
    required this.daysCount,
    required this.totalAvailablePatients,
    required this.selectedPatientsCount,
    required this.selectedPatients,
    required this.selectedScreenings,
    required this.totalScreenings,
    required this.exactScreeningsPerDay,
    required this.formattedScreeningsPerDay,
    required this.screeningsPerDayBadgeText,
    required this.screeningsPerDayHasArrow,
    required this.screeningsPerDayIsUp,
    required this.perempuanCount,
    required this.lakiLakiCount,
    required this.perempuanPercentage,
    required this.lakiLakiPercentage,
    required this.genderExcludedCount,
    required this.totalScreenedPatients,
    required this.obesityCounts,
    required this.obesityPercentages,
    required this.riskCounts,
    required this.riskPercentages,
    required this.trendPoints,
    this.isExceedingAvailable = false,
    this.perempuanInsufficient = 0,
    this.perempuanNormal = 0,
    this.perempuanOverweight = 0,
    this.perempuanObesity = 0,
    this.lakiLakiInsufficient = 0,
    this.lakiLakiNormal = 0,
    this.lakiLakiOverweight = 0,
    this.lakiLakiObesity = 0,
    this.newUsersCount = 0,
    this.newUserTrendPoints = const [],
    this.screeningsComparisonText = '',
    this.ageUnder18Count = 0,
    this.age18To24Count = 0,
    this.age25To34Count = 0,
    this.age35To44Count = 0,
    this.age45To54Count = 0,
    this.age55PlusCount = 0,
    this.ageUnknownCount = 0,
    this.avgBmi,
    this.minBmi,
    this.maxBmi,
    this.avgWeight,
    this.avgHeight,
    this.screenings1TimeCount = 0,
    this.screenings2TimesCount = 0,
    this.screenings3PlusTimesCount = 0,
    this.conditionImprovedCount = 0,
    this.conditionUnchangedCount = 0,
    this.conditionWorsenedCount = 0,
    this.hasPhysicalActivityData = false,
    this.physicalActivityUsersCount = 0,
    this.physicalActivityTotalMinutes = 0,
    this.physicalActivityTopName = '',
    this.hasNutritionData = false,
    this.nutritionUsersCount = 0,
    this.nutritionAvgMealsPerDay = 0.0,
    this.nutritionAvgWaterGlassesPerDay = 0.0,
    this.hasSleepData = false,
    this.sleepAvgDurationMinutes = 0,
    this.sleepUnder7HoursPct = 0.0,
    this.sleepActiveRestReminderCount = 0,
  });
}

/// Service untuk logika pemetaan, normalisasi, dan perhitungan data laporan Admin ObeSight
class AdminReportService {
  static final AdminReportService instance = AdminReportService._internal();
  AdminReportService._internal();

  /// 1. Normalisasi jenis kelamin pengguna dengan penanganan variasi penulisan & data kosong
  static AdminReportGender? normalizeGender(String? raw) {
    if (raw == null) return null;
    final clean = raw.trim().toLowerCase();
    if (clean.isEmpty) return null;

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

    return null;
  }

  /// Label tampilan bahasa Indonesia untuk jenis kelamin
  static String genderDisplayName(AdminReportGender gender) {
    switch (gender) {
      case AdminReportGender.perempuan:
        return 'Perempuan';
      case AdminReportGender.lakiLaki:
        return 'Laki-laki';
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

  /// Format angka skrining rata-rata/hari: 1 desimal dengan koma (contoh: 12 skrining / 30 hari = 0,4)
  /// Nilai kecil di atas 0 tidak boleh tampil sebagai 0 (misal: 1 / 30 = 0,033 -> 0,1)
  /// Jika hasilnya bilangan bulat (atau 0), tampilkan bulat (contoh: 2 atau 0) konsisten dengan kartu lain
  static String formatScreeningsPerDay(double value) {
    if (value <= 0.0) return '0';
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    double rounded = double.parse(value.toStringAsFixed(1));
    if (rounded == 0.0) {
      rounded = 0.1; // Nilai kecil di atas 0 jangan tampil sebagai 0
    }
    if (rounded == rounded.roundToDouble()) {
      return rounded.toInt().toString();
    }
    return rounded.toStringAsFixed(1).replaceAll('.', ',');
  }

  /// Menghitung pembagian bucket titik tren aktivitas skrining:
  /// - 7 hari: 1 titik per hari (Sen, Sel, ...)
  /// - 30 hari / 1 bulan: per minggu (4 sampai 5 titik) berlabel "Mgg 1", "Mgg 2", ...
  /// - Rentang lebih panjang / semua waktu: per minggu atau per bulan (maks 12 titik)
  /// - Periode tanpa skrining bernilai 0
  /// - Jumlah total seluruh titik konsisten 100% sama dengan totalScreenings
  static List<ScreeningTrendPoint> calculateTrendPoints({
    required List<ScreeningHistoryItem> screenings,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    const dayNames = {
      1: 'Sen',
      2: 'Sel',
      3: 'Rab',
      4: 'Kam',
      5: 'Jum',
      6: 'Sab',
      7: 'Min',
    };

    const monthNames = {
      1: 'Jan',
      2: 'Feb',
      3: 'Mar',
      4: 'Apr',
      5: 'Mei',
      6: 'Jun',
      7: 'Jul',
      8: 'Agu',
      9: 'Sep',
      10: 'Okt',
      11: 'Nov',
      12: 'Des',
    };

    DateTime start;
    DateTime end;

    if (startDate != null && endDate != null) {
      start = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
      end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);
    } else {
      // Rentang "Semua waktu"
      if (screenings.isNotEmpty) {
        DateTime earliest = screenings.first.date;
        DateTime latest = screenings.first.date;
        for (final s in screenings) {
          if (s.date.isBefore(earliest)) earliest = s.date;
          if (s.date.isAfter(latest)) latest = s.date;
        }
        start = DateTime(earliest.year, earliest.month, earliest.day, 0, 0, 0);
        end = DateTime(latest.year, latest.month, latest.day, 23, 59, 59, 999);
      } else {
        // Fallback rentang 7 hari jika kosong
        final now = DateTime.now();
        start = DateTime(now.year, now.month, now.day - 6, 0, 0, 0);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
      }
    }

    final int daysCount = end.difference(start).inDays + 1;

    // A. 7 hari atau kurang: 1 titik per hari (Sen, Sel, ...)
    if (daysCount <= 7) {
      final points = <ScreeningTrendPoint>[];
      for (int i = 0; i < daysCount; i++) {
        final dayStart = start.add(Duration(days: i));
        final dayEnd = DateTime(dayStart.year, dayStart.month, dayStart.day, 23, 59, 59, 999);
        final label = dayNames[dayStart.weekday] ?? 'Hari';

        final count = screenings.where((s) => isDateInRange(s.date, dayStart, dayEnd)).length;
        points.add(ScreeningTrendPoint(
          label: label,
          count: count,
          startDate: dayStart,
          endDate: dayEnd,
        ));
      }
      return points;
    }

    // B. Antara 8 sampai 35 hari (misal 30 hari atau 1 bulan): per minggu ("Mgg 1", "Mgg 2", ...)
    if (daysCount <= 35) {
      final numWeeks = (daysCount / 7.0).ceil();
      final points = <ScreeningTrendPoint>[];

      for (int w = 0; w < numWeeks; w++) {
        final wStart = start.add(Duration(days: w * 7));
        DateTime wEnd;
        if (w == numWeeks - 1) {
          wEnd = end;
        } else {
          final temp = start.add(Duration(days: (w + 1) * 7 - 1));
          wEnd = DateTime(temp.year, temp.month, temp.day, 23, 59, 59, 999);
        }

        final count = screenings.where((s) {
          return !s.date.isBefore(wStart) && !s.date.isAfter(wEnd);
        }).length;

        points.add(ScreeningTrendPoint(
          label: 'Mgg ${w + 1}',
          count: count,
          startDate: wStart,
          endDate: wEnd,
        ));
      }
      return points;
    }

    // C. Lebih dari 35 hari: per bulan (maksimal ~12 titik) atau per minggu jika pendek
    if (daysCount <= 84) {
      final numWeeks = (daysCount / 7.0).ceil();
      final points = <ScreeningTrendPoint>[];
      for (int w = 0; w < numWeeks; w++) {
        final wStart = start.add(Duration(days: w * 7));
        DateTime wEnd = (w == numWeeks - 1)
            ? end
            : DateTime(wStart.year, wStart.month, wStart.day + 6, 23, 59, 59, 999);

        final count = screenings.where((s) {
          return !s.date.isBefore(wStart) && !s.date.isAfter(wEnd);
        }).length;

        points.add(ScreeningTrendPoint(
          label: 'Mgg ${w + 1}',
          count: count,
          startDate: wStart,
          endDate: wEnd,
        ));
      }
      return points;
    } else {
      // Per bulan (maksimal 12 bulan)
      final points = <ScreeningTrendPoint>[];
      DateTime currentMonthStart = DateTime(start.year, start.month, 1);

      while (!currentMonthStart.isAfter(end) && points.length < 12) {
        final nextMonth = DateTime(currentMonthStart.year, currentMonthStart.month + 1, 1);
        final currentMonthEnd = nextMonth.subtract(const Duration(milliseconds: 1));

        final bucketStart = currentMonthStart.isBefore(start) ? start : currentMonthStart;
        final bucketEnd = currentMonthEnd.isAfter(end) ? end : currentMonthEnd;

        final label = monthNames[currentMonthStart.month] ?? '${currentMonthStart.month}';
        final count = screenings.where((s) {
          return !s.date.isBefore(bucketStart) && !s.date.isAfter(bucketEnd);
        }).length;

        points.add(ScreeningTrendPoint(
          label: label,
          count: count,
          startDate: bucketStart,
          endDate: bucketEnd,
        ));

        currentMonthStart = nextMonth;
      }
      return points;
    }
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
  /// - Panah naik/turun hanya muncul jika nilai benar-benar naik atau turun
  /// - Jika periode sebelumnya 0 dan periode ini > 0: penanda netral "Baru" tanpa panah
  /// - Jika keduanya 0 atau tidak berubah: "0%" netral tanpa panah
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
          hasArrow: false,
          isUp: true,
          badgeText: 'Baru',
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
    final localDate = date.toLocal();
    if (start != null) {
      final localStart = start.toLocal();
      final startDay = DateTime(localStart.year, localStart.month, localStart.day, 0, 0, 0, 0, 0);
      if (localDate.isBefore(startDay)) return false;
    }
    if (end != null) {
      final localEnd = end.toLocal();
      final endDay = DateTime(localEnd.year, localEnd.month, localEnd.day, 23, 59, 59, 999, 999);
      if (localDate.isAfter(endDay)) return false;
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

  /// Resolusi kategori klinis lengkap (dari label atau evaluasi IMT/BMI sebagai fallback aman)
  static ObesityCategory resolveObesityCategory(
    ScreeningHistoryItem? screening, [
    UserModel? user,
  ]) {
    final raw = extractCategoryRaw(screening, user);
    final cat = normalizeObesityCategory(raw);
    if (cat != ObesityCategory.tidakDiketahui) {
      return cat;
    }
    final bmi = (screening != null && screening.bmi > 0)
        ? screening.bmi
        : (user != null && user.bmiScore > 0 ? user.bmiScore : 0.0);
    if (bmi > 0.0) {
      if (bmi < 18.5) return ObesityCategory.insufficientWeight;
      if (bmi < 23.0) return ObesityCategory.normalWeight;
      if (bmi < 25.0) return ObesityCategory.overweightLevel1;
      if (bmi < 30.0) return ObesityCategory.overweightLevel2;
      if (bmi < 35.0) return ObesityCategory.obesityType1;
      if (bmi < 40.0) return ObesityCategory.obesityType2;
      return ObesityCategory.obesityType3;
    }
    return ObesityCategory.tidakDiketahui;
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
    // A. Deduplikasi dan penyaringan pengguna valid
    final seenUserIds = <String>{};
    final uniqueUsers = <UserModel>[];
    for (final u in users) {
      if (u.id.trim().isEmpty) {
        debugPrint('[AdminReportService] Data tidak lengkap: Pengguna dengan ID kosong dilewati.');
        continue;
      }
      if (seenUserIds.add(u.id)) {
        uniqueUsers.add(u);
      } else {
        debugPrint('[AdminReportService] Data duplikat diabaikan: Pengguna ID ${u.id}');
      }
    }

    // 1. Filter hanya pasien reguler (non-admin & non-dokter Hendra)
    final patients = uniqueUsers.where((u) {
      final nameLower = u.name.toLowerCase();
      final emailLower = u.email.toLowerCase();
      if (nameLower.contains('hendra') || emailLower.contains('hendra')) {
        return false;
      }
      if (u.isAdmin ||
          u.role == UserRole.admin ||
          emailLower == 'adminobesight@gmail.com' ||
          emailLower.contains('adminobesight') ||
          emailLower == 'admin@obesight.com') {
        return false;
      }
      // Akun tanpa jenis kelamin dikeluarkan dari seluruh perhitungan Laporan
      if (normalizeGender(u.gender) == null) {
        return false;
      }
      return true;
    }).toList();

    // 2. Filter rentang tanggal untuk pendaftaran pengguna
    final filteredPatients = patients.where((u) {
      if (startDate == null || endDate == null) return true;
      final uDate = extractUserDate(u);
      if (uDate == null) {
        debugPrint('[AdminReportService] Data tidak lengkap: Pengguna ${u.id} tidak memiliki tanggal registrasi valid.');
        return false;
      }
      return isDateInRange(uDate, startDate, endDate);
    }).toList();

    final totalPatients = filteredPatients.length;

    // 3. Breakdown jenis kelamin pasien (hanya Perempuan dan Laki-laki)
    int perempuanCount = 0;
    int lakiLakiCount = 0;

    for (final u in filteredPatients) {
      final g = normalizeGender(u.gender);
      if (g == AdminReportGender.perempuan) {
        perempuanCount++;
      } else if (g == AdminReportGender.lakiLaki) {
        lakiLakiCount++;
      }
    }

    final genderCounts = <AdminReportGender, int>{
      AdminReportGender.perempuan: perempuanCount,
      AdminReportGender.lakiLaki: lakiLakiCount,
    };

    final double perempuanPercentage = totalPatients > 0
        ? calculatePercentage(perempuanCount, totalPatients)
        : 0.0;
    final double lakiLakiPercentage = totalPatients > 0
        ? (perempuanCount > 0 && lakiLakiCount > 0
            ? double.parse((100.0 - perempuanPercentage).toStringAsFixed(1))
            : calculatePercentage(lakiLakiCount, totalPatients))
        : 0.0;

    final genderPercentages = <AdminReportGender, double>{
      AdminReportGender.perempuan: perempuanPercentage,
      AdminReportGender.lakiLaki: lakiLakiPercentage,
    };

    // 4. Kumpulkan seluruh dokumen skrining dan deduplikasi
    List<ScreeningHistoryItem> rawScreeningsList = allScreenings != null
        ? List<ScreeningHistoryItem>.from(allScreenings)
        : (latestScreenings != null
            ? latestScreenings.values.whereType<ScreeningHistoryItem>().toList()
            : <ScreeningHistoryItem>[]);

    final seenScreeningIds = <String>{};
    final validScreenings = <ScreeningHistoryItem>[];
    for (final s in rawScreeningsList) {
      if (s.id.trim().isEmpty) {
        debugPrint('[AdminReportService] Data tidak lengkap: Skrining dengan ID kosong dilewati.');
        continue;
      }
      if (seenScreeningIds.add(s.id)) {
        validScreenings.add(s);
      } else {
        debugPrint('[AdminReportService] Data duplikat diabaikan: Skrining ID ${s.id}');
      }
    }

    // 5. Hitung rentang periode sebelumnya yang panjangnya sama
    final prevPeriod = calculatePreviousPeriod(startDate, endDate);

    // 6. Filter dokumen skrining periode ini dan periode sebelumnya
    final screeningDistributionCounts = <ObesityCategory, int>{
      for (final cfg in ObesityCategoryConfig.all7Categories)
        cfg.category: 0,
    };

    final screeningsInPeriod = <ScreeningHistoryItem>[];
    for (final s in validScreenings) {
      if (!isDateInRange(s.date, startDate, endDate)) continue;
      final cat = resolveObesityCategory(s);
      if (cat == ObesityCategory.tidakDiketahui) {
        debugPrint('[AdminReportService] Data tidak lengkap: Skrining ${s.id} tanpa kategori atau IMT valid dilewati.');
        continue;
      }
      screeningsInPeriod.add(s);
      screeningDistributionCounts[cat] = (screeningDistributionCounts[cat] ?? 0) + 1;
    }

    final prevScreenings = prevPeriod != null
        ? validScreenings.where((s) {
            if (!isDateInRange(s.date, prevPeriod.start, prevPeriod.end)) return false;
            return resolveObesityCategory(s) != ObesityCategory.tidakDiketahui;
          }).toList()
        : <ScreeningHistoryItem>[];

    // a) Total Skrining (jumlah donat kategori = Total Skrining pada rentang yang sama)
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
    final String formattedAvg = formatScreeningsPerDay(exactAvg);
    final double prevExactAvg = (prevPeriod != null && daysInRange > 0)
        ? (prevTotalScreenings / daysInRange)
        : 0.0;
    final avgBadge = calculateChangeBadge(exactAvg, prevExactAvg);

    // d) Tren Aktivitas Skrining (Grafik Garis & Area)
    final trendPoints = calculateTrendPoints(
      screenings: screeningsInPeriod,
      startDate: startDate,
      endDate: endDate,
    );

    // e) Distribusi Hasil Skrining (Donut Chart 7 Kategori - kompatibilitas)
    final screeningDistributionPercentages = <ObesityCategory, double>{};
    for (final cfg in ObesityCategoryConfig.all7Categories) {
      screeningDistributionPercentages[cfg.category] = calculatePercentage(
        screeningDistributionCounts[cfg.category] ?? 0,
        totalScreenings,
      );
    }

    // f) Kategori Obesitas Terbaru per Pengguna (Bottom Section: 1 Pengguna Dihitung 1 Kali)
    final latestScreeningsMap = Map<String, ScreeningHistoryItem?>.from(
      latestScreenings ?? {},
    );
    if (latestScreenings == null) {
      for (final u in filteredPatients) {
        final userScreenings = validScreenings
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
      final cat = resolveObesityCategory(screening, u);

      if (cat != ObesityCategory.tidakDiketahui) {
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
      formattedScreeningsPerDay: formattedAvg,
      screeningsPerDayChangePercentage: avgBadge.percentage,
      screeningsPerDayHasArrow: avgBadge.hasArrow,
      screeningsPerDayIsUp: avgBadge.isUp,
      screeningsPerDayBadgeText: avgBadge.badgeText,
      trendPoints: trendPoints,
      screeningDistributionCounts: screeningDistributionCounts,
      screeningDistributionPercentages: screeningDistributionPercentages,
    );
  }

  // ===========================================================================
  // CETAK LAPORAN (REPORT PRINT & PDF GENERATION)
  // ===========================================================================

  /// Menentukan rentang tanggal kalender sebenarnya untuk periode cetak laporan
  /// - Satu bulan: 30 hari terakhir (inklusif penuh hari ini)
  /// - Triwulan: 90 hari terakhir (inklusif penuh hari ini)
  /// - Setahun: 365 hari terakhir (inklusif penuh hari ini)
  static ({DateTime start, DateTime end, int days}) resolveReportPeriodDates(
    ReportPeriod period, [
    DateTime? referenceDate,
  ]) {
    final now = referenceDate ?? DateTime.now();
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    final int days = period.daysCount;
    final startDay = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));
    final start = DateTime(startDay.year, startDay.month, startDay.day, 0, 0, 0);
    return (start: start, end: end, days: days);
  }

  /// Format tampilan rentang tanggal teks kecil (contoh: "17 Okt - 15 Nov 2026")
  static String formatReportPeriodRange(DateTime start, DateTime end) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final startMonth = months[start.month - 1];
    final endMonth = months[end.month - 1];
    if (start.year == end.year) {
      return '${start.day} $startMonth - ${end.day} $endMonth ${end.year}';
    }
    return '${start.day} $startMonth ${start.year} - ${end.day} $endMonth ${end.year}';
  }

  /// Pemetaan tingkat risiko klinis sesuai aturan:
  /// - Rendah = Normal Weight
  /// - Sedang = Overweight Level 1 dan 2
  /// - Tinggi = Obesity Type 1, 2, 3
  /// - Insufficient Weight = "Perlu perhatian gizi"
  static String resolveClinicalRisk(ObesityCategory category) {
    switch (category) {
      case ObesityCategory.insufficientWeight:
        return 'Perlu perhatian gizi';
      case ObesityCategory.normalWeight:
        return 'Rendah';
      case ObesityCategory.overweightLevel1:
      case ObesityCategory.overweightLevel2:
        return 'Sedang';
      case ObesityCategory.obesityType1:
      case ObesityCategory.obesityType2:
      case ObesityCategory.obesityType3:
        return 'Tinggi';
      case ObesityCategory.tidakDiketahui:
        return 'Tidak diketahui';
    }
  }

  /// Jarak kategori ke Normal Weight sesuai aturan klinis ObeSight:
  /// Normal=0, Insufficient=1, Overweight 1=1, Overweight 2=2,
  /// Obesity 1=3, Obesity 2=4, Obesity 3=5.
  static int getDistanceToNormal(ObesityCategory cat) {
    switch (cat) {
      case ObesityCategory.normalWeight:
        return 0;
      case ObesityCategory.insufficientWeight:
      case ObesityCategory.overweightLevel1:
        return 1;
      case ObesityCategory.overweightLevel2:
        return 2;
      case ObesityCategory.obesityType1:
        return 3;
      case ObesityCategory.obesityType2:
        return 4;
      case ObesityCategory.obesityType3:
        return 5;
      case ObesityCategory.tidakDiketahui:
        return 0;
    }
  }

  /// Pengelompokan titik data tren tanggal untuk cetak laporan:
  /// - Satu bulan: per minggu (5 titik: "Mgg 1", "Mgg 2", "Mgg 3", "Mgg 4", "Mgg 5")
  /// - Triwulan: per 2 minggu (~6 sampai 7 titik)
  /// - Setahun: per bulan (12 titik: "Jan", "Feb", ... "Des")
  static List<ScreeningTrendPoint> calculateTrendPointsForDates({
    required List<DateTime> dates,
    required ReportPeriod period,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    switch (period) {
      case ReportPeriod.satuBulan:
        final points = <ScreeningTrendPoint>[];
        for (int w = 0; w < 5; w++) {
          final wStart = startDate.add(Duration(days: w * 7));
          final DateTime wEnd = (w == 4)
              ? endDate
              : DateTime(wStart.year, wStart.month, wStart.day + 6, 23, 59, 59, 999);

          final count = dates.where((d) => !d.isBefore(wStart) && !d.isAfter(wEnd)).length;
          points.add(ScreeningTrendPoint(
            label: 'Mgg ${w + 1}',
            count: count,
            startDate: wStart,
            endDate: wEnd,
          ));
        }
        return points;

      case ReportPeriod.triwulan:
        final numBuckets = (90 / 14.0).ceil(); // 7 titik
        final points = <ScreeningTrendPoint>[];
        for (int b = 0; b < numBuckets; b++) {
          final bStart = startDate.add(Duration(days: b * 14));
          final DateTime bEnd = (b == numBuckets - 1)
              ? endDate
              : DateTime(bStart.year, bStart.month, bStart.day + 13, 23, 59, 59, 999);

          final count = dates.where((d) => !d.isBefore(bStart) && !d.isAfter(bEnd)).length;
          final label = 'Mgg ${b * 2 + 1}-${b == numBuckets - 1 ? 13 : (b + 1) * 2}';
          points.add(ScreeningTrendPoint(
            label: label,
            count: count,
            startDate: bStart,
            endDate: bEnd,
          ));
        }
        return points;

      case ReportPeriod.setahun:
        const monthNames = [
          'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
          'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
        ];
        final points = <ScreeningTrendPoint>[];
        DateTime currentMonthStart = DateTime(startDate.year, startDate.month, 1);

        while (!currentMonthStart.isAfter(endDate) && points.length < 12) {
          final nextMonth = DateTime(currentMonthStart.year, currentMonthStart.month + 1, 1);
          final currentMonthEnd = nextMonth.subtract(const Duration(milliseconds: 1));

          final bucketStart = currentMonthStart.isBefore(startDate) ? startDate : currentMonthStart;
          final bucketEnd = currentMonthEnd.isAfter(endDate) ? endDate : currentMonthEnd;

          final label = monthNames[currentMonthStart.month - 1];
          final count = dates.where((d) => !d.isBefore(bucketStart) && !d.isAfter(bucketEnd)).length;

          points.add(ScreeningTrendPoint(
            label: label,
            count: count,
            startDate: bucketStart,
            endDate: bucketEnd,
          ));

          currentMonthStart = nextMonth;
        }
        return points;
    }
  }

  /// Pengelompokan titik data tren skrining untuk cetak laporan
  static List<ScreeningTrendPoint> calculatePrintTrendPoints({
    required List<ScreeningHistoryItem> screenings,
    required ReportPeriod period,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return calculateTrendPointsForDates(
      dates: screenings.map((s) => s.date).toList(),
      period: period,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Menghitung seluruh data laporan cetak (ReportData) dari pengguna dan skrining
  /// Sesuai aturan:
  /// 1. Pemilihan N: urutkan skrining terbaru dalam periode, lalu tanpa skrining berdasarkan pendaftaran terbaru
  /// 2. Hitung semua angka hanya dari N pengguna tersebut
  /// 3. Gender hanya Perempuan dan Laki-laki; pengguna tanpa jenis kelamin dikeluarkan dari hitungan gender
  /// 4. 1 pengguna dihitung 1 kali berdasarkan skrining terbarunya dalam periode
  static ReportData computePrintReportData({
    required List<UserModel> users,
    required List<ScreeningHistoryItem> allScreenings,
    required ReportConfig config,
    DateTime? referenceDate,
  }) {
    // 1. Rentang tanggal periode
    final periodDates = resolveReportPeriodDates(config.period, referenceDate);
    final startDate = periodDates.start;
    final endDate = periodDates.end;
    final daysCount = periodDates.days;

    // 2. Filter hanya pasien valid (non-admin, non-dokter Hendra)
    final seenUserIds = <String>{};
    final uniqueUsers = <UserModel>[];
    for (final u in users) {
      if (u.id.trim().isEmpty) continue;
      if (seenUserIds.add(u.id)) {
        uniqueUsers.add(u);
      }
    }

    final patients = uniqueUsers.where((u) {
      final nameLower = u.name.toLowerCase();
      final emailLower = u.email.toLowerCase();
      if (nameLower.contains('hendra') || emailLower.contains('hendra')) {
        return false;
      }
      if (u.isAdmin ||
          u.role == UserRole.admin ||
          emailLower == 'adminobesight@gmail.com' ||
          emailLower.contains('adminobesight') ||
          emailLower == 'admin@obesight.com') {
        return false;
      }
      // Akun tanpa jenis kelamin dikeluarkan dari seluruh perhitungan Laporan
      if (normalizeGender(u.gender) == null) {
        return false;
      }
      return true;
    }).toList();

    // 3. Validasi & deduplikasi dokumen skrining
    final seenScreeningIds = <String>{};
    final validScreenings = <ScreeningHistoryItem>[];
    for (final s in allScreenings) {
      if (s.id.trim().isEmpty) continue;
      if (seenScreeningIds.add(s.id)) {
        validScreenings.add(s);
      }
    }

    // Skrining dalam periode
    final screeningsInPeriod = validScreenings
        .where((s) => isDateInRange(s.date, startDate, endDate))
        .toList();

    // 4. Pemilihan N Pengguna (BAGIAN C.2):
    // - Urutkan pengguna (pasien) berdasarkan tanggal skrining terakhir dalam periode (terbaru dulu);
    // - Yang tanpa skrining pada periode diurutkan setelahnya berdasarkan tanggal daftar terbaru.
    // - Ambil N pertama.
    final patientsWithScreeningInPeriod = <UserModel, DateTime>{};
    final patientsWithoutScreeningInPeriod = <UserModel>[];

    for (final p in patients) {
      final userScreeningsInPeriod = screeningsInPeriod.where((s) => s.userId == p.id).toList();
      if (userScreeningsInPeriod.isNotEmpty) {
        userScreeningsInPeriod.sort((a, b) => b.date.compareTo(a.date));
        patientsWithScreeningInPeriod[p] = userScreeningsInPeriod.first.date;
      } else {
        patientsWithoutScreeningInPeriod.add(p);
      }
    }

    final sortedScreenedPatients = patientsWithScreeningInPeriod.keys.toList()
      ..sort((a, b) {
        final dateA = patientsWithScreeningInPeriod[a]!;
        final dateB = patientsWithScreeningInPeriod[b]!;
        return dateB.compareTo(dateA); // Skrining terbaru dulu
      });

    final sortedUnscreenedPatients = List<UserModel>.from(patientsWithoutScreeningInPeriod)
      ..sort((a, b) {
        final dateA = extractUserDate(a) ?? DateTime(1970);
        final dateB = extractUserDate(b) ?? DateTime(1970);
        return dateB.compareTo(dateA); // Registrasi terbaru dulu
      });

    final sortedPatients = [
      ...sortedScreenedPatients,
      ...sortedUnscreenedPatients,
    ];

    final totalAvailablePatients = sortedPatients.length; // M
    bool isExceeding = false;
    int limitN = totalAvailablePatients;

    if (config.userLimit != null) {
      if (config.userLimit! > totalAvailablePatients) {
        isExceeding = true;
        limitN = totalAvailablePatients;
      } else if (config.userLimit! < 0) {
        limitN = 0;
      } else {
        limitN = config.userLimit!;
      }
    }

    final selectedPatients = sortedPatients.take(limitN).toList();
    final selectedPatientIds = selectedPatients.map((u) => u.id).toSet();

    // 5. SEMUA angka laporan dihitung HANYA dari N pengguna terpilih dan skriningnya dalam periode
    final selectedScreeningsInPeriod = screeningsInPeriod
        .where((s) => selectedPatientIds.contains(s.userId))
        .toList();

    // a) Total Skrining
    final totalScreenings = selectedScreeningsInPeriod.length;

    // b) Skrining Rata-rata/Hari
    final double exactAvg = daysCount > 0 ? (totalScreenings / daysCount) : 0.0;
    final String formattedAvg = formatScreeningsPerDay(exactAvg);

    // Hitung perbandingan dengan periode sebelumnya sepanjang sama persis
    final prevPeriod = calculatePreviousPeriod(startDate, endDate);
    final prevScreeningsCount = prevPeriod != null
        ? validScreenings
            .where((s) =>
                selectedPatientIds.contains(s.userId) &&
                isDateInRange(s.date, prevPeriod.start, prevPeriod.end))
            .length
        : 0;
    final double prevExactAvg = (prevPeriod != null && daysCount > 0)
        ? (prevScreeningsCount / daysCount)
        : 0.0;
    final avgBadge = calculateChangeBadge(exactAvg, prevExactAvg);

    // c) JENIS KELAMIN (BAGIAN C.3):
    // - Hanya dua kategori: Perempuan dan Laki-laki. Tidak ada kategori "Tidak diketahui".
    // - Pengguna tanpa jenis kelamin valid DIKELUARKAN dari perhitungan jenis kelamin.
    // - Tetap dihitung di total pengguna, IMT, kategori, skrining, dll.
    int perempuanCount = 0;
    int lakiLakiCount = 0;
    int genderExcludedCount = 0;

    for (final u in selectedPatients) {
      final g = normalizeGender(u.gender);
      if (g == AdminReportGender.perempuan) {
        perempuanCount++;
      } else if (g == AdminReportGender.lakiLaki) {
        lakiLakiCount++;
      } else {
        genderExcludedCount++;
      }
    }

    final validGenderTotal = perempuanCount + lakiLakiCount;
    final double perempuanPercentage = validGenderTotal > 0
        ? calculatePercentage(perempuanCount, validGenderTotal)
        : 0.0;
    final double lakiLakiPercentage = validGenderTotal > 0
        ? (perempuanCount > 0 && lakiLakiCount > 0
            ? double.parse((100.0 - perempuanPercentage).toStringAsFixed(1))
            : calculatePercentage(lakiLakiCount, validGenderTotal))
        : 0.0;

    // d) Distribusi Kategori Hasil Skrining Terbaru & Tingkat Risiko
    final obesityCounts = <ObesityCategory, int>{
      for (final cfg in ObesityCategoryConfig.all7Categories)
        cfg.category: 0,
      ObesityCategory.tidakDiketahui: 0,
    };

    final riskCounts = <String, int>{
      'Rendah': 0,
      'Sedang': 0,
      'Tinggi': 0,
      'Perlu perhatian gizi': 0,
    };

    int screenedPatientsCount = 0;

    for (final p in selectedPatients) {
      final pScreenings = selectedScreeningsInPeriod
          .where((s) => s.userId == p.id)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      if (pScreenings.isNotEmpty) {
        final latest = pScreenings.first;
        final cat = resolveObesityCategory(latest, p);
        if (cat != ObesityCategory.tidakDiketahui) {
          obesityCounts[cat] = (obesityCounts[cat] ?? 0) + 1;
          final risk = resolveClinicalRisk(cat);
          if (riskCounts.containsKey(risk)) {
            riskCounts[risk] = (riskCounts[risk] ?? 0) + 1;
          }
          screenedPatientsCount++;
        }
      }
    }

    final obesityPercentages = <ObesityCategory, double>{};
    for (final entry in obesityCounts.entries) {
      obesityPercentages[entry.key] = screenedPatientsCount > 0
          ? calculatePercentage(entry.value, screenedPatientsCount)
          : 0.0;
    }

    final riskPercentages = <String, double>{};
    for (final entry in riskCounts.entries) {
      riskPercentages[entry.key] = screenedPatientsCount > 0
          ? calculatePercentage(entry.value, screenedPatientsCount)
          : 0.0;
    }

    // e) Cross-Tab Gender x Kategori (Laporan Eksternal Bagian III.4)
    int perempuanInsufficient = 0;
    int perempuanNormal = 0;
    int perempuanOverweight = 0;
    int perempuanObesity = 0;

    int lakiLakiInsufficient = 0;
    int lakiLakiNormal = 0;
    int lakiLakiOverweight = 0;
    int lakiLakiObesity = 0;

    for (final p in selectedPatients) {
      final pScreenings = selectedScreeningsInPeriod
          .where((s) => s.userId == p.id)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      if (pScreenings.isNotEmpty) {
        final latest = pScreenings.first;
        final cat = resolveObesityCategory(latest, p);
        final g = normalizeGender(p.gender);

        if (g == AdminReportGender.perempuan) {
          switch (cat) {
            case ObesityCategory.insufficientWeight:
              perempuanInsufficient++;
              break;
            case ObesityCategory.normalWeight:
              perempuanNormal++;
              break;
            case ObesityCategory.overweightLevel1:
            case ObesityCategory.overweightLevel2:
              perempuanOverweight++;
              break;
            case ObesityCategory.obesityType1:
            case ObesityCategory.obesityType2:
            case ObesityCategory.obesityType3:
              perempuanObesity++;
              break;
            case ObesityCategory.tidakDiketahui:
              break;
          }
        } else if (g == AdminReportGender.lakiLaki) {
          switch (cat) {
            case ObesityCategory.insufficientWeight:
              lakiLakiInsufficient++;
              break;
            case ObesityCategory.normalWeight:
              lakiLakiNormal++;
              break;
            case ObesityCategory.overweightLevel1:
            case ObesityCategory.overweightLevel2:
              lakiLakiOverweight++;
              break;
            case ObesityCategory.obesityType1:
            case ObesityCategory.obesityType2:
            case ObesityCategory.obesityType3:
              lakiLakiObesity++;
              break;
            case ObesityCategory.tidakDiketahui:
              break;
          }
        }
      }
    }

    // f) Pertumbuhan Pengguna Baru & Trend Registrasi (Internal Bagian 2 & 4)
    int newUsersCount = 0;
    final newUserDates = <DateTime>[];
    for (final p in selectedPatients) {
      final regDate = extractUserDate(p);
      if (regDate != null && isDateInRange(regDate, startDate, endDate)) {
        newUsersCount++;
        newUserDates.add(regDate);
      }
    }
    final newUserTrendPoints = calculateTrendPointsForDates(
      dates: newUserDates,
      period: config.period,
      startDate: startDate,
      endDate: endDate,
    );

    // g) Teks Perbandingan Skrining Periode Sebelumnya (Internal Bagian 2)
    String compText;
    if (prevPeriod != null && prevScreeningsCount > 0) {
      final diff = totalScreenings - prevScreeningsCount;
      final pct = (diff.abs() / prevScreeningsCount) * 100.0;
      final pctStr = formatPercentage(pct);
      if (diff > 0) {
        compText = 'Total skrining naik $pctStr dibanding periode sebelumnya.';
      } else if (diff < 0) {
        compText = 'Total skrining turun $pctStr dibanding periode sebelumnya.';
      } else {
        compText = 'Total skrining stabil (0,0%) dibanding periode sebelumnya.';
      }
    } else if (prevPeriod != null && totalScreenings > 0) {
      compText = 'Total skrining periode ini tercatat $totalScreenings kali (naik 100% dibanding periode sebelumnya yang 0).';
    } else {
      compText = 'Total skrining periode ini tercatat $totalScreenings kali.';
    }

    // h) Distribusi Usia (Internal Bagian 3)
    int ageUnder18Count = 0;
    int age18To24Count = 0;
    int age25To34Count = 0;
    int age35To44Count = 0;
    int age45To54Count = 0;
    int age55PlusCount = 0;
    int ageUnknownCount = 0;

    for (final p in selectedPatients) {
      final a = p.age;
      if (a == null) {
        ageUnknownCount++;
      } else if (a < 18) {
        ageUnder18Count++;
      } else if (a <= 24) {
        age18To24Count++;
      } else if (a <= 34) {
        age25To34Count++;
      } else if (a <= 44) {
        age35To44Count++;
      } else if (a <= 54) {
        age45To54Count++;
      } else {
        age55PlusCount++;
      }
    }

    // i) Data Perhitungan IMT (Internal Bagian 5)
    final validBmis = <double>[];
    final validWeights = <double>[];
    final validHeights = <double>[];

    for (final p in selectedPatients) {
      final pScreenings = selectedScreeningsInPeriod
          .where((s) => s.userId == p.id)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      if (pScreenings.isNotEmpty) {
        final latest = pScreenings.first;
        if (latest.bmi > 0) validBmis.add(latest.bmi);
        final w = latest.skriningData.weight;
        if (w != null && w > 0) validWeights.add(w);
        final h = latest.skriningData.height;
        if (h != null && h > 0) validHeights.add(h);
      }
    }

    final double? avgBmi = validBmis.isNotEmpty ? validBmis.reduce((a, b) => a + b) / validBmis.length : null;
    final double? minBmi = validBmis.isNotEmpty ? validBmis.reduce((a, b) => a < b ? a : b) : null;
    final double? maxBmi = validBmis.isNotEmpty ? validBmis.reduce((a, b) => a > b ? a : b) : null;
    final double? avgWeight = validWeights.isNotEmpty ? validWeights.reduce((a, b) => a + b) / validWeights.length : null;
    final double? avgHeight = validHeights.isNotEmpty ? validHeights.reduce((a, b) => a + b) / validHeights.length : null;

    // j) Keaktifan & Perubahan Kondisi Skrining (Internal Bagian 10)
    int screenings1TimeCount = 0;
    int screenings2TimesCount = 0;
    int screenings3PlusTimesCount = 0;

    int conditionImprovedCount = 0;
    int conditionUnchangedCount = 0;
    int conditionWorsenedCount = 0;

    for (final p in selectedPatients) {
      final pScreenings = selectedScreeningsInPeriod
          .where((s) => s.userId == p.id)
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date)); // tertua dulu

      final count = pScreenings.length;
      if (count == 1) {
        screenings1TimeCount++;
      } else if (count == 2) {
        screenings2TimesCount++;
      } else if (count >= 3) {
        screenings3PlusTimesCount++;
      }

      if (count >= 2) {
        final firstScr = pScreenings.first;
        final latestScr = pScreenings.last;
        final catFirst = resolveObesityCategory(firstScr, p);
        final catLatest = resolveObesityCategory(latestScr, p);

        final distFirst = getDistanceToNormal(catFirst);
        final distLatest = getDistanceToNormal(catLatest);

        if (distLatest < distFirst) {
          conditionImprovedCount++;
        } else if (distLatest == distFirst) {
          conditionUnchangedCount++;
        } else {
          conditionWorsenedCount++;
        }
      }
    }

    // k) Tren Aktivitas
    final trendPoints = calculatePrintTrendPoints(
      screenings: selectedScreeningsInPeriod,
      period: config.period,
      startDate: startDate,
      endDate: endDate,
    );

    return ReportData(
      config: config,
      startDate: startDate,
      endDate: endDate,
      daysCount: daysCount,
      totalAvailablePatients: totalAvailablePatients,
      selectedPatientsCount: selectedPatients.length,
      selectedPatients: selectedPatients,
      selectedScreenings: selectedScreeningsInPeriod,
      totalScreenings: totalScreenings,
      exactScreeningsPerDay: exactAvg,
      formattedScreeningsPerDay: formattedAvg,
      screeningsPerDayBadgeText: avgBadge.badgeText,
      screeningsPerDayHasArrow: avgBadge.hasArrow,
      screeningsPerDayIsUp: avgBadge.isUp,
      perempuanCount: perempuanCount,
      lakiLakiCount: lakiLakiCount,
      perempuanPercentage: perempuanPercentage,
      lakiLakiPercentage: lakiLakiPercentage,
      genderExcludedCount: genderExcludedCount,
      totalScreenedPatients: screenedPatientsCount,
      obesityCounts: obesityCounts,
      obesityPercentages: obesityPercentages,
      riskCounts: riskCounts,
      riskPercentages: riskPercentages,
      trendPoints: trendPoints,
      isExceedingAvailable: isExceeding,
      perempuanInsufficient: perempuanInsufficient,
      perempuanNormal: perempuanNormal,
      perempuanOverweight: perempuanOverweight,
      perempuanObesity: perempuanObesity,
      lakiLakiInsufficient: lakiLakiInsufficient,
      lakiLakiNormal: lakiLakiNormal,
      lakiLakiOverweight: lakiLakiOverweight,
      lakiLakiObesity: lakiLakiObesity,
      newUsersCount: newUsersCount,
      newUserTrendPoints: newUserTrendPoints,
      screeningsComparisonText: compText,
      ageUnder18Count: ageUnder18Count,
      age18To24Count: age18To24Count,
      age25To34Count: age25To34Count,
      age35To44Count: age35To44Count,
      age45To54Count: age45To54Count,
      age55PlusCount: age55PlusCount,
      ageUnknownCount: ageUnknownCount,
      avgBmi: avgBmi,
      minBmi: minBmi,
      maxBmi: maxBmi,
      avgWeight: avgWeight,
      avgHeight: avgHeight,
      screenings1TimeCount: screenings1TimeCount,
      screenings2TimesCount: screenings2TimesCount,
      screenings3PlusTimesCount: screenings3PlusTimesCount,
      conditionImprovedCount: conditionImprovedCount,
      conditionUnchangedCount: conditionUnchangedCount,
      conditionWorsenedCount: conditionWorsenedCount,
    );
  }

  /// Mengambil data laporan cetak secara lengkap dari Firestore / cache
  Future<ReportData> fetchPrintReportData(ReportConfig config) async {
    List<UserModel> users = [];
    List<ScreeningHistoryItem> allScreenings = [];

    if (_mockUsers != null) {
      users = List<UserModel>.from(_mockUsers!);
      allScreenings = _mockScreenings != null
          ? List<ScreeningHistoryItem>.from(_mockScreenings!)
          : getDefaultMockScreenings();
    } else if (isFirebaseAvailable) {
      if (_cachedUsers != null && _cachedScreenings != null) {
        users = _cachedUsers!;
        allScreenings = _cachedScreenings!;
      } else {
        await fetchAdminReportData();
        users = _cachedUsers ?? [];
        allScreenings = _cachedScreenings ?? [];
      }
    } else {
      users = _cachedUsers ?? getDefaultMockUsers();
      allScreenings = _cachedScreenings ?? getDefaultMockScreenings();
    }

    return computePrintReportData(
      users: users,
      allScreenings: allScreenings,
      config: config,
    );
  }

  /// Menghitung jumlah pasien yang tersedia pada rentang periode yang dipilih
  int countAvailablePatientsForPeriod(ReportPeriod period, [DateTime? referenceDate]) {
    final users = _mockUsers ?? _cachedUsers ?? getDefaultMockUsers();
    final seen = <String>{};
    return users.where((u) {
      if (u.id.trim().isEmpty) return false;
      if (!seen.add(u.id)) return false;
      final nameLower = u.name.toLowerCase();
      final emailLower = u.email.toLowerCase();
      if (nameLower.contains('hendra') || emailLower.contains('hendra')) return false;
      if (u.isAdmin || u.role == UserRole.admin || emailLower.contains('admin')) return false;
      return true;
    }).length;
  }

  // In-memory cache untuk dokumen mentah Firestore
  List<UserModel>? _cachedUsers;
  List<ScreeningHistoryItem>? _cachedScreenings;

  // Mock data untuk pengujian unit & widget
  List<UserModel>? _mockUsers;
  List<ScreeningHistoryItem>? _mockScreenings;
  final List<VoidCallback> _mockUpdateListeners = [];

  bool get isFirebaseAvailable => AdminUserService.instance.isFirebaseAvailable;

  @visibleForTesting
  void setMockData({
    List<UserModel>? users,
    List<ScreeningHistoryItem>? screenings,
  }) {
    _mockUsers = users != null ? List<UserModel>.from(users) : null;
    _mockScreenings = screenings != null ? List<ScreeningHistoryItem>.from(screenings) : null;
    _notifyMockListeners();
  }

  @visibleForTesting
  void addMockScreening(ScreeningHistoryItem screening) {
    _mockScreenings ??= [];
    _mockScreenings!.add(screening);
    _notifyMockListeners();
  }

  @visibleForTesting
  void removeMockScreening(String screeningId) {
    _mockScreenings?.removeWhere((s) => s.id == screeningId);
    _notifyMockListeners();
  }

  @visibleForTesting
  void updateMockUser(UserModel updatedUser) {
    if (_mockUsers != null) {
      final index = _mockUsers!.indexWhere((u) => u.id == updatedUser.id);
      if (index >= 0) {
        _mockUsers![index] = updatedUser;
      } else {
        _mockUsers!.add(updatedUser);
      }
      _notifyMockListeners();
    }
  }

  @visibleForTesting
  void removeMockUser(String userId) {
    _mockUsers?.removeWhere((u) => u.id == userId);
    _mockScreenings?.removeWhere((s) => s.userId == userId);
    _notifyMockListeners();
  }

  void _notifyMockListeners() {
    for (final listener in List<VoidCallback>.from(_mockUpdateListeners)) {
      listener();
    }
  }

  @visibleForTesting
  void resetMockData() {
    _mockUsers = null;
    _mockScreenings = null;
    _cachedUsers = null;
    _cachedScreenings = null;
    _mockUpdateListeners.clear();
  }

  /// Mendengarkan perubahan data laporan secara real-time via Cloud Firestore snapshots.
  /// Memantau koleksi 'users' dan seluruh sub-koleksi 'screenings' milik pengguna.
  /// Mengupdate otomatis setiap ada pengguna baru, jenis kelamin diubah, skrining ditambah, atau data dihapus.
  Stream<AdminReportData> streamReportData({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    if (_mockUsers != null) {
      late StreamController<AdminReportData> controller;
      void emitCurrent() {
        if (!controller.isClosed) {
          final data = computeReportData(
            users: _mockUsers ?? [],
            allScreenings: _mockScreenings ?? [],
            startDate: startDate,
            endDate: endDate,
          );
          controller.add(data);
        }
      }

      controller = StreamController<AdminReportData>.broadcast(
        onListen: () {
          _mockUpdateListeners.add(emitCurrent);
          emitCurrent();
        },
        onCancel: () {
          _mockUpdateListeners.remove(emitCurrent);
        },
      );
      return controller.stream;
    }

    if (!isFirebaseAvailable) {
      final initialUsers = _cachedUsers ?? getDefaultMockUsers();
      final initialScreenings = _cachedScreenings ?? getDefaultMockScreenings();
      final data = computeReportData(
        users: initialUsers,
        allScreenings: initialScreenings,
        startDate: startDate,
        endDate: endDate,
      );
      return Stream.value(data);
    }

    late StreamController<AdminReportData> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? usersSub;
    final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>> screeningsSubs = {};
    final Map<String, List<ScreeningHistoryItem>> patientScreenings = {};
    List<UserModel> currentPatients = [];

    void emitReport() {
      if (controller.isClosed) return;
      try {
        final allScreenings = patientScreenings.values.expand((list) => list).toList();
        final report = computeReportData(
          users: currentPatients,
          allScreenings: allScreenings,
          startDate: startDate,
          endDate: endDate,
        );
        _cachedUsers = currentPatients;
        _cachedScreenings = allScreenings;
        controller.add(report);
      } catch (e, st) {
        debugPrint('[AdminReportService] Error computing stream report data: $e');
        if (!controller.isClosed) {
          controller.addError(e, st);
        }
      }
    }

    void subscribeToScreeningsFor(String userId) {
      if (screeningsSubs.containsKey(userId)) return;
      final sub = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('screenings')
          .snapshots()
          .listen(
        (snap) {
          final items = <ScreeningHistoryItem>[];
          for (final doc in snap.docs) {
            try {
              final data = doc.data();
              if (data['date'] == null && data['createdAt'] == null && data['dateIso'] == null) {
                debugPrint('[AdminReportService] Data tidak lengkap: Skrining ${doc.id} tanpa tanggal valid dilewati.');
                continue;
              }
              items.add(ScreeningHistoryItem.fromMap(data));
            } catch (e) {
              debugPrint('[AdminReportService] Data tidak lengkap: Gagal parsing skrining ${doc.id}: $e');
            }
          }
          patientScreenings[userId] = items;
          emitReport();
        },
        onError: (err) {
          debugPrint('[AdminReportService] Error streaming screenings for $userId: $err');
        },
      );
      screeningsSubs[userId] = sub;
    }

    void unsubscribeFromScreeningsFor(String userId) {
      final sub = screeningsSubs.remove(userId);
      sub?.cancel();
      patientScreenings.remove(userId);
    }

    controller = StreamController<AdminReportData>.broadcast(
      onListen: () {
        usersSub = FirebaseFirestore.instance
            .collection('users')
            .snapshots()
            .listen(
          (userSnap) {
            final activeUserIds = <String>{};
            final patients = <UserModel>[];

            for (final doc in userSnap.docs) {
              try {
                final user = UserModel.fromMap(doc.data(), doc.id);
                final nameLower = user.name.toLowerCase();
                final emailLower = user.email.toLowerCase();

                // Filter Dokter Hendra
                if (nameLower.contains('hendra') || emailLower.contains('hendra')) {
                  continue;
                }
                // Filter akun admin
                if (user.isAdmin ||
                    user.role == UserRole.admin ||
                    emailLower == 'adminobesight@gmail.com' ||
                    emailLower.contains('adminobesight') ||
                    emailLower == 'admin@obesight.com') {
                  continue;
                }

                patients.add(user);
                activeUserIds.add(user.id);
                subscribeToScreeningsFor(user.id);
              } catch (e) {
                debugPrint('[AdminReportService] Data tidak lengkap: Gagal parsing user doc ${doc.id}: $e');
              }
            }

            final existingSubIds = List<String>.from(screeningsSubs.keys);
            for (final subId in existingSubIds) {
              if (!activeUserIds.contains(subId)) {
                unsubscribeFromScreeningsFor(subId);
              }
            }

            currentPatients = patients;
            emitReport();
          },
          onError: (err, st) {
            debugPrint('[AdminReportService] Error streaming users: $err');
            if (!controller.isClosed) {
              controller.addError(err, st);
            }
          },
        );
      },
      onCancel: () {
        usersSub?.cancel();
        usersSub = null;
        for (final sub in screeningsSubs.values) {
          sub.cancel();
        }
        screeningsSubs.clear();
        patientScreenings.clear();
      },
    );

    return controller.stream;
  }

  /// Mengambil data laporan admin secara efisien dari Cloud Firestore:
  /// - Dokumen diambil dari Firestore server/cache
  /// - Riwayat skrining pengguna diambil secara paralel
  /// - Bebas data dummy: jika data kosong di Firestore, mengembalikan data kosong
  Future<AdminReportData> fetchAdminReportData({
    DateTime? startDate,
    DateTime? endDate,
    bool forceRefresh = false,
  }) async {
    List<UserModel> users = [];
    List<ScreeningHistoryItem> allScreenings = [];

    if (_mockUsers != null) {
      users = List<UserModel>.from(_mockUsers!);
      allScreenings = _mockScreenings != null
          ? List<ScreeningHistoryItem>.from(_mockScreenings!)
          : getDefaultMockScreenings();
    } else if (isFirebaseAvailable) {
      if (_cachedUsers != null && _cachedScreenings != null && !forceRefresh) {
        users = _cachedUsers!;
        allScreenings = _cachedScreenings!;
      } else {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .get(GetOptions(source: forceRefresh ? Source.server : Source.serverAndCache))
            .timeout(const Duration(seconds: 10));

        users = snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList();

        final patients = users.where((u) {
          final nameLower = u.name.toLowerCase();
          final emailLower = u.email.toLowerCase();
          if (nameLower.contains('hendra') || emailLower.contains('hendra')) {
            return false;
          }
          if (u.isAdmin ||
              u.role == UserRole.admin ||
              emailLower == 'adminobesight@gmail.com' ||
              emailLower.contains('adminobesight') ||
              emailLower == 'admin@obesight.com') {
            return false;
          }
          return true;
        }).toList();

        final screeningFutures = patients.map((u) async {
          try {
            final sSnap = await FirebaseFirestore.instance
                .collection('users')
                .doc(u.id)
                .collection('screenings')
                .get(GetOptions(source: forceRefresh ? Source.server : Source.serverAndCache))
                .timeout(const Duration(seconds: 10));
            return sSnap.docs.map((d) => ScreeningHistoryItem.fromMap(d.data())).toList();
          } catch (e) {
            debugPrint('[AdminReportService] Gagal memuat skrining untuk user ${u.id}: $e');
            return <ScreeningHistoryItem>[];
          }
        });

        final screeningResults = await Future.wait(screeningFutures);
        allScreenings = screeningResults.expand((list) => list).toList();

        _cachedUsers = users;
        _cachedScreenings = allScreenings;
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
