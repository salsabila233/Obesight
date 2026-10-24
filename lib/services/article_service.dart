import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/article_model.dart';

class ArticleService {
  static final ArticleService _instance = ArticleService._internal();
  factory ArticleService() => _instance;

  ArticleService._internal() {
    _initFirestoreListener();
  }

  /// 6 Data Artikel Awal Default (Persis sesuai dengan desain dan mockup ObeSight)
  static final List<ArticleModel> _initialArticles = [
    ArticleModel(
      id: 'article_1',
      title: '5 Pola Makan Penyebab Obesitas',
      snippet: 'Kenali Kebiasaan makan yang tanpa disadari meningkatkan resiko berat badan berlebih',
      date: '19 Oktober 2022',
      readTime: '5 Menit Baca',
      headerColor: const Color(0xFF7E96AC),
      icon: Icons.restaurant_menu_rounded,
      imageAsset: 'assets/articles/article_5_pola_makan.jpg',
      category: 'Pola Makan',
      author: 'Tim Medis ObeSight',
      isPublished: true,
      publishedAt: DateTime(2022, 10, 19, 8, 0),
      updatedAt: DateTime(2022, 10, 19, 8, 0),
      content:
          'Dalam penurunan berat badan, mengatur pola makan merupakan faktor paling penting yang harus diperhatikan oleh seseorang. Hal ini dikarenakan apabila pola makan yang buruk dan berlebihan, maka akan membuat penambahan berat badan terus berlanjut dan menyebabkan seseorang mengalami obesitas.\n\n'
          'Mengatur pola makan yang dimaksud adalah dengan memperhatikan kandungan gizi dan juga jumlah asupan yang masuk, sehingga kalori dalam tubuh tidak menumpuk dan menyebabkan tubuh memiliki timbunan lemak yang tidak sehat.\n\n'
          'Pola makan tidak sehat dapat menyebabkan tubuh menjadi obesitas. Berikut ini adalah beberapa pola makan yang dapat menjadi penyebab obesitas pada seseorang, diantaranya adalah sebagai:\n'
          '1. Banyak mengkonsumsi makanan gorengan, berlemak dan manis.\n'
          '2. Makan dalam jumlah yang banyak dan dalam jangka waktu yang singkat.\n'
          '3. Kurang makan sayur dan buah-buahan segar.\n'
          '4. Makan berlebihan atau dalam porsi yang terlalu besar.\n'
          '5. Sering ngemil makanan olahan tinggi garam dan gula di sela waktu makan.\n\n'
          'Tetap terapkan perilaku hidup sehat dengan menjaga pola makan gizi seimbang dan rutin melakukan aktivitas fisik minimal 30 menit setiap hari, agar tubuh tetap sehat dan terhindar dari bahaya obesitas.\n\n'
          'Segera lakukan konsultasi ke fasilitas pelayanan kesehatan atau nutrisionis apabila membutuhkan bantuan dalam proses pengaturan pola makan yang tepat.',
      takeaways: const [
        'Makan dengan jadwal teratur mencegah lonjakan rasa lapar mendadak.',
        'Mengunyah secara perlahan memberi waktu otak untuk merespons sinyal kenyang lambung.',
        'Pilih camilan sehat dan hindari minuman manis berpemanis buatan.',
        'Kendalikan porsi makan dengan piring yang proporsional.',
      ],
    ),
    ArticleModel(
      id: 'article_2',
      title: 'Obesitas Bukan Sekadar Masalah Penampilan',
      snippet: 'Pola hidup sehat sangat bermanfaat dimasa depan',
      date: '25 Oktober 2022',
      readTime: '4 Menit Baca',
      headerColor: const Color(0xFF818CF8),
      icon: Icons.nightlight_round,
      imageAsset: 'assets/articles/article_kualitas_tidur.jpg',
      category: 'Edukasi Kesehatan',
      author: 'Tim Medis ObeSight',
      isPublished: true,
      publishedAt: DateTime(2022, 10, 25, 8, 0),
      updatedAt: DateTime(2022, 10, 25, 8, 0),
      content:
          'Banyak orang mengira obesitas hanyalah persoalan estetika atau penampilan luar. Padahal, obesitas merupakan penyakit kronis kompleks yang berkaitan erat dengan berbagai gangguan metabolisme dan penurunan kualitas hidup jangka panjang.\n\n'
          'Kelebihan jaringan adiposa dalam tubuh bukan hanya sekadar penimbunan lemak pasif, melainkan jaringan endokrin aktif yang memicu proses inflamasi kronis tingkat rendah di seluruh tubuh.\n\n'
          'Pola hidup sehat yang diterapkan sejak dini menjadi investasi paling berharga untuk mencegah berbagai risiko komplikasi di masa depan.',
      takeaways: const [
        'Obesitas merupakan penyakit metabolik kronis, bukan sekadar masalah estetika.',
        'Perubahan gaya hidup kecil yang konsisten memberikan dampak kesehatan yang sangat besar.',
        'Jaga keseimbangan asupan nutrisi dan aktivitas harian secara terpadu.',
      ],
    ),
    ArticleModel(
      id: 'article_3',
      title: 'Isi Piringku: Cara Sederhana Mengatur Porsi Makan',
      snippet: 'Konsep 4 Sehat 5 Sempurna vs Isi Piringku',
      date: '05 November 2022',
      readTime: '4 Menit Baca',
      headerColor: const Color(0xFFE5BD87),
      icon: Icons.pie_chart_outline_rounded,
      imageAsset: 'assets/articles/article_porsi_piring_gizi_seimbang.jpg',
      category: 'Nutrisi & Gizi',
      author: 'Tim Medis ObeSight',
      isPublished: true,
      publishedAt: DateTime(2022, 11, 5, 8, 0),
      updatedAt: DateTime(2022, 11, 5, 8, 0),
      content:
          'Konsep "Isi Piringku" merupakan panduan sajian makanan sehat yang dicetuskan oleh Kementerian Kesehatan Republik Indonesia untuk membantu masyarakat mengontrol porsi dan kualitas gizi makanan sehari-hari.\n\n'
          'Dalam satu piring makan, porsi dibagi menjadi beberapa bagian utama:\n'
          '1. Makanan Pokok (Karbohidrat): Mengisi sepertiga (1/3) dari piring makan. Utamakan sumber karbohidrat kompleks seperti nasi merah, jagung, kentang rebus, atau ubi jalar yang kaya serat.\n\n'
          '2. Sayuran: Mengisi sepertiga (1/3) dari piring makan. Sayuran hijau dan berwarna menyediakan vitamin, mineral, serta serat untuk kelancaran pencernaan.\n\n'
          '3. Lauk-Pauk (Protein): Mengisi seperenam (1/6) dari piring makan. Pilih sumber protein hewani atau nabati rendah lemak jenuh seperti ikan, tempe, tahu, atau telur.\n\n'
          '4. Buah-buahan: Mengisi seperenam (1/6) dari piring makan sebagai sumber antioksidan alami.\n\n'
          'Lengkapi kebiasaan sehat dengan minum air putih minimal 8 gelas setiap hari dan beraktivitas fisik rutin.',
      takeaways: const [
        'Setengah piring makan terdiri dari kombinasi sayuran dan buah-buahan segar.',
        'Pilihlah karbohidrat kompleks dengan indeks glikemik lebih rendah untuk menjaga rasa kenyang.',
        'Batasi asupan Gula, Garam, dan Lemak (GGL) dalam pengolahan hidangan harian.',
      ],
    ),
    ArticleModel(
      id: 'article_4',
      title: '6 Manfaat Rutin Melakukan Aktivitas Fisik',
      snippet: 'Rutin bergerak membantu menjaga kesehatan tubuh.',
      date: '15 November 2022',
      readTime: '4 Menit Baca',
      headerColor: const Color(0xFF58B29C),
      icon: Icons.directions_run_rounded,
      imageAsset: 'assets/articles/article_aktivitas_fisik_ringan.jpg',
      category: 'Aktivitas Fisik',
      author: 'Tim Medis ObeSight',
      isPublished: false, // DRAFT: Hanya dapat dilihat oleh Admin
      publishedAt: DateTime(2022, 11, 15, 8, 0),
      updatedAt: DateTime(2022, 11, 15, 8, 0),
      content:
          'Aktivitas fisik secara rutin terbukti memberikan beragam manfaat luar biasa bagi tubuh dan kebugaran mental:\n\n'
          '1. Membantu Mengontrol dan Menurunkan Berat Badan\n'
          'Aktivitas fisik membakar kalori dan meningkatkan laju metabolisme basal tubuh.\n\n'
          '2. Menjaga Kesehatan Jantung dan Pembuluh Darah\n'
          'Gerakan teratur melatih elastisitas pembuluh darah dan menurunkan tekanan darah tinggi.\n\n'
          '3. Meningkatkan Sensitivitas Insulin\n'
          'Otot yang aktif menyerap glukosa darah lebih efektif, mencegah penumpukan gula darah.\n\n'
          '4. Memperkuat Tulang dan Otot\n'
          'Membantu mencegah pengeroposan tulang (osteoporosis) serta menjaga postur tubuh.\n\n'
          '5. Memperbaiki Kualitas Tidur\n'
          'Tubuh yang aktif di siang hari cenderung tidur lebih nyenyak di malam hari.\n\n'
          '6. Meredakan Stres dan Meningkatkan Mood\n'
          'Memicu pelepasan hormon endorfin dan serotonin yang memberikan rasa bahagia dan rileks.',
      takeaways: const [
        'Aktivitas fisik teratur membakar kalori dan melatih fungsi kardiovaskular.',
        'Membantu meningkatkan kebugaran jasmani dan ketenangan mental.',
        'Draf ini sedang disempurnakan sebelum dipublikasikan ke seluruh pengguna ObeSight.',
      ],
    ),
    ArticleModel(
      id: 'article_5',
      title: 'Cegah Obesitas dengan Pola Hidup Sehat',
      snippet: 'Kenali kebiasaan sederhana yang dapat menjaga berat badan',
      date: '17 November 2022',
      readTime: '3 Menit Baca',
      headerColor: const Color(0xFF489874),
      icon: Icons.favorite_outline_rounded,
      imageAsset: 'assets/articles/article_kenali_pola_hidup_sehat.jpg',
      category: 'Gaya Hidup',
      author: 'Tim Medis ObeSight',
      isPublished: true,
      publishedAt: DateTime(2022, 11, 17, 8, 0),
      updatedAt: DateTime(2022, 11, 17, 8, 0),
      content:
          'Menerapkan pola hidup sehat adalah sebuah perjalanan berkelanjutan untuk merawat tubuh dan pikiran, bukan sekadar program diet ketat yang membatasi segalanya secara ekstrem.\n\n'
          'Empat pilar utama pencegahan obesitas:\n'
          '1. Nutrisi Seimbang: Mengonsumsi makanan bergizi lengkap dan membatasi makanan olahan tinggi lemak serta gula.\n\n'
          '2. Aktivitas Fisik Rutin: Melakukan olahraga teratur minimal 150 menit per minggu.\n\n'
          '3. Istirahat Berkualitas: Memastikan waktu tidur 7-8 jam per malam.\n\n'
          '4. Manajemen Stres: Menghindari kebiasaan emotional eating saat menghadapi tekanan emosional.',
      takeaways: const [
        'Pola hidup sehat merupakan kombinasi dari nutrisi, olahraga, istirahat, dan kesehatan mental.',
        'Fokus pada konsistensi kebiasaan sehari-hari daripada hasil instan.',
      ],
    ),
    ArticleModel(
      id: 'article_6',
      title: 'Obesitas Sebagai Pemicu Komplikasi',
      snippet: 'Obesitas dapat meningkatkan risiko berbagai penyakit',
      date: '19 November 2022',
      readTime: '5 Menit Baca',
      headerColor: const Color(0xFF94A3B8),
      icon: Icons.medical_services_outlined,
      imageAsset: 'assets/articles/article_obesitas_komplikasi.jpg',
      category: 'Kesehatan Metabolik',
      author: 'Tim Medis ObeSight',
      isPublished: true,
      publishedAt: DateTime(2022, 11, 19, 8, 0),
      updatedAt: DateTime(2022, 11, 19, 8, 0),
      content:
          'Obesitas merupakan faktor risiko utama timbulnya berbagai penyakit kronis yang berbahaya. Lemak tubuh berlebih melepaskan senyawa kimia yang memicu inflamasi sistemik.\n\n'
          'Beberapa risiko komplikasi meliputi diabetes melitus tipe 2, hipertensi, perlemakan hati (fatty liver), osteoartritis, serta gangguan tidur sleep apnea.\n\n'
          'Dengan penurunan berat badan teratur sebesar 5-10%, risiko komplikasi penyakit tersebut dapat berkurang drastis.',
      takeaways: const [
        'Obesitas memicu peradangan kronis dan resistensi insulin dalam tubuh.',
        'Penurunan berat badan bertahap sebesar 5–10% memberikan proteksi kesehatan yang besar.',
      ],
    ),
  ];

  /// Cache memori aktif (dimulai dengan 6 data default agar UI langsung memiliki konten)
  List<ArticleModel> _cachedArticles = List.from(_initialArticles);

  /// Reactive Stream Controllers (Lazy & Static agar tidak pernah undefined saat hot reload)
  static StreamController<List<ArticleModel>>? _allArticlesController;
  static StreamController<List<ArticleModel>>? _publishedArticlesController;

  static StreamController<List<ArticleModel>> get _safeAllArticlesController {
    if (_allArticlesController == null || _allArticlesController!.isClosed) {
      _allArticlesController = StreamController<List<ArticleModel>>.broadcast();
    }
    return _allArticlesController!;
  }

  static StreamController<List<ArticleModel>> get _safePublishedArticlesController {
    if (_publishedArticlesController == null || _publishedArticlesController!.isClosed) {
      _publishedArticlesController = StreamController<List<ArticleModel>>.broadcast();
    }
    return _publishedArticlesController!;
  }

  void _notifyStreams() {
    try {
      _safeAllArticlesController.add(List.unmodifiable(_cachedArticles));
    } catch (e) {
      debugPrint('[ArticleService] _notifyStreams all notice: $e');
    }
    try {
      _safePublishedArticlesController.add(
        _cachedArticles.where((a) => a.isPublished).toList(),
      );
    } catch (e) {
      debugPrint('[ArticleService] _notifyStreams published notice: $e');
    }
  }

  bool _isListenerAttached = false;

  /// Memastikan Firestore listener terpasang saat Firebase siap
  void ensureInitialized() {
    if (_isListenerAttached) return;
    _initFirestoreListener();
  }

  void _initFirestoreListener() {
    if (_isListenerAttached) return;
    try {
      final articlesCol = FirebaseFirestore.instance.collection('articles');
      _isListenerAttached = true;
      articlesCol.snapshots().listen(
        (snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final parsedList = <ArticleModel>[];
            for (final doc in snapshot.docs) {
              try {
                parsedList.add(ArticleModel.fromFirestore(doc));
              } catch (err) {
                debugPrint('[ArticleService] Parsing error doc ${doc.id}: $err');
              }
            }

            parsedList.sort((a, b) {
              final aTime = a.updatedAt ?? a.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final bTime = b.updatedAt ?? b.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              return bTime.compareTo(aTime);
            });

            // Gabungkan artikel Firestore dengan cache lokal yang belum tersinkron
            for (final local in _cachedArticles) {
              if (!parsedList.any((p) => p.id == local.id)) {
                parsedList.add(local);
              }
            }

            _cachedArticles = parsedList;
            _notifyStreams();
          } else {
            _seedIfEmpty();
          }
        },
        onError: (e) {
          debugPrint('[ArticleService] Firestore listener error notice: $e');
        },
      );
    } catch (e) {
      _isListenerAttached = false;
      debugPrint('[ArticleService] Firestore init listener error: $e');
    }
  }

  Future<void> _seedIfEmpty() async {
    try {
      final coll = FirebaseFirestore.instance.collection('articles');
      for (final a in _initialArticles) {
        await coll.doc(a.id).set(a.toFirestoreMap(), SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('[ArticleService] Auto seed error: $e');
    }
  }

  /// Getter untuk referensi fallback artikel awal
  List<ArticleModel> get initialArticles => List.unmodifiable(_initialArticles);

  /// Mengambil daftar artikel aktif secara sinkron dari cache memori
  List<ArticleModel> getArticles() => List.unmodifiable(_cachedArticles);

  /// Mengambil artikel unggulan (maksimal 4 artikel pertama yang terbit)
  List<ArticleModel> getFeaturedArticles() =>
      _cachedArticles.where((a) => a.isPublished).take(4).toList();

  /// Mengambil artikel berdasarkan ID (mendukung id tipe String maupun int)
  ArticleModel? getArticleById(dynamic id) {
    if (id == null) return null;
    final idStr = id.toString();
    try {
      return _cachedArticles.firstWhere((art) => art.id == idStr || art.id == 'article_$idStr');
    } catch (_) {
      try {
        return _initialArticles.firstWhere((art) => art.id == idStr || art.id == 'article_$idStr');
      } catch (_) {
        return null;
      }
    }
  }

  /// Mengambil artikel langsung dari Firestore berdasarkan ID Dokumen (asinkron)
  Future<ArticleModel?> fetchArticleById(String docId) async {
    final local = getArticleById(docId);
    if (local != null) return local;

    try {
      final doc = await FirebaseFirestore.instance.collection('articles').doc(docId).get();
      if (doc.exists) {
        return ArticleModel.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('[ArticleService] fetchArticleById notice: $e');
    }
    return null;
  }

  /// Memfilter artikel berdasarkan kategori
  List<ArticleModel> getArticlesByCategory(String category) {
    final cat = category.trim().toLowerCase();
    if (cat.isEmpty) return List.unmodifiable(_cachedArticles);
    return _cachedArticles.where((art) => art.category.toLowerCase() == cat).toList();
  }

  /// Mencari artikel berdasarkan kata kunci judul atau isi
  List<ArticleModel> searchArticles(String query, {bool onlyPublished = false}) {
    final q = query.trim().toLowerCase();
    final source = onlyPublished
        ? _cachedArticles.where((a) => a.isPublished).toList()
        : _cachedArticles;

    if (q.isEmpty) return List.unmodifiable(source);
    return source.where((art) {
      return art.title.toLowerCase().contains(q) ||
          art.snippet.toLowerCase().contains(q) ||
          art.content.toLowerCase().contains(q);
    }).toList();
  }

  /// STREAM UNTUK ADMIN: Mengambil semua artikel (Semua, Dipublikasikan, maupun Draf)
  /// Mengalirkan data seketika tanpa delay dan tanpa menunggu roundtrip server
  Stream<List<ArticleModel>> getAllArticlesStream() async* {
    yield List.unmodifiable(_cachedArticles);
    yield* _safeAllArticlesController.stream;
  }

  /// STREAM UNTUK PENGGUNA: Hanya mengambil artikel yang sudah berstatus dipublikasikan (isPublished == true)
  Stream<List<ArticleModel>> getArticlesStream() async* {
    yield _cachedArticles.where((a) => a.isPublished).toList();
    yield* _safePublishedArticlesController.stream;
  }

  /// Mengambil data artikel sekali jalan (Future) dari Cloud Firestore
  Future<List<ArticleModel>> fetchArticles() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('articles')
          .where('isPublished', isEqualTo: true)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final parsed = snapshot.docs
            .map((doc) => ArticleModel.fromFirestore(doc))
            .toList();

        parsed.sort((a, b) {
          final aTime = a.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = b.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
        });

        _cachedArticles = parsed;
        _notifyStreams();
      }
    } catch (e) {
      debugPrint('[ArticleService] fetchArticles error, using cached fallback: $e');
    }
    return _cachedArticles.where((a) => a.isPublished).toList();
  }

  /// Menambahkan artikel baru (oleh Admin)
  Future<ArticleModel> createArticle({
    required String title,
    required String content,
    required bool isPublished,
    String? snippet,
    List<String>? takeaways,
    String? imageUrl,
    String? imageAsset,
    String? category,
    String? author,
  }) async {
    ensureInitialized();
    final now = DateTime.now();

    String docId = 'article_${now.millisecondsSinceEpoch}';
    DocumentReference? docRef;
    try {
      docRef = FirebaseFirestore.instance.collection('articles').doc();
      docId = docRef.id;
    } catch (e) {
      debugPrint('[ArticleService] Firestore doc reference creation notice: $e');
    }

    final autoSnippet = (snippet != null && snippet.trim().isNotEmpty)
        ? snippet.trim()
        : (content.trim().length > 110
            ? '${content.trim().substring(0, 110)}...'
            : content.trim());

    final cleanTakeaways = takeaways
            ?.map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        const <String>[];

    final newArticle = ArticleModel(
      id: docId,
      title: title.trim(),
      snippet: autoSnippet,
      date: formatIndonesianDate(now),
      readTime: estimateReadTime(content),
      imageAsset: imageAsset ?? 'assets/articles/article_5_pola_makan.jpg',
      imageUrl: (imageUrl != null && imageUrl.trim().isNotEmpty) ? imageUrl.trim() : null,
      content: content.trim(),
      takeaways: cleanTakeaways,
      category: category ?? 'Edukasi Kesehatan',
      author: author ?? 'Admin ObeSight',
      isPublished: isPublished,
      publishedAt: isPublished ? now : null,
      updatedAt: now,
    );

    // 1. Langsung perbarui cache lokal agar UI terupdate SEKETIKA
    _cachedArticles.removeWhere((a) => a.id == newArticle.id);
    _cachedArticles.insert(0, newArticle);
    _notifyStreams();

    // 2. Simpan ke Cloud Firestore di latar belakang tanpa memblokir UI
    try {
      final ref = docRef ?? FirebaseFirestore.instance.collection('articles').doc(docId);
      unawaited(
        ref.set(newArticle.toFirestoreMap()).timeout(
          const Duration(seconds: 4),
          onTimeout: () {
            debugPrint('[ArticleService] Firestore set timed out, saved locally.');
          },
        ).catchError((e) {
          debugPrint('[ArticleService] Firestore createArticle notice: $e');
        }),
      );
    } catch (e) {
      debugPrint('[ArticleService] Firestore set init error: $e');
    }

    return newArticle;
  }

  /// Memperbarui artikel yang sudah ada
  Future<ArticleModel?> updateArticle({
    required String id,
    required String title,
    required String content,
    required bool isPublished,
    String? snippet,
    List<String>? takeaways,
    String? imageUrl,
    String? imageAsset,
    String? category,
  }) async {
    final now = DateTime.now();
    final index = _cachedArticles.indexWhere((a) => a.id == id);
    if (index == -1) return null;

    final current = _cachedArticles[index];
    final autoSnippet = (snippet != null && snippet.trim().isNotEmpty)
        ? snippet.trim()
        : (content.trim().length > 110
            ? '${content.trim().substring(0, 110)}...'
            : content.trim());

    final cleanTakeaways = takeaways
            ?.map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        current.takeaways;

    final updated = current.copyWith(
      title: title.trim(),
      content: content.trim(),
      snippet: autoSnippet,
      takeaways: cleanTakeaways,
      isPublished: isPublished,
      imageUrl: imageUrl ?? current.imageUrl,
      imageAsset: imageAsset ?? current.imageAsset,
      category: category ?? current.category,
      updatedAt: now,
      publishedAt: isPublished ? (current.publishedAt ?? now) : current.publishedAt,
    );

    _cachedArticles[index] = updated;
    _notifyStreams();

    try {
      unawaited(
        FirebaseFirestore.instance
            .collection('articles')
            .doc(id)
            .set(updated.toFirestoreMap(), SetOptions(merge: true))
            .catchError((e) {
          debugPrint('[ArticleService] updateArticle notice: $e');
        }),
      );
    } catch (e) {
      debugPrint('[ArticleService] updateArticle error: $e');
    }

    return updated;
  }

  /// Mengubah status publikasi artikel (Publikasikan / Simpan sebagai draf)
  Future<void> togglePublishStatus(String id, bool publish) async {
    final now = DateTime.now();
    final index = _cachedArticles.indexWhere((a) => a.id == id);
    if (index != -1) {
      final current = _cachedArticles[index];
      _cachedArticles[index] = current.copyWith(
        isPublished: publish,
        publishedAt: publish ? (current.publishedAt ?? now) : current.publishedAt,
        updatedAt: now,
      );
      _notifyStreams();
    }

    try {
      unawaited(
        FirebaseFirestore.instance.collection('articles').doc(id).update({
          'isPublished': publish,
          'updatedAt': Timestamp.fromDate(now),
          if (publish) 'publishedAt': Timestamp.fromDate(now),
        }).catchError((e) {
          debugPrint('[ArticleService] togglePublishStatus notice: $e');
        }),
      );
    } catch (e) {
      debugPrint('[ArticleService] togglePublishStatus error: $e');
    }
  }

  /// Menghapus artikel
  Future<void> deleteArticle(String id) async {
    _cachedArticles.removeWhere((a) => a.id == id);
    _notifyStreams();
    try {
      unawaited(
        FirebaseFirestore.instance.collection('articles').doc(id).delete().catchError((e) {
          debugPrint('[ArticleService] deleteArticle notice: $e');
        }),
      );
    } catch (e) {
      debugPrint('[ArticleService] deleteArticle notice: $e');
    }
  }

  // --- Helper Date & Read Time Formatters ---

  static String formatIndonesianDate(DateTime dt) {
    const months = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    final monthName = (dt.month >= 1 && dt.month <= 12) ? months[dt.month] : '';
    return '${dt.day.toString().padLeft(2, '0')} $monthName ${dt.year}';
  }

  static String estimateReadTime(String content) {
    final wordCount = content.trim().split(RegExp(r'\s+')).length;
    final minutes = (wordCount / 180).ceil();
    return '${minutes < 1 ? 1 : minutes} Menit Baca';
  }

  /// Helper Seeding Awal Idempotent
  Future<Map<String, dynamic>> seedInitialArticles({
    bool forceOverwrite = false,
    bool checkOnly = false,
  }) async {
    final results = <String, dynamic>{
      'total': _initialArticles.length,
      'created': 0,
      'skipped': 0,
      'existing': 0,
      'missing': 0,
      'conflicts': <String>[],
      'details': <String, String>{},
    };

    final articlesCollection = FirebaseFirestore.instance.collection('articles');

    for (final article in _initialArticles) {
      final docRef = articlesCollection.doc(article.id);
      try {
        final docSnapshot = await docRef.get();

        if (docSnapshot.exists) {
          results['existing'] = (results['existing'] as int) + 1;

          if (checkOnly) {
            results['skipped'] = (results['skipped'] as int) + 1;
            (results['details'] as Map<String, String>)[article.id] =
                'Dokumen sudah ada di Firestore.';
            continue;
          }

          if (!forceOverwrite) {
            results['skipped'] = (results['skipped'] as int) + 1;
            (results['conflicts'] as List<String>).add(article.id);
            (results['details'] as Map<String, String>)[article.id] =
                'Dokumen sudah ada di Firestore. Dilewati.';
          } else {
            await docRef.set(article.toFirestoreMap());
            results['created'] = (results['created'] as int) + 1;
            (results['details'] as Map<String, String>)[article.id] =
                'Berhasil diperbarui (force overwrite) dengan ID ${article.id}.';
          }
        } else {
          results['missing'] = (results['missing'] as int) + 1;

          if (checkOnly) {
            (results['details'] as Map<String, String>)[article.id] =
                'Dokumen belum ada di Firestore.';
            continue;
          }

          await docRef.set(article.toFirestoreMap());
          results['created'] = (results['created'] as int) + 1;
          (results['details'] as Map<String, String>)[article.id] =
              'Berhasil dibuat dengan ID ${article.id}.';
        }
      } catch (e) {
        (results['details'] as Map<String, String>)[article.id] =
            'Gagal memeriksa/menulis dokumen: $e';
      }
    }

    return results;
  }
}
