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
  });

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

  // Category title matching UI reference: "Overweight\nLevel I" or similar
  String get categoryTitle {
    final currentBmi = bmi;
    if (currentBmi < 18.5) {
      return 'Underweight\nLevel I';
    } else if (currentBmi <= 22.9) {
      return 'Normal\nWeight';
    } else if (currentBmi <= 27.5) {
      return 'Overweight\nLevel I';
    } else if (currentBmi <= 29.9) {
      return 'Overweight\nLevel II';
    } else {
      return 'Obesitas\nTingkat I';
    }
  }

  // Category badge matching UI reference
  String get categoryBadge {
    final currentBmi = bmi;
    if (currentBmi < 18.5) {
      return 'Berat badan di bawah rentang ideal';
    } else if (currentBmi <= 22.9) {
      return 'Berat badan dalam rentang ideal';
    } else if (currentBmi <= 27.5) {
      return 'Berat badan sedikit diatas rentang ideal';
    } else {
      return 'Berat badan melampaui batas normal';
    }
  }

  // Risk Title
  String get riskTitle {
    final currentBmi = bmi;
    if (currentBmi < 18.5) {
      return 'Perlu Perhatian';
    } else if (currentBmi <= 22.9) {
      if (highCalorieFood == 'Ya' || physicalActivity == 'Tidak pernah') {
        return 'Risiko Rendah - Sedang';
      }
      return 'Risiko Terkendali';
    } else if (currentBmi <= 27.5) {
      return 'Risiko Meningkat';
    } else {
      return 'Risiko Tinggi';
    }
  }

  // Risk Description matching screenshot
  String get riskDescription {
    final currentBmi = bmi;
    if (currentBmi <= 22.9) {
      return 'Pola hidup dan berat badan Anda saat ini berada dalam rentang baik. Tetap pertahankan konsumsi makanan bergizi seimbang dan aktivitas fisik secara konsisten.';
    } else if (currentBmi <= 27.5) {
      return 'Anda memiliki risiko sedang terhadap obesitas. Beberapa kebiasaan Anda sudah cukup baik, namun masih ada yang perlu ditingkatkan agar risiko obesitas tidak bertambah.';
    } else {
      return 'Anda memiliki risiko tinggi terhadap obesitas dan komplikasi terkait. Disarankan untuk berkonsultasi dengan ahli gizi atau dokter serta mengatur pola makan dan aktivitas teratur.';
    }
  }

  // Potential risks bullet points
  List<String> get potentialRisks {
    final currentBmi = bmi;
    if (currentBmi <= 22.9) {
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
