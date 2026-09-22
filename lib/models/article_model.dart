import 'package:flutter/material.dart';

class ArticleModel {
  final int id;
  final String title;
  final String category;
  final String snippet;
  final String author;
  final String date;
  final String readTime;
  final Color headerColor;
  final IconData icon;
  final String content;
  final List<String> takeaways;
  final List<String> tags;

  const ArticleModel({
    required this.id,
    required this.title,
    required this.category,
    required this.snippet,
    required this.author,
    required this.date,
    required this.readTime,
    required this.headerColor,
    required this.icon,
    required this.content,
    required this.takeaways,
    this.tags = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'snippet': snippet,
      'author': author,
      'date': date,
      'readTime': readTime,
      'color': headerColor,
      'icon': icon,
      'content': content,
      'takeaways': takeaways,
      'tags': tags,
    };
  }

  factory ArticleModel.fromMap(Map<String, dynamic> map) {
    return ArticleModel(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id'].toString()) ?? 1,
      title: map['title'] as String? ?? '',
      category: map['category'] as String? ?? 'Edukasi Kesehatan',
      snippet: map['snippet'] as String? ?? '',
      author: map['author'] as String? ?? 'Tim Medis ObeSight',
      date: map['date'] as String? ?? '21 September 2026',
      readTime: map['readTime'] as String? ?? '4 Menit Baca',
      headerColor: map['color'] is Color
          ? map['color'] as Color
          : (map['headerColor'] is Color
              ? map['headerColor'] as Color
              : const Color(0xFF489874)),
      icon: map['icon'] is IconData
          ? map['icon'] as IconData
          : Icons.menu_book_rounded,
      content: map['content'] as String? ?? '',
      takeaways: (map['takeaways'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      tags: (map['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}
