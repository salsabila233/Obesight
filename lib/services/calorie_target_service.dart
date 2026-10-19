import 'screening_history_service.dart';

/// Enum kelompok kalori hasil skrining IMT
enum ScreeningCalorieGroup {
  underweight,
  normal,
  overweightObesity,
}

/// Service penyedia target kalori harian tetap per kategori hasil skrining IMT.
///
/// DASAR ILMIAH & RUJUKAN JURNAL:
/// 1. Overweight / Obesitas (Target: 1.700 kkal/hari):
///    - Rujukan: Poetry dkk., Media Gizi Indonesia 15(1): 52–59.
///    - Rata-rata asupan kelompok gemuk pada penelitian adalah 1.977 kkal/hari.
///      Disarankan pemotongan/defisit energi sekitar ~280 kkal/hari, sehingga
///      target asupan harian menjadi sekitar 1.700 kkal/hari.
///    - Fokus intervensi: Mengurangi makanan/minuman manis dan gorengan/lemak jenuh.
///
/// 2. Normal (Target: 1.700 kkal/hari):
///    - Rujukan: Poetry dkk., Media Gizi Indonesia 15(1): 52–59.
///    - Rata-rata asupan kelompok normal pada jurnal yang sama adalah 1.694 kkal/hari
///      (dibulatkan menjadi 1.700 kkal/hari).
///    - Catatan: Angka 1.700 kkal ini merupakan asumsi kebutuhan energi harian seimbang
///      untuk pemeliharaan berat badan ideal.
///
/// 3. Underweight (Target: 1.950 kkal/hari):
///    - Rujukan: Utomo & Renyoet, JGK 14(2), Juli 2022.
///    - Jurnal ini merekomendasikan penambahan asupan energi sebesar 200–300 kkal/hari
///      di atas kebutuhan normal harian dan tidak menyebut angka total mutlak.
///    - Angka 1.950 kkal berasal dari 1.700 kkal (kebutuhan dasar) ditambah 250 kkal
///      (nilai tengah dari rentang 200–300 kkal).
///    - Catatan: Angka ini merupakan turunan klinis. Komposisi protein diutamakan berasal
///      dari ayam, ikan, telur, dan daging sapi yang dipanggang, dikukus, atau direbus,
///      bukan digoreng.
class CalorieTargetService {
  CalorieTargetService._();

  // Konstanta total kalori harian tetap per kategori
  static const int calorieUnderweight = 1950;
  static const int calorieNormal = 1700;
  static const int calorieOverweightObesity = 1700;

  /// Toleransi kalori harian (±5%)
  static const double toleranceRatio = 0.05;

  /// Mengambil kategori hasil skrining terbaru pengguna dari riwayat skrining
  /// (mengembalikan null jika pengguna belum pernah melakukan skrining).
  static String? getLatestScreeningCategoryRaw({String? userId, String? email}) {
    final userKey = ScreeningHistoryService.instance.resolveUserKey(userId, email);
    final history = ScreeningHistoryService.instance.getHistory(userKey);
    if (history.isNotEmpty) {
      final cat = history.first.skriningData.classificationCategory.trim();
      if (cat.isNotEmpty) {
        return cat;
      }
    }
    return null;
  }

  /// Memeriksa apakah pengguna memiliki riwayat skrining yang valid
  static bool hasScreening({String? userId, String? email}) {
    return getLatestScreeningCategoryRaw(userId: userId, email: email) != null;
  }

  /// Mengelompokkan raw category string ke dalam 3 kelompok target kalori
  static ScreeningCalorieGroup resolveGroup(String? rawCategory) {
    if (rawCategory == null || rawCategory.isEmpty) {
      return ScreeningCalorieGroup.normal;
    }
    final lower = rawCategory.toLowerCase();
    if (lower.contains('underweight') ||
        lower.contains('insufficient') ||
        lower.contains('kurang')) {
      return ScreeningCalorieGroup.underweight;
    }
    if (lower.contains('overweight') ||
        lower.contains('obesitas') ||
        lower.contains('obesity') ||
        lower.contains('lebih')) {
      return ScreeningCalorieGroup.overweightObesity;
    }
    return ScreeningCalorieGroup.normal;
  }

  /// Mendapatkan target kalori harian tetap (dalam kkal)
  static int getDailyCalorieTarget(ScreeningCalorieGroup group) {
    switch (group) {
      case ScreeningCalorieGroup.underweight:
        return calorieUnderweight;
      case ScreeningCalorieGroup.normal:
        return calorieNormal;
      case ScreeningCalorieGroup.overweightObesity:
        return calorieOverweightObesity;
    }
  }

  /// Nama kategori yang ramah pengguna untuk ditampilkan pada banner
  static String getGroupDisplayName(ScreeningCalorieGroup group) {
    switch (group) {
      case ScreeningCalorieGroup.underweight:
        return 'Underweight (Berat Kurang)';
      case ScreeningCalorieGroup.normal:
        return 'Normal (Berat Ideal)';
      case ScreeningCalorieGroup.overweightObesity:
        return 'Overweight / Obesitas';
    }
  }

  /// Batas toleransi bawah (-5%)
  static int getMinTarget(int target) => (target * (1.0 - toleranceRatio)).round();

  /// Batas toleransi atas (+5%)
  static int getMaxTarget(int target) => (target * (1.0 + toleranceRatio)).round();

  /// Menilai apakah nilai kalori berada dalam batas toleransi ±5%
  static bool isWithinTolerance(int currentCalories, int targetCalories) {
    final min = getMinTarget(targetCalories);
    final max = getMaxTarget(targetCalories);
    return currentCalories >= min && currentCalories <= max;
  }
}
