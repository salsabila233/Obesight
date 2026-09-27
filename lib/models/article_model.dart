import 'package:flutter/material.dart';

class ArticleModel {
  final int id;
  final String title;
  final String snippet;
  final String date;
  final String readTime;
  final Color headerColor;
  final IconData icon;
  final String imageAsset;
  final String content;
  final List<String> takeaways;

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
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'snippet': snippet,
      'date': date,
      'readTime': readTime,
      'color': headerColor,
      'icon': icon,
      'imageAsset': imageAsset,
      'content': content,
      'takeaways': takeaways,
    };
  }

  factory ArticleModel.fromMap(Map<String, dynamic> map) {
    return ArticleModel(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id'].toString()) ?? 1,
      title: map['title'] as String? ?? '',
      snippet: map['snippet'] as String? ?? '',
      date: map['date'] as String? ?? '21 September 2026',
      readTime: map['readTime'] as String? ?? '4 Menit Baca',
      headerColor: map['color'] is Color
          ? map['color'] as Color
          : (map['headerColor'] is Color
              ? map['headerColor'] as Color
              : const Color(0xFF36785A)),
      icon: map['icon'] is IconData
          ? map['icon'] as IconData
          : Icons.menu_book_rounded,
      imageAsset: map['imageAsset'] as String? ?? 'assets/articles/article_porsi_piring_gizi_seimbang.jpg',
      content: map['content'] as String? ?? '',
      takeaways: (map['takeaways'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}
