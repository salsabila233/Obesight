/// Service terpadu untuk perhitungan dan klasifikasi Indeks Massa Tubuh (IMT / BMI).
/// Digunakan oleh semua alur kalkulator IMT di aplikasi ObeSight.
class ImtCalculatorService {
  /// Menghitung IMT dari berat badan (kg) dan tinggi badan (cm).
  ///
  /// Rumus: IMT = berat (kg) / (tinggi (m))^2
  /// Tinggi yang dimasukkan dalam cm dikonversi ke meter (dibagi 100) sebelum dikuadratkan.
  /// Mengembalikan null jika input null, 0, negatif, atau tidak valid.
  static double? calculateBmi({required double? weight, required double? height}) {
    if (weight == null || height == null) return null;
    if (weight <= 0 || height <= 0) return null;

    final heightInMeters = height / 100.0;
    return weight / (heightInMeters * heightInMeters);
  }

  /// Membulatkan nilai IMT ke 1 tempat desimal (sesuai standar tampilan ObeSight).
  static double roundBmi(double bmi) {
    return double.parse(bmi.toStringAsFixed(1));
  }

  /// Mengonversi teks string angka menjadi double, mendukung tanda koma (',') maupun titik ('.').
  /// Contoh: "65,5" -> 65.5, " 170.2 " -> 170.2.
  static double? parseDecimal(String? text) {
    if (text == null) return null;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    final normalized = trimmed.replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  /// Mengklasifikasikan IMT ke dalam kategori berat badan dan tingkat risiko kesehatan.
  ///
  /// Mengikuti rujukan standar ObeSight:
  /// - Kurus (< 18.5) -> Risiko: Rendah
  /// - Normal (18.5 - 24.9) -> Risiko: Rendah
  /// - Gemuk (25.0 - 29.9) -> Risiko: Sedang
  /// - Obesitas (>= 30.0 / > 29.9) -> Risiko: Tinggi
  static Map<String, String> classifyBmi(double bmi) {
    if (bmi < 18.5) {
      return {'category': 'Kurus', 'risk': 'Rendah'};
    } else if (bmi <= 24.9) {
      return {'category': 'Normal', 'risk': 'Rendah'};
    } else if (bmi <= 29.9) {
      return {'category': 'Gemuk', 'risk': 'Sedang'};
    } else {
      return {'category': 'Obesitas', 'risk': 'Tinggi'};
    }
  }

  /// Memvalidasi berat badan.
  /// Mengembalikan pesan error jika kosong, bukan angka, atau di luar rentang wajar (20 - 350 kg).
  static String? validateWeight(double? weight) {
    if (weight == null || weight < 20 || weight > 350) {
      return 'Harap masukkan berat badan yang valid (20 - 350 kg)';
    }
    return null;
  }

  /// Memvalidasi tinggi badan.
  /// Mengembalikan pesan error jika kosong, bukan angka, atau di luar rentang wajar (50 - 260 cm).
  static String? validateHeight(double? height) {
    if (height == null || height < 50 || height > 260) {
      return 'Harap masukkan tinggi badan yang valid (50 - 260 cm)';
    }
    return null;
  }
}
