import 'package:flutter/material.dart';
import '../screens/skrining/skrining_models.dart';

/// Service to track completed physical activities tied to specific dates
/// and provide clinical physical activity recommendations tailored to
/// user's screening results (PAPDI & KMK Kemenkes No. HK.01.07-MENKES-509-2025).
class PhysicalActivityService extends ChangeNotifier {
  static final PhysicalActivityService _instance = PhysicalActivityService._internal();
  factory PhysicalActivityService() => _instance;
  static PhysicalActivityService get instance => _instance;

  PhysicalActivityService._internal();

  // Map of dateKey ('yyyy-MM-dd') -> Set of completed activity IDs
  final Map<String, Set<String>> _completedActivitiesByDate = {};

  String formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String get todayKey => formatDateKey(DateTime.now());

  bool isCompleted(String dateKey, String activityId) {
    return _completedActivitiesByDate[dateKey]?.contains(activityId) ?? false;
  }

  Set<String> getCompletedForDate(String dateKey) {
    return _completedActivitiesByDate[dateKey] ?? const <String>{};
  }

  int getCompletedCountForDate(String dateKey) {
    return _completedActivitiesByDate[dateKey]?.length ?? 0;
  }

  void completeActivity(String dateKey, String activityId) {
    if (!_completedActivitiesByDate.containsKey(dateKey)) {
      _completedActivitiesByDate[dateKey] = <String>{};
    }
    _completedActivitiesByDate[dateKey]!.add(activityId);
    notifyListeners();
  }

  void uncompleteActivity(String dateKey, String activityId) {
    if (_completedActivitiesByDate.containsKey(dateKey)) {
      _completedActivitiesByDate[dateKey]!.remove(activityId);
      notifyListeners();
    }
  }

  /// Normalisasi kategori skrining ke standar 6 kategori resmi
  static String normalizeCategory(String category) {
    final cat = category.trim().toLowerCase();
    if (cat.contains('underweight') || cat.contains('insufficient') || cat.contains('kurang')) {
      return 'Underweight';
    } else if (cat.contains('normal')) {
      return 'Normal';
    } else if (cat.contains('overweight') || cat.contains('lebih')) {
      return 'Overweight';
    } else if (cat.contains('iii') || cat.contains('morbid') || cat.contains('3')) {
      return 'Obesitas III';
    } else if (cat.contains('ii') || cat.contains('2')) {
      return 'Obesitas II';
    } else if (cat.contains('obesitas') ||
        cat.contains('obesity') ||
        cat.contains('type_i') ||
        cat.contains('level_i') ||
        cat.contains('1')) {
      return 'Obesitas I';
    }
    return 'Overweight';
  }

  /// Mengambil daftar aktivitas olahraga yang disesuaikan secara klinis
  /// berdasarkan kategori skrining pengguna (PAPDI & KMK Kemenkes 2025).
  List<Map<String, dynamic>> getActivitiesForCategory(String category, {SkriningData? skriningData}) {
    final normalized = normalizeCategory(category);

    switch (normalized) {
      case 'Underweight':
        return _getUnderweightActivities(skriningData);
      case 'Normal':
        return _getNormalActivities(skriningData);
      case 'Overweight':
        return _getOverweightActivities(skriningData);
      case 'Obesitas I':
        return _getObesitas1Activities(skriningData);
      case 'Obesitas II':
        return _getObesitas2Activities(skriningData);
      case 'Obesitas III':
        return _getObesitas3Activities(skriningData);
      default:
        return _getOverweightActivities(skriningData);
    }
  }

  /// Helper tips adaptif berdasarkan kebiasaan fisik awal di skrining
  String _getHabitTip(SkriningData? data) {
    final habit = data?.physicalActivity?.trim().toLowerCase() ?? '';
    if (habit.contains('tidak') || habit.contains('jarang') || habit.contains('never')) {
      return 'Berdasarkan skrining Anda (aktivitas awal belum rutin): Awali 10-15 menit pertama dan tingkatkan durasi secara bertahap.';
    } else if (habit.contains('kadang') || habit.contains('1-2') || habit.contains('1 - 2')) {
      return 'Berdasarkan skrining Anda: Tetapkan jadwal 3-4 hari seminggu untuk membentuk kebiasaan olahraga yang konsisten.';
    } else if (habit.contains('sering') || habit.contains('selalu') || habit.contains('3-4') || habit.contains('rutin') || habit.contains('aktif')) {
      return 'Berdasarkan skrining Anda yang sudah aktif: Pertahankan konsistensi latihan dan pastikan waktu istirahat pemulihan otot cukup.';
    }
    return 'Lakukan latihan dengan ritme teratur dan sesuaikan dengan kapasitas kenyamanan tubuh.';
  }

  // =========================================================================
  // 1. KATEGORI NORMAL (IMT 18.5 - 22.9 kg/m²)
  // Fokus: Pemeliharaan Kapasitas Kardiorespirasi & Otot Bebas Lemak
  // Olahraga: Jogging, Bersepeda Outdoor, Renang Aerobik, Gym/Bodyweight, HIIT
  // =========================================================================
  List<Map<String, dynamic>> _getNormalActivities(SkriningData? data) {
    final habitTip = _getHabitTip(data);
    return [
      {
        'id': 'normal_jogging',
        'title': 'Jogging / Lari Santai',
        'name': 'Jogging / Lari Santai',
        'targetText': '30-45 menit',
        'heroImg': 'assets/progress/clean/hero_jogging.png',
        'thumbImg': 'assets/progress/clean/thumb_jogging.png',
        'thumb': 'assets/progress/clean/rec_thumb_jogging.png',
        'icon': 'assets/progress/clean/rec_icon_jogging.png',
        'desc': 'Meningkatkan daya tahan kardiorespirasi, pembakaran kalori, dan menjaga kesehatan jantung.',
        'duration': '30-45 menit',
        'frequency': '3-5x/minggu',
        'intensity': 'Sedang (60-70% HRmax)',
        'calories': '220-380 kkal',
        'aboutTitle': 'Tentang Jogging',
        'aboutDesc':
            'Jogging merupakan aktivitas aerobik sedang yang efektif mempertahankan berat badan ideal, menjaga elastisitas pembuluh darah, dan meningkatkan VO2 max.',
        'benefits': [
          'Mempertahankan kebugaran jantung dan paru-paru dalam rentang optimal',
          'Mendukung regulasi berat badan ideal dan sensitivitas insulin',
          'Memicu pelepasan endorfin untuk meredakan stres harian',
          'Meningkatkan daya tahan tubuh dan kebugaran fungsional',
        ],
        'specs': {
          'duration': '30-45 menit',
          'frequency': '3-5 kali/minggu',
          'intensity': 'Sedang (60-70% HRmax)',
          'calories': '220-380 kkal',
        },
        'tipsTitle': 'Tips Melakukan Jogging',
        'tips': [
          habitTip,
          'Lakukan pemanasan 5-10 menit sebelum mulai berlari.',
          'Gunakan sepatu lari dengan bantalan yang sesuai untuk meredam impak.',
          'Jaga postur tubuh tetap tegak dan pandangan lurus ke depan.',
        ],
        'refLink': 'https://doi.org/10.25182/jgp.2016.11.3.%25p',
      },
      {
        'id': 'normal_cycling',
        'title': 'Bersepeda Outdoor / Santai',
        'name': 'Bersepeda Outdoor',
        'targetText': '30-60 menit',
        'heroImg': 'assets/progress/clean/hero_cycling.png',
        'thumbImg': 'assets/progress/clean/thumb_cycling.png',
        'thumb': 'assets/progress/clean/rec_thumb_cycling.png',
        'icon': 'assets/progress/clean/rec_icon_cycling.png',
        'desc': 'Melatih daya tahan jantung-paru dan kekuatan otot kaki secara dinamis di luar ruangan.',
        'duration': '30-60 menit',
        'frequency': '3-4x/minggu',
        'intensity': 'Sedang (55-70% HRmax)',
        'calories': '200-380 kkal',
        'aboutTitle': 'Tentang Bersepeda Outdoor',
        'aboutDesc':
            'Bersepeda melatih kapasitas aerobik dan kekuatan otot kuadrisep serta betis, memberikan variasi rute yang menyenangkan untuk kesehatan mental.',
        'benefits': [
          'Melatih kebugaran kardiovaskular secara berkelanjutan',
          'Memperkuat otot paha, betis, dan pinggul',
          'Menurunkan hormon stres dan menyegarkan pikiran',
        ],
        'specs': {
          'duration': '30-60 menit',
          'frequency': '3-4 kali/minggu',
          'intensity': 'Sedang (55-70% HRmax)',
          'calories': '200-380 kkal',
        },
        'tipsTitle': 'Tips Bersepeda Outdoor',
        'tips': [
          habitTip,
          'Gunakan helm pelindung kepala dan patuhi rambu lalu lintas.',
          'Pastikan posisi sadel sejajar dengan pinggul saat berdiri.',
          'Bawa air minum untuk menjaga hidrasi sepanjang perjalanan.',
        ],
        'refLink': 'https://doi.org/10.21831/medikora.v14i2.7937',
      },
      {
        'id': 'normal_swimming',
        'title': 'Renang Aerobik (Full Body Workout)',
        'name': 'Renang Aerobik',
        'targetText': '30-45 menit',
        'heroImg': 'assets/progress/clean/hero_swimming.png',
        'thumbImg': 'assets/progress/clean/thumb_swimming.png',
        'thumb': 'assets/progress/clean/rec_thumb_swimming.png',
        'icon': 'assets/progress/clean/rec_icon_swimming.png',
        'desc': 'Melibatkan hampir seluruh kelompok otot tubuh sekaligus meningkatkan kapasitas vital paru-paru.',
        'duration': '30-45 menit',
        'frequency': '2-3x/minggu',
        'intensity': 'Sedang (60-75% HRmax)',
        'calories': '250-450 kkal',
        'aboutTitle': 'Tentang Renang Aerobik',
        'aboutDesc':
            'Berenang melatih kekuatan otot punggung, dada, bahu, dan tungkai sekaligus dengan resistensi alami air tanpa stres benturan gravitasi.',
        'benefits': [
          'Latihan aerobik seluruh tubuh dengan keterlibatan otot maksimal',
          'Meningkatkan kapasitas paru-paru dan ritme pernapasan',
          'Membakar kalori tinggi sekaligus mengencangkan otot tubuh',
        ],
        'specs': {
          'duration': '30-45 menit',
          'frequency': '2-3 kali/minggu',
          'intensity': 'Sedang (60-75% HRmax)',
          'calories': '250-450 kkal',
        },
        'tipsTitle': 'Tips Renang Aerobik',
        'tips': [
          habitTip,
          'Awali dengan pemanasan peregangan bahu dan kaki di tepi kolam.',
          'Kombinasikan gaya dada dan gaya bebas untuk variasi kelompok otot.',
          'Minum air setelah sesi renang untuk mencegah dehidrasi tersembunyi.',
        ],
        'refLink': 'https://doi.org/10.25182/jgp.2016.11.3.%25p',
      },
      {
        'id': 'normal_bodyweight',
        'title': 'Latihan Kekuatan Otot (Gym / Bodyweight)',
        'name': 'Latihan Kekuatan (Strength)',
        'targetText': '25-45 menit',
        'heroImg': 'assets/progress/clean/hero_bodyweight.png',
        'thumbImg': 'assets/progress/clean/thumb_bodyweight.png',
        'thumb': 'assets/progress/clean/rec_thumb_bodyweight.png',
        'icon': 'assets/progress/clean/rec_icon_bodyweight.png',
        'desc': 'Menjaga massa otot bebas lemak (Fat-Free Mass) dan kepadatan tulang agar metabolisme basal tetap prima.',
        'duration': '25-45 menit',
        'frequency': '2-3x/minggu',
        'intensity': 'Sedang-Tinggi (65-80% HRmax)',
        'calories': '180-320 kkal',
        'aboutTitle': 'Tentang Latihan Kekuatan',
        'aboutDesc':
            'Sesuai panduan PAPDI dan Kemenkes, latihan resistensi 2 kali seminggu esensial untuk menjaga massa otot dan mencegah penurunan laju metabolisme basal.',
        'benefits': [
          'Mempertahankan dan mengencangkan massa otot rangka',
          'Mendukung kepadatan tulang dan postur tubuh',
          'Meningkatkan pembakaran energi jangka panjang (BMR)',
        ],
        'specs': {
          'duration': '25-45 menit',
          'frequency': '2-3 kali/minggu',
          'intensity': 'Sedang-Tinggi (65-80% HRmax)',
          'calories': '180-320 kkal',
        },
        'tipsTitle': 'Tips Latihan Kekuatan',
        'tips': [
          habitTip,
          'Fokus pada gerakan kompon: squat, push-up, lunge, dan plank.',
          'Beri jeda istirahat 48 jam untuk kelompok otot yang sama.',
          'Lakukan pendinginan statis setelah sesi latihan.',
        ],
        'refLink': 'https://doi.org/10.21831/jk.v8i1.31208',
      },
      {
        'id': 'normal_hiit',
        'title': 'Senam Aerobik Dinamis & HIIT',
        'name': 'Senam Aerobik & HIIT',
        'targetText': '20-30 menit',
        'heroImg': 'assets/progress/clean/hero_hiit.png',
        'thumbImg': 'assets/progress/clean/thumb_hiit.png',
        'thumb': 'assets/progress/clean/rec_thumb_hiit.png',
        'icon': 'assets/progress/clean/rec_icon_hiit.png',
        'desc': 'Interval intensitas sedang-tinggi untuk menantang kapasitas jantung dan efisiensi metabolik.',
        'duration': '20-30 menit',
        'frequency': '2x/minggu',
        'intensity': 'Tinggi (75-85% HRmax)',
        'calories': '220-400 kkal',
        'aboutTitle': 'Tentang Senam Dinamis & HIIT',
        'aboutDesc':
            'Kombinasi gerak berirama dan interval intensif untuk menstimulasi fungsi mitokondria otot dan ambang batas laktat.',
        'benefits': [
          'Meningkatkan pembakaran kalori pasca latihan (EPOC)',
          'Melatih koordinasi, kelincahan, dan kapasitas anaerobik',
          'Variasi dinamis yang menyenangkan dan efisien waktu',
        ],
        'specs': {
          'duration': '20-30 menit',
          'frequency': '2 kali/minggu',
          'intensity': 'Tinggi (75-85% HRmax)',
          'calories': '220-400 kkal',
        },
        'tipsTitle': 'Tips Senam Dinamis & HIIT',
        'tips': [
          habitTip,
          'Wajib pemanasan menyeluruh 5-10 menit sebelum masuk interval.',
          'Lakukan gerakan dengan kontrol teknik sebelum meningkatkan kecepatan.',
          'Cukupi kebutuhan cairan sebelum, saat, dan sesudah latihan.',
        ],
        'refLink': 'https://doi.org/10.15294/jpes.v8i2.31208',
      },
    ];
  }

  // =========================================================================
  // 2. KATEGORI OVERWEIGHT (IMT 23.0 - 24.9 kg/m²)
  // Fokus: Defisit Energi Bertahap, Kardio Ramah Sendi & Aktivitas NEAT
  // Olahraga: Jalan Cepat, Senam Low-Impact, Bersepeda, Beban Terkontrol, Walk-Jog
  // =========================================================================
  List<Map<String, dynamic>> _getOverweightActivities(SkriningData? data) {
    final habitTip = _getHabitTip(data);
    return [
      {
        'id': 'overweight_brisk_walk',
        'title': 'Jalan Cepat (Brisk Walking 5 km/jam)',
        'name': 'Jalan Cepat (Brisk Walking)',
        'targetText': '35-50 menit',
        'heroImg': 'assets/progress/clean/hero_jogging.png',
        'thumbImg': 'assets/progress/clean/thumb_jogging.png',
        'thumb': 'assets/progress/clean/rec_thumb_jogging.png',
        'icon': 'assets/progress/clean/rec_icon_jogging.png',
        'desc': 'Olahraga kardio low-impact utama membakar timbunan kalori tanpa menimbulkan beban berlebih pada sendi lutut.',
        'duration': '35-50 menit',
        'frequency': '5x/minggu',
        'intensity': 'Sedang (55-65% HRmax)',
        'calories': '200-350 kkal',
        'safetyNotes':
            'Gunakan sepatu yang nyaman dengan sol peredam impak untuk menjaga persendian lutut dan tumit.',
        'aboutTitle': 'Tentang Jalan Cepat untuk Overweight',
        'aboutDesc':
            'Berdasarkan pedoman klinis PAPDI dan Kemenkes, jalan cepat dengan kecepatan konstan merupakan modalitas utama untuk memicu pembakaran lemak viseral secara aman dan berkelanjutan.',
        'benefits': [
          'Membakar kalori dan timbunan lemak tubuh dalam zona pembakaran lemak (fat-burn zone)',
          'Sangat ramah terhadap sendi lutut dan pinggul dibandingkan lari sprint',
          'Meningkatkan sensitivitas insulin dan menurunkan tekanan darah',
          'Mendukung target 150-200 menit aktivitas aerobik per minggu',
        ],
        'specs': {
          'duration': '35-50 menit',
          'frequency': '5 kali/minggu',
          'intensity': 'Sedang (55-65% HRmax)',
          'calories': '200-350 kkal',
        },
        'tipsTitle': 'Tips Jalan Cepat',
        'tips': [
          habitTip,
          'Awali dengan jalan santai 5 menit sebagai pemanasan bertahap.',
          'Pertahankan langkah tegap dengan ayunan lengan ritmis di samping tubuh.',
          'Pilih lintasan datar yang aman seperti taman atau treadmill.',
        ],
        'refLink': 'https://doi.org/10.25182/jgp.2016.11.3.%25p',
      },
      {
        'id': 'overweight_aerobic_dance',
        'title': 'Senam Aerobik Low-Impact',
        'name': 'Senam Aerobik Low-Impact',
        'targetText': '30-45 menit',
        'heroImg': 'assets/progress/clean/hero_hiit.png',
        'thumbImg': 'assets/progress/clean/thumb_hiit.png',
        'thumb': 'assets/progress/clean/rec_thumb_hiit.png',
        'icon': 'assets/progress/clean/rec_icon_hiit.png',
        'desc': 'Gerakan senam ritmis tanpa lompatan tinggi untuk memacu pengeluaran energi dengan aman.',
        'duration': '30-45 menit',
        'frequency': '3-4x/minggu',
        'intensity': 'Sedang (60-70% HRmax)',
        'calories': '220-380 kkal',
        'safetyNotes':
            'Hindari gerakan melompat tinggi. Pastikan satu kaki selalu menempel di lantai (low-impact).',
        'aboutTitle': 'Tentang Senam Aerobik Low-Impact',
        'aboutDesc':
            'Senam ritmis dengan tempo musik sedang menggerakkan seluruh kelompok otot besar untuk membakar kalori tanpa risiko cedera tendon akibat benturan keras.',
        'benefits': [
          'Pengeluaran kalori signifikan tanpa hentakan pada sendi',
          'Melatih koordinasi gerak tubuh dan elastisitas otot',
          'Meningkatkan suasana hati dan motivasi berolahraga rutin',
        ],
        'specs': {
          'duration': '30-45 menit',
          'frequency': '3-4 kali/minggu',
          'intensity': 'Sedang (60-70% HRmax)',
          'calories': '220-380 kkal',
        },
        'tipsTitle': 'Tips Senam Aerobik',
        'tips': [
          habitTip,
          'Ikuti instruksi gerakan dengan ritme yang nyaman.',
          'Gunakan matras atau lantai kayu/karet yang tidak licin.',
          'Minum sedikit air di sela sesi untuk menjaga hidrasi.',
        ],
        'refLink': 'https://doi.org/10.21831/medikora.v14i2.7937',
      },
      {
        'id': 'overweight_cycling',
        'title': 'Bersepeda Teratur (Outdoor / Statis)',
        'name': 'Bersepeda Teratur',
        'targetText': '30-45 menit',
        'heroImg': 'assets/progress/clean/hero_cycling.png',
        'thumbImg': 'assets/progress/clean/thumb_cycling.png',
        'thumb': 'assets/progress/clean/rec_thumb_cycling.png',
        'icon': 'assets/progress/clean/rec_icon_cycling.png',
        'desc': 'Berat badan bertumpu pada sadel sehingga mengurangi tekanan kompresi pada persendian lutut hingga 60%.',
        'duration': '30-45 menit',
        'frequency': '4-5x/minggu',
        'intensity': 'Sedang (55-70% HRmax)',
        'calories': '220-400 kkal',
        'safetyNotes':
            'Pastikan posisi sadel diatur agar lutut hanya menekuk sedikit (25-30 derajat) di titik pedal terbawah.',
        'aboutTitle': 'Tentang Bersepeda untuk Overweight',
        'aboutDesc':
            'Bersepeda sangat dianjurkan oleh konsensus PAPDI karena memindahkan beban berat badan dari persendian lutut ke sadel sepeda.',
        'benefits': [
          'Melindungi sendi lutut dari beban kompresi saat berolahraga',
          'Memperkuat otot paha, betis, dan gluteus',
          'Mendukung program defisit energi berkelanjutan',
        ],
        'specs': {
          'duration': '30-45 menit',
          'frequency': '4-5 kali/minggu',
          'intensity': 'Sedang (55-70% HRmax)',
          'calories': '220-400 kkal',
        },
        'tipsTitle': 'Tips Bersepeda',
        'tips': [
          habitTip,
          'Mulai kayuhan dengan resistensi ringan selama 5 menit pertama.',
          'Pertahankan irama kayuhan konstan sekitar 60-80 RPM.',
          'Jaga posisi punggung tetap tegak dan rileks.',
        ],
        'refLink': 'https://doi.org/10.21831/medikora.v14i2.7937',
      },
      {
        'id': 'overweight_bodyweight',
        'title': 'Latihan Beban Tubuh Terkontrol',
        'name': 'Latihan Beban Terkontrol',
        'targetText': '20-35 menit',
        'heroImg': 'assets/progress/clean/hero_bodyweight.png',
        'thumbImg': 'assets/progress/clean/thumb_bodyweight.png',
        'thumb': 'assets/progress/clean/rec_thumb_bodyweight.png',
        'icon': 'assets/progress/clean/rec_icon_bodyweight.png',
        'desc': 'Mempertahankan massa otot bebas lemak saat proses penurunan berat badan agar laju metabolisme BMR tidak menurun.',
        'duration': '20-35 menit',
        'frequency': '2-3x/minggu',
        'intensity': 'Sedang (55-65% HRmax)',
        'calories': '140-260 kkal',
        'aboutTitle': 'Tentang Latihan Beban Terkontrol',
        'aboutDesc':
            'Latihan penguatan otot penting agar berat badan yang turun berasal dari massa lemak, bukan dari penyusutan massa otot.',
        'benefits': [
          'Mencegah penurunan laju metabolisme basal selama defisit kalori',
          'Meningkatkan sensitivitas reseptor insulin terhadap glukosa',
          'Memperkuat stabilitas sendi pinggul dan lutut',
        ],
        'specs': {
          'duration': '20-35 menit',
          'frequency': '2-3 kali/minggu',
          'intensity': 'Sedang (55-65% HRmax)',
          'calories': '140-260 kkal',
        },
        'tipsTitle': 'Tips Latihan Beban',
        'tips': [
          habitTip,
          'Pilih variasi gerakan aman: wall push-up, chair squat, dan glute bridge.',
          'Lakukan 2-3 set dengan 10-12 repetisi terkontrol pada tiap gerakan.',
          'Jangan menahan napas saat melakukan kontraksi otot.',
        ],
        'refLink': 'https://doi.org/10.21831/jk.v8i1.31208',
      },
      {
        'id': 'overweight_walk_jog',
        'title': 'Jogging Bertahap (Walk-Jog Interval)',
        'name': 'Jogging Bertahap',
        'targetText': '25-40 menit',
        'heroImg': 'assets/progress/clean/hero_jogging.png',
        'thumbImg': 'assets/progress/clean/thumb_jogging.png',
        'thumb': 'assets/progress/clean/rec_thumb_jogging.png',
        'icon': 'assets/progress/clean/rec_icon_jogging.png',
        'desc': 'Kombinasi 3 menit jalan cepat disusul 1 menit lari santai untuk adaptasi kapasitas kardio.',
        'duration': '25-40 menit',
        'frequency': '3x/minggu',
        'intensity': 'Sedang (60-70% HRmax)',
        'calories': '200-360 kkal',
        'safetyNotes':
            'Bila timbul rasa sakit atau pegal tajam pada sendi lutut, segera beralih penuh ke jalan santai.',
        'aboutTitle': 'Tentang Walk-Jog Interval',
        'aboutDesc':
            'Metode interval jalan-jogging memungkinkan tubuh meningkatkan kapasitas aerobik tanpa kelelahan mendadak atau cedera sendi.',
        'benefits': [
          'Meningkatkan efisiensi pembakaran kalori per menit',
          'Membiasakan sistem kardiometabolik beradaptasi secara progresif',
          'Membantu target pengurangan lemak visceral perut',
        ],
        'specs': {
          'duration': '25-40 menit',
          'frequency': '3 kali/minggu',
          'intensity': 'Sedang (60-70% HRmax)',
          'calories': '200-360 kkal',
        },
        'tipsTitle': 'Tips Walk-Jog Interval',
        'tips': [
          habitTip,
          'Gunakan rasio 3 menit jalan cepat dan 1 menit jog santai.',
          'Tingkatkan porsi jogging secara perlahan setelah 2-3 minggu latihan rutin.',
          'Lakukan peregangan betis dan paha belakang setelah selesai.',
        ],
        'refLink': 'https://doi.org/10.25182/jgp.2016.11.3.%25p',
      },
    ];
  }

  // =========================================================================
  // 3. KATEGORI OBESITAS I (IMT 25.0 - 29.9 kg/m²)
  // Fokus: Proteksi Sendi Wajib (Low-Impact), Akumulasi 200-250 mnt/minggu
  // Olahraga: Berenang/Aquarobics, Sepeda Statis, Jalan Kaki Low-Impact, Penguatan Penyangga
  // =========================================================================
  List<Map<String, dynamic>> _getObesitas1Activities(SkriningData? data) {
    final habitTip = _getHabitTip(data);
    return [
      {
        'id': 'obesitas1_aquarobics',
        'title': 'Berenang / Senam Air (Aquarobics)',
        'name': 'Berenang / Senam Air',
        'targetText': '30-45 menit',
        'heroImg': 'assets/progress/clean/hero_swimming.png',
        'thumbImg': 'assets/progress/clean/thumb_swimming.png',
        'thumb': 'assets/progress/clean/rec_thumb_swimming.png',
        'icon': 'assets/progress/clean/rec_icon_swimming.png',
        'desc': 'Daya apung air menopang hingga 90% berat tubuh sehingga persendian lutut 100% bebas dari benturan kompresi.',
        'duration': '30-45 menit',
        'frequency': '3-4x/minggu',
        'intensity': 'Sedang Ramah Sendi (50-65% HRmax)',
        'calories': '200-380 kkal',
        'safetyNotes':
            'Pilihan utama klinis PAPDI & Kemenkes untuk obesitas karena bebas risiko trauma sendi lutut dan pergelangan kaki.',
        'aboutTitle': 'Tentang Senam Air & Renang untuk Obesitas',
        'aboutDesc':
            'Pada Obesitas I, tekanan pada sendi lutut saat berjalan meningkat 4 kali lipat. Berolahraga di dalam air mengeliminasi tekanan gravitasi tersebut sehingga kalori terbakar maksimal tanpa rasa nyeri.',
        'benefits': [
          'Melindungi sendi lutut dan tulang rawan dari risiko osteoartritis',
          'Resistensi air mengencangkan otot tubuh secara merata',
          'Mendukung penurunan 5-10% berat badan dalam program komprehensif',
        ],
        'specs': {
          'duration': '30-45 menit',
          'frequency': '3-4 kali/minggu',
          'intensity': 'Sedang Ramah Sendi (50-65% HRmax)',
          'calories': '200-380 kkal',
        },
        'tipsTitle': 'Tips Senam Air',
        'tips': [
          habitTip,
          'Lakukan gerakan berjalan atau mengayuh tangan di kolam setinggi dada.',
          'Gunakan kolam dangkal bila belum mahir berenang.',
          'Pastikan cukup minum air sebelum dan sesudah sesi latihan.',
        ],
        'refLink': 'https://keslan.kemkes.go.id/unduhan/KMK%20No.%20HK.01.07-MENKES-509-2025.pdf',
      },
      {
        'id': 'obesitas1_stationary_bike',
        'title': 'Bersepeda Statis (Stationary Bike)',
        'name': 'Bersepeda Statis',
        'targetText': '30-45 menit',
        'heroImg': 'assets/progress/clean/hero_cycling.png',
        'thumbImg': 'assets/progress/clean/thumb_cycling.png',
        'thumb': 'assets/progress/clean/rec_thumb_cycling.png',
        'icon': 'assets/progress/clean/rec_icon_cycling.png',
        'desc': 'Beban tubuh dialihkan ke sadel sepeda, memberikan latihan kardiorespirasi unggulan tanpa getaran benturan.',
        'duration': '30-45 menit',
        'frequency': '4-5x/minggu',
        'intensity': 'Sedang Terkontrol (50-60% HRmax)',
        'calories': '180-320 kkal',
        'safetyNotes':
            'Atur resistensi kayuhan ringan-sedang agar beban tidak menumpuk di tempurung lutut.',
        'aboutTitle': 'Tentang Bersepeda Statis',
        'aboutDesc':
            'Sepeda statis memberikan kontrol denyut jantung dan kecepatan yang sangat stabil, bebas dari risiko terjatuh di jalan raya dan minim kompresi sendi.',
        'benefits': [
          'Beban gravitasi pada persendian lutut sangat minimal',
          'Efektif melatih sirkulasi darah vena dan otot tungkai',
          'Dapat dilakukan di dalam ruangan dengan suhu sejuk',
        ],
        'specs': {
          'duration': '30-45 menit',
          'frequency': '4-5 kali/minggu',
          'intensity': 'Sedang Terkontrol (50-60% HRmax)',
          'calories': '180-320 kkal',
        },
        'tipsTitle': 'Tips Bersepeda Statis',
        'tips': [
          habitTip,
          'Sesuaikan tinggi sadel agar saat pedal di bawah, lutut hanya sedikit tertekuk.',
          'Kayuh dengan irama konstan tanpa tergesa-gesa.',
          'Jaga posisi punggung tetap tegak dan rileks.',
        ],
        'refLink': 'https://papdi.or.id/pdfs/1422/Soft%20copy%20konsensus%20obesitas.pdf',
      },
      {
        'id': 'obesitas1_low_impact_walk',
        'title': 'Jalan Kaki Rendah Beban (Low-Impact Walk)',
        'name': 'Jalan Kaki Low-Impact',
        'targetText': '30-40 menit',
        'heroImg': 'assets/progress/clean/hero_jogging.png',
        'thumbImg': 'assets/progress/clean/thumb_jogging.png',
        'thumb': 'assets/progress/clean/rec_thumb_jogging.png',
        'icon': 'assets/progress/clean/rec_icon_jogging.png',
        'desc': 'Aktivitas aerobik ramah sendi untuk mengakumulasikan target 200-250 menit/minggu secara konsisten.',
        'duration': '30-40 menit',
        'frequency': '5x/minggu',
        'intensity': 'Sedang (50-60% HRmax)',
        'calories': '160-300 kkal',
        'safetyNotes':
            'Hindari lari cepat di atas aspal keras. Wajib gunakan sepatu olahraga dengan bantalan empuk.',
        'aboutTitle': 'Tentang Jalan Kaki Low-Impact',
        'aboutDesc':
            'Jalan santai ritmis di lintasan datar membantu membakar lemak dan menurunkan tekanan darah tanpa menimbulkan peradangan pada sendi pergelangan kaki.',
        'benefits': [
          'Membantu akumulasi 200-250 menit aktivitas aerobik per minggu',
          'Melindungi sendi lutut dari cedera osteoarthritis',
          'Meningkatkan toleransi fisik dan kebugaran jantung-paru',
        ],
        'specs': {
          'duration': '30-40 menit',
          'frequency': '5 kali/minggu',
          'intensity': 'Sedang (50-60% HRmax)',
          'calories': '160-300 kkal',
        },
        'tipsTitle': 'Tips Jalan Rendah Beban',
        'tips': [
          habitTip,
          'Pemanasan 5-10 menit dengan putaran engkel dan lutut perlahan.',
          'Bisa dibagi menjadi 2 sesi (20 menit pagi dan 20 menit sore) bila perlu.',
          'Pilih lintasan datar di rumput, trek karet, atau treadmill datar.',
        ],
        'refLink': 'https://keslan.kemkes.go.id/unduhan/KMK%20No.%20HK.01.07-MENKES-509-2025.pdf',
      },
      {
        'id': 'obesitas1_joint_strength',
        'title': 'Latihan Kekuatan Penyangga Sendi',
        'name': 'Latihan Penguatan Sendi',
        'targetText': '20-30 menit',
        'heroImg': 'assets/progress/clean/hero_bodyweight.png',
        'thumbImg': 'assets/progress/clean/thumb_bodyweight.png',
        'thumb': 'assets/progress/clean/rec_thumb_bodyweight.png',
        'icon': 'assets/progress/clean/rec_icon_bodyweight.png',
        'desc': 'Memperkuat otot kuadrisep dan pinggul penopang sendi dengan gerakan stabil tanpa loncatan.',
        'duration': '20-30 menit',
        'frequency': '2-3x/minggu',
        'intensity': 'Ringan-Sedang (50% HRmax)',
        'calories': '120-200 kkal',
        'safetyNotes':
            'Dilarang melakukan gerakan melompat (jumping jack/burpee) atau squat terlalu dalam untuk mencegah cedera meniskus.',
        'aboutTitle': 'Tentang Penguatan Penyangga Sendi',
        'aboutDesc':
            'Latihan resistensi terkontrol memperkuat otot paha depan (kuadrisep) yang berfungsi sebagai penyerap getaran alami persendian lutut.',
        'benefits': [
          'Memperkuat otot penopang lutut dan tulang belakang',
          'Mencegah penyusutan massa otot selama menjalani Terapi Nutrisi Medis',
          'Meningkatkan kestabilan saat berjalan dan menaiki tangga',
        ],
        'specs': {
          'duration': '20-30 menit',
          'frequency': '2-3 kali/minggu',
          'intensity': 'Ringan-Sedang (50% HRmax)',
          'calories': '120-200 kkal',
        },
        'tipsTitle': 'Tips Penguatan Sendi',
        'tips': [
          habitTip,
          'Gunakan bantuan kursi untuk latihan bangkit-duduk (chair squat) terkontrol.',
          'Lakukan wall push-up dengan posisi tangan selebar bahu.',
          'Gunakan tempo lambat 2-3 detik naik dan 2-3 detik turun.',
        ],
        'refLink': 'https://doi.org/10.21831/jk.v8i1.31208',
      },
    ];
  }

  // =========================================================================
  // 4. KATEGORI OBESITAS II (IMT 30.0 - 34.9 kg/m²)
  // Fokus: Non-Weight Bearing, Fraksionasi Durasi, Proteksi Sendi Maksimal
  // Olahraga: Renang & Terapi Air, Sepeda Reclined, Latihan Kursi, Jalan Fraksionasi
  // =========================================================================
  List<Map<String, dynamic>> _getObesitas2Activities(SkriningData? data) {
    final habitTip = _getHabitTip(data);
    return [
      {
        'id': 'obesitas2_water_therapy',
        'title': 'Renang Santai & Terapi Air (Water Aerobics)',
        'name': 'Renang & Terapi Air',
        'targetText': '30-45 menit',
        'heroImg': 'assets/progress/clean/hero_swimming.png',
        'thumbImg': 'assets/progress/clean/thumb_swimming.png',
        'thumb': 'assets/progress/clean/rec_thumb_swimming.png',
        'icon': 'assets/progress/clean/rec_icon_swimming.png',
        'desc': 'Aktivitas kardio non-weight bearing paling aman; air menopang 90% berat badan tanpa membebani lutut dan pinggul.',
        'duration': '30-45 menit',
        'frequency': '3-4x/minggu',
        'intensity': 'Ringan-Sedang (45-60% HRmax)',
        'calories': '160-300 kkal',
        'safetyNotes':
            'Gunakan kolam dangkal bila belum mahir berenang. Lakukan gerakan ayunan tangan dan langkah santai di dalam air.',
        'aboutTitle': 'Tentang Terapi Air untuk Obesitas II',
        'aboutDesc':
            'Pada Obesitas II, olahraga di darat sering menimbulkan nyeri lutut. Terapi air memungkinkan pasien bergerak bebas dengan daya apung air, memperlancar sirkulasi darah tanpa sedikit pun tekanan pada tulang rawan sendi.',
        'benefits': [
          'Bebas 100% dari benturan gravitasi pada sendi lutut dan tulang belakang',
          'Membantu sirkulasi vena dan mengurangi pembengkakan kaki',
          'Membakar kalori secara nyaman tanpa risiko jatuh atau kepanasan',
        ],
        'specs': {
          'duration': '30-45 menit',
          'frequency': '3-4 kali/minggu',
          'intensity': 'Ringan-Sedang (45-60% HRmax)',
          'calories': '160-300 kkal',
        },
        'tipsTitle': 'Tips Terapi Air',
        'tips': [
          habitTip,
          'Berjalanlah maju-mundur di kolam air setinggi dada selama 15-20 menit.',
          'Gunakan papan pelampung untuk latihan kayuhan kaki santai.',
          'Selalu keringkan tubuh dan ganti pakaian setelah sesi selesai.',
        ],
        'refLink': 'https://keslan.kemkes.go.id/unduhan/KMK%20No.%20HK.01.07-MENKES-509-2025.pdf',
      },
      {
        'id': 'obesitas2_recumbent_bike',
        'title': 'Sepeda Statis Reclined (Senderan Punggung)',
        'name': 'Sepeda Statis Reclined',
        'targetText': '25-40 menit',
        'heroImg': 'assets/progress/clean/hero_cycling.png',
        'thumbImg': 'assets/progress/clean/thumb_cycling.png',
        'thumb': 'assets/progress/clean/rec_thumb_cycling.png',
        'icon': 'assets/progress/clean/rec_icon_cycling.png',
        'desc': 'Sandaran punggung ergonomis menopang tubuh dengan posisi kaki ke depan, meminimalkan kompresi lutut.',
        'duration': '25-40 menit',
        'frequency': '4-5x/minggu',
        'intensity': 'Ringan-Sedang (45-55% HRmax)',
        'calories': '140-260 kkal',
        'safetyNotes':
            'Jangan berdiri saat mengayuh. Selalu duduk stabil bersandar dan jaga denyut nadi dalam batas nyaman (talk test).',
        'aboutTitle': 'Tentang Sepeda Statis Reclined',
        'aboutDesc':
            'Sepeda statis bersandar (recumbent) memberikan penyangga penuh pada tulang belakang lumbal dan panggul, menjadikannya pilihan kardio darat paling aman bagi Obesitas Tingkat II.',
        'benefits': [
          'Sangat aman bagi penderita dengan gejala nyeri punggung bawah atau lutut',
          'Membantu sirkulasi darah tanpa memicu pembengkakan kaki',
          'Mendukung program penurunan berat badan di bawah pengawasan medis',
        ],
        'specs': {
          'duration': '25-40 menit',
          'frequency': '4-5 kali/minggu',
          'intensity': 'Ringan-Sedang (45-55% HRmax)',
          'calories': '140-260 kkal',
        },
        'tipsTitle': 'Tips Sepeda Statis Reclined',
        'tips': [
          habitTip,
          'Mulai dengan kayuhan santai 5 menit pertama.',
          'Bila lelah, kurangi kecepatan kayuhan namun jangan berhenti mendadak.',
          'Siapkan air minum di dekat sepeda untuk hidrasi teratur.',
        ],
        'refLink': 'https://papdi.or.id/pdfs/1422/Soft%20copy%20konsensus%20obesitas.pdf',
      },
      {
        'id': 'obesitas2_chair_workout',
        'title': 'Latihan Penguatan di Kursi (Chair Workout)',
        'name': 'Latihan Penguatan di Kursi',
        'targetText': '15-25 menit',
        'heroImg': 'assets/progress/clean/hero_bodyweight.png',
        'thumbImg': 'assets/progress/clean/thumb_bodyweight.png',
        'thumb': 'assets/progress/clean/rec_thumb_bodyweight.png',
        'icon': 'assets/progress/clean/rec_icon_bodyweight.png',
        'desc': 'Latihan penguatan otot paha, betis, dan lengan dalam posisi duduk stabil di atas kursi.',
        'duration': '15-25 menit',
        'frequency': '3x/minggu',
        'intensity': 'Ringan (40-50% HRmax)',
        'calories': '80-150 kkal',
        'safetyNotes':
            'Gunakan kursi yang stabil dan tidak beroda. Jangan melakukan gerakan sentakan mendadak.',
        'aboutTitle': 'Tentang Latihan Penguatan Kursi',
        'aboutDesc':
            'Gerakan seated leg extension, seated calf raise, dan seated arm reach melatih kelompok otot utama tanpa menanggung beban gravitasi penuh tubuh saat berdiri.',
        'benefits': [
          'Memperkuat otot paha tanpa membebani persendian',
          'Meningkatkan kestabilan saat bangkit dari posisi duduk',
          'Aman dari risiko kehilangan keseimbangan',
        ],
        'specs': {
          'duration': '15-25 menit',
          'frequency': '3 kali/minggu',
          'intensity': 'Ringan (40-50% HRmax)',
          'calories': '80-150 kkal',
        },
        'tipsTitle': 'Tips Latihan Kursi',
        'tips': [
          habitTip,
          'Duduk tegak di kursi dengan punggung menempel pada sandaran.',
          'Lakukan gerakan mengangkat ujung kaki (leg extension) secara bergantian.',
          'Tahan 2-3 detik di atas lalu turunkan perlahan.',
        ],
        'refLink': 'https://doi.org/10.21831/jk.v8i1.31208',
      },
      {
        'id': 'obesitas2_fractional_walk',
        'title': 'Jalan Santai Fraksionasi (2 Sesi x 15 Menit)',
        'name': 'Jalan Santai Fraksionasi',
        'targetText': '2 sesi x 15 menit',
        'heroImg': 'assets/progress/clean/hero_jogging.png',
        'thumbImg': 'assets/progress/clean/thumb_jogging.png',
        'thumb': 'assets/progress/clean/rec_thumb_jogging.png',
        'icon': 'assets/progress/clean/rec_icon_jogging.png',
        'desc': 'Membagi jalan santai menjadi 2 sesi 15 menit (pagi dan sore) untuk menjaga kenyamanan persendian.',
        'duration': '2 sesi x 15 menit',
        'frequency': '4-5x/minggu',
        'intensity': 'Ringan (40-50% HRmax)',
        'calories': '120-200 kkal',
        'safetyNotes':
            'Hindari jalan menanjak atau menurun terjal. Hentikan jika timbul nyeri lutut, nyeri dada, atau napas tersengal.',
        'aboutTitle': 'Tentang Jalan Fraksionasi',
        'aboutDesc':
            'Pendekatan fraksionasi (membagi durasi latihan menjadi 2 kali 15 menit sehari) terbukti sama efektifnya membakar kalori harian namun jauh lebih ramah terhadap toleransi sendi.',
        'benefits': [
          'Mencegah akumulasi kelelahan pada otot dan sendi tungkai',
          'Menjaga tubuh tetap aktif dan memecah waktu duduk lama (sedentary time)',
          'Meningkatkan kapasitas sirkulasi pernapasan secara aman',
        ],
        'specs': {
          'duration': '2 sesi x 15 menit',
          'frequency': '4-5 kali/minggu',
          'intensity': 'Ringan (40-50% HRmax)',
          'calories': '120-200 kkal',
        },
        'tipsTitle': 'Tips Jalan Fraksionasi',
        'tips': [
          habitTip,
          'Lakukan sesi 1: 15 menit di pagi hari sebelum beraktivitas.',
          'Lakukan sesi 2: 15 menit di sore hari menjelang matahari terbenam.',
          'Gunakan sepatu yang empuk dan fleksibel.',
        ],
        'refLink': 'https://papdi.or.id/pdfs/1422/Soft%20copy%20konsensus%20obesitas.pdf',
      },
    ];
  }

  // =========================================================================
  // 5. KATEGORI OBESITAS III (Sangat Ringan, Fungsional, Perlindungan Total & Medis)
  // =========================================================================
  List<Map<String, dynamic>> _getObesitas3Activities(SkriningData? data) {
    final habitTip = _getHabitTip(data);

    return [
      {
        'id': 'obesitas3_hydrotherapy',
        'title': 'Terapi Gerak Air Terawasi (Hydrotherapy)',
        'name': 'Terapi Gerak Air (Hydrotherapy)',
        'targetText': '15-20 menit',
        'heroImg': 'assets/progress/clean/hero_swimming.png',
        'thumbImg': 'assets/progress/clean/thumb_swimming.png',
        'thumb': 'assets/progress/clean/rec_thumb_swimming.png',
        'icon': 'assets/progress/clean/rec_icon_swimming.png',
        'desc':
            'Gerak fungsional dan berjalan di air kolam setinggi dada dengan daya apung yang meniadakan 90% beban gravitasi sendi.',
        'duration': '15-20 menit',
        'frequency': '2-3x/minggu',
        'intensity': 'Sangat Ringan-Ringan (30-45% HRmax)',
        'calories': '80-140 kkal',
        'safetyNotes':
            'Wajib didampingi dan pastikan suhu air nyaman (tidak terlalu dingin). Hentikan jika lemas, sesak, atau dada berdebar.',
        'aboutTitle': 'Tentang Terapi Gerak Air Terawasi',
        'aboutDesc':
            'Pada Obesitas Kelas III (Morbid), daya apung air (buoyancy) menghilangkan hingga 90% beban gravitasi pada sendi dan tulang belakang, menjadikannya modalitas paling aman untuk mengaktifkan metabolisme tanpa trauma muskuloskeletal.',
        'benefits': [
          'Menghilangkan tekanan kompresi pada sendi lutut, panggul, dan tulang belakang',
          'Membantu pembakaran kalori metabolik tanpa risiko cedera benturan mekanis',
          'Meningkatkan kelancaran aliran darah balik vena dan mengurangi pembengkakan tungkai',
        ],
        'specs': {
          'duration': '15-20 menit',
          'frequency': '2-3 kali/minggu',
          'intensity': 'Sangat Ringan-Ringan (30-45% HRmax)',
          'calories': '80-140 kkal',
        },
        'tipsTitle': 'Tips Terapi Air',
        'tips': [
          habitTip,
          'Cukup berjalan santai maju, mundur, dan menyamping di kolam setinggi dada.',
          'Gunakan pegangan pinggir kolam jika keseimbangan masih terasa goyah.',
          'Awali dengan durasi 10 menit dan tingkatkan perlahan sesuai daya tahan tubuh.',
        ],
        'refLink':
            'https://keslan.kemkes.go.id/unduhan/KMK%20No.%20HK.01.07-MENKES-509-2025.pdf',
      },
      {
        'id': 'obesitas3_recumbent_bike',
        'title': 'Sepeda Statis Recumbent (Kayuhan Sangat Santai)',
        'name': 'Sepeda Statis Recumbent',
        'targetText': '10-15 menit',
        'heroImg': 'assets/progress/clean/hero_cycling.png',
        'thumbImg': 'assets/progress/clean/thumb_cycling.png',
        'thumb': 'assets/progress/clean/rec_thumb_cycling.png',
        'icon': 'assets/progress/clean/rec_icon_cycling.png',
        'desc':
            'Posisi duduk bersandar menyangga punggung dan panggul secara optimal dengan kayuhan sangat ringan tanpa beban gir.',
        'duration': '10-15 menit',
        'frequency': '3-4x/minggu',
        'intensity': 'Sangat Ringan (30-45% HRmax)',
        'calories': '60-110 kkal',
        'safetyNotes':
            'Wajib konsultasi dokter sebelum memulai. Hentikan latihan jika sesak napas, pusing berputar, atau denyut nadi melonjak tinggi.',
        'aboutTitle': 'Tentang Sepeda Statis Recumbent',
        'aboutDesc':
            'Recumbent bike memiliki sandaran punggung yang kokoh dan posisi pedal di depan badan sehingga beban gravitasi pada tulang belakang dan lutut hampir nol, menjaga stabilitas sirkulasi kardiopulmonal.',
        'benefits': [
          'Memberikan proteksi total bagi persendian lutut dan tulang belakang',
          'Membantu aktivasi sirkulasi kardiopulmonal tanpa risiko pusing postural',
          'Mencegah risiko kelelahan ekstrem dan sesak napas',
        ],
        'specs': {
          'duration': '10-15 menit',
          'frequency': '3-4 kali/minggu',
          'intensity': 'Sangat Ringan (30-45% HRmax)',
          'calories': '60-110 kkal',
        },
        'tipsTitle': 'Tips Recumbent Bike',
        'tips': [
          habitTip,
          'Atur posisi kursi agar punggung tersangga penuh dengan nyaman.',
          'Kayuh dengan ritme sangat santai tanpa hambatan resistensi beban berat.',
          'Beri jeda istirahat 1-2 menit tiap mengayuh 5 menit bila diperlukan.',
        ],
        'refLink':
            'https://keslan.kemkes.go.id/unduhan/KMK%20No.%20HK.01.07-MENKES-509-2025.pdf',
      },
      {
        'id': 'obesitas3_seated_rom',
        'title': 'Gerak Sendi Duduk (Seated Range of Motion)',
        'name': 'Gerak Sendi Duduk (Seated ROM)',
        'targetText': '10-15 menit',
        'heroImg': 'assets/progress/clean/hero_bodyweight.png',
        'thumbImg': 'assets/progress/clean/thumb_bodyweight.png',
        'thumb': 'assets/progress/clean/rec_thumb_bodyweight.png',
        'icon': 'assets/progress/clean/rec_icon_bodyweight.png',
        'desc':
            'Rotasi pergelangan kaki, lutut santai, bahu, dan leher secara lembut dalam posisi duduk tegak di kursi bersandar kokoh.',
        'duration': '10-15 menit',
        'frequency': '3-5x/minggu',
        'intensity': 'Sangat Ringan (30-40% HRmax)',
        'calories': '40-70 kkal',
        'safetyNotes':
            'Gunakan kursi yang kokoh dengan sandaran punggung dan tanpa roda. Pastikan telapak kaki menapak rata di lantai.',
        'aboutTitle': 'Tentang Gerak Sendi Duduk',
        'aboutDesc':
            'Mempertahankan jangkauan gerak sendi (Range of Motion) tubuh bagian atas dan bawah agar terhindar dari kekakuan muskuloskeletal dan edema tungkai bawah.',
        'benefits': [
          'Memperlancar sirkulasi darah ke ujung jari kaki dan tangan',
          'Meringankan ketegangan otot pada leher, bahu, dan punggung',
          'Mencegah risiko pembengkakan cairan (edema) pada tungkai',
        ],
        'specs': {
          'duration': '10-15 menit',
          'frequency': '3-5 kali/minggu',
          'intensity': 'Sangat Ringan (30-40% HRmax)',
          'calories': '40-70 kkal',
        },
        'tipsTitle': 'Tips Gerak Sendi Duduk',
        'tips': [
          habitTip,
          'Lakukan gerakan ankle pump (dorong dan tarik pergelangan kaki) perlahan.',
          'Angkat kedua bahu perlahan ke arah telinga lalu turunkan rileks.',
          'Lakukan seluruh gerakan secara ritmis dan tenang tanpa hentakan.',
        ],
        'refLink': 'https://doi.org/10.21831/jk.v8i1.31208',
      },
      {
        'id': 'obesitas3_breathing',
        'title': 'Latihan Pernapasan Diafragma & Postur Terkendali',
        'name': 'Latihan Pernapasan Diafragma',
        'targetText': '10-15 menit',
        'heroImg': 'assets/progress/clean/hero_yoga.png',
        'thumbImg': 'assets/progress/clean/thumb_yoga.png',
        'thumb': 'assets/progress/clean/rec_thumb_yoga.png',
        'icon': 'assets/progress/clean/rec_icon_yoga.png',
        'desc':
            'Latihan pernapasan diafragma terfokus untuk melatih kapasitas paru-paru yang tertekan oleh lemak intra-abdomen.',
        'duration': '10-15 menit',
        'frequency': 'Setiap hari',
        'intensity': 'Sangat Ringan',
        'calories': '30-50 kkal',
        'safetyNotes':
            'Bernapaslah dengan ritme wajar. Bila merasa pusing atau hiperventilasi, rileks dan bernapaslah biasa.',
        'aboutTitle': 'Tentang Latihan Pernapasan Diafragma',
        'aboutDesc':
            'Pada obesitas tingkat lanjut, tumpukan lemak intra-abdomen membatasi gerak kubah diafragma. Latihan pernapasan dalam melatih kembali otot diafragma dan memaksimalkan saturasi oksigen.',
        'benefits': [
          'Memperluas kapasitas fungsional ventilasi paru-paru',
          'Meringankan kerja otot bantu napas di leher dan bahu',
          'Menstimulasi sistem saraf parasimpatis untuk meredakan kecemasan',
        ],
        'specs': {
          'duration': '10-15 menit',
          'frequency': 'Setiap hari',
          'intensity': 'Sangat Ringan',
          'calories': '30-50 kkal',
        },
        'tipsTitle': 'Tips Pernapasan Diafragma',
        'tips': [
          habitTip,
          'Duduk santai dengan satu tangan di dada dan satu tangan di perut atas.',
          'Tarik napas perlahan melalui hidung (3 detik) hingga perut mengembang.',
          'Hembuskan napas perlahan melalui bibir mengerucut (pursed-lip) 4-5 detik.',
        ],
        'refLink': 'https://doi.org/10.48144/jiks.v9i2.56',
      },
    ];
  }

  // =========================================================================
  // 6. KATEGORI UNDERWEIGHT (Peningkatan Massa Otot & Batasi Kardio Panjang)
  // =========================================================================
  List<Map<String, dynamic>> _getUnderweightActivities(SkriningData? data) {
    final habitTip = _getHabitTip(data);

    return [
      {
        'id': 'underweight_strength',
        'title': 'Latihan Beban & Angkat Beban (Strength Training)',
        'name': 'Latihan Beban & Kekuatan (Strength)',
        'targetText': '25-35 menit',
        'heroImg': 'assets/progress/clean/hero_bodyweight.png',
        'thumbImg': 'assets/progress/clean/thumb_bodyweight.png',
        'thumb': 'assets/progress/clean/rec_thumb_bodyweight.png',
        'icon': 'assets/progress/clean/rec_icon_bodyweight.png',
        'desc':
            'Fokus utama stimulasi hipertrofi serat otot melalui latihan beban bertahap untuk menambah berat badan sehat berupa massa otot padat.',
        'duration': '25-35 menit',
        'frequency': '3-4x/minggu',
        'intensity': 'Sedang (55-70% HRmax)',
        'calories': '130-220 kkal',
        'safetyNotes':
            'Pastikan asupan makanan kaya protein dan kalori kompleks dikonsumsi dalam 1-2 jam setelah sesi latihan beban.',
        'aboutTitle': 'Tentang Latihan Kekuatan untuk Underweight',
        'aboutDesc':
            'Pada kategori berat badan kurang, peningkatan berat badan harus diprioritaskan pada penambahan massa otot bebas lemak (lean muscle mass). Latihan resistensi memberikan sinyal biologis penting untuk sintesis protein otot.',
        'benefits': [
          'Memicu hipertrofi dan sintesis pembentukan massa otot baru',
          'Meningkatkan nafsu makan alami dan efisiensi metabolisme gizi',
          'Meningkatkan kepadatan mineral tulang dan kekuatan fungsional',
          'Membentuk postur tubuh yang lebih kokoh, berisi, dan tegap',
        ],
        'specs': {
          'duration': '25-35 menit',
          'frequency': '3-4 kali/minggu',
          'intensity': 'Sedang (55-70% HRmax)',
          'calories': '130-220 kkal',
        },
        'tipsTitle': 'Tips Latihan Beban',
        'tips': [
          habitTip,
          'Fokus pada rentang 8-12 repetisi dengan beban terkontrol (dumbbell ringan / resistance band).',
          'Gunakan gerakan majemuk: goblet squat, dumbbell bench press, dan seated row.',
          'Beri jeda istirahat 60-90 detik antar set agar tenaga pulih maksimal.',
        ],
        'refLink': 'https://doi.org/10.21831/jk.v8i1.31208',
      },
      {
        'id': 'underweight_calisthenics',
        'title': 'Kalistenik Kompon (Push-up, Inverted Row & Squat)',
        'name': 'Kalistenik Kompon (Bodyweight)',
        'targetText': '20-30 menit',
        'heroImg': 'assets/progress/clean/hero_bodyweight.png',
        'thumbImg': 'assets/progress/clean/thumb_bodyweight.png',
        'thumb': 'assets/progress/clean/rec_thumb_bodyweight.png',
        'icon': 'assets/progress/clean/rec_icon_bodyweight.png',
        'desc':
            'Latihan penguatan otot majemuk memanfaatkan beban tubuh sendiri dengan variasi knee push-up, glute bridge, dan chair dips.',
        'duration': '20-30 menit',
        'frequency': '3x/minggu',
        'intensity': 'Sedang (50-65% HRmax)',
        'calories': '110-180 kkal',
        'safetyNotes':
            'Gunakan tumpuan lutut jika push-up standar masih terasa berat. Jangan memaksakan repetisi jika bentuk postur mulai melengkung.',
        'aboutTitle': 'Tentang Kalistenik Kompon',
        'aboutDesc':
            'Gerakan gabungan (compound movement) merekrut banyak kelompok otot secara simultan, merangsang pelepasan hormon pertumbuhan alami tubuh untuk membangun massa otot fungsional.',
        'benefits': [
          'Membangun fondasi kekuatan fungsional seluruh tubuh',
          'Meningkatkan koordinasi neuromuskular dan kontrol gerak',
          'Dapat dilakukan di mana saja secara fleksibel tanpa peralatan rumit',
        ],
        'specs': {
          'duration': '20-30 menit',
          'frequency': '3 kali/minggu',
          'intensity': 'Sedang (50-65% HRmax)',
          'calories': '110-180 kkal',
        },
        'tipsTitle': 'Tips Kalistenik',
        'tips': [
          habitTip,
          'Lakukan knee push-up 3 set x 8-10 repetisi dengan teknik rapi.',
          'Lakukan bodyweight squat dengan tempo terkontrol (turun 2 detik, naik 1 detik).',
          'Jaga ritme napas: hembuskan saat mendorong/mengangkat badan.',
        ],
        'refLink': 'https://doi.org/10.21831/jk.v8i1.31208',
      },
      {
        'id': 'underweight_core',
        'title': 'Latihan Otot Inti & Stabilitas Postur (Core & Plank)',
        'name': 'Latihan Otot Inti & Postur',
        'targetText': '15-20 menit',
        'heroImg': 'assets/progress/clean/hero_bodyweight.png',
        'thumbImg': 'assets/progress/clean/thumb_bodyweight.png',
        'thumb': 'assets/progress/clean/rec_thumb_bodyweight.png',
        'icon': 'assets/progress/clean/rec_icon_bodyweight.png',
        'desc':
            'Memperkuat otot transversus abdominis, dinding perut, dan punggung bawah untuk memperbaiki postur tubuh yang bungkuk.',
        'duration': '15-20 menit',
        'frequency': '3x/minggu',
        'intensity': 'Sedang (50-65% HRmax)',
        'calories': '80-140 kkal',
        'safetyNotes':
            'Jaga punggung tetap rata sejajar, hindari pinggang melengkung ke bawah saat menahan posisi plank.',
        'aboutTitle': 'Tentang Latihan Otot Inti & Postur',
        'aboutDesc':
            'Penguatan otot penopang tulang belakang membantu mengatasi postur tubuh bungkuk yang kerap terjadi pada individu dengan massa otot kurang, memberikan kestabilan sentral yang kuat.',
        'benefits': [
          'Mengoreksi postur tubuh agar tampak lebih tegap dan percaya diri',
          'Memperkuat stabilitas panggul dan tulang belakang',
          'Mencegah risiko nyeri punggung saat beraktivitas harian',
        ],
        'specs': {
          'duration': '15-20 menit',
          'frequency': '3 kali/minggu',
          'intensity': 'Sedang (50-65% HRmax)',
          'calories': '80-140 kkal',
        },
        'tipsTitle': 'Tips Latihan Inti',
        'tips': [
          habitTip,
          'Tahan plank 20-30 detik dengan garis bahu, pinggul, dan tumit sejajar lurus.',
          'Kombinasikan dengan bird-dog 8-10 repetisi per sisi untuk keseimbangan.',
          'Pertahankan pernapasan teratur, hindari menahan napas saat kontraksi.',
        ],
        'refLink': 'https://doi.org/10.21831/jk.v8i1.31208',
      },
      {
        'id': 'underweight_recovery',
        'title': 'Peregangan Pemulihan & Mobilitas (Stretching & Light Walk)',
        'name': 'Peregangan Pemulihan & Mobilitas',
        'targetText': '15-20 menit',
        'heroImg': 'assets/progress/clean/hero_yoga.png',
        'thumbImg': 'assets/progress/clean/thumb_yoga.png',
        'thumb': 'assets/progress/clean/rec_thumb_yoga.png',
        'icon': 'assets/progress/clean/rec_icon_yoga.png',
        'desc':
            'Peregangan relaksasi dan jalan rileks singkat untuk melancarkan sirkulasi tanpa membakar surplus kalori yang dibutuhkan tubuh.',
        'duration': '15-20 menit',
        'frequency': '2-3x/minggu',
        'intensity': 'Ringan (35-45% HRmax)',
        'calories': '60-100 kkal',
        'safetyNotes':
            'Batasi kardio durasi panjang (seperti lari jarak jauh atau maraton) agar kalori surplus makanan tidak terbuang percuma.',
        'aboutTitle': 'Tentang Pemulihan & Batasan Kardio',
        'aboutDesc':
            'Bagi individu dengan berat badan kurang, olahraga kardio berdurasi panjang kontraproduktif karena menghabiskan kalori surplus yang seharusnya digunakan untuk sintesis otot. Peregangan pemulihan ringan melancarkan sirkulasi tanpa pembakaran kalori berlebih.',
        'benefits': [
          'Mempercepat pemulihan mikro lesi serat otot pasca latihan kekuatan',
          'Meningkatkan fleksibilitas persendian dan mobilitas gerak tubuh',
          'Mencegah defisit kalori tak terduga agar target kenaikan berat badan tercapai',
        ],
        'specs': {
          'duration': '15-20 menit',
          'frequency': '2-3 kali/minggu',
          'intensity': 'Ringan (35-45% HRmax)',
          'calories': '60-100 kkal',
        },
        'tipsTitle': 'Tips Peregangan Pemulihan',
        'tips': [
          habitTip,
          'Lakukan peregangan dinamis dan statis lembut pada otot paha, dada, dan punggung.',
          'Hindari kardio lari cepat berdurasi lama (>30 menit).',
          'Minum susu atau konsumsi camilan bernutrisi padat sesaat setelah sesi latihan.',
        ],
        'refLink': 'https://doi.org/10.25182/jgp.2016.11.3.%25p',
      },
    ];
  }
}

