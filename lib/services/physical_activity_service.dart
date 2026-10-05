import 'package:flutter/material.dart';

/// Service to track completed physical activities tied to specific dates.
/// Follows the same Singleton + ChangeNotifier pattern as other services in Obesight.
class PhysicalActivityService extends ChangeNotifier {
  static final PhysicalActivityService _instance = PhysicalActivityService._internal();
  factory PhysicalActivityService() => _instance;
  static PhysicalActivityService get instance => _instance;

  PhysicalActivityService._internal();

  // Map of dateKey ('yyyy-MM-dd') -> Set of completed activity IDs
  final Map<String, Set<String>> _completedActivitiesByDate = {};

  String formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String get todayKey => formatDateKey(DateTime.now());

  bool isCompleted(String dateKey, String activityId) {
    return _completedActivitiesByDate[dateKey]?.contains(activityId) ?? false;
  }

  Set<String> getCompletedForDate(String dateKey) {
    return _completedActivitiesByDate[dateKey] ?? const <String>{};
  }

  int getCompletedCountForDate(String dateKey) {
    return _completedActivitiesByDate[dateKey]?.length ?? 0;
  }

  void completeActivity(String dateKey, String activityId) {
    if (!_completedActivitiesByDate.containsKey(dateKey)) {
      _completedActivitiesByDate[dateKey] = <String>{};
    }
    _completedActivitiesByDate[dateKey]!.add(activityId);
    notifyListeners();
  }

  void uncompleteActivity(String dateKey, String activityId) {
    if (_completedActivitiesByDate.containsKey(dateKey)) {
      _completedActivitiesByDate[dateKey]!.remove(activityId);
      notifyListeners();
    }
  }
}
