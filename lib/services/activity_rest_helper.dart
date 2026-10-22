import 'package:flutter/material.dart';

/// Model untuk opsi durasi istirahat
class RestOption {
  final int minutes;
  final String label;
  final String subtitle;

  const RestOption({
    required this.minutes,
    required this.label,
    required this.subtitle,
  });
}

/// Helper untuk menentukan rekomendasi durasi aktivitas fisik dan istirahat
/// berdasarkan jenis aktivitas fisik, intensitas, dan durasi yang telah dijalankan.
class ActivityRestHelper {
  /// Batas minimal durasi aktivitas fisik (menit)
  static const int minActivityDurationMinutes = 15;

  /// Batas maksimal durasi aktivitas fisik (menit)
  static const int maxActivityDurationMinutes = 60;

  /// Seluruh pilihan opsi istirahat yang tersedia di Obesight
  static const List<RestOption> allRestOptions = [
    RestOption(
      minutes: 5,
      label: '5 menit',
      subtitle: '(Ringan / aktivitas ringan)',
    ),
    RestOption(
      minutes: 10,
      label: '10 menit',
      subtitle: '(Jalan cepat / yoga ringan)',
    ),
    RestOption(
      minutes: 15,
      label: '15 menit',
      subtitle: '(Senam / bersepeda ringan)',
    ),
    RestOption(
      minutes: 20,
      label: '20 menit',
      subtitle: '(Lari / HIIT ringan)',
    ),
    RestOption(
      minutes: 30,
      label: '30 menit',
      subtitle: '(Latihan intensitas tinggi)',
    ),
  ];

  /// Memvalidasi durasi aktivitas fisik agar berada dalam rentang 15-60 menit
  static int clampActivityDuration(int minutes) {
    if (minutes < minActivityDurationMinutes) return minActivityDurationMinutes;
    if (minutes > maxActivityDurationMinutes) return maxActivityDurationMinutes;
    return minutes;
  }

  /// Rekomendasi durasi awal aktivitas fisik berdasarkan jenis aktivitas
  static int getRecommendedActivityDuration(Map<String, dynamic>? activity) {
    if (activity == null) return 30;
    final id = (activity['id'] as String? ?? '').toLowerCase();
    final title = (activity['title'] as String? ?? '').toLowerCase();
    final name = (activity['name'] as String? ?? '').toLowerCase();
    final combined = '$id $title $name';

    if (combined.contains('hiit') || combined.contains('interval')) {
      return 20; // HIIT biasanya durasi lebih pendek namun intens
    } else if (combined.contains('yoga') || combined.contains('stretching') || combined.contains('peregangan')) {
      return 20;
    } else if (combined.contains('jogging') || combined.contains('lari')) {
      return 30;
    } else if (combined.contains('sepeda') || combined.contains('cycling')) {
      return 30;
    } else if (combined.contains('senam') || combined.contains('aerobik')) {
      return 30;
    } else if (combined.contains('bodyweight') || combined.contains('gym') || combined.contains('kekuatan')) {
      return 30;
    } else if (combined.contains('jalan') || combined.contains('walk')) {
      return 30;
    }
    return 30;
  }

  /// Dapatkan daftar opsi durasi istirahat yang tersedia sesuai jenis aktivitas
  static List<RestOption> getAvailableRestOptions(Map<String, dynamic>? activity) {
    if (activity == null) return allRestOptions;
    final id = (activity['id'] as String? ?? '').toLowerCase();
    final title = (activity['title'] as String? ?? '').toLowerCase();
    final name = (activity['name'] as String? ?? '').toLowerCase();
    final combined = '$id $title $name';

    if (combined.contains('hiit') || combined.contains('interval') || combined.contains('lari') || combined.contains('jogging')) {
      // Lari / HIIT ringan: 10, 15, 20, 30 menit
      return allRestOptions.where((opt) => opt.minutes >= 10).toList();
    } else if (combined.contains('tinggi') || combined.contains('berat') || combined.contains('intensitas tinggi')) {
      // Latihan intensitas tinggi: 15, 20, 30 menit
      return allRestOptions.where((opt) => opt.minutes >= 15).toList();
    }
    return allRestOptions;
  }

  /// Menentukan rekomendasi durasi istirahat secara kontekstual
  /// berdasarkan jenis aktivitas dan durasi yang telah diselesaikan
  static int getRecommendedRestMinutes({
    Map<String, dynamic>? activity,
    int? completedDurationMinutes,
  }) {
    if (activity == null) return 10;
    final id = (activity['id'] as String? ?? '').toLowerCase();
    final title = (activity['title'] as String? ?? '').toLowerCase();
    final name = (activity['name'] as String? ?? '').toLowerCase();
    final combined = '$id $title $name';

    if (combined.contains('hiit') || combined.contains('interval') || combined.contains('lari') || combined.contains('jogging')) {
      if ((completedDurationMinutes ?? 0) >= 45) return 30;
      return 20;
    } else if (combined.contains('tinggi') || combined.contains('berat') || combined.contains('intensitas tinggi')) {
      return 30;
    } else if (combined.contains('sepeda') || combined.contains('cycling') || combined.contains('senam') || combined.contains('bodyweight') || combined.contains('aerobik')) {
      return 15;
    } else if (combined.contains('jalan') || combined.contains('walk')) {
      return 10;
    } else if (combined.contains('yoga') || combined.contains('stretching') || combined.contains('peregangan')) {
      if ((completedDurationMinutes ?? 0) > 30) return 10;
      return 5;
    }
    return 10;
  }

  /// Ikon aktivitas fisik yang sesuai
  static IconData getActivityIcon(Map<String, dynamic>? activity) {
    if (activity == null) return Icons.fitness_center_rounded;
    final isRest = activity['isRest'] == true;
    if (isRest) return Icons.spa_rounded;

    final id = (activity['id'] as String? ?? '').toLowerCase();
    final title = (activity['title'] as String? ?? '').toLowerCase();
    final combined = '$id $title';

    if (combined.contains('jogging') || combined.contains('lari') || combined.contains('jalan')) {
      return Icons.directions_run_rounded;
    } else if (combined.contains('sepeda') || combined.contains('cycling')) {
      return Icons.directions_bike_rounded;
    } else if (combined.contains('yoga') || combined.contains('stretching')) {
      return Icons.self_improvement_rounded;
    } else if (combined.contains('hiit') || combined.contains('interval')) {
      return Icons.bolt_rounded;
    } else if (combined.contains('bodyweight') || combined.contains('gym') || combined.contains('kekuatan')) {
      return Icons.fitness_center_rounded;
    }
    return Icons.fitness_center_rounded;
  }
}
