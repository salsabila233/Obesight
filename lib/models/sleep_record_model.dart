import 'package:cloud_firestore/cloud_firestore.dart';

class SleepRecord {
  final String id;
  final String userId;
  final String date; // Format: yyyy-MM-dd (tanggal sesi tidur dicatat)
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final String source; // 'automatic' (aktivitas HP) atau 'manual' (input pengguna)
  final bool isConfirmed; // Flag status konfirmasi pencatatan tidur
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
    this.isConfirmed = true,
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

  /// Standar ideal tidur malam menurut acuan kesehatan (8 jam = 480 menit)
  static const int standardIdealMinutes = 8 * 60;

  /// Penilaian status berdasarkan acuan standar ideal tidur 8 jam:
  /// - < 8 jam (< 480 menit): "Tidur Kurang"
  /// - >= 8 jam (>= 480 menit): "Tidur Cukup"
  String get standard8HoursCategory =>
      durationMinutes < standardIdealMinutes ? 'Tidur Kurang' : 'Tidur Cukup';

  /// Status ideal acuan 8 jam ("Tidur Kurang" atau "Ideal")
  String get standard8HoursStatus =>
      durationMinutes < standardIdealMinutes ? 'Tidur Kurang' : 'Ideal';

  /// Apakah durasi tidur mencapai standar ideal (>= 8 jam)
  bool get isIdeal8Hours => durationMinutes >= standardIdealMinutes;

  /// Apakah durasi tidur kurang dari standar ideal (< 8 jam)
  bool get isUnder8Hours => durationMinutes < standardIdealMinutes;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'user_id': userId,
      'date': date,
      'tanggal': date,
      'startTime': startTime.toUtc().toIso8601String(),
      'waktu_mulai': startTime.toUtc().toIso8601String(),
      'endTime': endTime.toUtc().toIso8601String(),
      'waktu_bangun': endTime.toUtc().toIso8601String(),
      'durationMinutes': durationMinutes,
      'duration': durationMinutes,
      'durasi': durationMinutes,
      'source': source,
      'sumber_data': source,
      'isConfirmed': isConfirmed,
      'status_konfirmasi': isConfirmed,
      'status': isConfirmed ? 'confirmed' : 'pending',
      'createdAt': createdAt.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'note': note,
      'catatan': note,
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'userId': userId,
      'user_id': userId,
      'date': date,
      'tanggal': date,
      'startTime': Timestamp.fromDate(startTime.toUtc()),
      'waktu_mulai': Timestamp.fromDate(startTime.toUtc()),
      'endTime': Timestamp.fromDate(endTime.toUtc()),
      'waktu_bangun': Timestamp.fromDate(endTime.toUtc()),
      'durationMinutes': durationMinutes,
      'duration': durationMinutes,
      'durasi': durationMinutes,
      'source': source,
      'sumber_data': source,
      'isConfirmed': isConfirmed,
      'status_konfirmasi': isConfirmed,
      'status': isConfirmed ? 'confirmed' : 'pending',
      'createdAt': Timestamp.fromDate(createdAt.toUtc()),
      'created_at': Timestamp.fromDate(createdAt.toUtc()),
      'updatedAt': Timestamp.fromDate(updatedAt.toUtc()),
      'updated_at': Timestamp.fromDate(updatedAt.toUtc()),
      'note': note,
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

  factory SleepRecord.fromMap(Map<String, dynamic> map, [String? docId, String? defaultUserId]) {
    final startRaw = map['startTime'] ?? map['waktu_mulai'];
    final endRaw = map['endTime'] ?? map['waktu_bangun'];
    final start = _parseDateTime(startRaw, DateTime.now());
    final end = _parseDateTime(endRaw, start.add(const Duration(hours: 7)));

    final createdRaw = map['createdAt'] ?? map['created_at'];
    final updatedRaw = map['updatedAt'] ?? map['updated_at'];

    final rawDuration = map['durationMinutes'] ?? map['duration'] ?? map['durasi'];
    final rawConfirmed = map['isConfirmed'] ?? map['status_konfirmasi'] ?? map['is_confirmed'] ?? (map['status'] == 'confirmed');

    // Gunakan tanggal waktu bangun (pagi hari sesi tidur malam) sebagai fallback jika tanggal kosong
    final fallbackDate = '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';

    return SleepRecord(
      id: docId ?? (map['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString()),
      userId: (map['userId'] ?? map['user_id']) as String? ?? defaultUserId ?? 'guest_user',
      date: (map['date'] ?? map['tanggal']) as String? ?? fallbackDate,
      startTime: start,
      endTime: end,
      durationMinutes: rawDuration is int ? rawDuration : (rawDuration is num ? rawDuration.toInt() : null),
      source: (map['source'] ?? map['sumber_data']) as String? ?? 'manual',
      isConfirmed: rawConfirmed == null ? true : (rawConfirmed == true || rawConfirmed == 1 || rawConfirmed == 'true' || rawConfirmed == 'confirmed'),
      createdAt: createdRaw != null ? _parseDateTime(createdRaw, DateTime.now()) : null,
      updatedAt: updatedRaw != null ? _parseDateTime(updatedRaw, DateTime.now()) : null,
      note: (map['note'] ?? map['catatan']) as String?,
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
    bool? isConfirmed,
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
      isConfirmed: isConfirmed ?? this.isConfirmed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      note: note ?? this.note,
    );
  }
}
