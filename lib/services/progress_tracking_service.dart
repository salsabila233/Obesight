import 'package:flutter/material.dart';
import '../screens/skrining/skrining_models.dart';

class RecommendationProgressGoal {
  final String id;
  final String title;
  final String category; // 'Latihan', 'Pola Makan', 'Waktu Tidur'
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

  double get percentage => (completedCount / totalTargetCount).clamp(0.0, 1.0);
  bool get isFullyCompleted => completedCount >= totalTargetCount;
  int get remainingCount => (totalTargetCount - completedCount) > 0 ? (totalTargetCount - completedCount) : 0;
}

class ProgressTrackingService extends ChangeNotifier {
  static final ProgressTrackingService instance = ProgressTrackingService._internal();
  ProgressTrackingService._internal();

  // State Skrining & Periode Progres
  String _category = 'Overweight';
  String _riskLevel = 'Sedang';
  double _bmi = 26.8;
  int _cycleDays = 14; // Rentang waktu evaluasi siklus rekomendasi (14 hari)
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 0));
  DateTime _nextScreeningDate = DateTime.now().add(const Duration(days: 14));

  // Daftar Target Rekomendasi yang Dipantau dalam Rentang Waktu Ini
  final List<RecommendationProgressGoal> _goals = const [
    // 1. Latihan Fisik
    RecommendationProgressGoal(
      id: 'ex_1',
      title: 'Latihan Aerobik (Jalan Cepat / Sepeda)',
      category: 'Latihan',
      targetDesc: 'Minimal 30 menit per sesi (target 5 sesi/minggu)',
      completedCount: 4,
      totalTargetCount: 5,
      unit: 'sesi',
    ),
    RecommendationProgressGoal(
      id: 'ex_2',
      title: 'Latihan Kekuatan Otot & Peregangan',
      category: 'Latihan',
      targetDesc: 'Gerakan beban tubuh ringan (target 2 sesi/minggu)',
      completedCount: 1,
      totalTargetCount: 2,
      unit: 'sesi',
    ),

    // 2. Pola Makan & Nutrisi
    RecommendationProgressGoal(
      id: 'nut_1',
      title: 'Konsumsi Porsi Sayur & Serat Seimbang',
      category: 'Pola Makan',
      targetDesc: 'Isi piring dengan 50% sayur dan buah setiap makan',
      completedCount: 11,
      totalTargetCount: 14,
      unit: 'hari',
    ),
    RecommendationProgressGoal(
      id: 'nut_2',
      title: 'Minum Air Putih Minimal 2 Liter / Hari',
      category: 'Pola Makan',
      targetDesc: 'Cukupi hidrasi harian untuk metabolisme optimal',
      completedCount: 13,
      totalTargetCount: 14,
      unit: 'hari',
    ),
    RecommendationProgressGoal(
      id: 'nut_3',
      title: 'Batasi Makanan Manis & Gorengan',
      category: 'Pola Makan',
      targetDesc: 'Kurangi konsumsi gula berlebih dan lemak jenuh',
      completedCount: 10,
      totalTargetCount: 14,
      unit: 'hari',
    ),

    // 3. Waktu Tidur & Istirahat
    RecommendationProgressGoal(
      id: 'slp_1',
      title: 'Tidur Berkualitas 7–8 Jam per Malam',
      category: 'Waktu Tidur',
      targetDesc: 'Istirahat cukup untuk regulasi hormon nafsu makan',
      completedCount: 12,
      totalTargetCount: 14,
      unit: 'hari',
    ),
    RecommendationProgressGoal(
      id: 'slp_2',
      title: 'Jadwal Tidur Teratur & Bebas Gadget',
      category: 'Waktu Tidur',
      targetDesc: 'Tidur sebelum jam 23.00 dan matikan layar 30 mnt sebelum tidur',
      completedCount: 9,
      totalTargetCount: 14,
      unit: 'hari',
    ),
  ];

  // Getters
  String get category => _category;
  String get riskLevel => _riskLevel;
  double get bmi => _bmi;
  int get cycleDays => _cycleDays;
  DateTime get startDate => _startDate;
  DateTime get nextScreeningDate => _nextScreeningDate;
  List<RecommendationProgressGoal> get goals => _goals;

  int get daysUntilNextScreening {
    final now = DateTime.now();
    final diff = _nextScreeningDate.difference(DateTime(now.year, now.month, now.day)).inDays;
    return diff > 0 ? diff : 0;
  }

  String get formattedDateRange {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${_startDate.day} ${months[_startDate.month - 1]} – ${_nextScreeningDate.day} ${months[_nextScreeningDate.month - 1]} ${_nextScreeningDate.year}';
  }

  String get formattedNextScreeningDate {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${_nextScreeningDate.day} ${months[_nextScreeningDate.month - 1]} ${_nextScreeningDate.year}';
  }

  // Rekap Capaian Berdasarkan Kategori
  List<RecommendationProgressGoal> getGoalsByCategory(String category) {
    return _goals.where((g) => g.category == category).toList();
  }

  double getCategoryPercentage(String category) {
    final list = getGoalsByCategory(category);
    if (list.isEmpty) return 0.0;
    int totalDone = 0;
    int totalTarget = 0;
    for (var g in list) {
      totalDone += g.completedCount;
      totalTarget += g.totalTargetCount;
    }
    return totalTarget == 0 ? 0.0 : (totalDone / totalTarget).clamp(0.0, 1.0);
  }

  // Total Keseluruhan
  int get totalCompletedActions => _goals.fold(0, (sum, g) => sum + g.completedCount);
  int get totalTargetActions => _goals.fold(0, (sum, g) => sum + g.totalTargetCount);
  int get totalRemainingActions => (totalTargetActions - totalCompletedActions) > 0 ? (totalTargetActions - totalCompletedActions) : 0;

  double get overallPercentage {
    if (totalTargetActions == 0) return 0.0;
    return (totalCompletedActions / totalTargetActions).clamp(0.0, 1.0);
  }

  int get fullyCompletedGoalsCount => _goals.where((g) => g.isFullyCompleted).length;
  int get inProgressGoalsCount => _goals.where((g) => !g.isFullyCompleted).length;

  // Update State Saat Skrining Baru Dilakukan
  void updateFromScreening(SkriningData data) {
    _bmi = data.bmi;
    _category = data.classificationCategory;
    _startDate = DateTime.now();

    if (_category.contains('Obesitas')) {
      _riskLevel = 'Tinggi';
      _cycleDays = 14;
      _nextScreeningDate = DateTime.now().add(const Duration(days: 14));
    } else if (_category == 'Overweight') {
      _riskLevel = 'Sedang';
      _cycleDays = 14;
      _nextScreeningDate = DateTime.now().add(const Duration(days: 14));
    } else if (_category == 'Underweight') {
      _riskLevel = 'Perhatian';
      _cycleDays = 21;
      _nextScreeningDate = DateTime.now().add(const Duration(days: 21));
    } else {
      _riskLevel = 'Normal / Terkendali';
      _cycleDays = 30;
      _nextScreeningDate = DateTime.now().add(const Duration(days: 30));
    }

    notifyListeners();
  }
}
