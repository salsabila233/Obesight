import 'package:flutter/material.dart';
import '../models/article_model.dart';

class ArticleService {
  static final ArticleService _instance = ArticleService._internal();
  factory ArticleService() => _instance;
  ArticleService._internal();

  final List<ArticleModel> _articles = const [
    ArticleModel(
      id: 1,
      title: '5 Pola Makan Sehat Cegah Obesitas',
      category: 'Pola Makan & Nutrisi',
      snippet: 'Kenali kebiasaan makan yang tanpa disadari meningkatkan risiko berat badan berlebih dan cara mengatasinya.',
      author: 'Dr. Hendra Wijaya, Sp.GK',
      date: '21 September 2026',
      readTime: '4 Menit Baca',
      headerColor: Color(0xFF7E96AC),
      icon: Icons.restaurant_menu_rounded,
      content:
          'Menerapkan pola makan sehat merupakan fondasi utama dalam mencegah dan mengendalikan obesitas. Kebiasaan makan terburu-buru, konsumsi minuman manis kemasan, dan mengabaikan sinyal kenyang adalah faktor pemicu utama kenaikan berat badan.\n\n'
          'Untuk menjaga berat badan stabil, mulailah dengan membatasi konsumsi gula tambahan, garam berlebih, dan lemak jenuh (GGL). Pastikan Anda sarapan dengan asupan protein dan serat yang cukup agar rasa kenyang bertahan lebih lama hingga siang hari.\n\n'
          'Hindari makan sambil menatap layar gawai (mindless eating) karena hal ini membuat otak terlambat menerima sinyal kenyang, sehingga porsi makan cenderung berlebih.',
      takeaways: [
        'Hindari konsumsi kalori cair dari minuman berpemanis buatan dan bersoda.',
        'Makan secara perlahan dan kunyah minimal 20-30 kali per suapan.',
        'Jaga jam makan tetap teratur untuk menstabilkan ritme metabolisme tubuh.',
        'Penuhi kebutuhan air putih minimal 2 liter (8 gelas) sehari.',
      ],
      tags: ['Nutrisi', 'Diet', 'Pola Makan'],
    ),
    ArticleModel(
      id: 2,
      title: 'Porsi Piring Gizi Seimbang Kemenkes (Isi Piringku)',
      category: 'Panduan Gizi',
      snippet: 'Panduan praktis porsi gizi seimbang harian sesuai anjuran Kementerian Kesehatan RI.',
      author: 'Kementerian Kesehatan RI',
      date: '20 September 2026',
      readTime: '5 Menit Baca',
      headerColor: Color(0xFFE5BD87),
      icon: Icons.pie_chart_outline_rounded,
      content:
          'Konsep "Isi Piringku" menggantikan slogan lama 4 Sehat 5 Sempurna dengan penekanan pada porsi makanan yang proporsional dalam satu piring makan.\n\n'
          'Pembagian Isi Piringku untuk makanan utama:\n'
          '1. Makanan Pokok (Karbohidrat Kompleks): 1/3 bagian dari piring, seperti nasi merah, kentang, jagung, atau ubi.\n'
          '2. Sayur-mayur: 1/3 bagian dari piring sebagai sumber serat, vitamin, dan mineral alami.\n'
          '3. Lauk-pauk (Protein): 1/6 bagian dari piring, prioritaskan ikan, telur, tahu, tempe, atau dada ayam tanpa kulit.\n'
          '4. Buah-buahan: 1/6 bagian dari piring sebagai antioksidan alami.\n\n'
          'Penerapan porsi ini membantu mencegah penumpukan kalori berlebih dan menjaga kestabilan kadar glukosa darah.',
      takeaways: [
        'Separuh dari piring makan Anda harus diisi oleh sayuran dan buah-buahan segar.',
        'Pilihlah sumber karbohidrat kompleks dengan indeks glikemik rendah.',
        'Batasi anjuran G4-G1-L5: Gula 4 sendok makan, Garam 1 sendok teh, Lemak 5 sendok makan per hari.',
      ],
      tags: ['Isi Piringku', 'Kemenkes', 'Gizi Seimbang'],
    ),
    ArticleModel(
      id: 3,
      title: 'Aktivitas Fisik Ringan Pembakar Kalori',
      category: 'Aktivitas Fisik',
      snippet: 'Kebiasaan aktif harian sederhana yang efektif membakar kalori tanpa harus ke tempat gym.',
      author: 'Tim Medis ObeSight',
      date: '19 September 2026',
      readTime: '4 Menit Baca',
      headerColor: Color(0xFF58B29C),
      icon: Icons.directions_run_rounded,
      content:
          'Tidak perlu langsung memulai olahraga berat jika Anda baru memulai perjalanan hidup sehat. Non-Exercise Activity Thermogenesis (NEAT) atau pembakaran kalori dari aktivitas non-olahraga harian memiliki dampak yang sangat besar.\n\n'
          'Berjalan kaki 30 menit sehari (setara 3.000–5.000 langkah) dapat membakar sekitar 150-200 kalori. Memilih naik tangga dibanding lift, berjalan saat menelepon, dan melakukan peregangan ringan setiap 45 menit saat bekerja di meja dapat melancarkan sirkulasi darah serta membakar ekstra kalori.\n\n'
          'Kombinasikan dengan olahraga teratur 150 menit per minggu untuk hasil optimal.',
      takeaways: [
        'Targetkan minimal 7.000 langkah setiap hari secara bertahap.',
        'Jangan duduk diam lebih dari 60 menit berturut-turut.',
        'Jadikan jalan kaki cepat sebagai rutinitas pagi atau sore hari.',
      ],
      tags: ['Aktivitas', 'Olahraga', 'Kebugaran'],
    ),
    ArticleModel(
      id: 4,
      title: 'Obesitas Sebagai Pemicu Komplikasi Medis',
      category: 'Klinis & Medis',
      snippet: 'Memahami bagaimana peradangan kronis akibat lemak berlebih memicu penyakit metabolik.',
      author: 'dr. Nurul Aisyah, M.Kes',
      date: '18 September 2026',
      readTime: '5 Menit Baca',
      headerColor: Color(0xFF94A3B8),
      icon: Icons.medical_services_outlined,
      content:
          'Obesitas bukan sekadar permasalahan estetika atau penampilan luar, melainkan penyakit metabolik kronis yang memerlukan penanganan terarah.\n\n'
          'Akumulasi jaringan adiposa (lemak) berlebih, terutama lemak viseral di sekitar organ perut, melepaskan sitokin pro-inflamasi secara konstan. Hal ini menyebabkan resistensi insulin, yang merupakan awal mula terjadinya Diabetes Melitus Tipe 2, hipertensi, dislipidemia (kolesterol tinggi), hingga penyakit jantung koroner.\n\n'
          'Kabar baiknya, penurunan berat badan sebesar 5-10% dari berat badan awal sudah terbukti secara klinis mampu menurunkan risiko komplikasi ini secara drastis.',
      takeaways: [
        'Deteksi dini IMT dan lingkar perut secara berkala sangat krusial.',
        'Penurunan berat badan 5-10% memberikan proteksi kardiovaskular yang sangat signifikan.',
        'Konsultasikan ke dokter spesialis gizi klinis jika IMT Anda berada di kategori obesitas.',
      ],
      tags: ['Medis', 'Komplikasi', 'Resistensi Insulin'],
    ),
    ArticleModel(
      id: 5,
      title: 'Yuk, Kenali Pola Hidup Sehat Sehari-hari',
      category: 'Gaya Hidup',
      snippet: 'Langkah mudah membangun kebiasaan hidup sehat yang berkesinambungan dan menyenangkan.',
      author: 'Tim Edukasi ObeSight',
      date: '17 September 2026',
      readTime: '3 Menit Baca',
      headerColor: Color(0xFF489874),
      icon: Icons.favorite_outline_rounded,
      content:
          'Membangun gaya hidup sehat tidak harus dimulai dari perubahan ekstrem yang menyiksa. Perubahan kecil yang dilakukan secara konsisten jauh lebih berhasil membawa dampak positif jangka panjang.\n\n'
          'Tiga pilar utama hidup sehat:\n'
          '1. Nutrisi: Pilihlah makanan utuh (whole foods) dan kurangi makanan olahan ultra (ultra-processed food).\n'
          '2. Gerak: Temukan jenis olahraga yang Anda sukai, seperti bersepeda santai, yoga, renang, atau jogging.\n'
          '3. Istirahat: Tidur berkualitas 7–8 jam setiap malam membantu menyeimbangkan hormon leptin dan ghrelin yang mengontrol rasa lapar dan kenyang.',
      takeaways: [
        'Fokus pada konsistensi kebiasaan daripada kesempurnaan sesaat.',
        'Kelola stres melalui relaksasi dan istirahat yang cukup.',
        'Catat perkembangan berat badan dan aktivitas harian di aplikasi ObeSight.',
      ],
      tags: ['Gaya Hidup', 'Tips', 'Pola Sehat'],
    ),
    ArticleModel(
      id: 6,
      title: 'Pentingnya Kualitas Tidur untuk Mengatur Berat Badan',
      category: 'Gaya Hidup',
      snippet: 'Bagaimana kurang tidur dapat meningkatkan nafsu makan dan menghambat penurunan berat badan.',
      author: 'Dr. Hendra Wijaya, Sp.GK',
      date: '15 September 2026',
      readTime: '4 Menit Baca',
      headerColor: Color(0xFF818CF8),
      icon: Icons.nightlight_round,
      content:
          'Kurang tidur merupakan salah satu faktor tersembunyi yang sering menggagalkan usaha penurunan berat badan. Saat tubuh kurang istirahat, produksi hormon ghrelin (pemicu rasa lapar) meningkat, sementara hormon leptin (pemberi sinyal kenyang) menurun drastis.\n\n'
          'Akibatnya, Anda akan merasa lebih lapar dan cenderung mengidam makanan tinggi gula serta karbohidrat olahan pada siang dan malam hari.\n\n'
          'Terapkan sleep hygiene yang baik: matikan gawai 30 menit sebelum tidur, buat kamar tidur sejuk dan gelap, serta hindari kafein setelah pukul 3 sore.',
      takeaways: [
        'Tidur 7-8 jam per malam untuk menyeimbangkan hormon nafsu makan.',
        'Hindari makan berat 2-3 jam sebelum waktu tidur.',
        'Buat rutinitas tidur yang konsisten setiap hari.',
      ],
      tags: ['Tidur', 'Hormon', 'Metabolisme'],
    ),
  ];

  List<ArticleModel> getArticles() => _articles;

  List<ArticleModel> getFeaturedArticles() => _articles.take(4).toList();

  ArticleModel? getArticleById(int id) {
    try {
      return _articles.firstWhere((art) => art.id == id);
    } catch (_) {
      return null;
    }
  }

  List<ArticleModel> searchArticles(String query, {String? category}) {
    final q = query.trim().toLowerCase();
    return _articles.where((art) {
      final matchesQuery = q.isEmpty ||
          art.title.toLowerCase().contains(q) ||
          art.snippet.toLowerCase().contains(q) ||
          art.category.toLowerCase().contains(q) ||
          art.tags.any((tag) => tag.toLowerCase().contains(q));

      final matchesCategory = category == null ||
          category.isEmpty ||
          category == 'Semua' ||
          art.category.toLowerCase() == category.toLowerCase();

      return matchesQuery && matchesCategory;
    }).toList();
  }
}
