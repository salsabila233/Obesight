import 'package:flutter/material.dart';

enum RestType {
  day,
  night,
}

class RestReminderData {
  final RestType type;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final DateTime date;
  final bool isSet;

  const RestReminderData({
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.date,
    this.isSet = true,
  });

  int get durationMinutes {
    int startMinutes = startTime.hour * 60 + startTime.minute;
    int endMinutes = endTime.hour * 60 + endTime.minute;
    int diff = endMinutes - startMinutes;
    if (diff <= 0) {
      diff += 24 * 60;
    }
    return diff;
  }

  int get durationHours => durationMinutes ~/ 60;
  int get durationRemainingMinutes => durationMinutes % 60;

  String get durationDisplay {
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

  /// Format as shown in reference Gambar 3: e.g. "7 j 0 m" or "1 j 0 m"
  String get shortDurationDisplay {
    final h = durationHours;
    final m = durationRemainingMinutes;
    return '$h j $m m';
  }

  String get startTimeFormatted {
    final h = startTime.hour.toString().padLeft(2, '0');
    final m = startTime.minute.toString().padLeft(2, '0');
    return '$h.$m';
  }

  String get endTimeFormatted {
    final h = endTime.hour.toString().padLeft(2, '0');
    final m = endTime.minute.toString().padLeft(2, '0');
    return '$h.$m';
  }

  String get timeRangeFormatted => '$startTimeFormatted - $endTimeFormatted';
}

class RestReminderService extends ChangeNotifier {
  static final RestReminderService _instance = RestReminderService._internal();
  factory RestReminderService() => _instance;
  static RestReminderService get instance => _instance;
  RestReminderService._internal();

  RestReminderData? _dayRestReminder;
  RestReminderData? _nightSleepReminder;

  RestReminderData? get dayRestReminder => _dayRestReminder;
  RestReminderData? get nightSleepReminder => _nightSleepReminder;

  bool get hasDayRestReminder => _dayRestReminder != null && _dayRestReminder!.isSet;
  bool get hasNightSleepReminder => _nightSleepReminder != null && _nightSleepReminder!.isSet;

  RestReminderData? getReminder(RestType type) {
    return type == RestType.day ? _dayRestReminder : _nightSleepReminder;
  }

  bool hasReminder(RestType type) {
    return type == RestType.day ? hasDayRestReminder : hasNightSleepReminder;
  }

  void saveReminder({
    required RestType type,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    DateTime? date,
  }) {
    final reminder = RestReminderData(
      type: type,
      startTime: startTime,
      endTime: endTime,
      date: date ?? DateTime.now(),
      isSet: true,
    );

    if (type == RestType.day) {
      _dayRestReminder = reminder;
    } else {
      _nightSleepReminder = reminder;
    }
    notifyListeners();
  }

  void removeReminder(RestType type) {
    if (type == RestType.day) {
      _dayRestReminder = null;
    } else {
      _nightSleepReminder = null;
    }
    notifyListeners();
  }

  void reset() {
    _dayRestReminder = null;
    _nightSleepReminder = null;
    notifyListeners();
  }
}
