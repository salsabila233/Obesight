import 'package:flutter/material.dart';
import '../models/article_model.dart';

class ArticleService {
  static final ArticleService _instance = ArticleService._internal();
  factory ArticleService() => _instance;
  ArticleService._internal();

  final List<ArticleModel> _articles = const [
    ArticleModel(
      id: 1,
      title: 'Porsi piring gizi seimbang',
      snippet: 'Panduan takaran proporsional Isi Piringku untuk memenuhi kebutuhan gizi seimbang harian.',
      date: '21 September 2026',
      readTime: '4 Menit Baca',
      headerColor: Color(0xFFE5BD87),
      icon: Icons.pie_chart_outline_rounded,
      imageAsset: 'assets/articles/article_porsi_piring_gizi_seimbang.jpg',
      content:
          'Konsep "Isi Piringku" merupakan panduan sajian makanan sehat yang dicetuskan oleh Kementerian Kesehatan Republik Indonesia untuk membantu masyarakat mengontrol porsi dan kualitas gizi makanan sehari-hari.\n\n'
          'Dalam satu piring makan, porsi dibagi menjadi beberapa bagian utama:\n'
          '1. Makanan Pokok (Karbohidrat): Mengisi sepertiga (1/3) dari piring makan. Utamakan sumber karbohidrat kompleks seperti nasi merah, jagung, kentang rebus, atau ubi jalar yang kaya serat.\n\n'
          '2. Sayuran: Mengisi sepertiga (1/3) dari piring makan. Sayuran hijau dan berwarna seperti bayam, brokoli, wortel, dan buncis menyediakan vitamin, mineral, serta serat untuk kelancaran pencernaan.\n\n'
          '3. Lauk-Pauk (Protein): Mengisi seperenam (1/6) dari piring makan. Pilih sumber protein hewani atau nabati rendah lemak jenuh seperti ikan, tempe, tahu, dada ayam tanpa kulit, atau telur.\n\n'
          '4. Buah-buahan: Mengisi seperenam (1/6) dari piring makan sebagai sumber antioksidan, vitamin alami, dan pemanis alami pengganti gula buatan.\n\n'
          'Selain mengatur komposisi piring, lengkapi kebiasaan sehat dengan minum air putih minimal 8 gelas setiap hari, mencuci tangan dengan sabun sebelum makan, dan beraktivitas fisik secara rutin.',
      takeaways: [
        'Setengah piring makan terdiri dari kombinasi sayuran dan buah-buahan segar.',
        'Pilihlah karbohidrat kompleks dengan indeks glikemik lebih rendah untuk menjaga rasa kenyang.',
        'Batasi asupan Gula, Garam, dan Lemak (GGL) dalam pengolahan hidangan harian.',
        'Penuhi kebutuhan hidrasi tubuh dengan minum air putih minimal 2 liter per hari.',
      ],
    ),
    ArticleModel(
      id: 2,
      title: '5 pola makan',
      snippet: 'Lima prinsip pola makan sehat untuk mengontrol berat badan dan menjaga metabolisme tubuh.',
      date: '20 September 2026',
      readTime: '5 Menit Baca',
      headerColor: Color(0xFF7E96AC),
      icon: Icons.restaurant_menu_rounded,
      imageAsset: 'assets/articles/article_5_pola_makan.jpg',
      content:
          'Menjaga berat badan ideal dan mencegah obesitas bermula dari kebiasaan makan sehari-hari yang terencana dan disiplin. Berikut adalah 5 pola makan yang efektif diterapkan:\n\n'
          '1. Jadwalkan Waktu Makan Secara Teratur\n'
          'Makan pada jam yang konsisten setiap hari membantu tubuh mengatur siklus metabolisme dan mencegah rasa lapar berlebih yang memicu keinginan makan berlebihan pada waktu berikutnya.\n\n'
          '2. Utamakan Makanan Utuh (Whole Foods)\n'
          'Perbanyak konsumsi makanan utuh yang belum mengalami banyak proses industri (minimally processed). Biji-bijian utuh, kacang-kacangan, sayur, dan buah kaya akan nutrisi alami dan serat tinggi.\n\n'
          '3. Terapkan Mindful Eating\n'
          'Makanlah secara perlahan dan kunyah setiap suapan dengan baik (20-30 kali). Hindari makan sambil menonton TV atau bermain gawai agar otak dapat menerima sinyal kenyang tepat waktu.\n\n'
          '4. Kendalikan Ukuran Porsi\n'
          'Gunakan piring berukuran sedang atau lebih kecil untuk membantu mengontrol porsi secara visual tanpa merasa kekurangan makanan.\n\n'
          '5. Batasi Camilan Olahan Tinggi Gula dan Garam\n'
          'Ganti camilan manis atau gorengan dengan pilihan padat nutrisi seperti buah potong, kacang almond panggang, atau yogurt tawar.',
      takeaways: [
        'Makan dengan jadwal teratur mencegah lonjakan rasa lapar mendadak.',
        'Mengunyah secara perlahan memberi waktu otak untuk merespons sinyal kenyang lambung.',
        'Pilih camilan sehat dan hindari minuman manis berpemanis buatan.',
        'Kendalikan porsi makan dengan piring yang proporsional.',
      ],
    ),
    ArticleModel(
      id: 3,
      title: 'Pentingnya kualitas tidur',
      snippet: 'Hubungan penting antara tidur berkualitas dan regulasi hormon pengatur nafsu makan.',
      date: '19 September 2026',
      readTime: '4 Menit Baca',
      headerColor: Color(0xFF818CF8),
      icon: Icons.nightlight_round,
      imageAsset: 'assets/articles/article_kualitas_tidur.jpg',
      content:
          'Tidur bukan sekadar waktu istirahat pasif, melainkan periode penting bagi tubuh untuk meregenerasi sel, memulihkan energi, dan menyeimbangkan hormon pengatur metabolisme.\n\n'
          'Saat seseorang kurang tidur atau mengalami gangguan tidur kronis, produksi hormon Ghrelin (hormon pemicu rasa lapar) akan meningkat tajam. Di saat yang sama, hormon Leptin (hormon pemberi rasa kenyang) mengalami penurunan drastis.\n\n'
          'Kondisi ketidakseimbangan hormon ini menyebabkan seseorang merasa lebih cepat lapar, sulit merasa kenyang, dan memiliki dorongan kuat untuk mengonsumsi makanan manis, gurih, dan berkarbohidrat tinggi sepanjang hari.\n\n'
          'Untuk menjaga kualitas tidur yang optimal:\n'
          '• Targetkan durasi tidur 7–8 jam per malam untuk orang dewasa.\n'
          '• Hindari paparan cahaya biru dari layar gawai minimal 30 menit sebelum tidur.\n'
          '• Jaga suhu kamar tidur tetap sejuk, nyaman, dan minim cahaya.\n'
          '• Batasi konsumsi kafein dan hindari makan berat menjelang jam tidur.',
      takeaways: [
        'Tidur 7–8 jam setiap malam menjaga keseimbangan hormon nafsu makan (ghrelin dan leptin).',
        'Kurang tidur memicu metabolisme lambat dan rasa ingin mengonsumsi makanan tinggi kalori.',
        'Terapkan sleep hygiene dengan membatasi penggunaan gawai menjelang waktu istirahat.',
      ],
    ),
    ArticleModel(
      id: 4,
      title: 'Obesitas sebagai pemicu komplikasi',
      snippet: 'Memahami bagaimana kelebihan lemak tubuh dapat memicu berbagai risiko penyakit metabolik.',
      date: '18 September 2026',
      readTime: '5 Menit Baca',
      headerColor: Color(0xFF94A3B8),
      icon: Icons.medical_services_outlined,
      imageAsset: 'assets/articles/article_obesitas_komplikasi.jpg',
      content:
          'Obesitas merupakan penyakit metabolik kronis yang ditandai dengan penumpukan jaringan lemak berlebih, terutama di sekitar area rongga perut (lemak viseral).\n\n'
          'Jaringan lemak viseral yang berlebihan bukan hanya cadangan energi, melainkan organ endokrin aktif yang terus-menerus melepaskan zat kimia pemicu peradangan (sitokin pro-inflamasi). Hal ini menyebabkan terjadinya resistensi insulin di dalam jaringan otot dan hati.\n\n'
          'Beberapa komplikasi kesehatan utama yang dipicu oleh obesitas meliputi:\n'
          '1. Diabetes Melitus Tipe 2 akibat resistensi insulin yang berkepanjangan.\n'
          '2. Hipertensi dan Penyakit Jantung Koroner akibat beban kerja pompa jantung yang meningkat dan penumpukan plak di pembuluh darah.\n'
          '3. Perlemakan Hati Non-Alkoholik (NAFLD) yang dapat mengganggu fungsi organ hati.\n'
          '4. Gangguan Pernapasan saat Tidur (Sleep Apnea) yang menurunkan suplai oksigen malam hari.\n'
          '5. Masalah Sendi dan Nyeri Lutut (Osteoartritis) akibat beban tumpuan tubuh yang berlebih.\n\n'
          'Penurunan berat badan sebesar 5% sampai 10% dari berat badan awal terbukti secara klinis mampu menurunkan risiko komplikasi ini secara signifikan.',
      takeaways: [
        'Obesitas memicu peradangan kronis dan resistensi insulin dalam tubuh.',
        'Komplikasi meliputi diabetes tipe 2, penyakit kardiovaskular, dan perlemakan hati.',
        'Penurunan berat badan bertahap sebesar 5–10% memberikan proteksi kesehatan yang besar.',
        'Lakukan skrining risiko dan konsultasikan kondisi kesehatan Anda secara berkala.',
      ],
    ),
    ArticleModel(
      id: 5,
      title: 'Aktivitas fisik ringan',
      snippet: 'Gerakan aktif harian sederhana yang efektif membakar kalori dan meningkatkan kebugaran.',
      date: '17 September 2026',
      readTime: '4 Menit Baca',
      headerColor: Color(0xFF58B29C),
      icon: Icons.directions_run_rounded,
      imageAsset: 'assets/articles/article_aktivitas_fisik_ringan.jpg',
      content:
          'Memulai kebiasaan hidup aktif tidak selalu memerlukan latihan beban berat di gym. Aktivitas fisik ringan yang dilakukan secara konsisten setiap hari memiliki kontribusi besar dalam pembakaran kalori harian (NEAT - Non-Exercise Activity Thermogenesis).\n\n'
          'Beberapa contoh aktivitas fisik ringan yang mudah diterapkan:\n'
          '• Jalan Kaki Santai atau Cepat: Melakukan jalan kaki selama 30 menit sehari (setara 3.000–5.000 langkah) membantu membakar sekitar 150–200 kalori dan melancarkan sirkulasi darah.\n'
          '• Menggunakan Tangga: Memilih tangga daripada lift untuk 1–2 lantai dapat mengaktifkan otot kaki dan meningkatkan detak jantung secara bertahap.\n'
          '• Peregangan di Sela Kerja: Berdiri dan lakukan peregangan ringan setiap 45–60 menit duduk bekerja di meja.\n'
          '• Pekerjaan Rumah Tangga: Menyapu, mengepel, atau merawat tanaman di pekarangan juga termasuk aktivitas fisik yang produktif.\n\n'
          'Kombinasikan kebiasaan aktif ini dengan olahraga teratur minimal 150 menit per minggu untuk memperoleh tubuh yang bugar dan bertenaga.',
      takeaways: [
        'Aktivitas fisik ringan membantu meningkatkan pembakaran kalori tanpa membebani tubuh.',
        'Jalan kaki 30 menit per hari melancarkan aliran darah dan meningkatkan sensitivitas insulin.',
        'Hindari duduk diam berjam-jam tanpa jeda bergerak.',
        'Pilih aktivitas yang menyenangkan agar dapat dipertahankan menjadi rutinitas.',
      ],
    ),
    ArticleModel(
      id: 6,
      title: 'Yuk kenali pola hidup sehat',
      snippet: 'Langkah terintegrasi membangun kebiasaan hidup sehat yang berkesinambungan dan bahagia.',
      date: '16 September 2026',
      readTime: '3 Menit Baca',
      headerColor: Color(0xFF489874),
      icon: Icons.favorite_outline_rounded,
      imageAsset: 'assets/articles/article_kenali_pola_hidup_sehat.jpg',
      content:
          'Menerapkan pola hidup sehat adalah sebuah perjalanan berkelanjutan untuk merawat tubuh dan pikiran, bukan sekadar program diet ketat yang membatasi segalanya secara ekstrem.\n\n'
          'Empat pilar utama pola hidup sehat yang seimbang:\n'
          '1. Nutrisi Seimbang: Mengonsumsi makanan bergizi lengkap, memperhatikan proporsi piring makan, dan membatasi makanan olahan tinggi lemak serta gula.\n\n'
          '2. Aktivitas Fisik Rutin: Melakukan olahraga teratur dan memperbanyak gerak aktif setiap hari untuk melatih fungsi jantung dan otot.\n\n'
          '3. Istirahat dan Regenerasi: Memastikan waktu tidur yang cukup dan berkualitas agar hormon tubuh tetap seimbang.\n\n'
          '4. Manajemen Stres dan Ketenangan Mental: Luangkan waktu untuk relaksasi, meditasi, menyalurkan hobi, atau berkumpul bersama keluarga untuk menurunkan kadar hormon stres (kortisol).\n\n'
          'Mulailah dari satu perubahan kecil hari ini. Konsistensi kecil yang dilakukan setiap hari akan menghasilkan transformasi kesehatan yang luar biasa.',
      takeaways: [
        'Pola hidup sehat merupakan kombinasi dari nutrisi, olahraga, istirahat, dan kesehatan mental.',
        'Fokus pada konsistensi kebiasaan sehari-hari daripada hasil instan.',
        'Kelola stres dengan baik untuk mencegah emotional eating dan kelelahan kronis.',
        'Catat dan rayakan setiap pencapaian kesehatan Anda.',
      ],
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

  List<ArticleModel> searchArticles(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return _articles;
    return _articles.where((art) {
      return art.title.toLowerCase().contains(q);
    }).toList();
  }
}
