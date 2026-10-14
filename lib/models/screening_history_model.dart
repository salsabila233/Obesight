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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'bmi': bmi,
      'risk': risk,
      'category': category,
      'skriningData': skriningData.toMap(),
    };
  }

  factory ScreeningHistoryItem.fromMap(Map<String, dynamic> map) {
    final dt = DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now();
    final data = SkriningData.fromMap(
      Map<String, dynamic>.from(map['skriningData'] as Map? ?? {}),
    );
    data.date = dt;
    return ScreeningHistoryItem(
      id: map['id'] as String? ?? 'scr_${dt.millisecondsSinceEpoch}',
      userId: map['userId'] as String? ?? 'usr_guest',
      date: dt,
      bmi: (map['bmi'] as num?)?.toDouble() ?? data.bmi,
      risk: map['risk'] as String? ?? 'Sedang',
      category: map['category'] as String? ?? 'Overweight (IMT 25–27)',
      skriningData: data,
    );
  }
}
