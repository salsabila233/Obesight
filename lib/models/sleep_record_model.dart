class SleepRecord {
  final String id;
  final String userId;
  final String date; // Format: yyyy-MM-dd (tanggal sesi tidur dicatat)
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final String source; // 'automatic' (aktivitas HP) atau 'manual' (input pengguna)
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? note;

  SleepRecord({
    required this.id,
    required this.userId,
    required this.date,
    required this.startTime,
    required this.endTime,
    int? durationMinutes,
    this.source = 'manual',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.note,
  })  : durationMinutes = durationMinutes ?? calculateDurationMinutes(startTime, endTime),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Menghitung durasi tidur dalam menit dengan benar, menangani pergantian hari (melewati tengah malam)
  static int calculateDurationMinutes(DateTime start, DateTime end) {
    var diff = end.difference(start).inMinutes;
    if (diff <= 0) {
      // Jika waktu bangun terlihat lebih awal dari waktu mulai di hari yang sama,
      // diasumsikan waktu bangun adalah hari berikutnya (+24 jam)
      diff += 24 * 60;
    }
    return diff > 0 ? diff : 0;
  }

  int get durationHours => durationMinutes ~/ 60;
  int get durationRemainingMinutes => durationMinutes % 60;

  String get durationFormatted {
    final h = durationHours;
    final m = durationRemainingMinutes;
    if (h > 0 && m > 0) {
      return '$h jam $m menit';
    } else if (h > 0) {
      return '$h jam';
    } else {
      return '$m menit';
    }
  }

  /// Format ringkas: e.g. "7j 45m" atau "5j 10m"
  String get shortDurationFormatted {
    final h = durationHours;
    final m = durationRemainingMinutes;
    if (h > 0 && m > 0) {
      return '${h}j ${m}m';
    } else if (h > 0) {
      return '${h}j';
    } else {
      return '${m}m';
    }
  }

  String get startTimeFormatted {
    final h = startTime.hour.toString().padLeft(2, '0');
    final m = startTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get endTimeFormatted {
    final h = endTime.hour.toString().padLeft(2, '0');
    final m = endTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get timeRangeFormatted => '$startTimeFormatted – $endTimeFormatted';

  bool get isAutomatic => source == 'automatic';

  String get sourceLabel =>
      isAutomatic ? 'Perkiraan berdasarkan aktivitas HP' : 'Dicatat oleh pengguna';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'tanggal': date,
      'waktu_mulai': startTime.toIso8601String(),
      'waktu_bangun': endTime.toIso8601String(),
      'durasi': durationMinutes,
      'sumber_data': source,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'catatan': note,
    };
  }

  factory SleepRecord.fromMap(Map<String, dynamic> map, [String? docId]) {
    final startStr = map['waktu_mulai'] as String?;
    final endStr = map['waktu_bangun'] as String?;
    final start = startStr != null ? DateTime.parse(startStr) : DateTime.now();
    final end = endStr != null ? DateTime.parse(endStr) : DateTime.now().add(const Duration(hours: 7));

    return SleepRecord(
      id: docId ?? (map['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString()),
      userId: (map['user_id'] ?? map['userId']) as String? ?? 'guest',
      date: (map['tanggal'] ?? map['date']) as String? ??
          '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}',
      startTime: start,
      endTime: end,
      durationMinutes: (map['durasi'] ?? map['duration']) as int?,
      source: (map['sumber_data'] ?? map['source']) as String? ?? 'manual',
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
      note: map['catatan'] as String?,
    );
  }

  SleepRecord copyWith({
    String? id,
    String? userId,
    String? date,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    String? source,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? note,
  }) {
    return SleepRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      note: note ?? this.note,
    );
  }
}
