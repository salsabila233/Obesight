import 'package:flutter/material.dart';
import '../screens/skrining/skrining_models.dart';
import 'meal_plan_service.dart';
import 'nutrition_checklist_service.dart';
import 'physical_activity_service.dart';
import 'screening_history_service.dart';

class RecommendationProgressGoal {
  final String id;
  final String title;
  final String category; // 'Latihan', 'Pola Makan'
  final String targetDesc;
  final int completedCount;
  final int totalTargetCount;
  final String unit; // 'sesi', 'hari', dll.

  const RecommendationProgressGoal({
    required this.id,
    required this.title,
    required this.category,
    required this.targetDesc,
    required this.completedCount,
    required this.totalTargetCount,
    required this.unit,
  });

  double get percentage => totalTargetCount > 0 ? (completedCount / totalTargetCount).clamp(0.0, 1.0) : 0.0;
  bool get isFullyCompleted => completedCount >= totalTargetCount;
  int get remainingCount => (totalTargetCount - completedCount) > 0 ? (totalTargetCount - completedCount) : 0;
}

/// Item rincian progres yang telah dicentang oleh pengguna
class CompletedChecklistItem {
  final String id;
  final String title;
  final String type; // 'nutrition' or 'activity'
  final String categoryName; // 'Makanan & Minuman' atau 'Aktivitas Fisik'
  final String subCategory; // 'Sarapan', 'Makan Siang', 'Kardio Ringan', dll.
  final DateTime date;
  final String dateKey;
  final int weekNumber; // 1, 2, 3, or 4
  final String detailDesc;
  final String caloriesText;
  final String portionOrDuration;
  final String? thumb;
  final IconData icon;

  const CompletedChecklistItem({
    required this.id,
    required this.title,
    required this.type,
    required this.categoryName,
    required this.subCategory,
    required this.date,
    required this.dateKey,
    required this.weekNumber,
    required this.detailDesc,
    required this.caloriesText,
    required this.portionOrDuration,
    this.thumb,
    required this.icon,
  });
}

/// Ringkasan evaluasi mingguan dalam periode 1 bulan (4 minggu)
class WeeklyProgressSummary {
  final int weekNumber; // 1, 2, 3, 4
  final String label; // 'Minggu 1', 'Minggu 2', ...
  final String dateRangeText;
  final int nutritionCompleted;
  final int nutritionTarget;
  final int activityCompleted;
  final int activityTarget;

  const WeeklyProgressSummary({
    required this.weekNumber,
    required this.label,
    required this.dateRangeText,
    required this.nutritionCompleted,
    required this.nutritionTarget,
    required this.activityCompleted,
    required this.activityTarget,
  });

  int get totalCompleted => nutritionCompleted + activityCompleted;
  int get totalTarget => nutritionTarget + activityTarget;
  double get percentage => totalTarget > 0 ? (totalCompleted / totalTarget).clamp(0.0, 1.0) : 0.0;
  double get nutritionPercentage => nutritionTarget > 0 ? (nutritionCompleted / nutritionTarget).clamp(0.0, 1.0) : 0.0;
  double get activityPercentage => activityTarget > 0 ? (activityCompleted / activityTarget).clamp(0.0, 1.0) : 0.0;
}

class ProgressTrackingService extends ChangeNotifier {
  static final ProgressTrackingService instance = ProgressTrackingService._internal();
  ProgressTrackingService._internal();

  // State Skrining & Periode Progres 1 Bulan (4 Minggu / 30 Hari)
  String _category = 'Overweight';
  String _riskLevel = 'Sedang';
  double _bmi = 26.8;
  int _cycleDays = 30; // Rentang evaluasi 1 bulan penuh (30 hari / 4 minggu)
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 0));
  DateTime _nextScreeningDate = DateTime.now().add(const Duration(days: 30));

  // Getters
  String get category => _category;
  String get riskLevel => _riskLevel;
  double get bmi => _bmi;
  int get cycleDays => _cycleDays;
  DateTime get startDate => _startDate;
  DateTime get nextScreeningDate => _nextScreeningDate;

  int get daysUntilNextScreening {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(_nextScreeningDate.year, _nextScreeningDate.month, _nextScreeningDate.day);
    final diff = target.difference(today).inDays;
    return diff > 0 ? diff : 0;
  }

  String get formattedStartDate {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${_startDate.day} ${months[_startDate.month - 1]} ${_startDate.year}';
  }

  String get formattedNextScreeningDate {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${_nextScreeningDate.day} ${months[_nextScreeningDate.month - 1]} ${_nextScreeningDate.year}';
  }

  String get formattedDateRange {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${_startDate.day} ${months[_startDate.month - 1]} – ${_nextScreeningDate.day} ${months[_nextScreeningDate.month - 1]} ${_nextScreeningDate.year}';
  }

  /// Sinkronisasi dengan riwayat skrining pengguna untuk menentukan siklus 1 bulan aktif
  void syncWithUserScreening(String? userId, [String? email]) {
    final history = ScreeningHistoryService.instance.getHistory(userId, email);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (history.isNotEmpty) {
      // Ambil hasil skrining terbaru pengguna sebagai acuan kategori klinis & siklus evaluasi
      final latestScreening = history.first;
      _bmi = latestScreening.bmi;
      _category = latestScreening.category;

      DateTime cycleStart = DateTime(
        latestScreening.date.year,
        latestScreening.date.month,
        latestScreening.date.day,
      );

      // Jika rentang 30 hari dari skrining awal telah berlalu, sesuaikan siklus evaluasi 30 hari
      // agar selalu memuat hari ini secara dinamis (tidak kedaluwarsa di masa lampau)
      if (today.difference(cycleStart).inDays >= 30) {
        final cyclesPassed = today.difference(cycleStart).inDays ~/ 30;
        cycleStart = cycleStart.add(Duration(days: cyclesPassed * 30));
      }

      _startDate = cycleStart;
      _cycleDays = 30;
      _nextScreeningDate = _startDate.add(const Duration(days: 30));
    } else {
      // Pengguna belum skrining: siklus 30 hari berjalan mulai hari ini
      _startDate = today;
      _cycleDays = 30;
      _nextScreeningDate = _startDate.add(const Duration(days: 30));
    }

    // Pastikan _startDate juga mencakup tanggal centang aktif pengguna jika ada
    final nutritionService = NutritionChecklistService.instance;
    final activityService = PhysicalActivityService.instance;
    final allKeys = [
      ...nutritionService.completedItemsByDate.keys,
      ...activityService.completedActivitiesByDate.keys,
    ];
    for (final k in allKeys) {
      try {
        final p = k.split('-');
        if (p.length == 3) {
          final d = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
          if (d.isBefore(_startDate) && today.difference(d).inDays < 30) {
            _startDate = d;
            _nextScreeningDate = _startDate.add(const Duration(days: 30));
          }
        }
      } catch (_) {}
    }

    notifyListeners();
  }

  // Update State Saat Skrining Baru Dilakukan
  void updateFromScreening(SkriningData data) {
    _bmi = data.bmi;
    _category = data.classificationCategory;
    final d = data.date ?? DateTime.now();
    _startDate = DateTime(d.year, d.month, d.day);
    _cycleDays = 30; // 1 bulan / 4 minggu
    _nextScreeningDate = _startDate.add(const Duration(days: 30));

    final cat = _category.toLowerCase();
    if (cat.contains('obesitas') || cat.contains('obesity')) {
      _riskLevel = 'Tinggi';
    } else if (cat.contains('overweight')) {
      _riskLevel = 'Sedang';
    } else if (cat.contains('underweight') || cat.contains('insufficient')) {
      _riskLevel = 'Perhatian';
    } else {
      _riskLevel = 'Normal / Terkendali';
    }

    notifyListeners();
  }

  // =======================================================================
  // DATA PROGRES DINAMIS DARI CENTANGAN MAKANAN & MINUMAN SERTA AKTIVITAS FISIK
  // =======================================================================

  static const int dailyMealTarget = 5; // Sarapan, Makan Siang, Makan Malam, Cemilan, Minuman
  static const int dailyActivityTarget = 4; // 4 rekomendasi aktivitas per hari

  /// Target 1 bulan (30 hari)
  int get nutritionTargetCount => _cycleDays * dailyMealTarget; // 150 item
  int get activityTargetCount => _cycleDays * dailyActivityTarget; // 120 item

  /// Total Makanan & Minuman yang telah dicentang dalam rentang 30 hari
  int get nutritionCompletedCount {
    final nutritionService = NutritionChecklistService.instance;
    int count = 0;
    for (int i = 0; i < _cycleDays; i++) {
      final date = _startDate.add(Duration(days: i));
      final dateKey = nutritionService.formatDateKey(date);
      count += nutritionService.getCompletedCountForDate(dateKey);
    }
    // Jika centang ada di memori/storage tetapi berada di luar rentang pas, tetap hitung
    if (count == 0 && nutritionService.completedItemsByDate.isNotEmpty) {
      for (final set in nutritionService.completedItemsByDate.values) {
        count += set.length;
      }
    }
    return count;
  }

  /// Total Aktivitas Fisik yang telah diselesaikan dalam rentang 30 hari
  int get activityCompletedCount {
    final activityService = PhysicalActivityService.instance;
    int count = 0;
    for (int i = 0; i < _cycleDays; i++) {
      final date = _startDate.add(Duration(days: i));
      final dateKey = activityService.formatDateKey(date);
      count += activityService.getCompletedCountForDate(dateKey);
    }
    if (count == 0 && activityService.completedActivitiesByDate.isNotEmpty) {
      for (final set in activityService.completedActivitiesByDate.values) {
        count += set.length;
      }
    }
    return count;
  }

  double get nutritionPercentage {
    if (nutritionTargetCount == 0) return 0.0;
    return (nutritionCompletedCount / nutritionTargetCount).clamp(0.0, 1.0);
  }

  double get activityPercentage {
    if (activityTargetCount == 0) return 0.0;
    return (activityCompletedCount / activityTargetCount).clamp(0.0, 1.0);
  }

  /// Total gabungan 2 pilar (Makanan & Minuman + Aktivitas Fisik)
  int get totalCompletedActions => nutritionCompletedCount + activityCompletedCount;
  int get totalTargetActions => nutritionTargetCount + activityTargetCount;
  int get totalRemainingActions => (totalTargetActions - totalCompletedActions) > 0
      ? (totalTargetActions - totalCompletedActions)
      : 0;

  /// Persentase capaian keseluruhan 1 bulan (hanya Makanan & Minuman + Aktivitas Fisik)
  double get overallPercentage {
    if (totalTargetActions == 0) return 0.0;
    return (totalCompletedActions / totalTargetActions).clamp(0.0, 1.0);
  }

  /// Menghitung ringkasan per minggu (Minggu 1, Minggu 2, Minggu 3, Minggu 4)
  List<WeeklyProgressSummary> getWeeklySummaries() {
    final nutritionService = NutritionChecklistService.instance;
    final activityService = PhysicalActivityService.instance;
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
    ];

    final List<WeeklyProgressSummary> summaries = [];
    final weekDayRanges = [
      {'start': 0, 'days': 7},   // Minggu 1: Hari 1–7
      {'start': 7, 'days': 7},   // Minggu 2: Hari 8–14
      {'start': 14, 'days': 7},  // Minggu 3: Hari 15–21
      {'start': 21, 'days': 9},  // Minggu 4: Hari 22–30 (9 hari sisa)
    ];

    for (int w = 0; w < weekDayRanges.length; w++) {
      final startOffset = weekDayRanges[w]['start']!;
      final daySpan = weekDayRanges[w]['days']!;
      final wStartDate = _startDate.add(Duration(days: startOffset));
      final wEndDate = _startDate.add(Duration(days: startOffset + daySpan - 1));

      final dateRangeText = '${wStartDate.day} ${months[wStartDate.month - 1]} – ${wEndDate.day} ${months[wEndDate.month - 1]}';

      int wNutritionDone = 0;
      int wActivityDone = 0;

      for (int d = 0; d < daySpan; d++) {
        final curDate = _startDate.add(Duration(days: startOffset + d));
        final dKey = nutritionService.formatDateKey(curDate);
        wNutritionDone += nutritionService.getCompletedCountForDate(dKey);
        wActivityDone += activityService.getCompletedCountForDate(dKey);
      }

      final wNutritionTarget = daySpan * dailyMealTarget;
      final wActivityTarget = daySpan * dailyActivityTarget;

      summaries.add(WeeklyProgressSummary(
        weekNumber: w + 1,
        label: 'Minggu ${w + 1}',
        dateRangeText: dateRangeText,
        nutritionCompleted: wNutritionDone,
        nutritionTarget: wNutritionTarget,
        activityCompleted: wActivityDone,
        activityTarget: wActivityTarget,
      ));
    }

    return summaries;
  }

  /// Menghasilkan seluruh daftar item progres yang telah dicentang dalam rentang 1 bulan
  List<CompletedChecklistItem> getAllCompletedItems() {
    final List<CompletedChecklistItem> items = [];
    final nutritionService = NutritionChecklistService.instance;
    final activityService = PhysicalActivityService.instance;

    // Kumpulkan seluruh dateKey unik yang relevan (siklus 30 hari + semua yang memiliki checklist selesai)
    final Set<String> relevantDateKeys = {};
    for (int i = 0; i < _cycleDays; i++) {
      final date = _startDate.add(Duration(days: i));
      relevantDateKeys.add(nutritionService.formatDateKey(date));
    }
    relevantDateKeys.addAll(nutritionService.completedItemsByDate.keys);
    relevantDateKeys.addAll(activityService.completedActivitiesByDate.keys);

    for (final dateKey in relevantDateKeys) {
      DateTime itemDate;
      try {
        final parts = dateKey.split('-');
        itemDate = DateTime(
            int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      } catch (_) {
        itemDate = DateTime.now();
      }

      // Tentukan nomor minggu relatif terhadap _startDate
      final dayDiff = itemDate.difference(_startDate).inDays;
      int weekNum;
      if (dayDiff < 0) {
        weekNum = 1;
      } else {
        weekNum = (dayDiff ~/ 7) + 1;
        if (weekNum > 4) weekNum = 4;
      }

      // 1. Makanan & Minuman yang dicentang pada tanggal ini
      final completedMealIds = nutritionService.getCompletedForDate(dateKey);
      for (final mealId in completedMealIds) {
        final meal = MealPlanService.getMealById(mealId);
        if (meal != null) {
          items.add(CompletedChecklistItem(
            id: 'nut_${meal.id}_$dateKey',
            title: meal.name,
            type: 'nutrition',
            categoryName: 'Makanan & Minuman',
            subCategory: meal.mealTime,
            date: itemDate,
            dateKey: dateKey,
            weekNumber: weekNum,
            detailDesc: meal.desc,
            caloriesText: '${meal.calories} kkal',
            portionOrDuration: '${meal.portionGram}g',
            thumb: meal.thumbImg,
            icon: meal.categoryIcon,
          ));
        } else {
          items.add(CompletedChecklistItem(
            id: 'nut_${mealId}_$dateKey',
            title: 'Menu Nutrisi Seimbang',
            type: 'nutrition',
            categoryName: 'Makanan & Minuman',
            subCategory: 'Konsumsi Harian',
            date: itemDate,
            dateKey: dateKey,
            weekNumber: weekNum,
            detailDesc: 'Telah dikonsumsi sesuai anjuran porsi seimbang.',
            caloriesText: 'Tercatat',
            portionOrDuration: '1 Porsi',
            thumb: null,
            icon: Icons.restaurant_rounded,
          ));
        }
      }

      // 2. Aktivitas Fisik yang dicentang pada tanggal ini
      final completedActIds = activityService.getCompletedForDate(dateKey);
      for (final actId in completedActIds) {
        final act = activityService.getActivityById(actId);
        if (act != null) {
          items.add(CompletedChecklistItem(
            id: 'act_${act['id']}_$dateKey',
            title: act['name'] as String? ??
                act['title'] as String? ??
                'Aktivitas Fisik',
            type: 'activity',
            categoryName: 'Aktivitas Fisik',
            subCategory: act['category'] as String? ?? 'Latihan Fisik',
            date: itemDate,
            dateKey: dateKey,
            weekNumber: weekNum,
            detailDesc: act['desc'] as String? ??
                'Aktivitas fisik selesai dilakukan.',
            caloriesText: act['calories'] as String? ?? 'Kalori terbakar',
            portionOrDuration: act['duration'] as String? ?? '30 Menit',
            thumb: act['thumb'] as String?,
            icon: Icons.directions_run_rounded,
          ));
        } else {
          items.add(CompletedChecklistItem(
            id: 'act_${actId}_$dateKey',
            title: 'Sesi Latihan Fisik',
            type: 'activity',
            categoryName: 'Aktivitas Fisik',
            subCategory: 'Latihan Harian',
            date: itemDate,
            dateKey: dateKey,
            weekNumber: weekNum,
            detailDesc: 'Sesi aktivitas fisik harian telah selesai dikerjakan.',
            caloriesText: 'Terbakar',
            portionOrDuration: '30 Menit',
            thumb: null,
            icon: Icons.directions_run_rounded,
          ));
        }
      }
    }

    // Urutkan dari tanggal terbaru ke terlama
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  // Kompatibilitas dengan kode lama
  List<RecommendationProgressGoal> get goals => [
    RecommendationProgressGoal(
      id: 'nut_summary',
      title: 'Pola Makan & Nutrisi Seimbang',
      category: 'Pola Makan',
      targetDesc: 'Target 5 menu seimbang per hari selama 1 bulan ($nutritionTargetCount menu)',
      completedCount: nutritionCompletedCount,
      totalTargetCount: nutritionTargetCount,
      unit: 'menu',
    ),
    RecommendationProgressGoal(
      id: 'act_summary',
      title: 'Aktivitas Fisik & Latihan Teratur',
      category: 'Latihan',
      targetDesc: 'Target 4 rekomendasi latihan per hari selama 1 bulan ($activityTargetCount sesi)',
      completedCount: activityCompletedCount,
      totalTargetCount: activityTargetCount,
      unit: 'sesi',
    ),
  ];

  List<RecommendationProgressGoal> getGoalsByCategory(String category) {
    return goals.where((g) => g.category == category).toList();
  }

  double getCategoryPercentage(String category) {
    if (category == 'Latihan' || category == 'Aktivitas Fisik') {
      return activityPercentage;
    }
    if (category == 'Pola Makan' || category == 'Makanan & Minuman') {
      return nutritionPercentage;
    }
    return 0.0;
  }
}
