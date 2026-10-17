import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/nutrition_meal_model.dart';

/// Service untuk memantau menu makanan dan minuman yang telah dikonsumsi (diceklis) per tanggal.
/// Mengikuti pola Singleton + ChangeNotifier yang identik dengan PhysicalActivityService,
/// dengan persistensi lokal permanen via SharedPreferences.
class NutritionChecklistService extends ChangeNotifier {
  static final NutritionChecklistService _instance =
      NutritionChecklistService._internal();
  factory NutritionChecklistService() => _instance;
  static NutritionChecklistService get instance => _instance;

  static const String _prefKey = 'nutrition_checklist_completed_v1';

  NutritionChecklistService._internal() {
    _loadFromStorage();
  }

  // Map dari dateKey ('yyyy-MM-dd') -> Set of completed item IDs
  final Map<String, Set<String>> _completedItemsByDate = {};

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
        _completedItemsByDate.clear();
        decoded.forEach((key, val) {
          if (val is List) {
            _completedItemsByDate[key] = val.map((e) => e.toString()).toSet();
          }
        });
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[NutritionChecklistService] Error loading from storage: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapToSerialize = <String, List<String>>{};
      _completedItemsByDate.forEach((key, set) {
        mapToSerialize[key] = set.toList();
      });
      await prefs.setString(_prefKey, jsonEncode(mapToSerialize));
    } catch (e) {
      debugPrint('[NutritionChecklistService] Error saving to storage: $e');
    }
  }

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

  /// Menandai item telah dikonsumsi (permanen).
  Future<void> completeItem(String dateKey, String itemId) async {
    if (!_completedItemsByDate.containsKey(dateKey)) {
      _completedItemsByDate[dateKey] = <String>{};
    }
    if (_completedItemsByDate[dateKey]!.add(itemId)) {
      notifyListeners();
      await _saveToStorage();
    }
  }

  /// Pembatalan centang (jika diperlukan untuk pengujian atau reset).
  Future<void> uncompleteItem(String dateKey, String itemId) async {
    if (_completedItemsByDate.containsKey(dateKey)) {
      if (_completedItemsByDate[dateKey]!.remove(itemId)) {
        notifyListeners();
        await _saveToStorage();
      }
    }
  }

  /// Toggle centang (dipertahankan untuk kompatibilitas ke belakang).
  Future<void> toggleItem(String dateKey, String itemId) async {
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
    await _saveToStorage();
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
