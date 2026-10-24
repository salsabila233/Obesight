import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ArticleModel {
  final String id;
  final String title;
  final String snippet;
  final String date;
  final String readTime;
  final Color headerColor;
  final IconData icon;
  final String imageAsset;
  final String content;
  final List<String> takeaways;
  final String category;
  final String? imageUrl;
  final String author;
  final bool isPublished;
  final DateTime? publishedAt;
  final DateTime? updatedAt;

  const ArticleModel({
    required this.id,
    required this.title,
    required this.snippet,
    this.date = '21 September 2026',
    this.readTime = '4 Menit Baca',
    this.headerColor = const Color(0xFF36785A),
    this.icon = Icons.menu_book_rounded,
    required this.imageAsset,
    required this.content,
    this.takeaways = const [],
    this.category = 'Edukasi Kesehatan',
    this.imageUrl,
    this.author = 'Tim Medis ObeSight',
    this.isPublished = true,
    this.publishedAt,
    this.updatedAt,
  });

  ArticleModel copyWith({
    String? id,
    String? title,
    String? snippet,
    String? date,
    String? readTime,
    Color? headerColor,
    IconData? icon,
    String? imageAsset,
    String? content,
    List<String>? takeaways,
    String? category,
    String? imageUrl,
    String? author,
    bool? isPublished,
    DateTime? publishedAt,
    DateTime? updatedAt,
  }) {
    return ArticleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      snippet: snippet ?? this.snippet,
      date: date ?? this.date,
      readTime: readTime ?? this.readTime,
      headerColor: headerColor ?? this.headerColor,
      icon: icon ?? this.icon,
      imageAsset: imageAsset ?? this.imageAsset,
      content: content ?? this.content,
      takeaways: takeaways ?? this.takeaways,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      author: author ?? this.author,
      isPublished: isPublished ?? this.isPublished,
      publishedAt: publishedAt ?? this.publishedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Getter representasi string hex dari headerColor
  String get headerColorHex => _colorToHex(headerColor);

  /// Getter nama identifier ikon
  String get iconName => _iconToName(icon);

  /// Mengonversi model ke Map standar
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'snippet': snippet,
      'date': date,
      'readTime': readTime,
      'color': headerColor.toARGB32(),
      'headerColorHex': _colorToHex(headerColor),
      'icon': icon.codePoint,
      'iconName': _iconToName(icon),
      'imageAsset': imageAsset,
      'imageUrl': imageUrl ?? '',
      'content': content,
      'takeaways': takeaways,
      'category': category,
      'author': author,
      'isPublished': isPublished,
      'publishedAt': publishedAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Format data khusus untuk disimpan ke Cloud Firestore (menggunakan Timestamp)
  Map<String, dynamic> toFirestoreMap() {
    return {
      'title': title,
      'snippet': snippet,
      'date': date,
      'category': category,
      'readTime': readTime,
      'headerColorHex': _colorToHex(headerColor),
      'iconName': _iconToName(icon),
      'imageAsset': imageAsset,
      'imageUrl': imageUrl ?? '',
      'content': content,
      'takeaways': takeaways,
      'author': author,
      'isPublished': isPublished,
      'publishedAt': publishedAt != null ? Timestamp.fromDate(publishedAt!) : Timestamp.now(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : Timestamp.now(),
    };
  }

  /// Factory untuk membuat ArticleModel dari Map / Dokumen Firestore secara aman
  factory ArticleModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    // 1. Parsing ID dokumen dengan aman
    final rawId = docId ?? map['id'];
    final idStr = rawId?.toString() ?? '1';

    // 2. Parsing Tanggal Publikasi (Timestamp / DateTime / ISO String)
    final parsedPublishedAt = _parseDateTime(map['publishedAt']);
    final parsedUpdatedAt = _parseDateTime(map['updatedAt']);

    // 3. Parsing Teks Tanggal Tampilan (Fallback ke format lokal jika date kosong)
    String displayDate = map['date'] as String? ?? '';
    if (displayDate.trim().isEmpty && parsedPublishedAt != null) {
      displayDate = _formatIndonesianDate(parsedPublishedAt);
    }
    if (displayDate.trim().isEmpty) {
      displayDate = '21 September 2026';
    }

    // 4. Parsing Warna Header
    final headerColor = _parseColor(map);

    // 5. Parsing Ikon
    final iconData = _parseIcon(map);

    // 6. Parsing Takeaways
    final takeawaysList = (map['takeaways'] as List<dynamic>?)
            ?.map((e) => e.toString().trim())
            .where((s) => s.isNotEmpty)
            .toList() ??
        const [];

    // 7. Parsing Snippet / Summary
    final snippetText = (map['snippet'] as String?)?.trim() ??
        (map['summary'] as String?)?.trim() ??
        '';

    return ArticleModel(
      id: idStr,
      title: (map['title'] as String?)?.trim() ?? '',
      snippet: snippetText,
      date: displayDate,
      readTime: (map['readTime'] as String?)?.trim() ?? '4 Menit Baca',
      headerColor: headerColor,
      icon: iconData,
      imageAsset: (map['imageAsset'] as String?)?.trim() ??
          'assets/articles/article_porsi_piring_gizi_seimbang.jpg',
      content: (map['content'] as String?)?.trim() ?? '',
      takeaways: takeawaysList,
      category: (map['category'] as String?)?.trim() ?? 'Edukasi Kesehatan',
      imageUrl: () {
        final raw = (map['imageUrl'] as String?)?.trim();
        return (raw != null && raw.isNotEmpty) ? raw : null;
      }(),
      author: (map['author'] as String?)?.trim() ?? 'Tim Medis ObeSight',
      isPublished: () {
        final raw = map['isPublished'];
        if (raw is bool) return raw;
        if (raw is String) return raw.toLowerCase() == 'true' || raw == '1';
        if (raw is num) return raw == 1;
        return true;
      }(),
      publishedAt: parsedPublishedAt,
      updatedAt: parsedUpdatedAt,
    );
  }

  /// Factory dari DocumentSnapshot Cloud Firestore
  factory ArticleModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ArticleModel.fromMap(data, doc.id);
  }

  // --- Helper Parsers ---

  static DateTime? _parseDateTime(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    if (val is String && val.trim().isNotEmpty) {
      return DateTime.tryParse(val);
    }
    return null;
  }

  static String _formatIndonesianDate(DateTime dt) {
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
    return '${dt.day} $monthName ${dt.year}';
  }

  static Color _parseColor(Map<String, dynamic> map) {
    if (map['color'] is Color) return map['color'] as Color;
    if (map['headerColor'] is Color) return map['headerColor'] as Color;

    final hexStr = (map['headerColorHex'] as String?) ??
        (map['colorHex'] as String?) ??
        '';
    if (hexStr.isNotEmpty) {
      try {
        final cleanHex = hexStr.replaceAll('#', '').trim();
        if (cleanHex.length == 6) {
          return Color(int.parse('0xFF$cleanHex'));
        } else if (cleanHex.length == 8) {
          return Color(int.parse('0x$cleanHex'));
        }
      } catch (_) {}
    }

    if (map['color'] is int) return Color(map['color'] as int);
    if (map['headerColor'] is int) return Color(map['headerColor'] as int);

    return const Color(0xFF36785A);
  }

  static String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  static IconData _parseIcon(Map<String, dynamic> map) {
    if (map['icon'] is IconData) return map['icon'] as IconData;

    final name = (map['iconName'] as String?)?.toLowerCase().trim() ?? '';
    switch (name) {
      case 'pie_chart':
      case 'pie_chart_outline_rounded':
        return Icons.pie_chart_outline_rounded;
      case 'restaurant_menu':
      case 'restaurant_menu_rounded':
        return Icons.restaurant_menu_rounded;
      case 'nightlight':
      case 'nightlight_round':
        return Icons.nightlight_round;
      case 'medical_services':
      case 'medical_services_outlined':
        return Icons.medical_services_outlined;
      case 'directions_run':
      case 'directions_run_rounded':
        return Icons.directions_run_rounded;
      case 'favorite':
      case 'favorite_outline_rounded':
        return Icons.favorite_outline_rounded;
      default:
        return Icons.menu_book_rounded;
    }
  }

  static String _iconToName(IconData icon) {
    if (icon == Icons.pie_chart_outline_rounded) return 'pie_chart';
    if (icon == Icons.restaurant_menu_rounded) return 'restaurant_menu';
    if (icon == Icons.nightlight_round) return 'nightlight';
    if (icon == Icons.medical_services_outlined) return 'medical_services';
    if (icon == Icons.directions_run_rounded) return 'directions_run';
    if (icon == Icons.favorite_outline_rounded) return 'favorite';
    return 'menu_book';
  }
}
