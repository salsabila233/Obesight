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
  /// Kelas asli scikit-learn (e.g. 'Overweight_Level_I', 'Normal_Weight')
  final String rawClass;

  /// Kunci kategori yang cocok dengan aturan rekomendasi klinis
  /// ('Underweight', 'Normal', 'Overweight', 'Obesitas I', 'Obesitas II', 'Obesitas III')
  final String categoryKey;

  /// Judul tampilan kategori (e.g. 'Overweight\nLevel I', 'Normal\nWeight')
  final String categoryTitle;

  /// Badge deskriptif (e.g. 'Berat badan ideal berdasarkan analisis AI')
  final String categoryBadge;

  /// Tingkat keyakinan model (0.0 - 100.0%)
  final double confidence;

  /// Jumlah suara per kelas dari 100 pohon keputusan
  final Map<String, int> votes;

  /// Probabilitas persentase tiap kelas
  final Map<String, double> probabilities;

  const RandomForestPrediction({
    required this.rawClass,
    required this.categoryKey,
    required this.categoryTitle,
    required this.categoryBadge,
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

    // Cari kelas dengan suara terbanyak (Majority Voting)
    int bestClassIdx = 0;
    int maxVotes = -1;
    final totalTrees = _trees.isNotEmpty ? _trees.length : 1;

    for (int i = 0; i < totalClasses; i++) {
      if (voteCounts[i] > maxVotes) {
        maxVotes = voteCounts[i];
        bestClassIdx = i;
      }
    }

    final rawClass = (bestClassIdx < _classes.length)
        ? _classes[bestClassIdx]
        : 'Overweight_Level_I';

    final confidence = (maxVotes / totalTrees) * 100.0;

    final votesMap = <String, int>{};
    final probsMap = <String, double>{};
    for (int i = 0; i < totalClasses && i < _classes.length; i++) {
      votesMap[_classes[i]] = voteCounts[i];
      probsMap[_classes[i]] = (voteCounts[i] / totalTrees) * 100.0;
    }

    // Petakan rawClass ke standar kategori aplikasi dan rekomendasi klinis
    final mapping = _mapClassToCategory(rawClass);

    return RandomForestPrediction(
      rawClass: rawClass,
      categoryKey: mapping.categoryKey,
      categoryTitle: mapping.categoryTitle,
      categoryBadge: mapping.categoryBadge,
      confidence: confidence,
      votes: votesMap,
      probabilities: probsMap,
    );
  }

  /// Sinkronisasi label prediksi AI ke standar PAPDI / KMK Kemenkes 2025
  static _CategoryMeta _mapClassToCategory(String rawClass) {
    switch (rawClass) {
      case 'Insufficient_Weight':
        return const _CategoryMeta(
          categoryKey: 'Underweight',
          categoryTitle: 'Underweight\nLevel I',
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
          categoryBadge: 'Berat badan sedikit di atas rentang ideal',
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
          categoryTitle: 'Obesitas\nTingkat I',
          categoryBadge: 'Berat badan tingkat obesitas I',
        );

      case 'Obesity_Type_II':
        return const _CategoryMeta(
          categoryKey: 'Obesitas II',
          categoryTitle: 'Obesitas\nTingkat II',
          categoryBadge: 'Berat badan tingkat obesitas II',
        );

      case 'Obesity_Type_III':
        return const _CategoryMeta(
          categoryKey: 'Obesitas III',
          categoryTitle: 'Obesitas\nTingkat III',
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
