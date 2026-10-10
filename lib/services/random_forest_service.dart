import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../screens/skrining/skrining_models.dart';

/// Representasi satu decision tree Random Forest yang dioptimalkan dengan TypedData
class _CompiledTree {
  final Int32List left;
  final Int32List right;
  final Int32List feature;
  final Float32List threshold;
  final Int32List values;

  _CompiledTree({
    required this.left,
    required this.right,
    required this.feature,
    required this.threshold,
    required this.values,
  });

  /// Evaluasi satu pohon keputusan untuk vektor fitur x
  int predict(List<double> x) {
    int node = 0;
    while (left[node] != -1) {
      final f = feature[node];
      final th = threshold[node];
      if (x[f] <= th) {
        node = left[node];
      } else {
        node = right[node];
      }
    }
    return values[node];
  }
}

/// Hasil inferensi model Random Forest
class RandomForestPrediction {
  /// Kelas murni scikit-learn hasil voting mayoritas Random Forest (e.g. 'Normal_Weight', 'Overweight_Level_I')
  final String rawClass;

  /// Kunci kategori tampilan untuk kelas murni Random Forest ('Normal', 'Overweight', dsb.)
  final String rawCategoryKey;

  /// Judul tampilan kategori untuk kelas murni Random Forest
  final String rawCategoryTitle;

  /// Kelas setelah rekonsiliasi klinis IMT (atau sama dengan rawClass jika tidak ada rekonsiliasi)
  final String clinicalClass;

  /// Kunci kategori klinis akhir ('Normal', 'Overweight', 'Obesitas I', dsb.)
  final String categoryKey;

  /// Judul tampilan kategori klinis akhir (e.g. 'Overweight\nLevel I', 'Normal\nWeight')
  final String categoryTitle;

  /// Badge deskriptif akhir (e.g. 'Berat badan ideal berdasarkan analisis AI')
  final String categoryBadge;

  /// Apakah hasil klinis berbeda dari prediksi murni Random Forest?
  final bool isClinicallyAdjusted;

  /// Alasan penyesuaian klinis jika terjadi rekonsiliasi
  final String? adjustmentReason;

  /// Tingkat keyakinan model (0.0 - 100.0%)
  final double confidence;

  /// Jumlah suara per kelas dari 100 pohon keputusan
  final Map<String, int> votes;

  /// Probabilitas persentase tiap kelas
  final Map<String, double> probabilities;

  const RandomForestPrediction({
    required this.rawClass,
    required this.rawCategoryKey,
    required this.rawCategoryTitle,
    required this.clinicalClass,
    required this.categoryKey,
    required this.categoryTitle,
    required this.categoryBadge,
    required this.isClinicallyAdjusted,
    this.adjustmentReason,
    required this.confidence,
    required this.votes,
    required this.probabilities,
  });
}

/// Service untuk memuat dan mengevaluasi model Random Forest (UCI Obesity Dataset)
class RandomForestService {
  RandomForestService._();
  static final RandomForestService instance = RandomForestService._();

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  List<String> _classes = [];
  List<_CompiledTree> _trees = [];

  /// Inisialisasi model dari assets/obesight_model.json
  Future<void> init() async {
    if (_isLoaded) return;
    try {
      final jsonString = await rootBundle.loadString('assets/obesight_model.json');
      loadModelFromString(jsonString);
    } catch (e) {
      debugPrint('Error loading obesight_model.json: $e');
      rethrow;
    }
  }

  /// Memuat struktur model dari JSON string (bisa dipakai untuk testing atau runtime)
  void loadModelFromString(String jsonString) {
    final Map<String, dynamic> data = jsonDecode(jsonString) as Map<String, dynamic>;
    _classes = (data['classes'] as List).map((e) => e.toString()).toList();

    final rawTrees = data['trees'] as List;
    final compiled = <_CompiledTree>[];

    for (final raw in rawTrees) {
      final t = raw as Map<String, dynamic>;
      final leftList = t['left'] as List;
      final n = leftList.length;

      final left = Int32List(n);
      final right = Int32List(n);
      final feature = Int32List(n);
      final threshold = Float32List(n);
      final values = Int32List(n);

      final rightList = t['right'] as List;
      final featureList = t['feature'] as List;
      final thresholdList = t['threshold'] as List;
      final valuesList = t['values'] as List;

      for (int i = 0; i < n; i++) {
        left[i] = (leftList[i] as num).toInt();
        right[i] = (rightList[i] as num).toInt();
        feature[i] = (featureList[i] as num).toInt();
        threshold[i] = (thresholdList[i] as num).toDouble();
        values[i] = (valuesList[i] as num).toInt();
      }

      compiled.add(_CompiledTree(
        left: left,
        right: right,
        feature: feature,
        threshold: threshold,
        values: values,
      ));
    }

    _trees = compiled;
    _isLoaded = true;
  }

  /// Mengonversi jawaban formulir SkriningData menjadi vektor 31 fitur numerik & One-Hot Encoded
  List<double> preprocess(SkriningData data) {
    final x = List<double>.filled(31, 0.0);

    // 0: Age (tahun)
    x[0] = (data.age ?? 23).toDouble();

    // 1: Height (dalam meter, dataset dilatih dalam meter)
    final hCm = (data.height != null && data.height! > 0) ? data.height! : 165.0;
    x[1] = hCm / 100.0;

    // 2: Weight (kg)
    x[2] = (data.weight != null && data.weight! > 0) ? data.weight! : 72.0;

    // 3: FCVC - Frekuensi konsumsi sayuran (1 = Jarang, 2 = Kadang-kadang, 3 = Sering)
    switch (data.vegetableIntake) {
      case 'Jarang':
        x[3] = 1.0;
        break;
      case 'Kadang-kadang':
        x[3] = 2.0;
        break;
      case 'Sering':
        x[3] = 3.0;
        break;
      default:
        x[3] = 2.0;
    }

    // 4: NCP - Jumlah makanan utama harian (1, 2, 3, 4)
    switch (data.mainMealFrequency) {
      case '1 kali':
        x[4] = 1.0;
        break;
      case '2 kali':
        x[4] = 2.0;
        break;
      case '3 kali':
        x[4] = 3.0;
        break;
      case '4 kali atau lebih':
        x[4] = 4.0;
        break;
      default:
        x[4] = 3.0;
    }

    // 5: CH2O - Konsumsi air putih harian (1 = <1L, 2 = 1-2L, 3 = >2L)
    switch (data.waterIntake) {
      case '<1 Liter':
        x[5] = 1.0;
        break;
      case '1-2 Liter':
        x[5] = 2.0;
        break;
      case '>2 Liter':
        x[5] = 3.0;
        break;
      default:
        x[5] = 2.0;
    }

    // 6: FAF - Frekuensi aktivitas fisik mingguan (0 = Tidak pernah, 1 = Kadang-kadang, 2 = Sering, 3 = Selalu)
    switch (data.physicalActivity) {
      case 'Tidak pernah':
        x[6] = 0.0;
        break;
      case 'Kadang-kadang':
        x[6] = 1.0;
        break;
      case 'Sering':
        x[6] = 2.0;
        break;
      case 'Selalu':
        x[6] = 3.0;
        break;
      default:
        x[6] = 1.0;
    }

    // 7: TUE - Waktu di depan layar per hari (0 = <1 Jam, 1 = 1-2 Jam, 2 = >2 Jam)
    switch (data.screenTime) {
      case '<1 Jam':
        x[7] = 0.0;
        break;
      case '1-2 Jam':
        x[7] = 1.0;
        break;
      case '>2 Jam':
        x[7] = 2.0;
        break;
      default:
        x[7] = 1.0;
    }

    // === ONE-HOT ENCODED CATEGORICAL FEATURES (Indices 8 to 30) ===

    // Gender: [8: Female, 9: Male]
    final isMale = (data.gender == 'Laki-laki');
    if (isMale) {
      x[9] = 1.0;
    } else {
      x[8] = 1.0;
    }

    // family_history_with_overweight: [10: no, 11: yes]
    if (data.familyHistory == 'Ya') {
      x[11] = 1.0;
    } else {
      x[10] = 1.0;
    }

    // FAVC (Makanan berkalori tinggi): [12: no, 13: yes]
    if (data.highCalorieFood == 'Ya') {
      x[13] = 1.0;
    } else {
      x[12] = 1.0;
    }

    // CAEC (Frekuensi ngemil): [14: Always, 15: Frequently, 16: Sometimes, 17: no]
    switch (data.snackFrequency) {
      case 'Selalu':
        x[14] = 1.0;
        break;
      case 'Sering':
        x[15] = 1.0;
        break;
      case 'Kadang-kadang':
        x[16] = 1.0;
        break;
      case 'Tidak pernah':
      default:
        x[17] = 1.0;
        break;
    }

    // SMOKE (Merokok): [18: no, 19: yes]
    if (data.smoking == 'Ya') {
      x[19] = 1.0;
    } else {
      x[18] = 1.0;
    }

    // SCC (Pantau kalori): [20: no, 21: yes]
    if (data.monitorCalories == 'Ya') {
      x[21] = 1.0;
    } else {
      x[20] = 1.0;
    }

    // CALC (Konsumsi alkohol): [22: Always, 23: Frequently, 24: Sometimes, 25: no]
    switch (data.alcohol) {
      case 'Selalu':
        x[22] = 1.0;
        break;
      case 'Sering':
        x[23] = 1.0;
        break;
      case 'Kadang-kadang':
        x[24] = 1.0;
        break;
      case 'Tidak pernah':
      default:
        x[25] = 1.0;
        break;
    }

    // MTRANS (Transportasi): [26: Automobile, 27: Bike, 28: Motorbike, 29: Public_Transportation, 30: Walking]
    switch (data.transportation) {
      case 'Mobil':
        x[26] = 1.0;
        break;
      case 'Sepeda':
        x[27] = 1.0;
        break;
      case 'Motor':
        x[28] = 1.0;
        break;
      case 'Transportasi umum':
        x[29] = 1.0;
        break;
      case 'Jalan kaki':
        x[30] = 1.0;
        break;
      default:
        x[28] = 1.0; // default motor
        break;
    }

    return x;
  }

  /// Prediksi klasifikasi obesitas menggunakan model Random Forest
  Future<RandomForestPrediction> predict(SkriningData data) async {
    if (!_isLoaded) {
      await init();
    }

    final x = preprocess(data);
    final totalClasses = _classes.isNotEmpty ? _classes.length : 7;
    final voteCounts = List<int>.filled(totalClasses, 0);

    for (final tree in _trees) {
      final classIdx = tree.predict(x);
      if (classIdx >= 0 && classIdx < totalClasses) {
        voteCounts[classIdx]++;
      }
    }

    // 1. Dapatkan kelas dominan dari suara pohon keputusan (Random Forest murni)
    int bestClassIdx = 0;
    int maxVotes = -1;
    final totalTrees = _trees.isNotEmpty ? _trees.length : 1;

    for (int i = 0; i < totalClasses; i++) {
      if (voteCounts[i] > maxVotes) {
        maxVotes = voteCounts[i];
        bestClassIdx = i;
      }
    }

    final String rawMlClass = (bestClassIdx < _classes.length)
        ? _classes[bestClassIdx]
        : 'Overweight_Level_I';

    final rawMeta = _mapClassToCategory(rawMlClass);
    final confidence = (maxVotes / totalTrees) * 100.0;

    final votesMap = <String, int>{};
    final probsMap = <String, double>{};
    for (int i = 0; i < totalClasses && i < _classes.length; i++) {
      votesMap[_classes[i]] = voteCounts[i];
      probsMap[_classes[i]] = (voteCounts[i] / totalTrees) * 100.0;
    }

    // 2. Evaluasi Rekonsiliasi Klinis & Validasi Batas IMT (PAPDI & KMK Kemenkes No. HK.01.07-MENKES-509-2025)
    final double actualBmi = data.bmi;
    final reconciliation = _reconcileWithClinicalBmi(rawMlClass, actualBmi);
    final String clinicalClass = reconciliation.clinicalClass;
    final bool isAdjusted = reconciliation.isAdjusted;
    final String? adjustReason = reconciliation.reason;

    final clinicalMeta = _mapClassToCategory(clinicalClass);

    // 3. Detailed Debug Logging
    debugPrint('================ [DEBUG RANDOM FOREST] ================');
    debugPrint('1. Input Data Skrining:');
    debugPrint('   - Usia: ${data.age}, Gender: ${data.gender}, TB: ${data.height} cm, BB: ${data.weight} kg');
    debugPrint('   - IMT Terhitung: ${actualBmi.toStringAsFixed(2)}');
    debugPrint('   - Riwayat Keluarga: ${data.familyHistory}, Kalori Tinggi: ${data.highCalorieFood}');
    debugPrint('   - Sayur (FCVC): ${data.vegetableIntake}, Makan Utama (NCP): ${data.mainMealFrequency}');
    debugPrint('   - Camilan (CAEC): ${data.snackFrequency}, Merokok: ${data.smoking}, Air (CH2O): ${data.waterIntake}');
    debugPrint('   - Aktivitas (FAF): ${data.physicalActivity}, Layar (TUE): ${data.screenTime}');
    debugPrint('   - Alkohol: ${data.alcohol}, Transportasi: ${data.transportation}');
    debugPrint('2. Vektor Fitur Preprocessed (Jumlah: ${x.length}): $x');
    debugPrint('3. Distribusi Voting Pohon (Total $totalTrees Pohon):');
    for (final entry in votesMap.entries) {
      debugPrint('   - ${entry.key}: ${entry.value} suara (${probsMap[entry.key]?.toStringAsFixed(1)}%)');
    }
    debugPrint('4. Hasil Prediksi Murni AI: $rawMlClass (Keyakinan: ${confidence.toStringAsFixed(1)}%)');
    debugPrint('5. Status Rekonsiliasi Klinis: $clinicalClass (Disesuaikan: $isAdjusted)');
    if (isAdjusted && adjustReason != null) {
      debugPrint('   - Alasan Rekonsiliasi: $adjustReason');
    }
    debugPrint('========================================================');

    return RandomForestPrediction(
      rawClass: rawMlClass,
      rawCategoryKey: rawMeta.categoryKey,
      rawCategoryTitle: rawMeta.categoryTitle,
      clinicalClass: clinicalClass,
      categoryKey: clinicalMeta.categoryKey,
      categoryTitle: clinicalMeta.categoryTitle,
      categoryBadge: clinicalMeta.categoryBadge,
      isClinicallyAdjusted: isAdjusted,
      adjustmentReason: adjustReason,
      confidence: confidence,
      votes: votesMap,
      probabilities: probsMap,
    );
  }

  /// Rekonsiliasi prediksi model AI dengan batas rentang IMT antropometri klinis (PAPDI / Kemenkes 2025)
  /// Aturan ini HANYA bertindak sebagai safety net medis jika terjadi inkonsistensi ekstrem,
  /// dan TIDAK BOLEH membatalkan prediksi model Random Forest secara membabi-buta.
  static _ReconciliationResult _reconcileWithClinicalBmi(String rawMlClass, double bmi) {
    // Standar Antropometri Medis Kemenkes RI / PAPDI:
    // Underweight: IMT < 18.5
    // Normal: IMT 18.5 - 22.9
    // Overweight: IMT 23.0 - 24.9 (Pre-obesitas)
    // Obesitas I: IMT 25.0 - 29.9
    // Obesitas II: IMT 30.0 - 34.9
    // Obesitas III: IMT >= 35.0 (Morbid)
    final normClass = canonicalClassName(rawMlClass);

    // Kasus 1: IMT < 18.5 (Underweight Klinis Ekstrem)
    if (bmi < 18.5) {
      if (normClass != 'Insufficient_Weight') {
        return _ReconciliationResult(
          clinicalClass: 'Insufficient_Weight',
          isAdjusted: true,
          reason: 'IMT riil (${bmi.toStringAsFixed(1)}) berada di bawah 18.5 (Underweight). Prediksi AI disesuaikan untuk standar keselamatan medis.',
        );
      }
      return const _ReconciliationResult(clinicalClass: 'Insufficient_Weight', isAdjusted: false);
    }

    // Kasus 2: IMT 18.5 - 22.9 (Rentang Berat Badan Normal Kemenkes)
    if (bmi <= 22.9) {
      if (normClass == 'Normal_Weight') {
        return const _ReconciliationResult(clinicalClass: 'Normal_Weight', isAdjusted: false);
      }
      if (normClass == 'Insufficient_Weight') {
        return _ReconciliationResult(
          clinicalClass: 'Normal_Weight',
          isAdjusted: true,
          reason: 'IMT riil (${bmi.toStringAsFixed(1)}) berada di rentang normal (18.5 - 22.9), bukan berat kurang.',
        );
      }
      // Jika AI memprediksi risiko Overweight atau Obesitas karena pola makan & gaya hidup yang buruk,
      // jangan ditimpa paksa ke Normal_Weight agar hasil analisis faktor risiko model AI tetap terlihat!
      return _ReconciliationResult(
        clinicalClass: rawMlClass,
        isAdjusted: false,
      );
    }

    // Kasus 3: IMT 23.0 - 24.9 (Overweight Tingkat I / Pre-obesitas Kemenkes)
    if (bmi <= 24.9) {
      if (normClass == 'Insufficient_Weight' || normClass == 'Normal_Weight') {
        return _ReconciliationResult(
          clinicalClass: 'Overweight_Level_I',
          isAdjusted: true,
          reason: 'IMT (${bmi.toStringAsFixed(1)}) berada pada ambang batas kelebihan berat badan Kemenkes (23.0 - 24.9).',
        );
      }
      return _ReconciliationResult(clinicalClass: rawMlClass, isAdjusted: false);
    }

    // Kasus 4: IMT 25.0 - 27.0 (Overweight Tingkat II / Obesitas I awal)
    if (bmi <= 27.0) {
      if (normClass == 'Insufficient_Weight' || normClass == 'Normal_Weight') {
        return _ReconciliationResult(
          clinicalClass: 'Overweight_Level_II',
          isAdjusted: true,
          reason: 'IMT (${bmi.toStringAsFixed(1)}) berada pada rentang kelebihan berat badan (25.0 - 27.0).',
        );
      }
      return _ReconciliationResult(clinicalClass: rawMlClass, isAdjusted: false);
    }

    // Kasus 5: IMT 27.1 - 29.9 (Obesitas Tingkat I Kemenkes)
    if (bmi <= 29.9) {
      if (normClass == 'Insufficient_Weight' || normClass == 'Normal_Weight') {
        return _ReconciliationResult(
          clinicalClass: 'Obesity_Type_I',
          isAdjusted: true,
          reason: 'IMT (${bmi.toStringAsFixed(1)}) tergolong Obesitas Tingkat I (27.1 - 29.9).',
        );
      }
      return _ReconciliationResult(clinicalClass: rawMlClass, isAdjusted: false);
    }

    // Kasus 6: IMT 30.0 - 34.9 (Obesitas Tingkat II)
    if (bmi <= 34.9) {
      if (normClass == 'Insufficient_Weight' || normClass == 'Normal_Weight' || normClass == 'Overweight_Level_I') {
        return _ReconciliationResult(
          clinicalClass: 'Obesity_Type_II',
          isAdjusted: true,
          reason: 'IMT (${bmi.toStringAsFixed(1)}) tergolong Obesitas Tingkat II (30.0 - 34.9).',
        );
      }
      return _ReconciliationResult(clinicalClass: rawMlClass, isAdjusted: false);
    }

    // Kasus 7: IMT >= 35.0 (Obesitas Tingkat III / Morbid)
    if (normClass != 'Obesity_Type_III') {
      return _ReconciliationResult(
        clinicalClass: 'Obesity_Type_III',
        isAdjusted: true,
        reason: 'IMT (${bmi.toStringAsFixed(1)}) tergolong Obesitas Tingkat III / Morbid (>= 35.0).',
      );
    }
    return const _ReconciliationResult(clinicalClass: 'Obesity_Type_III', isAdjusted: false);
  }

  /// Normalisasi nama kelas ke standar kanonik (UCI Dataset: Type_I..III atau Level_I..III)
  static String canonicalClassName(String raw) {
    final clean = raw.trim();
    final lower = clean.toLowerCase();

    if (clean == 'Insufficient_Weight' || lower == 'insufficient weight' || lower == 'underweight') {
      return 'Insufficient_Weight';
    }
    if (clean == 'Normal_Weight' || lower == 'normal weight' || lower == 'normal') {
      return 'Normal_Weight';
    }
    if (clean == 'Overweight_Level_I' || lower == 'overweight level i' || lower == 'overweight i') {
      return 'Overweight_Level_I';
    }
    if (clean == 'Overweight_Level_II' || lower == 'overweight level ii' || lower == 'overweight ii') {
      return 'Overweight_Level_II';
    }
    if (clean == 'Obesity_Type_I' || clean == 'Obesity_Level_I' || lower == 'obesity level i' || lower == 'obesity type i' || lower == 'obesitas i' || lower == 'obesitas tingkat i') {
      return 'Obesity_Type_I';
    }
    if (clean == 'Obesity_Type_II' || clean == 'Obesity_Level_II' || lower == 'obesity level ii' || lower == 'obesity type ii' || lower == 'obesitas ii' || lower == 'obesitas tingkat ii') {
      return 'Obesity_Type_II';
    }
    if (clean == 'Obesity_Type_III' || clean == 'Obesity_Level_III' || lower == 'obesity level iii' || lower == 'obesity type iii' || lower == 'obesitas iii' || lower == 'obesitas tingkat iii') {
      return 'Obesity_Type_III';
    }
    return clean;
  }

  /// Label tampilan kanonik satu baris untuk 7 kelas Random Forest
  static String displayClassName(String rawClass) {
    final canonical = canonicalClassName(rawClass);
    switch (canonical) {
      case 'Insufficient_Weight':
        return 'Insufficient Weight';
      case 'Normal_Weight':
        return 'Normal Weight';
      case 'Overweight_Level_I':
        return 'Overweight Level I';
      case 'Overweight_Level_II':
        return 'Overweight Level II';
      case 'Obesity_Type_I':
        return 'Obesity Level I';
      case 'Obesity_Type_II':
        return 'Obesity Level II';
      case 'Obesity_Type_III':
        return 'Obesity Level III';
      default:
        return rawClass.replaceAll('_', ' ');
    }
  }

  /// Sinkronisasi label prediksi AI ke standar PAPDI / KMK Kemenkes 2025
  static _CategoryMeta _mapClassToCategory(String rawClass) {
    final canonical = canonicalClassName(rawClass);

    switch (canonical) {
      case 'Insufficient_Weight':
        return const _CategoryMeta(
          categoryKey: 'Underweight',
          categoryTitle: 'Insufficient\nWeight',
          categoryBadge: 'Berat badan di bawah rentang ideal',
        );

      case 'Normal_Weight':
        return const _CategoryMeta(
          categoryKey: 'Normal',
          categoryTitle: 'Normal\nWeight',
          categoryBadge: 'Berat badan dalam rentang ideal',
        );

      case 'Overweight_Level_I':
        return const _CategoryMeta(
          categoryKey: 'Overweight',
          categoryTitle: 'Overweight\nLevel I',
          categoryBadge: 'Kelebihan berat badan tingkat I',
        );

      case 'Overweight_Level_II':
        return const _CategoryMeta(
          categoryKey: 'Overweight',
          categoryTitle: 'Overweight\nLevel II',
          categoryBadge: 'Kelebihan berat badan tingkat II',
        );

      case 'Obesity_Type_I':
        return const _CategoryMeta(
          categoryKey: 'Obesitas I',
          categoryTitle: 'Obesity\nLevel I',
          categoryBadge: 'Berat badan tingkat obesitas I',
        );

      case 'Obesity_Type_II':
        return const _CategoryMeta(
          categoryKey: 'Obesitas II',
          categoryTitle: 'Obesity\nLevel II',
          categoryBadge: 'Berat badan tingkat obesitas II',
        );

      case 'Obesity_Type_III':
        return const _CategoryMeta(
          categoryKey: 'Obesitas III',
          categoryTitle: 'Obesity\nLevel III',
          categoryBadge: 'Berat badan tingkat obesitas III (Morbid)',
        );

      default:
        return const _CategoryMeta(
          categoryKey: 'Overweight',
          categoryTitle: 'Overweight\nLevel I',
          categoryBadge: 'Berat badan di atas rentang ideal',
        );
    }
  }
}

class _CategoryMeta {
  final String categoryKey;
  final String categoryTitle;
  final String categoryBadge;

  const _CategoryMeta({
    required this.categoryKey,
    required this.categoryTitle,
    required this.categoryBadge,
  });
}

class _ReconciliationResult {
  final String clinicalClass;
  final bool isAdjusted;
  final String? reason;

  const _ReconciliationResult({
    required this.clinicalClass,
    required this.isAdjusted,
    this.reason,
  });
}
