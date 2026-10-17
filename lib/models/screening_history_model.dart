import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../screens/skrining/skrining_models.dart';

class ScreeningHistoryItem {
  final String id;
  final String userId;
  final DateTime date;
  final double bmi;
  final String risk; // 'Tinggi', 'Sedang', 'Rendah'
  final String category; // e.g. 'Overweight (IMT 25–27)', 'Obesitas (IMT > 27)'
  final SkriningData skriningData;

  const ScreeningHistoryItem({
    required this.id,
    required this.userId,
    required this.date,
    required this.bmi,
    required this.risk,
    required this.category,
    required this.skriningData,
  });

  String get day => date.day.toString().padLeft(2, '0');

  String get monthYear {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'July', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final m = (date.month >= 1 && date.month <= 12) ? months[date.month - 1] : '';
    return '$m\n${date.year}';
  }

  String get fullDate {
    const fullMonths = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final m = (date.month >= 1 && date.month <= 12) ? fullMonths[date.month - 1] : '';
    return '$day $m ${date.year}';
  }

  String get formattedBmi {
    return bmi.toStringAsFixed(1).replaceAll('.', ',');
  }

  Color get riskColor {
    final r = risk.toLowerCase();
    if (r.contains('tinggi')) {
      return const Color(0xFFEF4444); // Red
    } else if (r.contains('sedang') || r.contains('meningkat') || r.contains('perhatian')) {
      return const Color(0xFFD97706); // Amber
    }
    return const Color(0xFF16A34A); // Green
  }

  Color get riskBg {
    final r = risk.toLowerCase();
    if (r.contains('tinggi')) {
      return const Color(0xFFFEE2E2);
    } else if (r.contains('sedang') || r.contains('meningkat') || r.contains('perhatian')) {
      return const Color(0xFFFEF3C7);
    }
    return const Color(0xFFDCFCE7);
  }

  Color get dotColor {
    final r = risk.toLowerCase();
    if (r.contains('tinggi')) {
      return const Color(0xFFF43F5E); // Pinkish-Red dot as in Figma
    } else if (r.contains('sedang') || r.contains('meningkat') || r.contains('perhatian')) {
      return const Color(0xFFEAB308); // Yellow dot as in Figma
    }
    return const Color(0xFF22C55E); // Green
  }

  /// Format data untuk penyimpanan lokal (SharedPreferences)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'bmi': bmi,
      'risk': risk,
      'category': category,
      'classificationCategory': skriningData.classificationCategory,
      'categoryTitle': skriningData.categoryTitle,
      'riskTitle': skriningData.riskTitle,
      // 16 Variabel Input Skrining sebagai field individual
      'gender': skriningData.gender,
      'age': skriningData.age,
      'height': skriningData.height,
      'weight': skriningData.weight,
      'familyHistory': skriningData.familyHistory,
      'highCalorieFood': skriningData.highCalorieFood,
      'vegetableIntake': skriningData.vegetableIntake,
      'mainMealFrequency': skriningData.mainMealFrequency,
      'snackFrequency': skriningData.snackFrequency,
      'smoking': skriningData.smoking,
      'waterIntake': skriningData.waterIntake,
      'monitorCalories': skriningData.monitorCalories,
      'physicalActivity': skriningData.physicalActivity,
      'screenTime': skriningData.screenTime,
      'alcohol': skriningData.alcohol,
      'transportation': skriningData.transportation,
      // Field Prediksi AI
      'aiRawClass': skriningData.aiRawClass,
      'aiRawCategoryKey': skriningData.aiRawCategoryKey,
      'aiRawCategoryTitle': skriningData.aiRawCategoryTitle,
      'aiClinicalClass': skriningData.aiClinicalClass,
      'aiCategoryKey': skriningData.aiCategoryKey,
      'aiCategoryTitle': skriningData.aiCategoryTitle,
      'aiCategoryBadge': skriningData.aiCategoryBadge,
      'isClinicallyAdjusted': skriningData.isClinicallyAdjusted,
      'clinicalAdjustmentReason': skriningData.clinicalAdjustmentReason,
      'aiConfidence': skriningData.aiConfidence,
      'isPredictionSuccess': skriningData.isPredictionSuccess,
      'predictionErrorMessage': skriningData.predictionErrorMessage,
      'skriningData': skriningData.toMap(),
    };
  }

  /// Format data untuk penyimpanan dokumen Cloud Firestore `users/{uid}/screenings/{id}`
  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'dateIso': date.toIso8601String(),
      'createdAt': FieldValue.serverTimestamp(),
      'bmi': bmi,
      'risk': risk,
      'category': category,
      'classificationCategory': skriningData.classificationCategory,
      'categoryTitle': skriningData.categoryTitle,
      'riskTitle': skriningData.riskTitle,
      // 16 Variabel Input Skrining Lengkap dengan tipe data Firestore
      'gender': skriningData.gender,
      'age': skriningData.age,
      'height': skriningData.height,
      'weight': skriningData.weight,
      'familyHistory': skriningData.familyHistory,
      'highCalorieFood': skriningData.highCalorieFood,
      'vegetableIntake': skriningData.vegetableIntake,
      'mainMealFrequency': skriningData.mainMealFrequency,
      'snackFrequency': skriningData.snackFrequency,
      'smoking': skriningData.smoking,
      'waterIntake': skriningData.waterIntake,
      'monitorCalories': skriningData.monitorCalories,
      'physicalActivity': skriningData.physicalActivity,
      'screenTime': skriningData.screenTime,
      'alcohol': skriningData.alcohol,
      'transportation': skriningData.transportation,
      // Field Prediksi AI
      'aiRawClass': skriningData.aiRawClass,
      'aiRawCategoryKey': skriningData.aiRawCategoryKey,
      'aiRawCategoryTitle': skriningData.aiRawCategoryTitle,
      'aiClinicalClass': skriningData.aiClinicalClass,
      'aiCategoryKey': skriningData.aiCategoryKey,
      'aiCategoryTitle': skriningData.aiCategoryTitle,
      'aiCategoryBadge': skriningData.aiCategoryBadge,
      'isClinicallyAdjusted': skriningData.isClinicallyAdjusted,
      'clinicalAdjustmentReason': skriningData.clinicalAdjustmentReason,
      'aiConfidence': skriningData.aiConfidence,
      'isPredictionSuccess': skriningData.isPredictionSuccess,
      'predictionErrorMessage': skriningData.predictionErrorMessage,
      // Salinan nested untuk kompatibilitas rekonstruksi instan
      'skriningData': skriningData.toMap(),
    };
  }

  factory ScreeningHistoryItem.fromMap(Map<String, dynamic> map) {
    DateTime dt;
    final dateVal = map['date'] ?? map['createdAt'];
    if (dateVal is Timestamp) {
      dt = dateVal.toDate();
    } else if (dateVal is String) {
      dt = DateTime.tryParse(dateVal) ?? DateTime.now();
    } else if (dateVal is int) {
      dt = DateTime.fromMillisecondsSinceEpoch(dateVal);
    } else {
      dt = DateTime.now();
    }

    // Rekonstruksi SkriningData: prioritaskan nested 'skriningData' jika ada,
    // atau gunakan top-level fields jika disimpan secara datar
    SkriningData data;
    if (map['skriningData'] is Map && (map['skriningData'] as Map).isNotEmpty) {
      data = SkriningData.fromMap(
        Map<String, dynamic>.from(map['skriningData'] as Map),
      );
    } else {
      data = SkriningData.fromMap(map);
    }
    data.date = dt;

    final bmiVal = (map['bmi'] as num?)?.toDouble() ?? data.bmi;
    final riskVal = map['risk'] as String? ?? data.riskTitle;
    final catVal = map['category'] as String? ?? data.categoryTitle.replaceAll('\n', ' ');

    return ScreeningHistoryItem(
      id: map['id'] as String? ?? 'scr_${dt.millisecondsSinceEpoch}',
      userId: map['userId'] as String? ?? 'usr_guest',
      date: dt,
      bmi: bmiVal,
      risk: riskVal,
      category: catVal,
      skriningData: data,
    );
  }
}
