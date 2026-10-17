import 'package:cloud_firestore/cloud_firestore.dart';

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
    required DateTime endTime,
    int? durationMinutes,
    this.source = 'manual',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.note,
  })  : endTime = (endTime.isBefore(startTime)) ? endTime.add(const Duration(days: 1)) : endTime,
        durationMinutes = durationMinutes != null && durationMinutes > 0
            ? durationMinutes
            : calculateDurationMinutes(
                startTime,
                endTime.isBefore(startTime) ? endTime.add(const Duration(days: 1)) : endTime,
              ),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Menghitung durasi tidur dalam menit dengan benar, menangani pergantian hari (melewati tengah malam)
  static int calculateDurationMinutes(DateTime start, DateTime end) {
    if (start.isAtSameMomentAs(end)) return 0;
    var effectiveEnd = end;
    if (effectiveEnd.isBefore(start)) {
      effectiveEnd = effectiveEnd.add(const Duration(days: 1));
    }
    final diff = effectiveEnd.difference(start).inMinutes;
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
      'waktu_mulai': startTime.toUtc().toIso8601String(),
      'waktu_bangun': endTime.toUtc().toIso8601String(),
      'durasi': durationMinutes,
      'sumber_data': source,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'catatan': note,
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'user_id': userId,
      'tanggal': date,
      'waktu_mulai': Timestamp.fromDate(startTime.toUtc()),
      'waktu_bangun': Timestamp.fromDate(endTime.toUtc()),
      'durasi': durationMinutes,
      'sumber_data': source,
      'created_at': Timestamp.fromDate(createdAt.toUtc()),
      'updated_at': Timestamp.fromDate(updatedAt.toUtc()),
      'catatan': note,
    };
  }

  static DateTime _parseDateTime(dynamic val, DateTime fallback) {
    if (val == null) return fallback;
    if (val is Timestamp) return val.toDate().toLocal();
    if (val is DateTime) return val.toLocal();
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val).toLocal();
    if (val is String) {
      final parsed = DateTime.tryParse(val);
      if (parsed != null) return parsed.toLocal();
    }
    return fallback;
  }

  factory SleepRecord.fromMap(Map<String, dynamic> map, [String? docId]) {
    final startRaw = map['waktu_mulai'] ?? map['startTime'];
    final endRaw = map['waktu_bangun'] ?? map['endTime'];
    final start = _parseDateTime(startRaw, DateTime.now());
    final end = _parseDateTime(endRaw, start.add(const Duration(hours: 7)));

    final createdRaw = map['created_at'] ?? map['createdAt'];
    final updatedRaw = map['updated_at'] ?? map['updatedAt'];

    return SleepRecord(
      id: docId ?? (map['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString()),
      userId: (map['user_id'] ?? map['userId']) as String? ?? 'guest',
      date: (map['tanggal'] ?? map['date']) as String? ??
          '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}',
      startTime: start,
      endTime: end,
      durationMinutes: (map['durasi'] ?? map['duration']) as int?,
      source: (map['sumber_data'] ?? map['source']) as String? ?? 'manual',
      createdAt: createdRaw != null ? _parseDateTime(createdRaw, DateTime.now()) : null,
      updatedAt: updatedRaw != null ? _parseDateTime(updatedRaw, DateTime.now()) : null,
      note: (map['catatan'] ?? map['note']) as String?,
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
