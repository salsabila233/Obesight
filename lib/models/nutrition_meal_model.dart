import 'package:flutter/material.dart';

/// Model representasi menu makanan atau minuman pada fitur Rekomendasi Nutrisi.
/// Mendukung informasi makronutrien (protein, karbohidrat, lemak),
/// takaran gram, serta kategori target (Underweight, Normal, Overweight/Obesitas).
class NutritionMealModel {
  final String id;
  final String name;
  final String type; // 'food' | 'drink'
  final String mealTime; // 'Sarapan' | 'Makan Siang' | 'Makan Malam' | 'Cemilan' | 'Minuman'
  final String category; // 'Sarapan' | 'Makan Siang' | 'Makan Malam' | 'Cemilan' | 'Minuman'
  final int calories; // kkal
  final double protein; // gram
  final double carbs; // gram
  final double fat; // gram
  final int portionGram; // gram
  final List<String> pills;
  final String thumbImg;
  final String heroImg;
  final String desc;
  final String detailDesc;
  final List<String> benefits;
  final String targetCategory; // 'all' | 'underweight' | 'overweight_obesity' | 'normal'
  final IconData categoryIcon;
  final Color categoryBg;
  final Color categoryText;
  final bool hasCustomPhoto;

  const NutritionMealModel({
    required this.id,
    required this.name,
    required this.type,
    required this.mealTime,
    required this.category,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.portionGram,
    required this.pills,
    required this.thumbImg,
    required this.heroImg,
    required this.desc,
    required this.detailDesc,
    required this.benefits,
    this.targetCategory = 'all',
    this.categoryIcon = Icons.restaurant_rounded,
    this.categoryBg = const Color(0xFFFFF7ED),
    this.categoryText = const Color(0xFFEA580C),
    this.hasCustomPhoto = false,
  });

  /// Konversi ke Map untuk interoperabilitas
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': name,
      'name': name,
      'type': type,
      'mealTime': mealTime,
      'category': category,
      'calories': '$calories kkal',
      'calorieVal': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'portionGram': portionGram,
      'pills': pills,
      'thumbImg': thumbImg,
      'heroImg': heroImg,
      'desc': desc,
      'detailDesc': detailDesc,
      'benefits': benefits,
      'targetCategory': targetCategory,
      'categoryIcon': categoryIcon,
      'categoryBg': categoryBg,
      'categoryText': categoryText,
      'hasCustomPhoto': hasCustomPhoto,
    };
  }

  factory NutritionMealModel.fromMap(Map<String, dynamic> map) {
    return NutritionMealModel(
      id: map['id'] as String,
      name: (map['name'] ?? map['title']) as String,
      type: map['type'] as String? ?? 'food',
      mealTime: map['mealTime'] as String? ?? map['category'] as String? ?? 'Makanan',
      category: map['category'] as String? ?? 'Makanan',
      calories: (map['calorieVal'] as num?)?.toInt() ?? 0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0.0,
      portionGram: (map['portionGram'] as num?)?.toInt() ?? 0,
      pills: (map['pills'] as List<dynamic>?)?.cast<String>() ?? const [],
      thumbImg: map['thumbImg'] as String? ?? '',
      heroImg: map['heroImg'] as String? ?? '',
      desc: map['desc'] as String? ?? '',
      detailDesc: map['detailDesc'] as String? ?? '',
      benefits: (map['benefits'] as List<dynamic>?)?.cast<String>() ?? const [],
      targetCategory: map['targetCategory'] as String? ?? 'all',
      categoryIcon: map['categoryIcon'] as IconData? ?? Icons.restaurant_rounded,
      categoryBg: map['categoryBg'] as Color? ?? const Color(0xFFFFF7ED),
      categoryText: map['categoryText'] as Color? ?? const Color(0xFFEA580C),
      hasCustomPhoto: map['hasCustomPhoto'] as bool? ?? false,
    );
  }
}
