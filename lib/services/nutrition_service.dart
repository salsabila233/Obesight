import 'package:flutter/material.dart';

class NutritionService extends ChangeNotifier {
  static final NutritionService _instance = NutritionService._internal();
  factory NutritionService() => _instance;
  static NutritionService get instance => _instance;

  NutritionService._internal();

  // 8 Data Items Makanan & Minuman
  static final List<Map<String, dynamic>> allItems = [
    // ------------------- MAKANAN -------------------
    {
      'id': 'food_oatmeal',
      'type': 'food',
      'title': 'Oatmeal + Pisang +Almond',
      'name': 'Oatmeal + Pisang +Almond',
      'category': 'Sarapan',
      'categoryIcon': Icons.wb_sunny_rounded,
      'categoryBg': Color(0xFFFFF7ED),
      'categoryText': Color(0xFFEA580C),
      'desc': 'Mengenyangkan, tinggi serat, baik untuk pencernaan.',
      'detailDesc':
          'Hidangan ini adalah sarapan bernutrisi lengkap yang dirancang sebagai opsi makanan padat energi untuk memulai hari. Oatmeal sebagai karbohidrat kompleks menyediakan pelepasan energi lambat, sementara Pisang menyumbangkan glukosa alami dan mikronutrien penting, dan Almond memberikan lemak sehat dan protein nabati untuk rasa kenyang yang tahan lama.',
      'calories': '~350 - 450 kkal (Tergantung ukuran porsi dan jenis oatmeal).',
      'pills': ['Oatmeal 50g', 'Pisang 50g', 'Almond 10g'],
      'benefits': [
        'Kaya serat pangan yang baik untuk pencernaan.',
        'Sumber karbohidrat kompleks untuk energi stabil.',
        'Lemak sehat & protein yang dapat menjaga rasa kenyang.',
        'Vitamin & mineral (Potasium dari pisang, Magnesium & Vit.E dari almond).',
      ],
      'thumbImg': 'assets/progress/nutrition/food_oatmeal.png',
      'heroImg': 'assets/progress/nutrition/hero_oatmeal.png',
      'hasThumb': true,
      'hasThumbInDrinkTab': true,
    },
    {
      'id': 'food_nasi_merah',
      'type': 'food',
      'title': 'Nasi Merah + Ayam Panggang + Sayur',
      'name': 'Nasi Merah + Ayam Panggang + Sayur',
      'category': 'Makan Siang',
      'categoryIcon': Icons.wb_sunny_rounded,
      'categoryBg': Color(0xFFFFF7ED),
      'categoryText': Color(0xFFEA580C),
      'desc': 'Tinggi protein, serat, dan rendah lemak.',
      'detailDesc':
          'Kombinasi makan siang seimbang yang dirancang untuk mendukung pemulihan energi dan pembentukan jaringan otot tanpa menambah lemak jenuh berlebih. Nasi merah menyajikan indeks glikemik rendah untuk menjaga gula darah tetap stabil, ayam panggang tanpa kulit menyuplai protein murni, serta aneka sayuran hijau melengkapi asupan serat dan antioksidan harian.',
      'calories': '~400 - 480 kkal (Tergantung bagian ayam dan metode pemanggangan).',
      'pills': ['Nasi merah 100g', 'Ayam 100g', 'Sayur 150g'],
      'benefits': [
        'Tinggi protein tanpa lemak untuk regenerasi dan massa otot.',
        'Karbohidrat kompleks dengan indeks glikemik rendah.',
        'Kaya serat pangan sayuran untuk kelancaran saluran cerna.',
        'Mengandung zat besi, vitamin B kompleks, dan kalium alami.',
      ],
      'thumbImg': 'assets/progress/nutrition/food_nasi_merah.png',
      'heroImg': 'assets/progress/nutrition/hero_nasi_merah.png',
      'hasThumb': true,
      'hasThumbInDrinkTab': true,
    },
    {
      'id': 'food_sup_tahu',
      'type': 'food',
      'title': 'Sup Tahu + Sayuran',
      'name': 'Sup Tahu + Sayuran',
      'category': 'Makan Malam',
      'categoryIcon': Icons.nightlight_round,
      'categoryBg': Color(0xFFF3E8FF),
      'categoryText': Color(0xFF7C3AED),
      'desc': 'Rendah kalori, tinggi serat, dan vitamin.',
      'detailDesc':
          'Pilihan santap malam yang hangat, ringan di lambung, serta rendah kalori sehingga sangat ideal untuk membantu menjaga berat badan sebelum beristirahat. Tahu putih kaya akan isoflavon dan protein nabati yang mudah dicerna, dipadukan bersama kaldu sayuran segar yang menghidrasi dan menutrisi sel-sel tubuh sepanjang malam.',
      'calories': '~150 - 220 kkal (Tanpa penggunaan santan atau minyak berlebih).',
      'pills': ['Tahu 100g', 'Sayur 150g'],
      'benefits': [
        'Rendah kalori dan sangat ramah bagi metabolisme malam hari.',
        'Protein nabati berkualitas tinggi dari kedelai murni.',
        'Kaya serat larut serta aneka vitamin (Vit. A, C, dan K).',
        'Mendukung hidrasi tubuh dan tidur yang lebih nyenyak.',
      ],
      'thumbImg': 'assets/progress/nutrition/food_sup_tahu.png',
      'heroImg': 'assets/progress/nutrition/hero_sup_tahu.png',
      'hasThumb': true,
      'hasThumbInDrinkTab': true,
    },
    {
      'id': 'food_yogurt',
      'type': 'food',
      'title': 'Yogurt + Buah + Granola',
      'name': 'Yogurt + Buah + Granola',
      'category': 'Cemilan',
      'categoryIcon': Icons.coffee_rounded,
      'categoryBg': Color(0xFFE0F2FE),
      'categoryText': Color(0xFF0284C7),
      'desc': 'Baik untuk pencernaan dan menjaga energi.',
      'detailDesc':
          'Camilan sehat padat nutrisi yang memadukan kebaikan probiotik alami untuk kesehatan mikrobioma usus dan pencernaan optimal. Potongan buah segar memberikan ledakan rasa manis alami tanpa gula buatan, sementara taburan granola menghadirkan kerenyahan kaya serat yang membantu menekan rasa lapar di sela-sela jam makan utama.',
      'calories': '~180 - 250 kkal (Menggunakan yogurt plain tawar).',
      'pills': ['Yogurt Plain 100g', 'Buah 50g', 'Granola 15g'],
      'benefits': [
        'Probiotik aktif untuk menjaga keseimbangan bakteri baik usus.',
        'Kalsium dan fosfor untuk kekuatan tulang dan persendian.',
        'Antioksidan polifenol dari buah-buahan berry dan segar.',
        'Serat oat granola yang menjaga rasa kenyang lebih lama.',
      ],
      'thumbImg': 'assets/progress/nutrition/food_yogurt.png',
      'heroImg': 'assets/progress/nutrition/hero_yogurt.png',
      'hasThumb': true,
      'hasThumbInDrinkTab': true,
    },

    // ------------------- MINUMAN -------------------
    {
      'id': 'drink_teh_hijau',
      'type': 'drink',
      'title': 'Teh Hijau',
      'name': 'Teh Hijau',
      'category': 'pagi',
      'categoryIcon': Icons.wb_sunny_rounded,
      'categoryBg': Color(0xFFFEF9C3),
      'categoryText': Color(0xFFCA8A04),
      'desc': 'Membantu metabolisme dan kaya akan antioksidan.',
      'detailDesc':
          'Teh hijau adalah minuman alami bebas kalori yang menjadi salah satu pilihan populer untuk menunjang program penurunan berat badan. Minuman ini kaya akan antioksidan, terutama epigallocatechin gallate (EGCG), serta kafein alami yang bekerja merangsang pemecahan lemak dan meningkatkan pembakaran kalori tubuh secara optimal.',
      'calories': '0 - 2 kkal (Tanpa tambahan gula, madu, atau krimer).',
      'pills': ['0 kalori', 'Antioksidan', 'Vitamin C'],
      'benefits': [
        'Kandungan EGCG dan kafein membantu mempercepat proses pembakaran kalori dan lemak tubuh.',
        'Membantu memecah jaringan lemak untuk dijadikan sumber energi saat beraktivitas.',
        'Bebas kalori & rendah gula.',
        'Kaya antioksidan.',
      ],
      'thumbImg': 'assets/progress/nutrition/drink_teh_hijau.png',
      'heroImg': 'assets/progress/nutrition/hero_teh_hijau.png',
      'hasThumb': true,
      'hasThumbInDrinkTab': false, // Di tab Minuman tanpa foto (card lebih pendek sesuai Page 2)
    },
    {
      'id': 'drink_jus_sayur',
      'type': 'drink',
      'title': 'Jus Sayur (Bayam, apel hijau dan seledri)',
      'name': 'Jus Sayur (Bayam, apel hijau dan seledri)',
      'category': 'Cemilan',
      'categoryIcon': Icons.coffee_rounded,
      'categoryBg': Color(0xFFE0F2FE),
      'categoryText': Color(0xFF0284C7),
      'desc': 'Mengendalikan rasa lapar, banyak mengandung serat serta detox.',
      'detailDesc':
          'Minuman hijau pembersih alami yang menggabungkan bayam segar tinggi klorofil, apel hijau renyah, dan seledri yang kaya elektrolit. Kombinasi ini efektif membantu proses detoksifikasi tubuh secara alami, meredakan peradangan, serta memberikan rasa segar instan yang membantu mengendalikan rasa lapar dan keinginan ngemil.',
      'calories': '~60 - 90 kkal (Murni sari buah dan sayur tanpa pemanis tambahan).',
      'pills': ['0 lemak', 'kaya serat', 'detox'],
      'benefits': [
        'Tinggi klorofil dan fitonutrien untuk detoksifikasi sel tubuh.',
        'Mengandung potasium alami dari seledri yang membantu membuang kelebihan cairan.',
        'Bebas lemak dan ramah bagi program penurunan berat badan.',
        'Kaya vitamin A, C, asam folat, dan zat besi.',
      ],
      'thumbImg': 'assets/progress/nutrition/drink_jus_sayur.png',
      'heroImg': 'assets/progress/nutrition/hero_jus_sayur.png',
      'hasThumb': true,
      'hasThumbInDrinkTab': true,
    },
    {
      'id': 'drink_jus_buah',
      'type': 'drink',
      'title': 'Jus Buah Segar (Apel dan Wortel)',
      'name': 'Jus Buah Segar (Apel dan Wortel)',
      'category': 'siang',
      'categoryIcon': Icons.wb_sunny_rounded,
      'categoryBg': Color(0xFFFFEDD5),
      'categoryText': Color(0xFFEA580C),
      'desc': 'Sumbangan vitamin yang baik untuk energi.',
      'detailDesc':
          'Perpaduan manis segar antara apel merah pilihan dan wortel organik yang memberikan dorongan energi instan yang sehat di siang hari. Mengandung konsentrasi beta-karoten tinggi yang bermanfaat untuk ketajaman penglihatan, peremajaan kulit, serta sistem imunitas tubuh agar tetap prima dalam menjalani aktivitas padat.',
      'calories': '~90 - 130 kkal (100% buah dan sayur segar tanpa sirup).',
      'pills': ['Energi alami', 'Kaya serat', 'Vitamin C'],
      'benefits': [
        'Beta-karoten konsentrasi tinggi untuk kesehatan mata dan kulit.',
        'Sumber gula buah alami (fruktosa) sebagai bahan bakar energi siang hari.',
        'Kaya vitamin C dan antioksidan untuk daya tahan tubuh.',
        'Pektin apel yang membantu menurunkan kolesterol jahat (LDL).',
      ],
      'thumbImg': 'assets/progress/nutrition/drink_jus_buah.png',
      'heroImg': 'assets/progress/nutrition/hero_jus_buah.png',
      'hasThumb': true,
      'hasThumbInDrinkTab': false, // Di tab Minuman tanpa foto (card lebih pendek sesuai Page 2)
    },
    {
      'id': 'drink_infused_lemon',
      'type': 'drink',
      'title': 'Infused Water Lemon',
      'name': 'Infused Water Lemon',
      'category': 'malam',
      'categoryIcon': Icons.nightlight_round,
      'categoryBg': Color(0xFFF3E8FF),
      'categoryText': Color(0xFF7C3AED),
      'desc': 'Membantu menghidrasi dan membersihkan tubuh.',
      'detailDesc':
          'Air minum segar beraroma sitrus dengan rendaman irisan lemon segar yang memberikan sensasi menyegarkan sekaligus menyehatkan organ pencernaan. Sangat baik dikonsumsi untuk mencukupi kebutuhan hidrasi harian, memelihara pH tubuh tetap seimbang, dan mempercepat pembuangan racun sebelum waktu istirahat malam.',
      'calories': '~5 - 10 kkal (Hanya dari sari alami lemon).',
      'pills': ['Hidrasi', 'Rendah kalori', 'Vitamin C'],
      'benefits': [
        'Meningkatkan kecukupan hidrasi seluler tubuh tanpa kalori.',
        'Kandungan asam sitrat alami yang mendukung pembersihan ginjal dan saluran cerna.',
        'Sumber vitamin C yang membantu menjaga daya tahan tubuh dan sintesis kolagen.',
        'Menyegarkan napas dan menenangkan sistem pencernaan sebelum tidur.',
      ],
      'thumbImg': 'assets/progress/nutrition/drink_infused_lemon.png',
      'heroImg': 'assets/progress/nutrition/hero_infused_lemon.png',
      'hasThumb': true,
      'hasThumbInDrinkTab': true,
    },
  ];

  // ================= Backend Data Filtering Providers =================
  List<Map<String, dynamic>> getAllItems() {
    final foods = allItems.where((it) => it['type'] == 'food').toList();
    final drinks = allItems.where((it) => it['type'] == 'drink').toList();
    return [...foods, ...drinks];
  }

  List<Map<String, dynamic>> getFoodItems() {
    return allItems.where((it) => it['type'] == 'food').toList();
  }

  List<Map<String, dynamic>> getDrinkItems() {
    return allItems.where((it) => it['type'] == 'drink').toList();
  }

  // ================= Saved Items (Makananku & Minumanku) =================
  final List<Map<String, dynamic>> _myFoods = [
    allItems[0], // Default: Oatmeal + Pisang + Almond
  ];
  final List<Map<String, dynamic>> _myDrinks = [
    allItems[7], // Default: Infused Water Lemon
  ];

  List<Map<String, dynamic>> get myFoods => List.unmodifiable(_myFoods);
  List<Map<String, dynamic>> get myDrinks => List.unmodifiable(_myDrinks);

  Map<String, dynamic>? get myFood => _myFoods.isNotEmpty ? _myFoods.last : null;
  Map<String, dynamic>? get myDrink => _myDrinks.isNotEmpty ? _myDrinks.last : null;

  Set<String> get savedItemIds => {
        ..._myFoods.map((f) => f['id'] as String),
        ..._myDrinks.map((d) => d['id'] as String),
      };

  bool isFoodSaved(String id) => _myFoods.any((f) => f['id'] == id);
  bool isDrinkSaved(String id) => _myDrinks.any((d) => d['id'] == id);
  bool isSaved(String id) => isFoodSaved(id) || isDrinkSaved(id);

  void addFood(Map<String, dynamic> item) {
    if (!isFoodSaved(item['id'] as String)) {
      _myFoods.add(item);
      notifyListeners();
    }
  }

  void removeFood(String id) {
    _myFoods.removeWhere((item) => item['id'] == id);
    notifyListeners();
  }

  void addDrink(Map<String, dynamic> item) {
    if (!isDrinkSaved(item['id'] as String)) {
      _myDrinks.add(item);
      notifyListeners();
    }
  }

  void removeDrink(String id) {
    _myDrinks.removeWhere((item) => item['id'] == id);
    notifyListeners();
  }
}

