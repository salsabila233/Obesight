class SkriningData {
  // Step 1: Data Diri
  String? gender; // 'Laki-laki', 'Perempuan'
  int? age;
  double? height; // in cm
  double? weight; // in kg

  // Step 2: Riwayat Keluarga & Pola Makan
  String? familyHistory; // 'Ya', 'Tidak'
  String? highCalorieFood; // 'Ya', 'Tidak'
  String? vegetableIntake; // 'Jarang', 'Kadang-kadang', 'Sering'
  String? mainMealFrequency; // '1 kali', '2 kali', '3 kali', '4 kali atau lebih'

  // Step 3: Kebiasaan & Gaya Hidup
  String? snackFrequency; // 'Tidak pernah', 'Kadang-kadang', 'Sering', 'Selalu'
  String? smoking; // 'Ya', 'Tidak'
  String? waterIntake; // '<1 Liter', '1-2 Liter', '>2 Liter'
  String? monitorCalories; // 'Ya', 'Tidak'

  // Step 4: Aktifitas Fisik
  String? physicalActivity; // 'Tidak pernah', 'Kadang-kadang', 'Sering', 'Selalu'
  String? screenTime; // '<1 Jam', '1-2 Jam', '>2 Jam'

  // Step 5: Konsumsi Alkohol & Transportasi
  String? alcohol; // 'Tidak pernah', 'Kadang-kadang', 'Sering', 'Selalu'
  String? transportation; // 'Jalan kaki', 'Sepeda', 'Motor', 'Mobil', 'Transportasi umum'

  // Hasil Inferensi Model AI (Random Forest)
  String? aiRawClass; // Prediksi murni RF: 'Normal_Weight', 'Overweight_Level_I', etc.
  String? aiRawCategoryKey;
  String? aiRawCategoryTitle;

  String? aiClinicalClass; // Kelas setelah validasi klinis
  String? aiCategoryKey;
  String? aiCategoryTitle;
  String? aiCategoryBadge;

  bool isClinicallyAdjusted = false;
  String? clinicalAdjustmentReason;

  double? aiConfidence; // e.g. 85.0
  Map<String, int>? aiVotes; // Distribusi suara 100 decision trees
  Map<String, double>? aiProbabilities;

  bool isPredictionSuccess = false;
  String? predictionErrorMessage;

  /// Getter penyesuaian backwards compatibility
  String? get aiPredictedClass => aiRawClass;
  set aiPredictedClass(String? val) => aiRawClass = val;

  SkriningData({
    this.gender = 'Perempuan',
    this.age = 23,
    this.height = 165,
    this.weight = 72,
    this.familyHistory,
    this.highCalorieFood,
    this.vegetableIntake,
    this.mainMealFrequency,
    this.snackFrequency,
    this.smoking,
    this.waterIntake,
    this.monitorCalories,
    this.physicalActivity,
    this.screenTime,
    this.alcohol,
    this.transportation,
    this.aiRawClass,
    this.aiRawCategoryKey,
    this.aiRawCategoryTitle,
    this.aiClinicalClass,
    this.aiCategoryKey,
    this.aiCategoryTitle,
    this.aiCategoryBadge,
    this.isClinicallyAdjusted = false,
    this.clinicalAdjustmentReason,
    this.aiConfidence,
    this.aiVotes,
    this.aiProbabilities,
    this.isPredictionSuccess = false,
    this.predictionErrorMessage,
    String? aiPredictedClass,
  }) {
    if (aiPredictedClass != null && aiRawClass == null) {
      aiRawClass = aiPredictedClass;
    }
  }

  // Calculate BMI
  double get bmi {
    if (height == null || weight == null || height! <= 0 || weight! <= 0) {
      return 26.8;
    }
    final hMeters = height! / 100.0;
    return weight! / (hMeters * hMeters);
  }

  String get formattedBmi {
    return bmi.toStringAsFixed(1).replaceAll('.', ',');
  }

  // Official classification category key (PAPDI & KMK No. HK.01.07-MENKES-509-2025)
  // Memprioritaskan hasil prediksi model Random Forest yang telah tervalidasi klinis
  String get classificationCategory {
    if (isPredictionSuccess && aiCategoryKey != null && aiCategoryKey!.isNotEmpty) {
      return aiCategoryKey!;
    }
    final currentBmi = bmi;
    if (currentBmi < 18.5) {
      return 'Underweight';
    } else if (currentBmi <= 22.9) {
      return 'Normal';
    } else if (currentBmi <= 24.9) {
      return 'Overweight';
    } else if (currentBmi <= 29.9) {
      return 'Obesitas I';
    } else if (currentBmi <= 34.9) {
      return 'Obesitas II';
    } else {
      return 'Obesitas III';
    }
  }

  // Category title matching UI reference (prioritas hasil Random Forest yang valid)
  // Konsisten dengan 7 kelas dataset & model:
  // 1. Insufficient Weight, 2. Normal Weight, 3. Overweight Level I,
  // 4. Overweight Level II, 5. Obesity Level I, 6. Obesity Level II, 7. Obesity Level III
  String get categoryTitle {
    if (isPredictionSuccess && aiCategoryTitle != null && aiCategoryTitle!.isNotEmpty) {
      return aiCategoryTitle!;
    }

    final currentBmi = bmi;
    if (currentBmi < 18.5) {
      return 'Insufficient\nWeight';
    } else if (currentBmi <= 22.9) {
      return 'Normal\nWeight';
    } else if (currentBmi <= 24.9) {
      return 'Overweight\nLevel I';
    } else if (currentBmi <= 27.0) {
      return 'Overweight\nLevel II';
    } else if (currentBmi <= 29.9) {
      return 'Obesity\nLevel I';
    } else if (currentBmi <= 34.9) {
      return 'Obesity\nLevel II';
    } else {
      return 'Obesity\nLevel III';
    }
  }

  // Category badge matching UI reference
  String get categoryBadge {
    if (isPredictionSuccess && aiCategoryBadge != null && aiCategoryBadge!.isNotEmpty) {
      return aiCategoryBadge!;
    }

    final currentBmi = bmi;
    if (currentBmi < 18.5) {
      return 'Berat badan di bawah rentang ideal';
    } else if (currentBmi <= 22.9) {
      return 'Berat badan dalam rentang ideal';
    } else if (currentBmi <= 24.9) {
      return 'Kelebihan berat badan tingkat I';
    } else if (currentBmi <= 27.0) {
      return 'Kelebihan berat badan tingkat II';
    } else if (currentBmi <= 29.9) {
      return 'Berat badan tingkat obesitas I';
    } else if (currentBmi <= 34.9) {
      return 'Berat badan tingkat obesitas II';
    } else {
      return 'Berat badan tingkat obesitas III (Morbid)';
    }
  }

  // Risk Title (selaras dengan kategori klasifikasi hasil AI & IMT)
  String get riskTitle {
    final cat = classificationCategory.toLowerCase();
    if (cat.contains('obesitas iii') || cat.contains('obesity level iii') || cat.contains('morbid')) {
      return 'Risiko Sangat Tinggi';
    } else if (cat.contains('obesitas') || cat.contains('obesity')) {
      return 'Risiko Tinggi';
    } else if (cat.contains('overweight') || cat.contains('lebih')) {
      return 'Risiko Meningkat';
    } else if (cat.contains('underweight') || cat.contains('insufficient') || cat.contains('kurang')) {
      return 'Perlu Perhatian';
    }

    // Jika Kategori Normal:
    if (highCalorieFood == 'Ya' || physicalActivity == 'Tidak pernah') {
      return 'Risiko Rendah - Sedang';
    }
    return 'Risiko Terkendali';
  }

  // Risk Description matching clinical risk profile
  String get riskDescription {
    final currentBmi = bmi;
    if (currentBmi < 18.5) {
      return 'Berat badan Anda berada di bawah batas sehat. Diperlukan evaluasi asupan gizi seimbang dan pemenuhan kalori untuk mencegah risiko malnutrisi atau penurunan imunitas.';
    } else if (currentBmi <= 22.9) {
      return 'Pola hidup dan berat badan Anda saat ini berada dalam rentang baik. Tetap pertahankan konsumsi makanan bergizi seimbang dan aktivitas fisik secara konsisten.';
    } else if (currentBmi <= 27.0) {
      return 'Anda memiliki risiko sedang terhadap obesitas. Beberapa kebiasaan Anda sudah cukup baik, namun masih ada yang perlu ditingkatkan agar risiko obesitas tidak bertambah.';
    } else {
      return 'Anda memiliki risiko tinggi terhadap obesitas dan komplikasi terkait. Disarankan untuk berkonsultasi dengan ahli gizi atau dokter serta mengatur pola makan dan aktivitas teratur.';
    }
  }

  // Potential risks bullet points
  List<String> get potentialRisks {
    final currentBmi = bmi;
    if (currentBmi < 18.5) {
      return [
        'Risiko defisiensi zat gizi mikro & anemia',
        'Penurunan daya tahan tubuh / imunitas',
        'Kelemahan massa otot dan mudah lelah',
        'Kerapuhan tulang dini (risiko osteopenia)',
      ];
    } else if (currentBmi <= 22.9) {
      return [
        'Kekurangan nutrisi mikro jika pola makan tidak beragam',
        'Penurunan massa otot bila kurang berolahraga',
        'Potensi kenaikan berat badan tanpa disadari',
      ];
    }
    return [
      'Lemak tubuh meningkat',
      'Risiko tekanan darah tinggi',
      'Kolesterol mulai naik',
      'Mudah lelah',
    ];
  }

  // Attention factors bullet points (soft green card in UI reference)
  List<String> get attentionFactors {
    final factors = <String>[];

    if (physicalActivity == 'Tidak pernah' || physicalActivity == 'Kadang-kadang') {
      factors.add('Aktifitas fisik rendah');
    }
    if (highCalorieFood == 'Ya' || snackFrequency == 'Sering' || snackFrequency == 'Selalu') {
      factors.add('Konsumsi makanan tinggi kalori yang sering');
    }
    if (vegetableIntake == 'Jarang' || vegetableIntake == 'Kadang-kadang') {
      factors.add('Konsumsi sayur yang kurang');
    }
    if (waterIntake == '<1 Liter') {
      factors.add('Konsumsi air putih kurang dari kebutuhan harian');
    }
    if (screenTime == '>2 Jam') {
      factors.add('Waktu santai di depan layar relatif tinggi');
    }
    if (smoking == 'Ya') {
      factors.add('Kebiasaan merokok yang berisiko pada sirkulasi');
    }

    // Default factors if user lived very healthy
    if (factors.isEmpty) {
      factors.addAll([
        'Aktifitas fisik tetap perlu dijaga rutin',
        'Pertahankan konsumsi serat dan sayuran',
        'Cukupi kebutuhan istirahat setiap malam',
      ]);
    }

    return factors;
  }
}
