import 'package:flutter/material.dart';
import '../models/nutrition_meal_model.dart';

/// Service untuk memantau menu makanan dan minuman yang telah dikonsumsi (diceklis) per tanggal.
/// Mengikuti pola Singleton + ChangeNotifier yang identik dengan PhysicalActivityService.
class NutritionChecklistService extends ChangeNotifier {
  static final NutritionChecklistService _instance =
      NutritionChecklistService._internal();
  factory NutritionChecklistService() => _instance;
  static NutritionChecklistService get instance => _instance;

  NutritionChecklistService._internal();

  // Map dari dateKey ('yyyy-MM-dd') -> Set of completed item IDs
  final Map<String, Set<String>> _completedItemsByDate = {};

  String formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String get todayKey => formatDateKey(DateTime.now());

  bool isCompleted(String dateKey, String itemId) {
    return _completedItemsByDate[dateKey]?.contains(itemId) ?? false;
  }

  Set<String> getCompletedForDate(String dateKey) {
    return _completedItemsByDate[dateKey] ?? const <String>{};
  }

  int getCompletedCountForDate(String dateKey) {
    return _completedItemsByDate[dateKey]?.length ?? 0;
  }

  /// Toggle centang manual oleh pengguna
  void toggleItem(String dateKey, String itemId) {
    if (!_completedItemsByDate.containsKey(dateKey)) {
      _completedItemsByDate[dateKey] = <String>{};
    }
    final set = _completedItemsByDate[dateKey]!;
    if (set.contains(itemId)) {
      set.remove(itemId);
    } else {
      set.add(itemId);
    }
    notifyListeners();
  }

  void completeItem(String dateKey, String itemId) {
    if (!_completedItemsByDate.containsKey(dateKey)) {
      _completedItemsByDate[dateKey] = <String>{};
    }
    _completedItemsByDate[dateKey]!.add(itemId);
    notifyListeners();
  }

  void uncompleteItem(String dateKey, String itemId) {
    if (_completedItemsByDate.containsKey(dateKey)) {
      _completedItemsByDate[dateKey]!.remove(itemId);
      notifyListeners();
    }
  }

  /// Menghitung total kalori yang telah terkonsumsi pada tanggal tertentu
  /// berdasarkan daftar menu hari itu.
  int getConsumedCaloriesForDate(String dateKey, List<NutritionMealModel> dailyMeals) {
    final completed = getCompletedForDate(dateKey);
    int sum = 0;
    for (final meal in dailyMeals) {
      if (completed.contains(meal.id)) {
        sum += meal.calories;
      }
    }
    return sum;
  }
}
