/// Aturan Rekomendasi Klinis Tata Laksana Obesitas & Pengendalian Berat Badan
/// Berdasarkan:
/// 1. Konsensus Pengelolaan Obesitas PAPDI (Perhimpunan Dokter Spesialis Penyakit Dalam Indonesia)
///    https://papdi.or.id/pdfs/1422/Soft%20copy%20konsensus%20obesitas.pdf
/// 2. Keputusan Menteri Kesehatan RI No. HK.01.07-MENKES-509-2025
///    (Pedoman Nasional Pelayanan Kedokteran Tata Laksana Obesitas Dewasa)
///    https://keslan.kemkes.go.id/unduhan/KMK%20No.%20HK.01.07-MENKES-509-2025.pdf

class CategoryRecommendation {
  final String categoryKey; // 'Normal', 'Overweight', 'Obesitas I', 'Obesitas II', 'Obesitas III', 'Underweight'
  final String categoryDisplayName;
  final String imtRange;
  final String clinicalGoal; // Target Klinis (misal: Pertahankan BB, Penurunan 5-10%, dll)
  final String subtitleNote;
  final List<String> foodRecommendations; // Pola Makan / Terapi Nutrisi Medis
  final List<String> physicalActivityRecommendations; // Aktivitas Fisik & Latihan
  final List<String> hydrationRecommendations; // Hidrasi & Minuman
  final List<String> restAndBehaviorRecommendations; // Istirahat & Modifikasi Perilaku
  final String evaluationPeriod; // Durasi evaluasi (misal: 30 hari / 3-6 bulan)

  const CategoryRecommendation({
    required this.categoryKey,
    required this.categoryDisplayName,
    required this.imtRange,
    required this.clinicalGoal,
    required this.subtitleNote,
    required this.foodRecommendations,
    required this.physicalActivityRecommendations,
    required this.hydrationRecommendations,
    required this.restAndBehaviorRecommendations,
    required this.evaluationPeriod,
  });
}

class SkriningRecommendationRules {
  /// Mendapatkan rekomendasi spesifik berdasarkan kategori hasil klasifikasi model/skrining
  static CategoryRecommendation getRecommendationByCategory(String category) {
    switch (category) {
      case 'Normal':
        return _normalRecommendation;

      case 'Overweight':
        return _overweightRecommendation;

      case 'Obesitas I':
        return _obesitas1Recommendation;

      case 'Obesitas II':
        return _obesitas2Recommendation;

      case 'Obesitas III':
        return _obesitas3Recommendation;

      case 'Underweight':
        return _underweightRecommendation;

      default:
        // Default fallback ke Overweight jika kategori tidak teridentifikasi
        return _overweightRecommendation;
    }
  }

  // =========================================================================
  // 1. KATEGORI NORMAL (IMT 18.5 - 22.9 kg/m²)
  // Sumber: PAPDI & KMK Kemenkes 2025 - Pemeliharaan Berat Badan & Gaya Hidup Sehat
  // =========================================================================
  static const CategoryRecommendation _normalRecommendation = CategoryRecommendation(
    categoryKey: 'Normal',
    categoryDisplayName: 'Berat Badan Normal',
    imtRange: 'IMT 18.5 – 22.9 kg/m²',
    clinicalGoal: 'Pemeliharaan berat badan ideal & pencegahan penumpukan lemak viseral.',
    subtitleNote: 'Status berat badan Anda saat ini berada dalam rentang sehat. Pertahankan kebiasaan baik ini.',
    foodRecommendations: [
      'Terapkan pola makan gizi seimbang sesuai panduan "Isi Piringku" (50% sayur & buah, 25% karbohidrat kompleks, 25% protein rendah lemak).',
      'Konsumsi minimal 3–5 porsi sayur dan buah beragam setiap hari untuk mencukupi kebutuhan serat 25–30 gram/hari.',
      'Batasi konsumsi Gula, Garam, dan Lemak (GGL) harian (Maksimal: Gula 4 sdm/50g, Garam 1 sdt/5g, Lemak 5 sdm/67g).',
      'Utamakan karbohidrat kompleks (nasi merah, oatmeal, ubi) dan hindari makanan ultra-proses (UPF) berlebih.',
    ],
    physicalActivityRecommendations: [
      'Lakukan aktivitas fisik aerobik intensitas sedang minimal 150 menit per minggu (30 menit/hari, 5x seminggu).',
      'Contoh latihan: Jalan cepat, jogging ringan, bersepeda, renang, atau senam aerobik.',
      'Sertakan latihan penguatan otot (beban tubuh/gym) minimal 2 kali seminggu untuk menjaga massa otot (Fat-Free Mass).',
      'Kurangi perilaku menetap (sedentary behavior) dengan jeda peregangan atau jalan santai tiap 1-2 jam.',
    ],
    hydrationRecommendations: [
      'Minum air putih minimal 8 gelas per hari (± 2 Liter) secara teratur.',
      'Hindari konsumsi Minuman Berpemanis Dalam Kemasan (MBDK), boba, soda, dan minuman beralkohol.',
      'Jadwalkan minum air secara teratur tanpa menunggu timbulnya rasa haus.',
    ],
    restAndBehaviorRecommendations: [
      'Penuhi durasi tidur berkualitas 7–8 jam setiap malam untuk mendukung metabolisme dan regenerasi sel.',
      'Batasi waktu penggunaan gawai/layar (screen time) rekreasional maksimal 1–2 jam per hari.',
      'Matikan gadget minimal 1 jam sebelum tidur untuk menjaga ritme sirkadian tubuh.',
    ],
    evaluationPeriod: 'Lakukan evaluasi pola hidup dan ulangi skrining setiap 30 hari untuk mempertahankan status normal.',
  );

  // =========================================================================
  // 2. KATEGORI OVERWEIGHT / PRE-OBESITAS (IMT 23.0 - 24.9 kg/m²)
  // Sumber: PAPDI & KMK Kemenkes 2025 - Intervensi Dini & Defisit Energi Ringan
  // =========================================================================
  static const CategoryRecommendation _overweightRecommendation = CategoryRecommendation(
    categoryKey: 'Overweight',
    categoryDisplayName: 'Overweight (Kelebihan Berat Badan)',
    imtRange: 'IMT 23.0 – 24.9 kg/m²',
    clinicalGoal: 'Pencegahan progresi ke obesitas & penurunan berat badan 3–5% menuju rentang normal.',
    subtitleNote: 'Berat badan sedikit di atas rentang ideal. Intervensi gaya hidup dini sangat efektif mengembalikan ke batas normal.',
    foodRecommendations: [
      'Terapkan defisit energi ringan (kurangi 300–500 kkal/hari dari total kebutuhan energi harian).',
      'Makan 3 kali sehari teratur dengan porsi terkontrol; hindari porsi berlebih dan kebiasaan ngemil larut malam.',
      'Tingkatkan konsumsi serat larut air (sayuran hijau, apel, pir, oatmeal) untuk memperlama rasa kenyang.',
      'Batasi makanan yang digoreng, makanan bersantan kental, kue manis, dan camilan tinggi kalori kosong.',
    ],
    physicalActivityRecommendations: [
      'Tingkatkan aktivitas fisik menjadi 150–200 menit per minggu (30–45 menit/hari, 5x seminggu).',
      'Contoh olahraga: Jalan cepat dengan kecepatan konstan, bersepeda, jogging, atau senam aerobik.',
      'Lakukan pemanasan 5–10 menit sebelum olahraga dan pendinginan setelahnya untuk mencegah ketegangan otot.',
      'Tingkatkan Non-Exercise Activity Thermogenesis (NEAT), seperti gunakan tangga dan targetkan 7.000–10.000 langkah/hari.',
    ],
    hydrationRecommendations: [
      'Minum air putih 8 gelas sehari (± 2 Liter).',
      'Biasakan minum 1 gelas air putih 30 menit sebelum makan untuk membantu mengontrol nafsu makan.',
      'Hindari total minuman manis kemasan, sirup, teh manis kemasan, dan alkohol.',
    ],
    restAndBehaviorRecommendations: [
      'Pertahankan tidur teratur 7–8 jam/malam (kurang tidur memicu peningkatan hormon ghrelin pemicu lapar).',
      'Batasi penggunaan perangkat hiburan maksimal 1–2 jam per hari dan hindari makan di depan layar TV/smartphone.',
      'Matikan gadget 1 jam sebelum tidur dan lakukan pencatatan mandiri (self-monitoring) pola makan harian.',
    ],
    evaluationPeriod: 'Coba lakukan perubahan gaya hidup selama 30 hari dan ulangi skrining untuk mengevaluasi progres penurunan berat badan.',
  );

  // =========================================================================
  // 3. KATEGORI OBESITAS I (IMT 25.0 - 29.9 kg/m²)
  // Sumber: PAPDI & KMK Kemenkes 2025 - Terapi Nutrisi Medis & Defisit 500-750 kkal
  // =========================================================================
  static const CategoryRecommendation _obesitas1Recommendation = CategoryRecommendation(
    categoryKey: 'Obesitas I',
    categoryDisplayName: 'Obesitas Tingkat I',
    imtRange: 'IMT 25.0 – 29.9 kg/m²',
    clinicalGoal: 'Penurunan berat badan 5–10% dari berat awal dalam 3–6 bulan untuk menurunkan risiko metabolik.',
    subtitleNote: 'Anda memiliki risiko obesitas tingkat 1. Penurunan berat badan terstruktur terbukti menurunkan tekanan darah & gula darah.',
    foodRecommendations: [
      'Terapkan Terapi Nutrisi Medis (TNM) dengan diet rendah kalori terstruktur (defisit 500–750 kkal/hari).',
      'Target asupan energi sekitar 1.200–1.500 kkal/hari untuk wanita dan 1.500–1.800 kkal/hari untuk pria (atau sesuai arahan nutrisionis).',
      'Pilih makanan tinggi protein tanpa lemak (dada ayam tanpa kulit, tahu, tempe, ikan) dan tinggi serat (sayur, buah utuh).',
      'Eliminasi total makanan ultra-proses (junk food), gorengan bertepung, camilan gurih tinggi garam, dan minuman manis.',
    ],
    physicalActivityRecommendations: [
      'Latihan aerobik intensitas sedang 200–250 menit per minggu (40–50 menit/hari, 5x seminggu).',
      'Pilih jenis olahraga low-impact untuk melindungi sendi lutut & pergelangan: Jalan cepat, sepeda statis, berenang, atau senam air.',
      'Wajib pemanasan dan pendinginan 10 menit untuk menjaga denyut jantung dan fleksibilitas sendi.',
      'Kombinasikan dengan latihan resistensi ringan 2 kali seminggu untuk mempertahankan massa otot.',
    ],
    hydrationRecommendations: [
      'Tingkatkan asupan air putih menjadi 8–10 gelas per hari (± 2.0 – 2.5 Liter) guna mendukung laju metabolisme.',
      'Minum 1–2 gelas air putih 30 menit sebelum makan besar guna menekan porsi makan berlebih.',
      'Pantang minuman bersoda, boba, kopi manis susu kental manis, dan minuman beralkohol.',
    ],
    restAndBehaviorRecommendations: [
      'Tidur cukup 7–8 jam/malam dengan jadwal tidur yang konsisten setiap harinya.',
      'Lakukan pencatatan makanan harian (food diary) dan penimbangan berat badan secara berkala 1 kali seminggu.',
      'Matikan gadget 1 jam sebelum tidur dan konsultasikan dengan dokter/ahli gizi untuk pemeriksaan komorbiditas.',
    ],
    evaluationPeriod: 'Terapkan program selama 30 hari pertama, pantau penurunan berat badan, dan ulangi skrining berkala.',
  );

  // =========================================================================
  // 4. KATEGORI OBESITAS II (IMT 30.0 - 34.9 kg/m²)
  // Sumber: PAPDI & KMK Kemenkes 2025 - Intervensi Intensif & Proteksi Sendi
  // =========================================================================
  static const CategoryRecommendation _obesitas2Recommendation = CategoryRecommendation(
    categoryKey: 'Obesitas II',
    categoryDisplayName: 'Obesitas Tingkat II',
    imtRange: 'IMT 30.0 – 34.9 kg/m²',
    clinicalGoal: 'Penurunan berat badan 10–15% secara bertahap di bawah pengawasan medis untuk mencegah komplikasi kardiometabolik.',
    subtitleNote: 'Tingkat obesitas memerlukan penanganan terstruktur untuk mencegah komplikasi diabetes, hipertensi, dan sendi.',
    foodRecommendations: [
      'Jalani Terapi Nutrisi Medis intensif dengan defisit 750–1.000 kkal/hari di bawah pendampingan dokter/dietisien.',
      'Fokus pada porsi makan terukur: Perbanyak serat sayuran (>30 gram/hari) dan sumber protein murni berkualitas tinggi.',
      'Hindari diet ekstrem tak seimbang; terapkan pola 3 kali makan utama porsi kecil dan 2 selingan buah rendah kalori.',
      'Hindari sepenuhnya makanan cepat saji, karbohidrat sederhana murni, makanan tinggi lemak jenuh, dan garam berlebih.',
    ],
    physicalActivityRecommendations: [
      'Aktivitas fisik berfokus pada olahraga ramah sendi (non-weight bearing): Berenang, sepeda statis reclined, atau jalan santai bertahap.',
      'Durasi 45–60 menit/hari, 5–6 hari seminggu (target akumulasi 250–300 menit per minggu secara bertahap).',
      'Hindari olahraga high-impact seperti melompat atau lari cepat di permukaan keras guna mencegah cedera lutut (osteoarthritis).',
      'Lakukan pengawasan denyut nadi saat berolahraga dan awali selalu dengan pemanasan bertahap.',
    ],
    hydrationRecommendations: [
      'Konsumsi air putih 10–12 gelas per hari (± 2.5 Liter) untuk mendukung fungsi ginjal dan hidrasi seluler.',
      'Minum air putih dingin atau suhu ruang sebelum dan sesudah beraktivitas fisik.',
      'Hindari seluruh jenis minuman berpemanis, sirup, alkohol, dan minuman berenergi.',
    ],
    restAndBehaviorRecommendations: [
      'Pastikan tidur 7–8 jam/malam; konsultasikan ke dokter jika terdapat keluhan mendengkur keras atau henti napas saat tidur (Sleep Apnea).',
      'Terapkan modifikasi perilaku kognitif (menghindari emotional eating saat stres) dan batasi screen time.',
      'Lakukan pemeriksaan laboratorium berkala (gula darah puasa, HbA1c, profil lipid, fungsi hati dan ginjal).',
    ],
    evaluationPeriod: 'Lakukan intervensi disiplin selama 30 hari dan konsultasikan hasil perkembangan kepada tenaga kesehatan.',
  );

  // =========================================================================
  // 5. KATEGORI OBESITAS III (IMT >= 35.0 kg/m² - Obesitas Morbid/Ekstrem)
  // Sumber: PAPDI & KMK Kemenkes 2025 - Tata Laksana Medis Multidisiplin
  // =========================================================================
  static const CategoryRecommendation _obesitas3Recommendation = CategoryRecommendation(
    categoryKey: 'Obesitas III',
    categoryDisplayName: 'Obesitas Tingkat III (Morbid)',
    imtRange: 'IMT ≥ 35.0 kg/m²',
    clinicalGoal: 'Penurunan berat badan klinis signifikan (>15-20%) melalui pendekatan multidisiplin medis terpadu.',
    subtitleNote: 'Status obesitas tingkat lanjut membutuhkan pengawasan medis langsung untuk evaluasi komorbiditas dan terapi komprehensif.',
    foodRecommendations: [
      'Wajib konsultasi dengan Dokter Spesialis Penyakit Dalam (Sp.PD) dan Dokter Spesialis Gizi Klinik (Sp.GK) untuk terapi nutrisi ketat.',
      'Terapi diet sangat terkontrol (bila diindikasikan: Low Calorie Diet/LCD atau Very Low Calorie Diet/VLCD terawasi medis).',
      'Porsi makan sangat terukur dengan penekanan pada protein tinggi untuk cegah sarkopenia, kaya mikronutrien, dan bebas gula tambahan.',
      'Evaluasi bersama dokter mengenai opsi terapi farmakoterapi anti-obesitas atau bedah bariatrik sesuai pedoman KMK Kemenkes 2025.',
    ],
    physicalActivityRecommendations: [
      'Latihan fisik terawasi (supervised exercise) yang disesuaikan dengan kapasitas fungsional jantung-paru dan toleransi sendi.',
      'Sangat dianjurkan latihan dalam air (hydrotherapy / renang santai) atau sepeda statis senderan (recumbent bike).',
      'Mulai dengan durasi 15–20 menit/hari, tingkatkan secara perlahan sesuai rekomendasi dokter spesialis kedokteran olahraga.',
      'Hindari berdiri terlalu lama tanpa tumpuan dan hindari gerakan dengan beban hentakan tinggi.',
    ],
    hydrationRecommendations: [
      'Konsumsi air putih 2.5 – 3 Liter per hari (disesuaikan dengan kondisi fungsi jantung dan ginjal oleh dokter).',
      'Ganti seluruh minuman berkalori dengan air putih murni.',
      'Pantau warna urine agar tetap jernih atau kuning muda sebagai indikator hidrasi optimal.',
    ],
    restAndBehaviorRecommendations: [
      'Skrining dan tata laksana segera untuk risiko Obstructive Sleep Apnea (OSA) dan gangguan tidur obstruktif.',
      'Posisikan kepala dan leher lebih ergonomis saat tidur (gunakan bantal penopang yang tepat).',
      'Wajib pemeriksaan medis komprehensif (EKG, USG Abdomen, HbA1c, profil lipid lengkap, tekanan darah harian).',
    ],
    evaluationPeriod: 'Pantau ketat progres kesehatan Anda setiap minggu dan jadwalkan kontrol rutin ke fasilitas pelayanan kesehatan.',
  );

  // =========================================================================
  // 6. KATEGORI UNDERWEIGHT (IMT < 18.5 kg/m²)
  // Sumber: Kemenkes RI - Peningkatan Berat Badan Sehat & Massa Otot
  // =========================================================================
  static const CategoryRecommendation _underweightRecommendation = CategoryRecommendation(
    categoryKey: 'Underweight',
    categoryDisplayName: 'Berat Badan Kurang (Underweight)',
    imtRange: 'IMT < 18.5 kg/m²',
    clinicalGoal: 'Peningkatan berat badan bertahap (surplus energi sehat) untuk mencapai IMT ideal 18.5–22.9 kg/m².',
    subtitleNote: 'Berat badan Anda berada di bawah rentang normal. Tingkatkan asupan kalori dan nutrisi untuk daya tahan tubuh optimal.',
    foodRecommendations: [
      'Terapkan pola makan dengan surplus energi sehat (tambah 300–500 kkal/hari dari kebutuhan harian).',
      'Makan teratur 3 kali sehari porsi lengkap ditambah 2–3 kali camilan padat nutrisi (alpukat, kacang-kacangan, telur rebus, smoothie susu).',
      'Tingkatkan asupan protein berkualitas (1.2–1.5 g/kgBB/hari): Telur, ikan, daging ayam, tempe, tahu, dan susu.',
      'Hindari minum air dalam jumlah banyak tepat sebelum makan agar tidak cepat merasa kenyang sebelum porsi habis.',
    ],
    physicalActivityRecommendations: [
      'Fokus pada latihan beban (resistance & strength training) 3–4 kali seminggu untuk membangun massa otot, bukan hanya lemak.',
      'Batasi olahraga kardio durasi panjang dengan intensitas tinggi yang membakar terlalu banyak kalori.',
      'Lakukan pemanasan dan pendinginan setiap sesi latihan untuk mencegah cedera otot.',
      'Beri jeda istirahat antar hari latihan untuk memberi waktu pemulihan dan hipertrofi otot.',
    ],
    hydrationRecommendations: [
      'Cukupi kebutuhan air putih minimal 8 gelas per hari (± 2 Liter) di antara waktu makan.',
      'Pilih minuman bernutrisi seperti susu murni, jus buah asli tanpa gula tambahan, atau smoothie kaya protein.',
      'Hindari konsumsi kafein berlebih yang dapat menekan nafsu makan alami.',
    ],
    restAndBehaviorRecommendations: [
      'Tidur cukup 7–8 jam setiap malam untuk mendukung proses sintesis protein dan regenerasi jaringan tubuh.',
      'Kelola stres dengan baik untuk menjaga kestabilan nafsu makan dan penyerapan nutrisi saluran cerna.',
      'Konsultasikan dengan ahli gizi jika berat badan sulit bertambah atau ada keluhan gangguan pencernaan.',
    ],
    evaluationPeriod: 'Terapkan program selama 30 hari dan pantau peningkatan berat badan secara berkala.',
  );
}
