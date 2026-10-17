import 'package:flutter/material.dart';
import '../models/nutrition_meal_model.dart';
import 'calorie_target_service.dart';

/// Service penyedia basis data menu makanan & minuman serta logika deterministik
/// pembagian menu harian sesuai target kalori hasil skrining IMT pengguna.
///
/// ESTIMASI NILAI GIZI:
/// Seluruh estimasi kalori dan makronutrien (protein, karbohidrat, lemak)
/// dalam database ini dirujuk dan diestimasi berdasarkan standar
/// Tabel Komposisi Pangan Indonesia (TKPI) Kemenkes RI 2017.
class MealPlanService {
  MealPlanService._();

  // =======================================================================
  // MASTER POOL MENU REKOMENDASI OBESIGHT
  // =======================================================================

  // ------------------------- 1. SARAPAN (7 PILIHAN) -------------------------
  static final List<NutritionMealModel> _breakfastPool = [
    // 1. Oatmeal + Pisang + Almond (Menu Asli dengan Foto)
    const NutritionMealModel(
      id: 'food_oatmeal',
      name: 'Oatmeal + Pisang + Almond',
      type: 'food',
      mealTime: 'Sarapan',
      category: 'Sarapan',
      calories: 425,
      protein: 14.5,
      carbs: 68.0,
      fat: 11.0,
      portionGram: 210,
      pills: ['Oatmeal 60g', 'Pisang 60g', 'Almond 15g'],
      thumbImg: 'assets/progress/nutrition/food_oatmeal.png',
      heroImg: 'assets/progress/nutrition/hero_oatmeal.png',
      hasCustomPhoto: true,
      desc: 'Mengenyangkan, tinggi serat, baik untuk pencernaan.',
      detailDesc:
          'Hidangan ini adalah sarapan bernutrisi lengkap yang dirancang sebagai opsi makanan padat energi untuk memulai hari. Oatmeal sebagai karbohidrat kompleks menyediakan pelepasan energi lambat, sementara Pisang menyumbangkan glukosa alami dan mikronutrien penting, dan Almond memberikan lemak sehat dan protein nabati untuk rasa kenyang yang tahan lama.',
      benefits: [
        'Kaya serat pangan larut beta-glukan untuk kesehatan pencernaan.',
        'Sumber karbohidrat kompleks untuk energi yang stabil sepanjang pagi.',
        'Lemak sehat tak jenuh & protein nabati yang menjaga rasa kenyang.',
        'Kaya potasium, magnesium, dan vitamin E.',
      ],
      categoryIcon: Icons.wb_sunny_rounded,
      categoryBg: Color(0xFFFFF7ED),
      categoryText: Color(0xFFEA580C),
    ),

    // 2. Roti Gandum Panggang + Telur Orak-Arik + Tomat
    const NutritionMealModel(
      id: 'food_roti_telur',
      name: 'Roti Gandum Panggang + Telur Orak-Arik',
      type: 'food',
      mealTime: 'Sarapan',
      category: 'Sarapan',
      calories: 420,
      protein: 20.0,
      carbs: 48.0,
      fat: 14.0,
      portionGram: 200,
      pills: ['Roti Gandum 70g', 'Telur 100g', 'Tomat 30g'],
      thumbImg: 'assets/progress/nutrition/food_roti_telur.jpg',
      heroImg: 'assets/progress/nutrition/food_roti_telur.jpg',
      hasCustomPhoto: true,
      desc: 'Tinggi protein berkualitas tinggi dan serat biji-bijian.',
      detailDesc:
          'Dua lembar roti gandum utuh panggang dipadukan dengan telur orak-arik lembut tanpa mentega berlebih dan irisan tomat ceri segar. Memberikan rasa kenyang optimal tanpa lonjakan gula darah.',
      benefits: [
        'Protein lengkap dengan 9 asam amino esensial untuk otot.',
        'Kolin dari kuning telur mendukung fungsi kognitif otak.',
        'Likoppen dari tomat sebagai antioksidan protektif jantung.',
      ],
      categoryIcon: Icons.wb_sunny_rounded,
      categoryBg: Color(0xFFFFF7ED),
      categoryText: Color(0xFFEA580C),
    ),

    // 3. Bubur Beras Merah Dada Ayam Suwir Bening
    const NutritionMealModel(
      id: 'food_bubur_ayam',
      name: 'Bubur Beras Merah + Dada Ayam Suwir',
      type: 'food',
      mealTime: 'Sarapan',
      category: 'Sarapan',
      calories: 430,
      protein: 26.0,
      carbs: 58.0,
      fat: 8.0,
      portionGram: 280,
      pills: ['Beras Merah 60g', 'Dada Ayam 90g', 'Kuah Kaldu 130ml'],
      thumbImg: 'assets/progress/nutrition/food_bubur_ayam.jpg',
      heroImg: 'assets/progress/nutrition/food_bubur_ayam.jpg',
      hasCustomPhoto: true,
      desc: 'Hangat, mudah dicerna, rendah lemak jenuh.',
      detailDesc:
          'Bubur lembut dari beras merah kaya serat disajikan bersama suwiran dada ayam kukus empuk dan kuah kaldu rempah bening tanpa santan, dilengkapi taburan daun seledri dan bawang daun.',
      benefits: [
        'Rendah lemak jenuh, sangat aman untuk pembuluh darah.',
        'Serat beras merah menstabilkan respon glikemik pagi hari.',
        'Mudah dicerna dan ramah bagi lambung sensitif.',
      ],
      categoryIcon: Icons.wb_sunny_rounded,
      categoryBg: Color(0xFFFFF7ED),
      categoryText: Color(0xFFEA580C),
    ),

    // 4. Sandwich Tempe Panggang & Selada Hijau
    const NutritionMealModel(
      id: 'food_sandwich_tempe',
      name: 'Sandwich Gandum Tempe Panggang',
      type: 'food',
      mealTime: 'Sarapan',
      category: 'Sarapan',
      calories: 415,
      protein: 19.0,
      carbs: 52.0,
      fat: 12.0,
      portionGram: 210,
      pills: ['Roti Gandum 70g', 'Tempe 100g', 'Selada 40g'],
      thumbImg: 'assets/progress/nutrition/food_oatmeal.png',
      heroImg: 'assets/progress/nutrition/hero_oatmeal.png',
      hasCustomPhoto: false,
      desc: 'Kaya probiotik fermentasi dan isoflavon nabati.',
      detailDesc:
          'Irisan tempe berbumbu bawang putih dan ketumbar dipanggang teflon tanpa minyak, diselipkan di antara roti gandum renyah bersama daun selada romaine dan timun segar.',
      benefits: [
        'Probiotik alami tempe menyehatkan mikrobiota usus.',
        'Isoflavon kedelai membantu regulasi lipid darah.',
        'Serat ganda dari nabati menjaga kenyang lebih tahan lama.',
      ],
      categoryIcon: Icons.wb_sunny_rounded,
      categoryBg: Color(0xFFFFF7ED),
      categoryText: Color(0xFFEA580C),
    ),

    // 5. Omelet Putih Telur Sayur + Ubi Rebus
    const NutritionMealModel(
      id: 'food_omelet_sayur',
      name: 'Omelet Putih Telur Sayur + Ubi Rebus',
      type: 'food',
      mealTime: 'Sarapan',
      category: 'Sarapan',
      calories: 425,
      protein: 24.0,
      carbs: 56.0,
      fat: 7.0,
      portionGram: 230,
      pills: ['Ubi Kuning 120g', 'Putih Telur 3 btr', 'Bayam 50g'],
      thumbImg: 'assets/progress/nutrition/food_omelet_sayur.jpg',
      heroImg: 'assets/progress/nutrition/food_omelet_sayur.jpg',
      hasCustomPhoto: true,
      desc: 'Bebas kolesterol tinggi, kaya vitamin A & karotenoid.',
      detailDesc:
          'Omelet ringan dari putih telur dicampur cincangan bayam dan jamur kancing, dipadukan dengan ubi jalar kukus manis alami sebagai sumber karbohidrat kompleks alami.',
      benefits: [
        'Beta-karoten dari ubi mendukung imunitas dan kesehatan mata.',
        'Sangat rendah kolesterol dan lemak jenuh.',
        'Kaya kalium untuk keseimbangan elektrolit tubuh.',
      ],
      categoryIcon: Icons.wb_sunny_rounded,
      categoryBg: Color(0xFFFFF7ED),
      categoryText: Color(0xFFEA580C),
    ),

    // 6. Lontong Sayur Bening Labu Siam + Tahu Kukus
    const NutritionMealModel(
      id: 'food_lontong_sayur',
      name: 'Lontong Sayur Bening + Tahu Kukus',
      type: 'food',
      mealTime: 'Sarapan',
      category: 'Sarapan',
      calories: 410,
      protein: 16.0,
      carbs: 64.0,
      fat: 8.0,
      portionGram: 270,
      pills: ['Lontong 120g', 'Tahu 100g', 'Labu Siam 50g'],
      thumbImg: 'assets/progress/nutrition/food_lontong_sayur.jpg',
      heroImg: 'assets/progress/nutrition/food_lontong_sayur.jpg',
      hasCustomPhoto: true,
      desc: 'Menu tradisional sehat tanpa santan dan minyak berlebih.',
      detailDesc:
          'Potongan lontong beras disiram kuah sayur bening labu siam manis gurih, disajikan dengan tahu putih kukus berbumbu rempah nusantara yang harum dan segar.',
      benefits: [
        'Bebas santan jenuh sehingga ringan di pembuluh darah.',
        'Labu siam kaya air dan serat untuk hidrasi pagi.',
        'Kalsium nabati dari olahan kedelai tahu kukus.',
      ],
      categoryIcon: Icons.wb_sunny_rounded,
      categoryBg: Color(0xFFFFF7ED),
      categoryText: Color(0xFFEA580C),
    ),

    // 7. Smoothie Bowl Buah Naga & Biji Chia
    const NutritionMealModel(
      id: 'food_smoothie_bowl',
      name: 'Smoothie Bowl Buah Naga & Biji Chia',
      type: 'food',
      mealTime: 'Sarapan',
      category: 'Sarapan',
      calories: 420,
      protein: 15.0,
      carbs: 62.0,
      fat: 10.0,
      portionGram: 240,
      pills: ['Buah Naga 100g', 'Yogurt Plain 100g', 'Chia 15g'],
      thumbImg: 'assets/progress/nutrition/food_smoothie_bowl.jpg',
      heroImg: 'assets/progress/nutrition/food_smoothie_bowl.jpg',
      hasCustomPhoto: true,
      desc: 'Segar, tinggi antioksidan antosianin dan omega-3.',
      detailDesc:
          'Puree buah naga merah segar dikombinasikan dengan Greek yogurt tawar kaya protein, ditaburi biji chia yang mengembang memberikan rasa kenyang dan kesegaran luar biasa.',
      benefits: [
        'Asam lemak Omega-3 ALA dari biji chia untuk kesehatan sel.',
        'Antioksidan betalain buah naga melawan stres oksidatif.',
        'Mendukung gerakan peristaltik usus yang sehat.',
      ],
      categoryIcon: Icons.wb_sunny_rounded,
      categoryBg: Color(0xFFFFF7ED),
      categoryText: Color(0xFFEA580C),
    ),
  ];

  // ------------------------- 2. MAKAN SIANG (7 PILIHAN) -------------------------
  static final List<NutritionMealModel> _lunchPool = [
    // 1. Nasi Merah + Ayam Panggang + Sayur (Menu Asli dengan Foto)
    const NutritionMealModel(
      id: 'food_nasi_merah',
      name: 'Nasi Merah + Ayam Panggang + Sayur',
      type: 'food',
      mealTime: 'Makan Siang',
      category: 'Makan Siang',
      calories: 595,
      protein: 38.0,
      carbs: 72.0,
      fat: 13.0,
      portionGram: 360,
      pills: ['Nasi Merah 130g', 'Dada Ayam 120g', 'Sayur 110g'],
      thumbImg: 'assets/progress/nutrition/food_nasi_merah.png',
      heroImg: 'assets/progress/nutrition/hero_nasi_merah.png',
      hasCustomPhoto: true,
      desc: 'Tinggi protein, serat, dan rendah lemak jenuh.',
      detailDesc:
          'Kombinasi makan siang seimbang yang dirancang untuk mendukung pemulihan energi dan pembentukan jaringan otot tanpa menambah lemak jenuh berlebih. Nasi merah menyajikan indeks glikemik rendah untuk menjaga gula darah tetap stabil, ayam panggang tanpa kulit menyuplai protein murni, serta aneka sayuran hijau melengkapi asupan serat dan antioksidan harian.',
      benefits: [
        'Tinggi protein tanpa lemak untuk regenerasi dan massa otot.',
        'Karbohidrat kompleks dengan indeks glikemik rendah.',
        'Kaya serat pangan sayuran untuk kelancaran saluran cerna.',
        'Mengandung zat besi, vitamin B kompleks, dan kalium alami.',
      ],
      categoryIcon: Icons.wb_sunny_rounded,
      categoryBg: Color(0xFFFFF7ED),
      categoryText: Color(0xFFEA580C),
    ),

    // 2. Ikan Kembung Panggang + Nasi Merah + Lalapan Kukus
    const NutritionMealModel(
      id: 'food_ikan_kembung',
      name: 'Ikan Kembung Panggang + Lalapan Kukus',
      type: 'food',
      mealTime: 'Makan Siang',
      category: 'Makan Siang',
      calories: 590,
      protein: 36.0,
      carbs: 68.0,
      fat: 16.0,
      portionGram: 340,
      pills: ['Ikan Kembung 120g', 'Nasi Merah 120g', 'Lalapan 100g'],
      thumbImg: 'assets/progress/nutrition/food_ikan_kembung.jpg',
      heroImg: 'assets/progress/nutrition/food_ikan_kembung.jpg',
      hasCustomPhoto: true,
      desc: 'Super kaya asam lemak Omega-3 dan kalsium alami.',
      detailDesc:
          'Ikan kembung bumbu kunyit dipanggang tanpa minyak, kaya DHA & EPA, disandingkan bersama nasi merah hangat dan lalapan kukus labu siam serta wortel yang renyah.',
      benefits: [
        'Omega-3 ikan laut lokal sebanding bahkan melebihi salmon.',
        'Menurunkan trigliserida dan memelihara elastisitas arteri.',
        'Tinggi kalsium dan fosfor untuk kekuatan tulang.',
      ],
      categoryIcon: Icons.wb_sunny_rounded,
      categoryBg: Color(0xFFFFF7ED),
      categoryText: Color(0xFFEA580C),
    ),

    // 3. Pepes Dada Ayam & Tahu + Sayur Bening Bayam
    const NutritionMealModel(
      id: 'food_pepes_ayam',
      name: 'Pepes Dada Ayam & Tahu + Sayur Bayam',
      type: 'food',
      mealTime: 'Makan Siang',
      category: 'Makan Siang',
      calories: 590,
      protein: 42.0,
      carbs: 66.0,
      fat: 12.0,
      portionGram: 370,
      pills: ['Ayam Pepes 120g', 'Tahu 80g', 'Nasi 110g', 'Bayam 60g'],
      thumbImg: 'assets/progress/nutrition/food_pepes_ayam.jpg',
      heroImg: 'assets/progress/nutrition/food_pepes_ayam.jpg',
      hasCustomPhoto: true,
      desc: 'Kukus rempah aromatik daun pisang, bebas minyak goreng.',
      detailDesc:
          'Dada ayam dan tahu dibalut bumbu pepes tradisional kemangi dan cabai merah, dibungkus daun pisang lalu dikukus hingga matang sempurna tanpa setetes pun minyak goreng.',
      benefits: [
        'Fitonutrien dan aroma kemangi meningkatkan nafsu makan sehat.',
        'Dua sumber protein sinergis (hewani + nabati).',
        'Zat besi bayam mencegah anemia dan kelelahan siang hari.',
      ],
      categoryIcon: Icons.wb_sunny_rounded,
      categoryBg: Color(0xFFFFF7ED),
      categoryText: Color(0xFFEA580C),
    ),

    // 4. Tumis Daging Sapi Lada Hitam Non-Minyak + Brokoli
    const NutritionMealModel(
      id: 'food_daging_brokoli',
      name: 'Tumis Sapi Rendah Lemak + Brokoli',
      type: 'food',
      mealTime: 'Makan Siang',
      category: 'Makan Siang',
      calories: 605,
      protein: 40.0,
      carbs: 68.0,
      fat: 15.0,
      portionGram: 330,
      pills: ['Daging Sapi 100g', 'Brokoli 110g', 'Nasi Merah 120g'],
      thumbImg: 'assets/progress/nutrition/food_daging_brokoli.jpg',
      heroImg: 'assets/progress/nutrition/food_daging_brokoli.jpg',
      hasCustomPhoto: true,
      desc: 'Kaya zat besi heme, seng (zinc), dan vitamin C brokoli.',
      detailDesc:
          'Daging sapi tenderloin tanpa lemak ditumis dengan sedikit air dan lada hitam aromatik, disajikan bersama kuntum brokoli kukus segar dan nasi merah.',
      benefits: [
        'Zat besi heme dengan tingkat absorpsi tubuh paling tinggi.',
        'Sulforaphane dari brokoli sebagai senyawa antikanker poten.',
        'Mendukung sintesis mioglobin dan pemulihan stamina fisik.',
      ],
      categoryIcon: Icons.wb_sunny_rounded,
      categoryBg: Color(0xFFFFF7ED),
      categoryText: Color(0xFFEA580C),
    ),

    // 5. Gado-Gado Rebus + Telur + Kentang (Saus Kacang Ringan)
    const NutritionMealModel(
      id: 'food_gado_gado',
      name: 'Gado-Gado Rebus + Telur & Kentang',
      type: 'food',
      mealTime: 'Makan Siang',
      category: 'Makan Siang',
      calories: 585,
      protein: 26.0,
      carbs: 76.0,
      fat: 16.0,
      portionGram: 380,
      pills: ['Sayuran 180g', 'Telur 60g', 'Kentang 100g', 'Bumbu 40g'],
      thumbImg: 'assets/progress/nutrition/food_gado_gado.jpg',
      heroImg: 'assets/progress/nutrition/food_gado_gado.jpg',
      hasCustomPhoto: true,
      desc: 'Salad sayur nusantara padat serat dengan protein telur utuh.',
      detailDesc:
          'Kombinasi bayam, tauge, kacang panjang, dan pare rebus segar, dilengkapi telur rebus matang, kentang kukus, dan siraman saus kacang sangrai rendah gula aren.',
      benefits: [
        'Kaya serat pangan larut dan tidak larut melancarkan pencernaan.',
        'Vitamin K dan folat berlimpah dari sayuran hijau segar.',
        'Lemak tak jenuh tunggal dari bumbu kacang tanah sangrai.',
      ],
      categoryIcon: Icons.wb_sunny_rounded,
      categoryBg: Color(0xFFFFF7ED),
      categoryText: Color(0xFFEA580C),
    ),

    // 6. Soto Ayam Bening Rempah + Nasi Merah
    const NutritionMealModel(
      id: 'food_soto_bening',
      name: 'Soto Ayam Kampung Kuah Bening',
      type: 'food',
      mealTime: 'Makan Siang',
      category: 'Makan Siang',
      calories: 595,
      protein: 36.0,
      carbs: 74.0,
      fat: 12.0,
      portionGram: 390,
      pills: ['Ayam Suwir 120g', 'Nasi Merah 120g', 'Kuah & Tauge 150ml'],
      thumbImg: 'assets/progress/nutrition/food_soto_ayam.jpg',
      heroImg: 'assets/progress/nutrition/food_soto_ayam.jpg',
      hasCustomPhoto: true,
      desc: 'Kunyit dan rempah soto sebagai agen anti-inflamasi alami.',
      detailDesc:
          'Kuah soto bening kaya kunyit, jahe, dan serai disajikan dengan suwiran ayam kampung empuk, tauge segar renyah, bihun jagung secukupnya, dan nasi merah.',
      benefits: [
        'Kurkumin kunyit meredakan peradangan sendi dan sel tubuh.',
        'Menghidrasi tubuh sekaligus memulihkan elektrolit keringat.',
        'Rendah kalori minyak namun kaya kelezatan alami.',
      ],
      categoryIcon: Icons.wb_sunny_rounded,
      categoryBg: Color(0xFFFFF7ED),
      categoryText: Color(0xFFEA580C),
    ),

    // 7. Ikan Salmon / Tongkol Panggang + Kentang Tumbuk
    const NutritionMealModel(
      id: 'food_salmon_panggang',
      name: 'Ikan Panggang Herbal + Kentang Tumbuk',
      type: 'food',
      mealTime: 'Makan Siang',
      category: 'Makan Siang',
      calories: 600,
      protein: 37.0,
      carbs: 65.0,
      fat: 16.0,
      portionGram: 330,
      pills: ['Ikan Panggang 130g', 'Kentang 140g', 'Buncis 60g'],
      thumbImg: 'assets/progress/nutrition/food_ikan_herbal.jpg',
      heroImg: 'assets/progress/nutrition/food_ikan_herbal.jpg',
      hasCustomPhoto: true,
      desc: 'Menu barat modern dengan asam lemak esensial dan buncis manis.',
      detailDesc:
          'Fillet ikan laut segar dipanggang dengan taburan oregano dan lada hitam, disajikan dengan kentang rebus tumbuk lembut dan rebusan buncis manis renyah.',
      benefits: [
        'DHA & EPA esensial memelihara kesehatan sistem saraf.',
        'Kalium dari kentang tumbuk membantu kontrol tekanan darah.',
        'Asam amino lengkap mempercepat sintesis protein tubuh.',
      ],
      categoryIcon: Icons.wb_sunny_rounded,
      categoryBg: Color(0xFFFFF7ED),
      categoryText: Color(0xFFEA580C),
    ),
  ];

  // ------------------------- 3. MAKAN MALAM (7 PILIHAN) -------------------------
  static final List<NutritionMealModel> _dinnerPool = [
    // 1. Sup Tahu + Sayuran (Menu Asli dengan Foto)
    const NutritionMealModel(
      id: 'food_sup_tahu',
      name: 'Sup Tahu + Sayuran Segar',
      type: 'food',
      mealTime: 'Makan Malam',
      category: 'Makan Malam',
      calories: 510,
      protein: 28.0,
      carbs: 64.0,
      fat: 12.0,
      portionGram: 340,
      pills: ['Tahu Sutra 120g', 'Sayur 120g', 'Beras Merah 100g'],
      thumbImg: 'assets/progress/nutrition/food_sup_tahu.png',
      heroImg: 'assets/progress/nutrition/hero_sup_tahu.png',
      hasCustomPhoto: true,
      desc: 'Rendah lemak jenuh, hangat, dan sangat ramah lambung malam.',
      detailDesc:
          'Pilihan santap malam yang hangat, ringan di lambung, serta rendah kalori sehingga sangat ideal untuk membantu menjaga berat badan sebelum beristirahat. Tahu putih kaya akan isoflavon dan protein nabati yang mudah dicerna, dipadukan bersama kaldu sayuran segar yang menghidrasi dan menutrisi sel-sel tubuh sepanjang malam.',
      benefits: [
        'Rendah beban cerna, tidak mengganggu kualitas tidur malam.',
        'Protein nabati berkualitas tinggi dari kedelai murni.',
        'Kaya serat larut serta aneka vitamin (Vit. A, C, dan K).',
        'Mendukung hidrasi tubuh dan tidur yang lebih nyenyak.',
      ],
      categoryIcon: Icons.nightlight_round,
      categoryBg: Color(0xFFF3E8FF),
      categoryText: Color(0xFF7C3AED),
    ),

    // 2. Sup Ayam Bening Jagung Manis & Wortel
    const NutritionMealModel(
      id: 'food_sup_ayam_jagung',
      name: 'Sup Ayam Bening Jagung & Wortel',
      type: 'food',
      mealTime: 'Makan Malam',
      category: 'Makan Malam',
      calories: 515,
      protein: 34.0,
      carbs: 60.0,
      fat: 11.0,
      portionGram: 330,
      pills: ['Dada Ayam 110g', 'Jagung Manis 70g', 'Wortel 80g', 'Nasi 70g'],
      thumbImg: 'assets/progress/nutrition/food_sup_ayam_jagung.jpg',
      heroImg: 'assets/progress/nutrition/food_sup_ayam_jagung.jpg',
      hasCustomPhoto: true,
      desc: 'Kaldu ayam asli menghangatkan tubuh sebelum tidur.',
      detailDesc:
          'Sup ayam berkuah kaldu bening dengan pipilan jagung manis segar dan irisan wortel kaya vitamin A, disajikan bersama porsi nasi sedang yang pas untuk istirahat malam.',
      benefits: [
        'Asam amino triptofan ayam memicu produksi hormon melatonin tidur.',
        'Lutein dari jagung manis memelihara kesehatan retina mata.',
        'Menghidrasi jaringan tubuh selama istirahat malam 7-8 jam.',
      ],
      categoryIcon: Icons.nightlight_round,
      categoryBg: Color(0xFFF3E8FF),
      categoryText: Color(0xFF7C3AED),
    ),

    // 3. Tumis Tempe Buncis Tanpa Santan + Nasi Merah
    const NutritionMealModel(
      id: 'food_tumis_tempe_buncis',
      name: 'Tumis Tempe Buncis Tanpa Santan',
      type: 'food',
      mealTime: 'Makan Malam',
      category: 'Makan Malam',
      calories: 510,
      protein: 24.0,
      carbs: 68.0,
      fat: 13.0,
      portionGram: 310,
      pills: ['Tempe 120g', 'Buncis 90g', 'Nasi Merah 100g'],
      thumbImg: 'assets/progress/nutrition/food_tumis_tempe_buncis.jpg',
      heroImg: 'assets/progress/nutrition/food_tumis_tempe_buncis.jpg',
      hasCustomPhoto: true,
      desc: 'Paduan serat tinggi buncis dan protein nabati fermentasi.',
      detailDesc:
          'Potongan tempe segar ditumis dengan buncis muda renyah, bawang merah, dan cabai merah tanpa minyak jenuh, ditemani nasi merah dengan porsi terukur.',
      benefits: [
        'Serat buncis memperlambat penyerapan glukosa malam hari.',
        'Kaya magnesium untuk relaksasi otot dan saraf.',
        'Mudah diserap usus tanpa memicu begah atau refluks asam.',
      ],
      categoryIcon: Icons.nightlight_round,
      categoryBg: Color(0xFFF3E8FF),
      categoryText: Color(0xFF7C3AED),
    ),

    // 4. Capcay Kuah Seafood (Udang & Bakso Ikan)
    const NutritionMealModel(
      id: 'food_capcay_seafood',
      name: 'Capcay Kuah Seafood + Nasi Merah',
      type: 'food',
      mealTime: 'Makan Malam',
      category: 'Makan Malam',
      calories: 505,
      protein: 32.0,
      carbs: 65.0,
      fat: 10.0,
      portionGram: 350,
      pills: ['Udang & Bakso 100g', 'Sayuran 150g', 'Nasi 100g'],
      thumbImg: 'assets/progress/nutrition/food_capcay_seafood.jpg',
      heroImg: 'assets/progress/nutrition/food_capcay_seafood.jpg',
      hasCustomPhoto: true,
      desc: 'Bervariasi aneka sayuran kembang kol, sawi, dan wortel.',
      detailDesc:
          'Sayuran segar kembang kol, sawi putih, dan kapri dimasak kuah kaldu udang gurih bening, menyuplai aneka vitamin mikronutrien lengkap di malam hari.',
      benefits: [
        'Ragam mikronutrien dari aneka warna sayuran (pelangi gizi).',
        'Protein udang rendah kalori namun padat selenium dan seng.',
        'Membantu pemulihan sel organ saat tidur lelap.',
      ],
      categoryIcon: Icons.nightlight_round,
      categoryBg: Color(0xFFF3E8FF),
      categoryText: Color(0xFF7C3AED),
    ),

    // 5. Warm Salad Dada Ayam Rebus + Telur Rebus
    const NutritionMealModel(
      id: 'food_salad_ayam',
      name: 'Warm Salad Ayam & Telur Rebus',
      type: 'food',
      mealTime: 'Makan Malam',
      category: 'Makan Malam',
      calories: 510,
      protein: 38.0,
      carbs: 48.0,
      fat: 16.0,
      portionGram: 290,
      pills: ['Dada Ayam 100g', 'Telur 60g', 'Sayur 130g'],
      thumbImg: 'assets/progress/nutrition/food_sup_tahu.png',
      heroImg: 'assets/progress/nutrition/hero_sup_tahu.png',
      hasCustomPhoto: false,
      desc: 'Protein tinggi sangat rendah karbohidrat sederhana.',
      detailDesc:
          'Selada hijau, tomat ceri, dan timun jepang disajikan hangat dengan suwiran ayam kukus, irisan telur rebus, dan percikan minyak zaitun serta perasan jeruk nipis.',
      benefits: [
        'Mencegah penumpukan glikogen berlebih saat malam hari.',
        'Asam lemak tak jenuh zaitun menjaga kolesterol HDL.',
        'Memperbaiki massa otot tanpa menaikkan lemak perut.',
      ],
      categoryIcon: Icons.nightlight_round,
      categoryBg: Color(0xFFF3E8FF),
      categoryText: Color(0xFF7C3AED),
    ),

    // 6. Ikan Kuah Asam Manado Segar + Sayuran
    const NutritionMealModel(
      id: 'food_ikan_kuah_asam',
      name: 'Ikan Kuah Asam Segar + Sayur',
      type: 'food',
      mealTime: 'Makan Malam',
      category: 'Makan Malam',
      calories: 515,
      protein: 36.0,
      carbs: 62.0,
      fat: 11.0,
      portionGram: 330,
      pills: ['Ikan Kakap 120g', 'Kuah Asam 110ml', 'Nasi 100g'],
      thumbImg: 'assets/progress/nutrition/food_ikan_kuah_asam.jpg',
      heroImg: 'assets/progress/nutrition/food_ikan_kuah_asam.jpg',
      hasCustomPhoto: true,
      desc: 'Belimbing wuluh & kemangi segar tanpa setetes santan.',
      detailDesc:
          'Potongan ikan kakap segar dimasak kuah bening asam rempah belimbing wuluh, daun kemangi, dan tomat hijau. Menyegarkan, bebas minyak, dan nikmat tiada tara.',
      benefits: [
        'Asam sitrat alami belimbing wuluh menyegarkan saluran cerna.',
        'Protein ikan laut sangat cepat dicerna tubuh (kurang dari 2 jam).',
        'Menstabilkan tekanan darah dan detak jantung istirahat.',
      ],
      categoryIcon: Icons.nightlight_round,
      categoryBg: Color(0xFFF3E8FF),
      categoryText: Color(0xFF7C3AED),
    ),

    // 7. Sup Jamur Tiram Telur Puyuh + Nasi Merah
    const NutritionMealModel(
      id: 'food_sup_jamur',
      name: 'Sup Jamur Tiram & Telur Puyuh',
      type: 'food',
      mealTime: 'Makan Malam',
      category: 'Makan Malam',
      calories: 505,
      protein: 25.0,
      carbs: 66.0,
      fat: 12.0,
      portionGram: 320,
      pills: ['Jamur Tiram 100g', 'Telur Puyuh 4 btr', 'Nasi 100g'],
      thumbImg: 'assets/progress/nutrition/food_sup_jamur.jpg',
      heroImg: 'assets/progress/nutrition/food_sup_jamur.jpg',
      hasCustomPhoto: true,
      desc: 'Tinggi beta-glukan jamur dan mikronutrien esensial.',
      detailDesc:
          'Sup kuah bening jamur tiram putih yang kenyal dipadu dengan telur puyuh rebus dan daun bawang, disajikan bersama nasi merah hangat bertakaran pas.',
      benefits: [
        'Beta-glukan jamur merangsang aktivitas sel imun makrofag.',
        'Rendah kalori tapi memberikan tekstur kenyal memuaskan.',
        'Kaya vitamin D nabati untuk kekuatan tulang dan imunitas.',
      ],
      categoryIcon: Icons.nightlight_round,
      categoryBg: Color(0xFFF3E8FF),
      categoryText: Color(0xFF7C3AED),
    ),
  ];

  // ------------------------- 4. CEMILAN (7 PILIHAN) -------------------------
  static final List<NutritionMealModel> _snackPool = [
    // 1. Yogurt + Buah + Granola (Menu Asli dengan Foto)
    const NutritionMealModel(
      id: 'food_yogurt',
      name: 'Yogurt + Buah + Granola',
      type: 'food',
      mealTime: 'Cemilan',
      category: 'Cemilan',
      calories: 160,
      protein: 7.0,
      carbs: 26.0,
      fat: 3.5,
      portionGram: 165,
      pills: ['Yogurt Plain 100g', 'Buah 50g', 'Granola 15g'],
      thumbImg: 'assets/progress/nutrition/food_yogurt.png',
      heroImg: 'assets/progress/nutrition/hero_yogurt.png',
      hasCustomPhoto: true,
      desc: 'Baik untuk pencernaan dan menjaga energi.',
      detailDesc:
          'Camilan sehat padat nutrisi yang memadukan kebaikan probiotik alami untuk kesehatan mikrobioma usus dan pencernaan optimal. Potongan buah segar memberikan ledakan rasa manis alami tanpa gula buatan, sementara taburan granola menghadirkan kerenyahan kaya serat yang membantu menekan rasa lapar di sela-sela jam makan utama.',
      benefits: [
        'Probiotik aktif untuk menjaga keseimbangan bakteri baik usus.',
        'Kalsium dan fosfor untuk kekuatan tulang dan persendian.',
        'Antioksidan polifenol dari buah-buahan segar alami.',
        'Serat oat granola yang menjaga rasa kenyang lebih lama.',
      ],
      categoryIcon: Icons.coffee_rounded,
      categoryBg: Color(0xFFE0F2FE),
      categoryText: Color(0xFF0284C7),
    ),

    // 2. Edamame Rebus Garam Laut
    const NutritionMealModel(
      id: 'food_edamame',
      name: 'Edamame Rebus Gurih',
      type: 'food',
      mealTime: 'Cemilan',
      category: 'Cemilan',
      calories: 155,
      protein: 13.0,
      carbs: 12.0,
      fat: 6.0,
      portionGram: 120,
      pills: ['Edamame 120g', 'Garam Laut Sejumput'],
      thumbImg: 'assets/progress/nutrition/food_yogurt.png',
      heroImg: 'assets/progress/nutrition/hero_yogurt.png',
      hasCustomPhoto: false,
      desc: 'Kaya protein nabati utuh dan serat tinggi penahan lapar.',
      detailDesc:
          'Polong edamame segar direbus dengan sejumput garam laut alami. Camilan sehat yang praktis, gurih, dan sarat asam amino esensial nabati.',
      benefits: [
        'Protein lengkap nabati dengan profil asam amino seimbang.',
        'Indeks glikemik sangat rendah, aman bagi gula darah.',
        'Kaya zat besi dan magnesium untuk kebugaran otot.',
      ],
      categoryIcon: Icons.coffee_rounded,
      categoryBg: Color(0xFFE0F2FE),
      categoryText: Color(0xFF0284C7),
    ),

    // 3. Potongan Apel Fuji + Kacang Almond
    const NutritionMealModel(
      id: 'food_apel_almond',
      name: 'Apel Segar + Kacang Almond',
      type: 'food',
      mealTime: 'Cemilan',
      category: 'Cemilan',
      calories: 165,
      protein: 3.5,
      carbs: 26.0,
      fat: 6.5,
      portionGram: 140,
      pills: ['Apel 120g', 'Almond 10g'],
      thumbImg: 'assets/progress/nutrition/food_yogurt.png',
      heroImg: 'assets/progress/nutrition/hero_yogurt.png',
      hasCustomPhoto: false,
      desc: 'Kombinasi serat pektin renyah dan lemak sehat tak jenuh.',
      detailDesc:
          'Irisan apel manis renyah kaya pektin disandingkan dengan butiran kacang almond panggang tanpa garam. Memberikan kepuasan mengunyah yang menenangkan.',
      benefits: [
        'Pektin apel mengikat kolesterol berlebih di saluran cerna.',
        'Vitamin E almond menutrisi kulit dan melawan radikal bebas.',
        'Kombinasi serat dan lemak sehat menjaga stabilitas insulin.',
      ],
      categoryIcon: Icons.coffee_rounded,
      categoryBg: Color(0xFFE0F2FE),
      categoryText: Color(0xFF0284C7),
    ),

    // 4. Pisang Kepok Kukus Lembut
    const NutritionMealModel(
      id: 'food_pisang_kukus',
      name: 'Pisang Kepok Kukus',
      type: 'food',
      mealTime: 'Cemilan',
      category: 'Cemilan',
      calories: 160,
      protein: 2.0,
      carbs: 38.0,
      fat: 0.5,
      portionGram: 140,
      pills: ['Pisang Kepok Kukus 2 buah (140g)'],
      thumbImg: 'assets/progress/nutrition/food_yogurt.png',
      heroImg: 'assets/progress/nutrition/hero_yogurt.png',
      hasCustomPhoto: false,
      desc: 'Pati resisten alami yang ramah usus dan bebas minyak.',
      detailDesc:
          'Pisang kepok matang pohon dikukus hingga empuk dan harum. Sumber pati resisten alami yang berfungsi sebagai makanan bagi bakteri baik usus.',
      benefits: [
        'Pati resisten meningkatkan produksi asam lemak rantai pendek (SCFA).',
        'Sumber energi cepat pulih setelah beraktivitas.',
        'Bebas kolesterol, natrium, dan lemak trans.',
      ],
      categoryIcon: Icons.coffee_rounded,
      categoryBg: Color(0xFFE0F2FE),
      categoryText: Color(0xFF0284C7),
    ),

    // 5. Puding Biji Chia Buah Naga
    const NutritionMealModel(
      id: 'food_puding_chia',
      name: 'Puding Chia Buah Naga',
      type: 'food',
      mealTime: 'Cemilan',
      category: 'Cemilan',
      calories: 150,
      protein: 5.0,
      carbs: 22.0,
      fat: 5.0,
      portionGram: 150,
      pills: ['Chia Seed 15g', 'Puree Buah Naga 135g'],
      thumbImg: 'assets/progress/nutrition/food_puding_chia.jpg',
      heroImg: 'assets/progress/nutrition/food_puding_chia.jpg',
      hasCustomPhoto: true,
      desc: 'Puding alami tinggi serat larut dan warna antosianin alami.',
      detailDesc:
          'Biji chia yang direndam dalam puree buah naga hingga membentuk tekstur jeli puding lembut tanpa tambahan gula pasir maupun gelatin buatan.',
      benefits: [
        'Menyerap air hingga 12x lipat bobotnya, mengenyangkan lambung.',
        'Omega-3 nabati mendukung kesehatan kardiovaskular.',
        'Tekstur jeli lembut melancarkan buang air besar harian.',
      ],
      categoryIcon: Icons.coffee_rounded,
      categoryBg: Color(0xFFE0F2FE),
      categoryText: Color(0xFF0284C7),
    ),

    // 6. Telur Rebus Matang + Sejumput Lada
    const NutritionMealModel(
      id: 'food_telur_snack',
      name: 'Telur Rebus Organik',
      type: 'food',
      mealTime: 'Cemilan',
      category: 'Cemilan',
      calories: 155,
      protein: 13.0,
      carbs: 1.5,
      fat: 10.5,
      portionGram: 110,
      pills: ['Telur Ayam 2 butir (110g)'],
      thumbImg: 'assets/progress/nutrition/food_telur_organik.jpg',
      heroImg: 'assets/progress/nutrition/food_telur_organik.jpg',
      hasCustomPhoto: true,
      desc: 'Camilan super padat protein esensial dan lutein.',
      detailDesc:
          'Dua butir telur ayam rebus matang bertabur sedikit lada bubuk hitam. Opsi camilan kaya protein hewani murni untuk menopang perbaikan sel otot.',
      benefits: [
        'Protein biologis nilai tinggi (skor BV 100).',
        'Zat kolin esensial untuk kesehatan membran sel saraf.',
        'Sangat minim karbohidrat, menjaga keton/insulin tetap tenang.',
      ],
      categoryIcon: Icons.coffee_rounded,
      categoryBg: Color(0xFFE0F2FE),
      categoryText: Color(0xFF0284C7),
    ),

    // 7. Semangkuk Pepaya Potong Segar + Jeruk Nipis
    const NutritionMealModel(
      id: 'food_pepaya_potong',
      name: 'Pepaya Segar Jeruk Nipis',
      type: 'food',
      mealTime: 'Cemilan',
      category: 'Cemilan',
      calories: 140,
      protein: 2.0,
      carbs: 34.0,
      fat: 0.5,
      portionGram: 280,
      pills: ['Pepaya California 280g', 'Perasan Nipis'],
      thumbImg: 'assets/progress/nutrition/food_yogurt.png',
      heroImg: 'assets/progress/nutrition/hero_yogurt.png',
      hasCustomPhoto: false,
      desc: 'Enzim papain pelarut protein dan vitamin C tinggi.',
      detailDesc:
          'Potongan pepaya manis berair dingin diperciki perasan jeruk nipis segar. Kaya enzim papain yang membantu pencernaan protein dan membersihkan usus.',
      benefits: [
        'Enzim papain membantu memecah sisa protein dalam lambung.',
        'Vitamin C dan likopen dosis tinggi untuk pertahanan sel.',
        'Kadar air tinggi menyegarkan dan melegakan dahaga siang.',
      ],
      categoryIcon: Icons.coffee_rounded,
      categoryBg: Color(0xFFE0F2FE),
      categoryText: Color(0xFF0284C7),
    ),
  ];

  // ------------------------- 5. MINUMAN (7 PILIHAN) -------------------------
  static final List<NutritionMealModel> _drinkPool = [
    // 1. Teh Hijau (Menu Asli dengan Foto)
    const NutritionMealModel(
      id: 'drink_teh_hijau',
      name: 'Teh Hijau Murni',
      type: 'drink',
      mealTime: 'Minuman',
      category: 'Minuman',
      calories: 2,
      protein: 0.2,
      carbs: 0.4,
      fat: 0.0,
      portionGram: 250,
      pills: ['0 kalori', 'Antioksidan EGCG', 'Bebas Gula'],
      thumbImg: 'assets/progress/nutrition/drink_teh_hijau.png',
      heroImg: 'assets/progress/nutrition/hero_teh_hijau.png',
      hasCustomPhoto: true,
      desc: 'Membantu metabolisme dan kaya akan antioksidan.',
      detailDesc:
          'Teh hijau adalah minuman alami bebas kalori yang menjadi salah satu pilihan populer untuk menunjang program penurunan berat badan. Minuman ini kaya akan antioksidan, terutama epigallocatechin gallate (EGCG), serta kafein alami yang bekerja merangsang pemecahan lemak dan meningkatkan pembakaran kalori tubuh secara optimal.',
      benefits: [
        'Kandungan EGCG dan kafein membantu mempercepat pembakaran kalori.',
        'Membantu memecah jaringan lemak untuk dijadikan sumber energi.',
        'Bebas kalori & rendah gula.',
        'Kaya antioksidan polifenol pelindung sel.',
      ],
      categoryIcon: Icons.wb_sunny_rounded,
      categoryBg: Color(0xFFFEF9C3),
      categoryText: Color(0xFFCA8A04),
    ),

    // 2. Jus Sayur (Bayam, apel hijau, seledri) (Menu Asli dengan Foto)
    const NutritionMealModel(
      id: 'drink_jus_sayur',
      name: 'Jus Sayur (Bayam, Apel & Seledri)',
      type: 'drink',
      mealTime: 'Minuman',
      category: 'Minuman',
      calories: 70,
      protein: 2.0,
      carbs: 16.0,
      fat: 0.2,
      portionGram: 250,
      pills: ['Bebas Lemak', 'Kaya Serat', 'Detox Alami'],
      thumbImg: 'assets/progress/nutrition/drink_jus_sayur.png',
      heroImg: 'assets/progress/nutrition/hero_jus_sayur.png',
      hasCustomPhoto: true,
      desc: 'Mengendalikan rasa lapar, banyak serat, dan detoksifikasi.',
      detailDesc:
          'Minuman hijau pembersih alami yang menggabungkan bayam segar tinggi klorofil, apel hijau renyah, dan seledri yang kaya elektrolit. Kombinasi ini efektif membantu proses detoksifikasi tubuh secara alami, meredakan peradangan, serta memberikan rasa segar instan yang membantu mengendalikan rasa lapar dan keinginan ngemil.',
      benefits: [
        'Tinggi klorofil dan fitonutrien untuk detoksifikasi sel tubuh.',
        'Potasium alami seledri membantu ekskresi kelebihan garam natrium.',
        'Bebas lemak dan ramah bagi program penurunan berat badan.',
        'Kaya vitamin A, C, asam folat, dan zat besi nabati.',
      ],
      categoryIcon: Icons.coffee_rounded,
      categoryBg: Color(0xFFE0F2FE),
      categoryText: Color(0xFF0284C7),
    ),

    // 3. Jus Buah Segar (Apel dan Wortel) (Menu Asli dengan Foto)
    const NutritionMealModel(
      id: 'drink_jus_buah',
      name: 'Jus Buah Segar (Apel & Wortel)',
      type: 'drink',
      mealTime: 'Minuman',
      category: 'Minuman',
      calories: 105,
      protein: 1.5,
      carbs: 25.0,
      fat: 0.3,
      portionGram: 250,
      pills: ['Energi Alami', 'Beta-Karoten', 'Vitamin C'],
      thumbImg: 'assets/progress/nutrition/drink_jus_buah.png',
      heroImg: 'assets/progress/nutrition/hero_jus_buah.png',
      hasCustomPhoto: true,
      desc: 'Sumbangan vitamin yang baik untuk energi siang hari.',
      detailDesc:
          'Perpaduan manis segar antara apel merah pilihan dan wortel organik yang memberikan dorongan energi instan yang sehat di siang hari. Mengandung konsentrasi beta-karoten tinggi yang bermanfaat untuk ketajaman penglihatan, peremajaan kulit, serta sistem imunitas tubuh agar tetap prima dalam menjalani aktivitas padat.',
      benefits: [
        'Beta-karoten konsentrasi tinggi untuk kesehatan mata dan kulit.',
        'Sumber gula buah alami (fruktosa) sebagai bahan bakar energi siang hari.',
        'Kaya vitamin C dan antioksidan untuk daya tahan tubuh.',
        'Pektin apel yang membantu menurunkan kolesterol jahat (LDL).',
      ],
      categoryIcon: Icons.wb_sunny_rounded,
      categoryBg: Color(0xFFFFEDD5),
      categoryText: Color(0xFFEA580C),
    ),

    // 4. Infused Water Lemon (Menu Asli dengan Foto)
    const NutritionMealModel(
      id: 'drink_infused_lemon',
      name: 'Infused Water Lemon & Mint',
      type: 'drink',
      mealTime: 'Minuman',
      category: 'Minuman',
      calories: 8,
      protein: 0.2,
      carbs: 2.0,
      fat: 0.0,
      portionGram: 300,
      pills: ['Hidrasi Sel', 'Hampir 0 Kalori', 'Vitamin C'],
      thumbImg: 'assets/progress/nutrition/drink_infused_lemon.png',
      heroImg: 'assets/progress/nutrition/hero_infused_lemon.png',
      hasCustomPhoto: true,
      desc: 'Membantu menghidrasi dan membersihkan tubuh malam hari.',
      detailDesc:
          'Air minum segar beraroma sitrus dengan rendaman irisan lemon segar dan daun mint yang memberikan sensasi menyegarkan sekaligus menyehatkan organ pencernaan. Sangat baik dikonsumsi untuk mencukupi kebutuhan hidrasi harian, memelihara pH tubuh tetap seimbang, dan mempercepat pembuangan racun sebelum waktu istirahat malam.',
      benefits: [
        'Meningkatkan kecukupan hidrasi seluler tubuh tanpa kalori.',
        'Asam sitrat alami mendukung pembersihan ginjal dan saluran cerna.',
        'Vitamin C membantu menjaga sintesis kolagen dan imunitas.',
        'Menyegarkan napas dan menenangkan sistem pencernaan sebelum tidur.',
      ],
      categoryIcon: Icons.nightlight_round,
      categoryBg: Color(0xFFF3E8FF),
      categoryText: Color(0xFF7C3AED),
    ),

    // 5. Susu Kedelai Murni Hangat Tanpa Gula
    const NutritionMealModel(
      id: 'drink_susu_kedelai',
      name: 'Susu Kedelai Murni Tanpa Gula',
      type: 'drink',
      mealTime: 'Minuman',
      category: 'Minuman',
      calories: 80,
      protein: 7.0,
      carbs: 6.0,
      fat: 3.5,
      portionGram: 220,
      pills: ['Tinggi Protein', 'Isoflavon', 'Bebas Laktosa'],
      thumbImg: 'assets/progress/nutrition/drink_infused_lemon.png',
      heroImg: 'assets/progress/nutrition/hero_infused_lemon.png',
      hasCustomPhoto: false,
      desc: 'Susu nabati kaya protein murni dan bebas laktosa.',
      detailDesc:
          'Susu kedelai perasan murni tanpa penambahan gula pasir, beraroma daun pandan wangi. Sangat kaya protein nabati, kalsium, dan isoflavon yang menyehatkan jantung.',
      benefits: [
        'Alternatif susu bebas laktosa ramah bagi pencernaan.',
        'Isoflavon kedelai membantu regulasi lipid dan kepadatan tulang.',
        'Memberikan rasa kenyang sehat di sela jam makan.',
      ],
      categoryIcon: Icons.coffee_rounded,
      categoryBg: Color(0xFFE0F2FE),
      categoryText: Color(0xFF0284C7),
    ),

    // 6. Air Rebusan Jahe Merah & Serai Hangat
    const NutritionMealModel(
      id: 'drink_wedang_jahe',
      name: 'Air Jahe Merah & Serai Hangat',
      type: 'drink',
      mealTime: 'Minuman',
      category: 'Minuman',
      calories: 5,
      protein: 0.1,
      carbs: 1.2,
      fat: 0.0,
      portionGram: 250,
      pills: ['Anti-Inflamasi', 'Hangat di Perut', '0 Gula'],
      thumbImg: 'assets/progress/nutrition/drink_jahe_serai.jpg',
      heroImg: 'assets/progress/nutrition/drink_jahe_serai.jpg',
      hasCustomPhoto: true,
      desc: 'Gingerol alami melancarkan sirkulasi darah dan redakan kembung.',
      detailDesc:
          'Rebusan rimpang jahe merah geprek bersama batang serai wangi dan kayu manis. Menghangatkan rongga dada, meredakan ketegangan otot, dan melancarkan pencernaan.',
      benefits: [
        'Senyawa bioaktif gingerol menekan peradangan dan nyeri sendi.',
        'Meredakan rasa mual, kembung, dan rasa tidak nyaman di lambung.',
        'Bebas kalori sehingga tidak menambah beban energi malam.',
      ],
      categoryIcon: Icons.nightlight_round,
      categoryBg: Color(0xFFF3E8FF),
      categoryText: Color(0xFF7C3AED),
    ),

    // 7. Air Kelapa Murni Alami
    const NutritionMealModel(
      id: 'drink_air_kelapa',
      name: 'Air Kelapa Muda Murni',
      type: 'drink',
      mealTime: 'Minuman',
      category: 'Minuman',
      calories: 45,
      protein: 1.0,
      carbs: 10.0,
      fat: 0.2,
      portionGram: 250,
      pills: ['Isotonik Alami', 'Kaya Elektrolit', 'Bebas Sirup'],
      thumbImg: 'assets/progress/nutrition/drink_kelapa_muda.jpg',
      heroImg: 'assets/progress/nutrition/drink_kelapa_muda.jpg',
      hasCustomPhoto: true,
      desc: 'Isotonik alami penyeimbang elektrolit dan hidrasi sel.',
      detailDesc:
          'Air kelapa muda segar murni langsung dari batok kelapa tanpa sirup atau pemanis. Mengandung kalium, natrium alami, dan magnesium untuk rehidrasi tubuh.',
      benefits: [
        'Kandungan elektrolit alami menggantikan cairan tubuh secara cepat.',
        'Mengandung sitokinin alami sebagai antioksidan anti-penuaan.',
        'Rendah gula dan sangat ringan di lambung.',
      ],
      categoryIcon: Icons.wb_sunny_rounded,
      categoryBg: Color(0xFFFFEDD5),
      categoryText: Color(0xFFEA580C),
    ),
  ];

  // =======================================================================
  // ALGORITMA DETERMINISTIK PENYUSUNAN MENU HARIAN
  // =======================================================================

  /// Menghasilkan 5 menu harian (Sarapan, Makan Siang, Makan Malam, Cemilan, Minuman)
  /// secara deterministik berdasarkan tanggal dan kategori skrining pengguna.
  ///
  /// KETENTUAN UTAMA:
  /// 1. Tanggal yang sama -> selalu menu yang sama.
  /// 2. Tanggal berbeda -> menu berbeda (rotasi deterministik, tanpa pengulangan berturut-turut).
  /// 3. Total kalori sehari (makanan + minuman) berada dalam batas toleransi ±5% dari target:
  ///    - Underweight: 1.950 kkal (rentang aman ±5%: 1.852 - 2.047 kkal)
  ///    - Normal / Obesitas: 1.700 kkal (rentang aman ±5%: 1.615 - 1.785 kkal)
  ///    Bahkan saat menu minuman berkalori rendah (0-8 kkal), totalnya tetap presisi ±5%.
  static List<NutritionMealModel> getDailyPlanForDate({
    required DateTime date,
    required ScreeningCalorieGroup group,
  }) {
    final targetCalories = CalorieTargetService.getDailyCalorieTarget(group);
    final isUnderweight = group == ScreeningCalorieGroup.underweight;

    // Indeks hari berkelanjutan untuk rotasi tanpa berulang berturut-turut
    final dayContinuous = (date.difference(DateTime(2020, 1, 1)).inDays).abs();

    // 1. Pilih Sarapan (Rotasi dari 7 pilihan)
    final bIndex = (dayContinuous + group.index) % _breakfastPool.length;
    final rawBreakfast = _breakfastPool[bIndex];

    // 2. Pilih Makan Siang (Offset +1 agar tidak sama polanya dengan sarapan)
    final lIndex = (dayContinuous * 2 + 1 + group.index) % _lunchPool.length;
    final rawLunch = _lunchPool[lIndex];

    // 3. Pilih Makan Malam (Offset +3)
    final dIndex = (dayContinuous * 3 + 2 + group.index) % _dinnerPool.length;
    final rawDinner = _dinnerPool[dIndex];

    // 4. Pilih Minuman (Offset +4)
    final drIndex = (dayContinuous * 5 + 3 + group.index) % _drinkPool.length;
    final rawDrink = _drinkPool[drIndex];

    // 5. Pilih Cemilan (Offset +5)
    final snIndex = (dayContinuous * 7 + 4 + group.index) % _snackPool.length;
    final rawSnack = _snackPool[snIndex];

    // SKALA PORSI DAN KALORI MENURUT KATEGORI PENGGUNA
    // Normal / Obesitas: Target 1.700 kkal
    // Underweight: Target 1.950 kkal (Faktor skala ~1.147x, diutamakan tinggi protein)
    final scaleFactor = isUnderweight ? (1950.0 / 1700.0) : 1.0;

    // Hitung porsi terkalibrasi untuk menu utama & minuman
    final breakfast = _scaleMeal(rawBreakfast, scaleFactor, isUnderweight);
    final lunch = _scaleMeal(rawLunch, scaleFactor, isUnderweight);
    final dinner = _scaleMeal(rawDinner, scaleFactor, isUnderweight);
    final drink = _scaleMeal(rawDrink, 1.0, isUnderweight); // Minuman tetap alami

    // Sisa kalori yang dibutuhkan untuk cemilan agar total 5 menu tepat = target kalori (±0%)
    final subTotal = breakfast.calories + lunch.calories + dinner.calories + drink.calories;
    final neededSnackCalories = targetCalories - subTotal;

    // Sesuaikan porsi cemilan agar total hari itu tepat sama dengan target
    final snack = _calibrateSnack(rawSnack, neededSnackCalories, isUnderweight);

    return [breakfast, lunch, dinner, snack, drink];
  }

  /// Menyesuaikan porsi gram dan kalori menu makanan
  static NutritionMealModel _scaleMeal(
    NutritionMealModel base,
    double factor,
    bool isUnderweight,
  ) {
    if ((factor - 1.0).abs() < 0.01) return base;

    final newCalories = (base.calories * factor).round();
    final newProtein = double.parse((base.protein * (isUnderweight ? factor * 1.08 : factor)).toStringAsFixed(1));
    final newCarbs = double.parse((base.carbs * factor).toStringAsFixed(1));
    final newFat = double.parse((base.fat * factor).toStringAsFixed(1));
    final newPortion = (base.portionGram * factor).round();

    // Perbarui teks takaran gram di pill
    final newPills = base.pills.map((pill) {
      // Ganti angka gram di pill bila ada format 'XXXg'
      final reg = RegExp(r'(\d+)\s*g');
      return pill.replaceAllMapped(reg, (match) {
        final val = int.tryParse(match.group(1) ?? '') ?? 0;
        final scaled = (val * factor).round();
        return '${scaled}g';
      });
    }).toList();

    return NutritionMealModel(
      id: base.id,
      name: base.name,
      type: base.type,
      mealTime: base.mealTime,
      category: base.category,
      calories: newCalories,
      protein: newProtein,
      carbs: newCarbs,
      fat: newFat,
      portionGram: newPortion,
      pills: newPills,
      thumbImg: base.thumbImg,
      heroImg: base.heroImg,
      desc: base.desc,
      detailDesc: base.detailDesc,
      benefits: base.benefits,
      targetCategory: isUnderweight ? 'underweight' : 'normal',
      categoryIcon: base.categoryIcon,
      categoryBg: base.categoryBg,
      categoryText: base.categoryText,
      hasCustomPhoto: base.hasCustomPhoto,
    );
  }

  /// Mengalibrasi porsi cemilan agar menutup selisih kalori hari itu secara presisi
  static NutritionMealModel _calibrateSnack(
    NutritionMealModel base,
    int targetCalorie,
    bool isUnderweight,
  ) {
    final safeTarget = targetCalorie.clamp(90, 260);
    final ratio = safeTarget / (base.calories > 0 ? base.calories : 150);

    final newProtein = double.parse((base.protein * ratio).toStringAsFixed(1));
    final newCarbs = double.parse((base.carbs * ratio).toStringAsFixed(1));
    final newFat = double.parse((base.fat * ratio).toStringAsFixed(1));
    final newPortion = (base.portionGram * ratio).round();

    final newPills = base.pills.map((pill) {
      final reg = RegExp(r'(\d+)\s*g');
      return pill.replaceAllMapped(reg, (match) {
        final val = int.tryParse(match.group(1) ?? '') ?? 0;
        final scaled = (val * ratio).round();
        return '${scaled}g';
      });
    }).toList();

    return NutritionMealModel(
      id: base.id,
      name: base.name,
      type: base.type,
      mealTime: base.mealTime,
      category: base.category,
      calories: safeTarget,
      protein: newProtein,
      carbs: newCarbs,
      fat: newFat,
      portionGram: newPortion,
      pills: newPills,
      thumbImg: base.thumbImg,
      heroImg: base.heroImg,
      desc: base.desc,
      detailDesc: base.detailDesc,
      benefits: base.benefits,
      targetCategory: isUnderweight ? 'underweight' : 'normal',
      categoryIcon: base.categoryIcon,
      categoryBg: base.categoryBg,
      categoryText: base.categoryText,
      hasCustomPhoto: base.hasCustomPhoto,
    );
  }

  /// Master list seluruh 35 menu makanan dan minuman rekomendasi ObeSight
  static List<NutritionMealModel> get allMasterMeals => [
    ..._breakfastPool,
    ..._lunchPool,
    ..._dinnerPool,
    ..._snackPool,
    ..._drinkPool,
  ];

  /// Mengambil objek menu berdasarkan id uniknya dari master pool
  static NutritionMealModel? getMealById(String id) {
    for (final meal in allMasterMeals) {
      if (meal.id == id) return meal;
    }
    return null;
  }
}
