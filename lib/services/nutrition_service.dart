import 'package:flutter/material.dart';

/// Service pendukung legacy untuk katalog dasar nutrisi di Obesight.
/// Fitur perencanaan makan dinamis dan target kalori kini dikelola oleh:
/// - [MealPlanService] untuk rotasi deterministik per tanggal & hasil skrining
/// - [CalorieTargetService] untuk konstanta target kalori (1.700 kkal / 1.950 kkal)
/// - [NutritionChecklistService] untuk tracking ceklis manual harian.
class NutritionService extends ChangeNotifier {
  static final NutritionService _instance = NutritionService._internal();
  factory NutritionService() => _instance;
  static NutritionService get instance => _instance;

  NutritionService._internal();
}
