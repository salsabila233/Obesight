import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/sleep_record_model.dart';
import 'auth_service.dart';
import 'rest_reminder_service.dart';

class DailySleepSummary {
  final DateTime date;
  final String dateKey;
  final String dayName;
  final String dayNumber;
  final int totalMinutes;
  final List<SleepRecord> records;
  final bool isToday;

  const DailySleepSummary({
    required this.date,
    required this.dateKey,
    required this.dayName,
    required this.dayNumber,
    required this.totalMinutes,
    required this.records,
    required this.isToday,
  });

  bool get hasData => totalMinutes > 0;
  int get hours => totalMinutes ~/ 60;
  int get remainingMinutes => totalMinutes % 60;
  String get formattedDuration {
    if (totalMinutes <= 0) return '-';
    if (hours > 0 && remainingMinutes > 0) return '${hours}j ${remainingMinutes}m';
    if (hours > 0) return '${hours}j';
    return '${remainingMinutes}m';
  }

  /// Standar ideal tidur malam 8 jam (480 menit)
  static const int standardIdealMinutes = 8 * 60;

  /// Kategori penilaian acuan standar tidur 8 jam: "Tidur Kurang" (< 8 jam) atau "Tidur Cukup" (>= 8 jam)
  String get standard8HoursCategory =>
      totalMinutes < standardIdealMinutes ? 'Tidur Kurang' : 'Tidur Cukup';

  /// Status ideal acuan 8 jam: "Tidur Kurang" atau "Ideal"
  String get standard8HoursStatus =>
      totalMinutes < standardIdealMinutes ? 'Tidur Kurang' : 'Ideal';

  /// Memeriksa apakah durasi tidur mencapai standar ideal 8 jam
  bool get isIdeal8Hours => totalMinutes >= standardIdealMinutes;
}

class WeeklySleepSummary {
  final String weekLabel;
  final DateTime startDate;
  final DateTime endDate;
  final double averageMinutesPerDay;
  final int totalMinutes;
  final int daysWithData;
  final bool isCurrentWeek;

  const WeeklySleepSummary({
    required this.weekLabel,
    required this.startDate,
    required this.endDate,
    required this.averageMinutesPerDay,
    required this.totalMinutes,
    required this.daysWithData,
    required this.isCurrentWeek,
  });

  bool get hasData => totalMinutes > 0;
  int get averageHours => averageMinutesPerDay ~/ 60;
  int get averageRemainingMinutes => (averageMinutesPerDay % 60).round();
  String get formattedAverage {
    if (averageMinutesPerDay <= 0) return '-';
    if (averageHours > 0 && averageRemainingMinutes > 0) {
      return '${averageHours}j ${averageRemainingMinutes}m';
    }
    if (averageHours > 0) return '${averageHours}j';
    return '${averageRemainingMinutes}m';
  }
}

class MonthlySleepSummary {
  final String monthLabel;
  final int month;
  final int year;
  final double averageMinutesPerDay;
  final int totalMinutes;
  final int daysWithData;
  final bool isCurrentMonth;

  const MonthlySleepSummary({
    required this.monthLabel,
    required this.month,
    required this.year,
    required this.averageMinutesPerDay,
    required this.totalMinutes,
    required this.daysWithData,
    required this.isCurrentMonth,
  });

  bool get hasData => totalMinutes > 0;
  int get averageHours => averageMinutesPerDay ~/ 60;
  int get averageRemainingMinutes => (averageMinutesPerDay % 60).round();
  String get formattedAverage {
    if (averageMinutesPerDay <= 0) return '-';
    if (averageHours > 0 && averageRemainingMinutes > 0) {
      return '${averageHours}j ${averageRemainingMinutes}m';
    }
    if (averageHours > 0) return '${averageHours}j';
    return '${averageRemainingMinutes}m';
  }
}

class CalendarMonthSummary {
  final int month;
  final int year;
  final String monthLabel;
  final int totalMinutes;
  final int daysWithData;
  final int totalDaysInMonth;
  final double averageMinutesPerDay;
  final List<DailySleepSummary> dailySummaries;
  final List<WeeklySleepSummary> weeklyChunks;

  const CalendarMonthSummary({
    required this.month,
    required this.year,
    required this.monthLabel,
    required this.totalMinutes,
    required this.daysWithData,
    required this.totalDaysInMonth,
    required this.averageMinutesPerDay,
    required this.dailySummaries,
    required this.weeklyChunks,
  });

  bool get hasData => totalMinutes > 0;
  int get averageHours => averageMinutesPerDay ~/ 60;
  int get averageRemainingMinutes => (averageMinutesPerDay % 60).round();
  int get totalHours => totalMinutes ~/ 60;
  int get totalRemainingMinutes => totalMinutes % 60;
  String get formattedAverage {
    if (averageMinutesPerDay <= 0) return '-';
    if (averageHours > 0 && averageRemainingMinutes > 0) {
      return '${averageHours}j ${averageRemainingMinutes}m';
    }
    if (averageHours > 0) return '${averageHours}j';
    return '${averageRemainingMinutes}m';
  }
}

class SingleWeekSummary {
  final DateTime startDate;
  final DateTime endDate;
  final String weekLabel;
  final int totalMinutes;
  final int daysWithData;
  final double averageMinutesPerDay;
  final List<DailySleepSummary> days;
  final String averageBedtime;
  final String averageWakeTime;

  const SingleWeekSummary({
    required this.startDate,
    required this.endDate,
    required this.weekLabel,
    required this.totalMinutes,
    required this.daysWithData,
    required this.averageMinutesPerDay,
    required this.days,
    required this.averageBedtime,
    required this.averageWakeTime,
  });

  bool get hasData => totalMinutes > 0;
  int get totalHours => totalMinutes ~/ 60;
  int get totalRemainingMinutes => totalMinutes % 60;
  int get averageHours => averageMinutesPerDay ~/ 60;
  int get averageRemainingMinutes => (averageMinutesPerDay % 60).round();
  String get formattedAverage {
    if (averageMinutesPerDay <= 0) return '-';
    if (averageHours > 0 && averageRemainingMinutes > 0) {
      return '${averageHours}j ${averageRemainingMinutes}m';
    }
    if (averageHours > 0) return '${averageHours}j';
    return '${averageRemainingMinutes}m';
  }
}

class HourlySleepData {
  final int hour;
  final String label;
  final int minutesSlept;
  final bool isAsleep;

  const HourlySleepData({
    required this.hour,
    required this.label,
    required this.minutesSlept,
    required this.isAsleep,
  });

  double get fraction => (minutesSlept / 60.0).clamp(0.0, 1.0);
}

class SleepTrackingService extends ChangeNotifier with WidgetsBindingObserver {
  static final SleepTrackingService _instance = SleepTrackingService._internal();
  factory SleepTrackingService() => _instance;
  static SleepTrackingService get instance => _instance;

  static const String _keyRecords = 'obesight_sleep_records_v1';
  static const String _keyPendingAuto = 'obesight_pending_auto_v1';
  static const String _keyLastInactive = 'obesight_last_inactive_time_v1';
  static const String _keyLastNightInactive = 'obesight_last_night_inactive_time_v1';
  static const String _keyReminderEnabled = 'obesight_sleep_reminder_enabled_v1';
  static const String _keyBedtimeTargetH = 'obesight_sleep_bedtime_target_h_v1';
  static const String _keyBedtimeTargetM = 'obesight_sleep_bedtime_target_m_v1';
  static const String _keyReminderMinutesBefore = 'obesight_sleep_reminder_mins_v1';
  static const MethodChannel _platformChannel = MethodChannel('com.obesight.obesight/device_activity');

  static bool get _isNativeSupported {
    if (kIsWeb) return false;
    try {
      if (Platform.environment.containsKey('FLUTTER_TEST')) return false;
    } catch (_) {
      return false;
    }
    return true;
  }

  SleepTrackingService._internal();

  bool _isInitialized = false;

  // Inactivity & sensor tracking parameters
  int _minimumInactivityMinutes = 15; // Batas minimum tidak aktif HP (default: 15 menit)
  static const int _minimumNightSleepMinutes = 180; // Minimal 3 jam (180 menit) untuk sesi tidur malam
  DateTime? _lastInactiveTime;
  DateTime? _lastNightInactiveTime;
  DateTime? _lastScreenOffTime;
  DateTime? _lastScreenOnTime;
  DateTime? _lastDarkTime;
  DateTime? _lastLightRiseTime;
  double _currentAmbientLux = -1.0;
  SleepRecord? _pendingAutoDetectedRecord;

  // User target & reminder settings
  int _targetSleepMinutes = 8 * 60; // 8 jam (480 menit)
  bool _reminderEnabled = true;
  TimeOfDay _bedtimeTarget = const TimeOfDay(hour: 22, minute: 30); // 22:30
  int _reminderMinutesBefore = 60; // 1 jam sebelum waktu tidur (21:30)

  // In-memory list of sleep records
  final List<SleepRecord> _records = [];

  // Local notifications plugin
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _notificationsInitialized = false;
  static const int _sleepReminderNotificationId = 88101;
  static const int _testNotificationId = 88102;
  static const String _sleepChannelId = 'sleep_reminder_channel_v2';
  static const String _sleepChannelName = 'Pengingat Waktu Tidur';

  // Getters
  int get minimumInactivityMinutes => _minimumInactivityMinutes;
  set minimumInactivityMinutes(int val) {
    _minimumInactivityMinutes = val > 0 ? val : 15;
    notifyListeners();
  }

  DateTime? get lastInactiveTime => _lastInactiveTime;
  DateTime? get lastNightInactiveTime => _lastNightInactiveTime;
  DateTime? get lastScreenOffTime => _lastScreenOffTime;
  DateTime? get lastScreenOnTime => _lastScreenOnTime;
  DateTime? get lastDarkTime => _lastDarkTime;
  DateTime? get lastLightRiseTime => _lastLightRiseTime;
  double get currentAmbientLux => _currentAmbientLux;
  bool get isSensorTrackingActive => _isInitialized;
  SleepRecord? get pendingAutoDetectedRecord => _pendingAutoDetectedRecord;

  /// Membaca intensitas cahaya lingkungan (ambient light lux) dari sensor perangkat
  Future<double?> getAmbientLux() async {
    if (!_isNativeSupported) return null;
    try {
      final lux = await _platformChannel.invokeMethod<num>('getAmbientLux');
      if (lux != null) {
        _currentAmbientLux = lux.toDouble();
        return _currentAmbientLux;
      }
    } catch (_) {}
    return null;
  }

  /// Seluruh catatan tidur yang tersimpan (1 Tanggal = Maksimal 1 Data Unik)
  List<SleepRecord> get allRecords {
    final Map<String, SleepRecord> uniqueByDate = {};
    final list = List<SleepRecord>.from(_records);
    list.sort((a, b) => b.startTime.compareTo(a.startTime));
    for (final rec in list) {
      uniqueByDate.putIfAbsent(rec.date, () => rec);
    }
    return uniqueByDate.values.toList();
  }

  /// Memeriksa ketersediaan ekosistem kesehatan bawaan OS (Health Connect / Google Fit / Samsung Health)
  Future<bool> checkHealthEcosystemAvailable() async {
    if (kIsWeb) return false;
    try {
      final available = await _platformChannel.invokeMethod<bool>('checkHealthEcosystemAvailable');
      return available ?? false;
    } catch (_) {
      return false;
    }
  }

  int get targetSleepMinutes => _targetSleepMinutes;
  set targetSleepMinutes(int val) {
    _targetSleepMinutes = val;
    notifyListeners();
  }

  bool get reminderEnabled => _reminderEnabled;
  set reminderEnabled(bool val) {
    _reminderEnabled = val;
    _saveToLocal();
    if (val) {
      scheduleBedtimeNotification();
    } else {
      cancelBedtimeNotification();
    }
    notifyListeners();
  }

  TimeOfDay get bedtimeTarget => _bedtimeTarget;
  set bedtimeTarget(TimeOfDay val) {
    _bedtimeTarget = val;
    _saveToLocal();
    if (_reminderEnabled) {
      scheduleBedtimeNotification();
    }
    notifyListeners();
  }

  int get reminderMinutesBefore => _reminderMinutesBefore;
  set reminderMinutesBefore(int val) {
    _reminderMinutesBefore = val;
    _saveToLocal();
    if (_reminderEnabled) {
      scheduleBedtimeNotification();
    }
    notifyListeners();
  }

  TimeOfDay get reminderTime {
    int targetMinutes = _bedtimeTarget.hour * 60 + _bedtimeTarget.minute;
    int reminderM = targetMinutes - _reminderMinutesBefore;
    if (reminderM < 0) reminderM += 24 * 60;
    return TimeOfDay(hour: reminderM ~/ 60, minute: reminderM % 60);
  }

  String get reminderMessage =>
      'Waktu tidurmu semakin dekat 🌙\nYuk mulai bersiap untuk beristirahat agar metabolisme tetap optimal.';

  String get currentUserId => AuthService().currentUser?.id ?? 'guest_user';

  static bool isMatchingUser(String recordUserId, String currentUid) {
    if (recordUserId == currentUid) return true;
    final isCurrentGuest = currentUid == 'guest_user' || currentUid == 'guest' || currentUid.isEmpty;
    final isRecordGuest = recordUserId == 'guest_user' || recordUserId == 'guest' || recordUserId.isEmpty;
    if (isCurrentGuest && isRecordGuest) return true;
    if (!isCurrentGuest && isRecordGuest) return true;
    return false;
  }

  static String formatDateKey(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  static String formatIndonesianDateFull(DateTime date) {
    const dayNames = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    const monthNames = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final dayName = dayNames[date.weekday % 7];
    final monthName = monthNames[date.month];
    return '$dayName, ${date.day} $monthName ${date.year}';
  }

  /// Initialize observer & start tracking, loading data from local SharedPreferences
  Future<void> initialize() async {
    if (!_isInitialized) {
      _isInitialized = true;
      WidgetsBinding.instance.addObserver(this);
    }
    await _loadFromLocal();
    await initNotifications();
    await checkDeviceInactivityCandidate();
    _loadFromFirestore();
    startFirestoreRealtimeListener();
  }

  void disposeObserver() {
    WidgetsBinding.instance.removeObserver(this);
    _firestoreSubscription?.cancel();
    _isInitialized = false;
  }

  // ==========================================
  // NOTIFICATION SYSTEM (Local Push Notifications)
  // ==========================================

  void _configureLocalTimeZone() {
    try {
      tz.initializeTimeZones();
      final String currentTimeZone = DateTime.now().timeZoneName;
      if (tz.timeZoneDatabase.locations.containsKey(currentTimeZone)) {
        tz.setLocalLocation(tz.getLocation(currentTimeZone));
        return;
      }
      // Cocokkan offset waktu perangkat lokal
      final offset = DateTime.now().timeZoneOffset;
      tz.Location? matchedLocation;
      for (final loc in tz.timeZoneDatabase.locations.values) {
        if (loc.currentTimeZone.offset == offset) {
          matchedLocation = loc;
          break;
        }
      }
      if (matchedLocation != null) {
        tz.setLocalLocation(matchedLocation);
      } else if (tz.timeZoneDatabase.locations.containsKey('Asia/Jakarta')) {
        tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
      }
    } catch (e) {
      debugPrint('[SleepTrackingService] Notice setting timezone location: $e');
    }
  }

  static String formatTimeOfDay(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> initNotifications() async {
    if (kIsWeb) return;
    try {
      tz.initializeTimeZones();
      _configureLocalTimeZone();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      try {
        await _notificationsPlugin.initialize(
          settings: initSettings,
        );
      } catch (e) {
        debugPrint('[SleepTrackingService] Notifications plugin initialize notice: $e');
      }

      // Buat notification channel dengan prioritas tertinggi di Android (Heads-up banner & sound)
      try {
        const AndroidNotificationChannel sleepChannel = AndroidNotificationChannel(
          _sleepChannelId,
          _sleepChannelName,
          description: 'Pengingat harian jadwal waktu istirahat tidur malam',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );

        final androidPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          await androidPlugin.createNotificationChannel(sleepChannel);
        }
      } catch (e) {
        debugPrint('[SleepTrackingService] Notification channel create notice: $e');
      }

      _notificationsInitialized = true;

      if (_reminderEnabled) {
        await scheduleBedtimeNotification();
      }
    } catch (e) {
      debugPrint('[SleepTrackingService] Notifications init error: $e');
    }
  }

  Future<bool> requestNotificationPermission() async {
    if (kIsWeb) return false;
    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final areEnabled = await androidPlugin.areNotificationsEnabled();
        if (areEnabled == true) {
          try {
            await androidPlugin.requestExactAlarmsPermission();
          } catch (_) {}
          return true;
        }
        final granted = await androidPlugin.requestNotificationsPermission();
        try {
          await androidPlugin.requestExactAlarmsPermission();
        } catch (_) {}
        return granted ?? false;
      }
      final iosPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('[SleepTrackingService] Error requesting notification permission: $e');
    }
    return false;
  }

  Future<void> scheduleBedtimeNotification() async {
    if (kIsWeb || !_reminderEnabled) return;
    try {
      if (!_notificationsInitialized) {
        await initNotifications();
      }
      await cancelBedtimeNotification();
      _configureLocalTimeZone();

      final rTime = reminderTime;
      final nowTz = tz.TZDateTime.now(tz.local);
      var tzScheduled = tz.TZDateTime(
        tz.local,
        nowTz.year,
        nowTz.month,
        nowTz.day,
        rTime.hour,
        rTime.minute,
      );

      if (!tzScheduled.isAfter(nowTz)) {
        tzScheduled = tzScheduled.add(const Duration(days: 1));
      }

      const androidDetails = AndroidNotificationDetails(
        _sleepChannelId,
        _sleepChannelName,
        channelDescription: 'Pengingat harian jadwal waktu istirahat tidur malam',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.reminder,
        ticker: 'Pengingat Waktu Tidur',
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final targetStr = formatTimeOfDay(_bedtimeTarget);
      const title = 'Pengingat Waktu Tidur 🌙';
      final body = 'Waktu tidurmu semakin dekat (Target: $targetStr). Yuk mulai bersiap tidur agar tubuh tetap bugar besok.';

      try {
        await _notificationsPlugin.zonedSchedule(
          id: _sleepReminderNotificationId,
          title: title,
          body: body,
          scheduledDate: tzScheduled,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (e) {
        debugPrint('[SleepTrackingService] Fallback to inexact alarm: $e');
        await _notificationsPlugin.zonedSchedule(
          id: _sleepReminderNotificationId,
          title: title,
          body: body,
          scheduledDate: tzScheduled,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
      debugPrint('[SleepTrackingService] Scheduled daily bedtime notification at $tzScheduled');
    } catch (e) {
      debugPrint('[SleepTrackingService] Error scheduling notification: $e');
    }
  }

  Future<void> cancelBedtimeNotification() async {
    if (kIsWeb || !_notificationsInitialized) return;
    try {
      await _notificationsPlugin.cancel(id: _sleepReminderNotificationId);
      debugPrint('[SleepTrackingService] Bedtime notification cancelled');
    } catch (e) {
      debugPrint('[SleepTrackingService] Error cancelling notification: $e');
    }
  }

  Future<void> showInstantTestNotification() async {
    if (kIsWeb) return;
    if (!_notificationsInitialized) {
      await initNotifications();
    }
    await requestNotificationPermission();
    try {
      const androidDetails = AndroidNotificationDetails(
        _sleepChannelId,
        _sleepChannelName,
        channelDescription: 'Pengingat harian jadwal waktu istirahat tidur malam',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.reminder,
        ticker: 'Pengingat Waktu Tidur',
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final targetStr = formatTimeOfDay(_bedtimeTarget);
      final reminderStr = formatTimeOfDay(reminderTime);

      await _notificationsPlugin.show(
        id: _testNotificationId,
        title: 'Pengingat Waktu Tidur 🌙',
        body: 'Pengingat aktif pukul $reminderStr (Target tidur: $targetStr). Yuk mulai bersiap untuk beristirahat!',
        notificationDetails: notificationDetails,
      );
      debugPrint('[SleepTrackingService] Test notification shown successfully');
    } catch (e) {
      debugPrint('[SleepTrackingService] Error showing test notification: $e');
    }
  }

  // ==========================================
  // LOCAL STORAGE (SharedPreferences)
  // ==========================================

  Future<void> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recordsJson = prefs.getString(_keyRecords);
      if (recordsJson != null && recordsJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(recordsJson);
        _records.clear();
        for (final item in decoded) {
          if (item is Map) {
            final rec = SleepRecord.fromMap(Map<String, dynamic>.from(item));
            final existingIdx = _records.indexWhere((r) => isMatchingUser(r.userId, rec.userId) && r.date == rec.date);
            if (existingIdx != -1) {
              if (rec.updatedAt.isAfter(_records[existingIdx].updatedAt)) {
                _records[existingIdx] = rec;
              }
            } else {
              _records.add(rec);
            }
          }
        }
      }

      final pendingJson = prefs.getString(_keyPendingAuto);
      if (pendingJson != null && pendingJson.isNotEmpty) {
        try {
          _pendingAutoDetectedRecord = SleepRecord.fromMap(Map<String, dynamic>.from(jsonDecode(pendingJson)));
        } catch (_) {}
      }

      final lastInactiveStr = prefs.getString(_keyLastInactive);
      if (lastInactiveStr != null && lastInactiveStr.isNotEmpty) {
        _lastInactiveTime = DateTime.tryParse(lastInactiveStr);
      }

      final lastNightStr = prefs.getString(_keyLastNightInactive);
      if (lastNightStr != null && lastNightStr.isNotEmpty) {
        _lastNightInactiveTime = DateTime.tryParse(lastNightStr);
      }

      _reminderEnabled = prefs.getBool(_keyReminderEnabled) ?? true;
      final savedH = prefs.getInt(_keyBedtimeTargetH);
      final savedM = prefs.getInt(_keyBedtimeTargetM);
      if (savedH != null && savedM != null) {
        _bedtimeTarget = TimeOfDay(hour: savedH, minute: savedM);
      }
      _reminderMinutesBefore = prefs.getInt(_keyReminderMinutesBefore) ?? 60;

      notifyListeners();
    } catch (e) {
      debugPrint('[SleepTrackingService] Load local error: $e');
    }
  }

  Future<void> _saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _records.map((r) => r.toMap()).toList();
      await prefs.setString(_keyRecords, jsonEncode(jsonList));

      if (_pendingAutoDetectedRecord != null) {
        await prefs.setString(_keyPendingAuto, jsonEncode(_pendingAutoDetectedRecord!.toMap()));
      } else {
        await prefs.remove(_keyPendingAuto);
      }

      if (_lastInactiveTime != null) {
        await prefs.setString(_keyLastInactive, _lastInactiveTime!.toIso8601String());
      } else {
        await prefs.remove(_keyLastInactive);
      }

      if (_lastNightInactiveTime != null) {
        await prefs.setString(_keyLastNightInactive, _lastNightInactiveTime!.toIso8601String());
      } else {
        await prefs.remove(_keyLastNightInactive);
      }

      await prefs.setBool(_keyReminderEnabled, _reminderEnabled);
      await prefs.setInt(_keyBedtimeTargetH, _bedtimeTarget.hour);
      await prefs.setInt(_keyBedtimeTargetM, _bedtimeTarget.minute);
      await prefs.setInt(_keyReminderMinutesBefore, _reminderMinutesBefore);
    } catch (e) {
      debugPrint('[SleepTrackingService] Save local error: $e');
    }
  }

  /// Bersihkan seluruh data (berguna untuk testing atau logout)
  Future<void> clearAll() async {
    _records.clear();
    _pendingAutoDetectedRecord = null;
    _lastInactiveTime = null;
    _lastNightInactiveTime = null;
    _lastScreenOffTime = null;
    _lastScreenOnTime = null;
    _lastDarkTime = null;
    _lastLightRiseTime = null;
    _currentAmbientLux = -1.0;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyRecords);
      await prefs.remove(_keyPendingAuto);
      await prefs.remove(_keyLastInactive);
      await prefs.remove(_keyLastNightInactive);
    } catch (_) {}
    notifyListeners();
  }

  // ==========================================
  // DEVICE INACTIVITY & SENSOR MONITORING
  // ==========================================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Saat aplikasi dibuka / di-resume, periksa apakah ada data tidur dari aktivitas perangkat
      checkDeviceInactivityCandidate();
    }
  }

  /// Logika Deteksi Waktu Tidur Berbasis Sensor & Aktivitas Perangkat:
  /// Mengintegrasikan deteksi otomatis waktu tidur yang menggabungkan indikator:
  /// a. Aktivitas Layar Perangkat: Layar HP dimatikan (screen off) di malam hari hingga aktif kembali di pagi hari.
  /// b. Ketidakaktifan Pengguna: Waktu terakhir interaksi pengguna dengan perangkat sebelum tidur.
  /// c. Sensor Cahaya Lingkungan (Ambient Light Sensor): Mendeteksi ruangan gelap di malam hari (< 5 lux)
  ///    dan peningkatan intensitas cahaya di pagi hari (> 40 lux). Jika sensor tidak tersedia, sistem tetap
  ///    berjalan menggunakan indikator aktivitas perangkat lainnya.
  /// CATATAN PENTING: Waktu buka/tutup aplikasi TIDAK digunakan sebagai waktu tidur/bangun!
  SleepRecord? detectSleepFromSensors({
    DateTime? screenOff,
    DateTime? screenOn,
    DateTime? darkTime,
    DateTime? lightRiseTime,
    DateTime? referenceNow,
    DateTime? lastInactivityTime,
  }) {
    final now = referenceNow ?? DateTime.now();

    // 1. Tentukan Titik Mulai Tidur (Waktu Malam: >= 20.00 atau < 05.00)
    // Harus bersumber dari layar HP dimatikan (screen off) atau sensor cahaya gelap (darkTime)
    DateTime? primaryStart = screenOff ?? lastInactivityTime;

    DateTime? effectiveStart;
    final isScreenNight = primaryStart != null && (primaryStart.hour >= 20 || primaryStart.hour < 5);
    final isDarkNight = darkTime != null && (darkTime.hour >= 20 || darkTime.hour < 5);

    if (isScreenNight && isDarkNight) {
      // Jika kedua indikator mendeteksi kondisi malam hari:
      // Tidur efektif dimulai saat layar dimatikan DAN ruangan telah gelap (ambil titik paling akhir jika selisih wajar <= 90m)
      if (darkTime.difference(primaryStart).abs().inMinutes <= 90) {
        effectiveStart = darkTime.isAfter(primaryStart) ? darkTime : primaryStart;
      } else {
        effectiveStart = primaryStart;
      }
    } else if (isScreenNight) {
      effectiveStart = primaryStart;
    } else if (isDarkNight) {
      effectiveStart = darkTime;
    }

    if (effectiveStart == null) return null;

    // 2. Tentukan Titik Bangun Tidur (Pagi Hari: >= 05.00 s.d. 14.00)
    // Harus bersumber dari layar HP menyala (screen on / unlock) atau sensor cahaya terang (lightRiseTime)
    // PENTING: Jangan gunakan waktu buka aplikasi sebagai waktu bangun!
    DateTime? primaryEnd = screenOn;

    final morningOn = (primaryEnd != null && primaryEnd.isAfter(effectiveStart) && primaryEnd.hour >= 5 && primaryEnd.hour <= 14)
        ? primaryEnd
        : null;
    final morningRise = (lightRiseTime != null && lightRiseTime.isAfter(effectiveStart) && lightRiseTime.hour >= 5 && lightRiseTime.hour <= 14)
        ? lightRiseTime
        : null;

    DateTime? effectiveEnd;
    if (morningOn != null && morningRise != null) {
      // Jika kedua sensor (layar HP menyala & sensor cahaya ruangan terang) mendeteksi pagi hari:
      // Ambil waktu paling awal saat aktivitas bangun terdeteksi jika rentangnya berdekatan (<= 90 menit)
      if (morningOn.difference(morningRise).abs().inMinutes <= 90) {
        effectiveEnd = morningRise.isBefore(morningOn) ? morningRise : morningOn;
      } else {
        effectiveEnd = morningOn;
      }
    } else if (morningOn != null) {
      effectiveEnd = morningOn;
    } else if (morningRise != null) {
      effectiveEnd = morningRise;
    }

    // Jika belum ada sinyal bangun dari perangkat (layar on/sensor pagi), kembalikan null
    // (JANGAN buat data tidur otomatis sembarangan berdasarkan waktu buka aplikasi)
    if (effectiveEnd == null) return null;

    // 3. Validasi Durasi Sesi Tidur Malam (Minimal 3 jam / 180 menit s.d. 14 jam / 840 menit)
    final diffMinutes = SleepRecord.calculateDurationMinutes(effectiveStart, effectiveEnd);
    if (diffMinutes < _minimumNightSleepMinutes || diffMinutes > 840) {
      return null;
    }

    final dateKey = formatDateKey(effectiveEnd);
    return SleepRecord(
      id: 'auto_${effectiveStart.millisecondsSinceEpoch}',
      userId: currentUserId,
      date: dateKey,
      startTime: effectiveStart,
      endTime: effectiveEnd,
      durationMinutes: diffMinutes,
      source: 'automatic',
      isConfirmed: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 1. Logika Rekam Tidur Otomatis:
  /// Fungsi pendeteksi waktu tidur otomatis yang menggunakan aktivitas layar perangkat
  /// (screen off di malam hari: >= 20.00 atau < 05.00, dan screen on di pagi hari: >= 05.00 s.d. 14.00).
  SleepRecord? detectSleepFromScreenActivity({
    required DateTime? screenOff,
    required DateTime? screenOn,
    DateTime? referenceNow,
  }) {
    return detectSleepFromSensors(
      screenOff: screenOff,
      screenOn: screenOn,
      referenceNow: referenceNow,
    );
  }

  /// Alias fungsi deteksi tidur otomatis berbasis aktivitas layar perangkat
  SleepRecord? detectAutomaticSleep({
    DateTime? screenOff,
    DateTime? screenOn,
    DateTime? referenceNow,
  }) {
    return detectSleepFromSensors(
      screenOff: screenOff,
      screenOn: screenOn,
      referenceNow: referenceNow,
    );
  }

  /// Merekam waktu tidur otomatis dan menghubungkannya ke sistem tanpa mengganggu
  /// fungsi maupun data input manual yang sudah ada.
  /// - Menghubungkan kandidat deteksi otomatis ke sistem (pendingAutoDetectedRecord) agar dapat ditinjau
  ///   dan dicatat pengguna melalui tombol "Catat waktu ini" (atau disimpan langsung jika autoConfirm = true).
  /// - Perlindungan Data Manual: Jika pengguna telah memiliki catatan manual yang terkonfirmasi untuk tanggal sesi tidur ini,
  ///   data manual tersebut TIDAK AKAN diganggu atau ditimpa oleh deteksi otomatis.
  Future<SleepRecord?> recordAutomaticSleep({
    DateTime? screenOff,
    DateTime? screenOn,
    DateTime? referenceNow,
    bool autoConfirm = false,
  }) async {
    final candidate = detectSleepFromSensors(
      screenOff: screenOff,
      screenOn: screenOn,
      referenceNow: referenceNow,
    );

    if (candidate == null) return null;

    // Proteksi data manual: Jangan ganggu atau timpa data manual yang sudah dicatat oleh pengguna
    final existingRecord = getSavedRecordForDate(candidate.endTime);
    if (existingRecord != null && existingRecord.isConfirmed && existingRecord.source == 'manual') {
      debugPrint('[SleepTrackingService] Data manual terkonfirmasi pada tanggal ${candidate.date} dilindungi. Deteksi otomatis tidak menimpa data manual pengguna.');
      return null;
    }

    if (autoConfirm) {
      final confirmed = candidate.copyWith(
        isConfirmed: true,
        updatedAt: DateTime.now(),
      );
      await addRecord(confirmed);
      _pendingAutoDetectedRecord = null;
      await _saveToLocal();
      notifyListeners();
      return confirmed;
    } else {
      _pendingAutoDetectedRecord = candidate;
      await _saveToLocal();
      notifyListeners();
      return candidate;
    }
  }

  /// Simulasi deteksi sensor untuk keperluan testing dan demo
  void simulateSensorDetection({
    DateTime? screenOff,
    DateTime? screenOn,
    DateTime? darkTime,
    DateTime? lightRiseTime,
    DateTime? referenceNow,
  }) {
    final candidate = detectSleepFromSensors(
      screenOff: screenOff,
      screenOn: screenOn,
      darkTime: darkTime,
      lightRiseTime: lightRiseTime,
      referenceNow: referenceNow,
    );
    if (candidate != null) {
      _pendingAutoDetectedRecord = candidate;
      _saveToLocal();
      notifyListeners();
    }
  }

  /// Memeriksa aktivitas layar mati semalam dan nyala pagi hari didukung sensor cahaya ruangan
  Future<void> checkDeviceInactivityCandidate() async {
    if (!_isNativeSupported) return;
    final now = DateTime.now();
    final savedToday = getSavedRecordForDate(now);

    // Jika hari ini sudah ada catatan tidur resmi tersimpan, jangan tampilkan pending auto lagi.
    if (savedToday != null && savedToday.isConfirmed) {
      if (_pendingAutoDetectedRecord != null) {
        _pendingAutoDetectedRecord = null;
        _saveToLocal();
        notifyListeners();
      }
      return;
    }

    DateTime? screenOff;
    DateTime? screenOn;
    DateTime? darkTime;
    DateTime? lightRiseTime;

    if (_isNativeSupported) {
      try {
        final lastOffMillis = await _platformChannel.invokeMethod<int>('getLastScreenOff');
        final lastOnMillis = await _platformChannel.invokeMethod<int>('getLastScreenOn');
        final lastDarkMillis = await _platformChannel.invokeMethod<int>('getLastDarkTime');
        final lastLightRiseMillis = await _platformChannel.invokeMethod<int>('getLastLightRiseTime');

        if (lastOffMillis != null && lastOffMillis > 0) {
          screenOff = DateTime.fromMillisecondsSinceEpoch(lastOffMillis);
        }
        if (lastOnMillis != null && lastOnMillis > 0) {
          screenOn = DateTime.fromMillisecondsSinceEpoch(lastOnMillis);
        }
        if (lastDarkMillis != null && lastDarkMillis > 0) {
          darkTime = DateTime.fromMillisecondsSinceEpoch(lastDarkMillis);
        }
        if (lastLightRiseMillis != null && lastLightRiseMillis > 0) {
          lightRiseTime = DateTime.fromMillisecondsSinceEpoch(lastLightRiseMillis);
        }

        _lastScreenOffTime = screenOff;
        _lastScreenOnTime = screenOn;
        _lastDarkTime = darkTime;
        _lastLightRiseTime = lightRiseTime;
      } catch (_) {}
    }

    final candidate = detectSleepFromSensors(
      screenOff: screenOff,
      screenOn: screenOn,
      darkTime: darkTime,
      lightRiseTime: lightRiseTime,
      referenceNow: now,
    );

    if (candidate != null) {
      // Pastikan kandidat otomatis tidak menimpa catatan manual yang valid
      final existingRecord = getSavedRecordForDate(candidate.endTime);
      if (existingRecord != null && existingRecord.isConfirmed && existingRecord.source == 'manual') {
        if (_pendingAutoDetectedRecord != null) {
          _pendingAutoDetectedRecord = null;
          await _saveToLocal();
          notifyListeners();
        }
        return;
      }

      _pendingAutoDetectedRecord = candidate;
      await _saveToLocal();
      notifyListeners();
      return;
    } else {
      // Jika tidak ada data sensor perangkat yang valid (misalnya belum ada siklus tidur semalam),
      // pastikan tidak menampilkan kandidat palsu
      if (_pendingAutoDetectedRecord != null && !_pendingAutoDetectedRecord!.isConfirmed) {
        _pendingAutoDetectedRecord = null;
        await _saveToLocal();
        notifyListeners();
      }
    }
  }

  /// Membuat calon (kandidat) perkiraan waktu tidur otomatis untuk ditinjau pengguna
  void _recordAutomaticSleepCandidate(DateTime start, DateTime end) {
    final dateKey = formatDateKey(end);
    final duration = SleepRecord.calculateDurationMinutes(start, end);
    final autoRecord = SleepRecord(
      id: 'auto_${start.millisecondsSinceEpoch}',
      userId: currentUserId,
      date: dateKey,
      startTime: start,
      endTime: end,
      durationMinutes: duration,
      source: 'automatic',
      isConfirmed: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _pendingAutoDetectedRecord = autoRecord;
    _saveToLocal();
    notifyListeners();
  }

  /// Menetapkan kandidat tidur otomatis secara manual/testing
  void setPendingAutoRecord(SleepRecord? record) {
    _pendingAutoDetectedRecord = record;
    _saveToLocal();
    notifyListeners();
  }

  /// Memungkinkan simulasi deteksi otomatis saat testing/demo
  void simulateInactivity({
    DateTime? customStart,
    DateTime? customEnd,
    int durationMinutes = 465, // 7 jam 45 menit (contoh 22:30 -> 06:15)
  }) {
    final end = customEnd ?? DateTime.now();
    final start = customStart ?? end.subtract(Duration(minutes: durationMinutes));
    _recordAutomaticSleepCandidate(start, end);
  }

  /// Menerima / mengonfirmasi rekaman perkiraan waktu tidur otomatis (Tombol "Catat waktu ini")
  /// Struktur data & field disamakan persis dengan input manual ("Masukkan data"):
  /// userId, date, startTime, endTime, durationMinutes, source, isConfirmed = true
  Future<bool> acceptPendingAutoRecord({DateTime? targetDate}) async {
    if (_pendingAutoDetectedRecord != null) {
      final candidate = _pendingAutoDetectedRecord!;
      final now = targetDate ?? candidate.endTime;
      final targetDateKey = formatDateKey(now);

      // Validasi durasi tidur
      final durationM = candidate.durationMinutes > 0
          ? candidate.durationMinutes
          : SleepRecord.calculateDurationMinutes(candidate.startTime, candidate.endTime);
      if (durationM < _minimumNightSleepMinutes || durationM > 840) {
        return false;
      }

      // Pastikan tidak menimpa catatan manual yang sudah valid
      final existingForDate = getSavedRecordForDate(now);
      if (existingForDate != null && existingForDate.isConfirmed && existingForDate.source == 'manual') {
        _pendingAutoDetectedRecord = null;
        await _saveToLocal();
        notifyListeners();
        return false;
      }

      // Bentuk SleepRecord terkonfirmasi dengan field dan struktur yang persis sama
      final confirmedRecord = candidate.copyWith(
        id: candidate.id.isNotEmpty ? candidate.id : 'auto_${candidate.startTime.millisecondsSinceEpoch}',
        userId: currentUserId,
        date: targetDateKey,
        startTime: candidate.startTime,
        endTime: candidate.endTime,
        durationMinutes: durationM,
        source: 'automatic',
        isConfirmed: true,
        updatedAt: DateTime.now(),
      );

      // Simpan menggunakan fungsi addRecord
      await addRecord(confirmedRecord);
      _pendingAutoDetectedRecord = null;
      await _saveToLocal();
      if (_isNativeSupported) {
        try {
          await _platformChannel.invokeMethod('clearScreenTimes');
        } catch (_) {}
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Menolak kandidat otomatis
  Future<void> dismissPendingAutoRecord() async {
    if (_pendingAutoDetectedRecord != null) {
      _pendingAutoDetectedRecord = null;
      await _saveToLocal();
      notifyListeners();
    }
  }

  // ==========================================
  // DATA ACCESS & QUERIES
  // ==========================================

  List<SleepRecord> getRecordsForDate(DateTime date, {String? userId}) {
    final uid = userId ?? currentUserId;
    final key = formatDateKey(date);
    final matching = _records
        .where((r) =>
            isMatchingUser(r.userId, uid) &&
            (r.date == key || (r.date.isEmpty && formatDateKey(r.endTime) == key)))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    if (matching.length > 1) {
      // Prioritaskan yang confirmed, lalu updatedAt paling mutakhir untuk mencegah duplikasi
      matching.sort((a, b) {
        if (a.isConfirmed != b.isConfirmed) {
          return b.isConfirmed ? 1 : -1;
        }
        return b.updatedAt.compareTo(a.updatedAt);
      });
      return [matching.first];
    }
    return matching;
  }

  /// Priority Check: Mengambil data tidur tersimpan untuk tanggal tertentu
  SleepRecord? getSavedRecordForDate(DateTime date, {String? userId}) {
    final recs = getRecordsForDate(date, userId: userId);
    if (recs.isEmpty) return null;
    final confirmed = recs.where((r) => r.isConfirmed).toList();
    if (confirmed.isNotEmpty) {
      return confirmed.last;
    }
    return recs.last;
  }

  /// Mengecek apakah sudah ada data tidur yang tersimpan untuk tanggal tertentu
  bool hasSavedRecordForDate(DateTime date, {String? userId}) {
    return getSavedRecordForDate(date, userId: userId) != null;
  }

  List<SleepRecord> get todayRecords => getRecordsForDate(DateTime.now());

  bool get hasTodayData => hasSavedRecordForDate(DateTime.now());

  int getTotalSleepMinutesForDate(DateTime date, {String? userId}) {
    final list = getRecordsForDate(date, userId: userId);
    return list.fold<int>(0, (acc, r) => acc + r.durationMinutes);
  }

  int get todayTotalMinutes => getTotalSleepMinutesForDate(DateTime.now());

  /// Menghitung total waktu terjaga (jika pengguna tidur, terbangun, lalu tidur lagi)
  int getAwakeMinutesForDate(DateTime date, {String? userId}) {
    final list = getRecordsForDate(date, userId: userId);
    if (list.length < 2) return 0;

    int totalAwake = 0;
    for (int i = 0; i < list.length - 1; i++) {
      final currentEnd = list[i].endTime;
      final nextStart = list[i + 1].startTime;
      if (nextStart.isAfter(currentEnd)) {
        totalAwake += nextStart.difference(currentEnd).inMinutes;
      }
    }
    return totalAwake;
  }

  int get todayAwakeMinutes => getAwakeMinutesForDate(DateTime.now());

  /// Status pencapaian target tidur
  String getSleepStatus(int totalMinutes) {
    if (totalMinutes <= 0) return 'Belum ada data';
    final target = _targetSleepMinutes;
    if (totalMinutes >= target - 30 && totalMinutes <= target + 60) {
      return 'Mencapai target';
    } else if (totalMinutes >= target - 90 && totalMinutes < target - 30) {
      return 'Hampir mencapai target';
    } else if (totalMinutes < target - 90) {
      return 'Kurang tidur';
    } else {
      return 'Tidur berlebih';
    }
  }

  /// 2. Validasi Acuan Standar Tidur 8 Jam:
  /// Standar ideal durasi tidur malam adalah 8 jam (480 menit).
  static const int standardIdealSleepHours = 8;
  static const int standardIdealSleepMinutes = 8 * 60; // 480 menit

  /// Aturan penilaian berdasarkan standar ideal 8 jam:
  /// - JIKA total durasi tidur kurang dari 8 jam (< 8 jam), berikan status "Tidur Kurang".
  /// - JIKA total durasi tidur mencapai atau melebihi 8 jam (>= 8 jam), berikan status "Tidur Cukup".
  String getSleepStandard8HoursCategory(int totalMinutes) {
    if (totalMinutes <= 0) return 'Belum ada data';
    return totalMinutes < standardIdealSleepMinutes ? 'Tidur Kurang' : 'Tidur Cukup';
  }

  /// Label alternatif status acuan standar 8 jam ("Tidur Kurang" / "Ideal"):
  /// - < 8 jam: "Tidur Kurang"
  /// - >= 8 jam: "Ideal"
  String getSleepStandard8HoursStatus(int totalMinutes) {
    if (totalMinutes <= 0) return 'Belum ada data';
    return totalMinutes < standardIdealSleepMinutes ? 'Tidur Kurang' : 'Ideal';
  }

  /// Evaluasi validasi acuan standar tidur 8 jam (alias)
  String getSleepValidationCategory(int totalMinutes) {
    return getSleepStandard8HoursCategory(totalMinutes);
  }

  /// Memeriksa apakah total durasi tidur mencapai atau melampaui standar ideal 8 jam (>= 480 menit)
  bool isSleepDurationIdeal8Hours(int totalMinutes) {
    return totalMinutes >= standardIdealSleepMinutes;
  }

  /// Rekomendasi/insight pola tidur berdasarkan durasi
  String getSleepInsight(int totalMinutes) {
    if (totalMinutes <= 0) {
      return 'Catat waktu tidur Anda untuk memantau ritme istirahat dan metabolisme tubuh.';
    }
    if (totalMinutes < 360) {
      // Kurang dari 6 jam
      return 'Tidur kurang dari 6 jam dapat meningkatkan hormon lapar (ghrelin) dan memicu keinginan ngemil.';
    } else if (totalMinutes < 420) {
      // 6 - 7 jam
      return 'Durasi tidur Anda hampir cukup. Usahakan tidur 30 menit lebih awal untuk pemulihan optimal.';
    } else if (totalMinutes <= 540) {
      // 7 - 9 jam
      return 'Luar biasa! Durasi tidur Anda sangat ideal untuk menjaga metabolisme dan pembakaran lemak.';
    } else {
      // > 9 jam
      return 'Tidur lebih dari 9 jam dapat membuat tubuh lemas. Usahakan bangun dan bergerak aktif.';
    }
  }

  // ==========================================
  // RIWAYAT 7 HARI & STATISTIK
  // ==========================================

  List<DailySleepSummary> getPast7DaysSummaries([DateTime? referenceDate]) {
    final ref = referenceDate ?? DateTime.now();
    final baseDate = DateTime(ref.year, ref.month, ref.day);
    const dayNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

    final summaries = <DailySleepSummary>[];
    for (int i = 6; i >= 0; i--) {
      final date = baseDate.subtract(Duration(days: i));
      final key = formatDateKey(date);
      final recs = getRecordsForDate(date);
      final totalM = recs.fold<int>(0, (acc, r) => acc + r.durationMinutes);

      summaries.add(DailySleepSummary(
        date: date,
        dateKey: key,
        dayName: dayNames[date.weekday % 7],
        dayNumber: date.day.toString(),
        totalMinutes: totalM,
        records: recs,
        isToday: i == 0,
      ));
    }
    return summaries;
  }

  double getAverageSleepMinutes7Days([DateTime? referenceDate]) {
    final summaries = getPast7DaysSummaries(referenceDate);
    final daysWithData = summaries.where((s) => s.totalMinutes > 0).toList();
    if (daysWithData.isEmpty) return 0.0;
    final total = daysWithData.fold<int>(0, (acc, s) => acc + s.totalMinutes);
    return total / daysWithData.length;
  }

  String get formatted7DayAverage {
    final avg = getAverageSleepMinutes7Days();
    if (avg <= 0) return '0 jam 0 menit';
    final hours = avg ~/ 60;
    final mins = (avg % 60).round();
    return '$hours jam $mins menit';
  }

  /// Menghitung rata-rata waktu tidur (bedtime) dari catatan 7 hari
  String getAverageBedtime7Days([DateTime? referenceDate]) {
    final summaries = getPast7DaysSummaries(referenceDate);
    final allRecs = summaries.expand((s) => s.records).toList();
    if (allRecs.isEmpty) return '11:00 PM';

    int totalMinutes = 0;
    for (final r in allRecs) {
      int m = r.startTime.hour * 60 + r.startTime.minute;
      // Normalisasi waktu malam (misal 22:00 = -120 dari tengah malam)
      if (m > 12 * 60) m -= 24 * 60;
      totalMinutes += m;
    }
    int avgM = totalMinutes ~/ allRecs.length;
    if (avgM < 0) avgM += 24 * 60;
    final h = avgM ~/ 60;
    final m = avgM % 60;
    return _format12Hour(h, m);
  }

  /// Menghitung rata-rata waktu bangun dari catatan 7 hari
  String getAverageWakeTime7Days([DateTime? referenceDate]) {
    final summaries = getPast7DaysSummaries(referenceDate);
    final allRecs = summaries.expand((s) => s.records).toList();
    if (allRecs.isEmpty) return '06:00 AM';

    int totalMinutes = 0;
    for (final r in allRecs) {
      int m = r.endTime.hour * 60 + r.endTime.minute;
      totalMinutes += m;
    }
    int avgM = totalMinutes ~/ allRecs.length;
    final h = avgM ~/ 60;
    final m = avgM % 60;
    return _format12Hour(h, m);
  }

  String _format12Hour(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    int h12 = hour % 12;
    if (h12 == 0) h12 = 12;
    final mStr = minute.toString().padLeft(2, '0');
    return '$h12:$mStr $period';
  }

  /// Data distribusi tidur per jam untuk satu tanggal tertentu (24 jam)
  List<HourlySleepData> getHourlySleepForDate(DateTime date) {
    final recs = getRecordsForDate(date);
    // Jika belum ada record tersimpan hari ini tapi ada deteksi otomatis, gunakan deteksi otomatis
    final pending = _pendingAutoDetectedRecord;
    final effectiveRecs = List<SleepRecord>.from(recs);
    if (effectiveRecs.isEmpty && pending != null && pending.date == formatDateKey(date)) {
      effectiveRecs.add(pending);
    }

    final List<HourlySleepData> hourly = [];
    for (int h = 0; h < 24; h++) {
      int minutesInThisHour = 0;

      // 1. Cek jam di hari aktif
      final hourStartSameDay = DateTime(date.year, date.month, date.day, h, 0);
      final hourEndSameDay = hourStartSameDay.add(const Duration(hours: 1));

      // 2. Cek kemungkinan jam malam berasal dari hari sebelumnya (sesi tidur malam lintas tengah malam)
      final hourStartPrevDay = DateTime(date.year, date.month, date.day - 1, h, 0);
      final hourEndPrevDay = hourStartPrevDay.add(const Duration(hours: 1));

      for (final r in effectiveRecs) {
        final rStart = r.startTime;
        final rEnd = r.endTime;

        // Overlap di hari yang sama
        final oStart1 = rStart.isAfter(hourStartSameDay) ? rStart : hourStartSameDay;
        final oEnd1 = rEnd.isBefore(hourEndSameDay) ? rEnd : hourEndSameDay;
        if (oEnd1.isAfter(oStart1)) {
          minutesInThisHour += oEnd1.difference(oStart1).inMinutes;
        }

        // Overlap di hari sebelumnya (khusus jam malam h >= 18)
        if (h >= 18) {
          final oStart2 = rStart.isAfter(hourStartPrevDay) ? rStart : hourStartPrevDay;
          final oEnd2 = rEnd.isBefore(hourEndPrevDay) ? rEnd : hourEndPrevDay;
          if (oEnd2.isAfter(oStart2)) {
            minutesInThisHour += oEnd2.difference(oStart2).inMinutes;
          }
        }

        // Overlap di hari berikutnya (khusus jam pagi h < 12)
        if (h < 12) {
          final hourStartNextDay = DateTime(date.year, date.month, date.day + 1, h, 0);
          final hourEndNextDay = hourStartNextDay.add(const Duration(hours: 1));
          final oStart3 = rStart.isAfter(hourStartNextDay) ? rStart : hourStartNextDay;
          final oEnd3 = rEnd.isBefore(hourEndNextDay) ? rEnd : hourEndNextDay;
          if (oEnd3.isAfter(oStart3)) {
            minutesInThisHour += oEnd3.difference(oStart3).inMinutes;
          }
        }
      }

      final label = '${h.toString().padLeft(2, '0')}.00';
      hourly.add(HourlySleepData(
        hour: h,
        label: label,
        minutesSlept: minutesInThisHour.clamp(0, 60),
        isAsleep: minutesInThisHour > 0,
      ));
    }
    return hourly;
  }

  /// Urutan jam kronologis untuk sesi tidur malam (20.00 – 08.00)
  List<HourlySleepData> getChronologicalHourlySleep(DateTime date) {
    final hourly = getHourlySleepForDate(date);
    const relevantHours = [20, 21, 22, 23, 0, 1, 2, 3, 4, 5, 6, 7, 8];
    return relevantHours.map((h) => hourly[h]).toList();
  }

  /// Ringkasan tidur per minggu (4 minggu terakhir) dari database asli
  List<WeeklySleepSummary> getPast4WeeksSummaries([DateTime? referenceDate]) {
    final ref = referenceDate ?? DateTime.now();
    final summaries = <WeeklySleepSummary>[];

    for (int w = 3; w >= 0; w--) {
      final endDay = ref.subtract(Duration(days: w * 7));
      final startDay = endDay.subtract(const Duration(days: 6));

      int totalM = 0;
      int daysWithData = 0;

      for (int d = 0; d < 7; d++) {
        final current = startDay.add(Duration(days: d));
        final recs = getRecordsForDate(current);
        final dayM = recs.fold<int>(0, (acc, r) => acc + r.durationMinutes);
        if (dayM > 0) {
          totalM += dayM;
          daysWithData++;
        }
      }

      final avgM = daysWithData > 0 ? (totalM / daysWithData) : 0.0;
      final weekLabel = w == 0 ? 'Mgg Ini' : 'Mgg -$w';

      summaries.add(WeeklySleepSummary(
        weekLabel: weekLabel,
        startDate: startDay,
        endDate: endDay,
        averageMinutesPerDay: avgM,
        totalMinutes: totalM,
        daysWithData: daysWithData,
        isCurrentWeek: w == 0,
      ));
    }
    return summaries;
  }

  /// Ringkasan tidur per bulan (6 bulan terakhir) dari database asli
  List<MonthlySleepSummary> getPastMonthsSummaries([int count = 6, DateTime? referenceDate]) {
    final ref = referenceDate ?? DateTime.now();
    const monthNames = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final summaries = <MonthlySleepSummary>[];

    for (int m = count - 1; m >= 0; m--) {
      int targetMonth = ref.month - m;
      int targetYear = ref.year;
      while (targetMonth <= 0) {
        targetMonth += 12;
        targetYear -= 1;
      }

      final monthRecs = _records.where((r) {
        final parsedDate = DateTime.tryParse(r.date);
        if (parsedDate != null) {
          return parsedDate.year == targetYear && parsedDate.month == targetMonth;
        }
        final d = r.endTime;
        return d.year == targetYear && d.month == targetMonth;
      }).toList();

      final totalM = monthRecs.fold<int>(0, (acc, r) => acc + r.durationMinutes);
      final uniqueDays = monthRecs.map((r) => r.date).toSet().length;
      final avgM = uniqueDays > 0 ? (totalM / uniqueDays) : 0.0;

      summaries.add(MonthlySleepSummary(
        monthLabel: monthNames[targetMonth],
        month: targetMonth,
        year: targetYear,
        averageMinutesPerDay: avgM,
        totalMinutes: totalM,
        daysWithData: uniqueDays,
        isCurrentMonth: m == 0,
      ));
    }
    return summaries;
  }

  /// Data ringkasan tidur HANYA untuk satu minggu kalender tertentu (7 hari: Senin - Minggu)
  SingleWeekSummary getSingleWeekSummary(DateTime referenceDate) {
    final ref = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
    // Senin sebagai awal minggu (ISO 8601: weekday 1 = Senin, 7 = Minggu)
    final startOfWeek = ref.subtract(Duration(days: ref.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    const dayNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

    final days = <DailySleepSummary>[];
    int totalMinutes = 0;
    int daysWithData = 0;

    for (int i = 0; i < 7; i++) {
      final d = startOfWeek.add(Duration(days: i));
      final recs = getRecordsForDate(d);
      final dayM = recs.fold<int>(0, (acc, r) => acc + r.durationMinutes);
      if (dayM > 0) {
        totalMinutes += dayM;
        daysWithData++;
      }
      days.add(DailySleepSummary(
        date: d,
        dateKey: formatDateKey(d),
        dayName: dayNames[d.weekday % 7],
        dayNumber: d.day.toString(),
        totalMinutes: dayM,
        records: recs,
        isToday: formatDateKey(d) == formatDateKey(DateTime.now()),
      ));
    }

    final avgM = daysWithData > 0 ? (totalMinutes / daysWithData) : 0.0;
    const monthNames = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final weekLabel = startOfWeek.month == endOfWeek.month
        ? '${startOfWeek.day} - ${endOfWeek.day} ${monthNames[startOfWeek.month]} ${startOfWeek.year}'
        : '${startOfWeek.day} ${monthNames[startOfWeek.month]} - ${endOfWeek.day} ${monthNames[endOfWeek.month]} ${endOfWeek.year}';

    // Rata-rata jam tidur dan bangun untuk 1 minggu ini
    final allRecs = days.expand((s) => s.records).toList();
    String avgBed = '11:00 PM';
    String avgWake = '06:00 AM';
    if (allRecs.isNotEmpty) {
      int totalBed = 0;
      int totalWake = 0;
      for (final r in allRecs) {
        int bm = r.startTime.hour * 60 + r.startTime.minute;
        if (bm > 12 * 60) bm -= 24 * 60;
        totalBed += bm;
        totalWake += (r.endTime.hour * 60 + r.endTime.minute);
      }
      int avgBedM = totalBed ~/ allRecs.length;
      if (avgBedM < 0) avgBedM += 24 * 60;
      avgBed = _format12Hour(avgBedM ~/ 60, avgBedM % 60);

      int avgWakeM = totalWake ~/ allRecs.length;
      avgWake = _format12Hour(avgWakeM ~/ 60, avgWakeM % 60);
    }

    return SingleWeekSummary(
      startDate: startOfWeek,
      endDate: endOfWeek,
      weekLabel: weekLabel,
      totalMinutes: totalMinutes,
      daysWithData: daysWithData,
      averageMinutesPerDay: avgM,
      days: days,
      averageBedtime: avgBed,
      averageWakeTime: avgWake,
    );
  }

  /// Data ringkasan tidur HANYA untuk satu bulan kalender tertentu (misal: Oktober 2026)
  CalendarMonthSummary getCalendarMonthSummary(DateTime referenceDate) {
    final year = referenceDate.year;
    final month = referenceDate.month;
    const monthFullNames = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final daysInMonth = DateTime(year, month + 1, 0).day;
    const dayNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

    final dailySummaries = <DailySleepSummary>[];
    int totalMinutes = 0;
    int daysWithData = 0;

    for (int day = 1; day <= daysInMonth; day++) {
      final d = DateTime(year, month, day);
      final recs = getRecordsForDate(d);
      final dayM = recs.fold<int>(0, (acc, r) => acc + r.durationMinutes);
      if (dayM > 0) {
        totalMinutes += dayM;
        daysWithData++;
      }
      dailySummaries.add(DailySleepSummary(
        date: d,
        dateKey: formatDateKey(d),
        dayName: dayNames[d.weekday % 7],
        dayNumber: day.toString(),
        totalMinutes: dayM,
        records: recs,
        isToday: formatDateKey(d) == formatDateKey(DateTime.now()),
      ));
    }

    // Kelompokkan menjadi minggu-minggu di bulan kalender ini (M1: 1-7, M2: 8-14, M3: 15-21, M4: 22-28, M5: 29-N)
    final weeklyChunks = <WeeklySleepSummary>[];
    int chunkStart = 1;
    int weekIndex = 1;
    while (chunkStart <= daysInMonth) {
      final chunkEnd = (chunkStart + 6 <= daysInMonth) ? chunkStart + 6 : daysInMonth;
      final startDate = DateTime(year, month, chunkStart);
      final endDate = DateTime(year, month, chunkEnd);

      final chunkDays = dailySummaries.sublist(chunkStart - 1, chunkEnd);
      final chunkTotalM = chunkDays.fold<int>(0, (acc, s) => acc + s.totalMinutes);
      final chunkDaysWithData = chunkDays.where((s) => s.hasData).length;
      final chunkAvg = chunkDaysWithData > 0 ? (chunkTotalM / chunkDaysWithData) : 0.0;

      final now = DateTime.now();
      final isCurrent = now.year == year && now.month == month && now.day >= chunkStart && now.day <= chunkEnd;

      weeklyChunks.add(WeeklySleepSummary(
        weekLabel: 'Mgg $weekIndex',
        startDate: startDate,
        endDate: endDate,
        averageMinutesPerDay: chunkAvg,
        totalMinutes: chunkTotalM,
        daysWithData: chunkDaysWithData,
        isCurrentWeek: isCurrent,
      ));

      chunkStart = chunkEnd + 1;
      weekIndex++;
    }

    final avgM = daysWithData > 0 ? (totalMinutes / daysWithData) : 0.0;

    return CalendarMonthSummary(
      month: month,
      year: year,
      monthLabel: '${monthFullNames[month]} $year',
      totalMinutes: totalMinutes,
      daysWithData: daysWithData,
      totalDaysInMonth: daysInMonth,
      averageMinutesPerDay: avgM,
      dailySummaries: dailySummaries,
      weeklyChunks: weeklyChunks,
    );
  }

  // ==========================================
  // CRUD & VALIDASI DATA
  // ==========================================

  /// Mendeteksi apakah waktu baru tumpang tindih dengan data tidur yang sudah ada
  SleepRecord? findOverlappingRecord(DateTime start, DateTime end, String dateKey, {String? excludeId}) {
    final effectiveEnd = end.isBefore(start) ? end.add(const Duration(days: 1)) : end;
    final list = _records.where((r) => isMatchingUser(r.userId, currentUserId) && r.date == dateKey && r.id != excludeId);
    for (final existing in list) {
      final existingEnd = existing.endTime.isBefore(existing.startTime)
          ? existing.endTime.add(const Duration(days: 1))
          : existing.endTime;
      // Overlap terjadi jika rentang saling berpotongan
      if (start.isBefore(existingEnd) && effectiveEnd.isAfter(existing.startTime)) {
        return existing;
      }
    }
    return null;
  }

  /// Tambah atau perbarui catatan tidur (1 Tanggal = Maksimal 1 Data Unik)
  Future<void> addRecord(SleepRecord record) async {
    // 1 Tanggal = Maksimal 1 Data Unik:
    // Jika sudah ada catatan pada tanggal yang sama, ganti (timpa) catatan tersebut
    final existingIndex = _records.indexWhere((r) => isMatchingUser(r.userId, record.userId) && r.date == record.date);
    if (existingIndex != -1) {
      final oldRecord = _records[existingIndex];
      // Lindungi catatan manual yang sudah valid agar tidak tertimpa deteksi otomatis yang belum terverifikasi
      if (oldRecord.source == 'manual' && oldRecord.isConfirmed && record.source == 'automatic' && !record.isConfirmed) {
        return;
      }
      if (oldRecord.id != record.id) {
        await _deleteFromFirestore(oldRecord.id);
      }
      _records[existingIndex] = record;
    } else {
      _records.add(record);
    }

    if (_pendingAutoDetectedRecord != null && _pendingAutoDetectedRecord!.date == record.date) {
      _pendingAutoDetectedRecord = null;
    }

    _records.sort((a, b) => a.startTime.compareTo(b.startTime));
    await _saveToLocal();
    _syncToRestReminder(record);
    await _syncToFirestore(record);
    notifyListeners();
  }

  /// Perbarui periode tidur yang sudah ada (1 Tanggal = Maksimal 1 Data Unik)
  Future<void> updateRecord(SleepRecord updated) async {
    // 1 Tanggal = 1 Data Unik: Hapus catatan lain pada tanggal yang sama jika id berbeda
    final sameDateOther = _records.where((r) => isMatchingUser(r.userId, updated.userId) && r.date == updated.date && r.id != updated.id).toList();
    for (final other in sameDateOther) {
      await _deleteFromFirestore(other.id);
    }
    _records.removeWhere((r) => isMatchingUser(r.userId, updated.userId) && r.date == updated.date && r.id != updated.id);

    final index = _records.indexWhere((r) => r.id == updated.id);
    if (index != -1) {
      _records[index] = updated;
    } else {
      _records.add(updated);
    }

    if (_pendingAutoDetectedRecord != null && _pendingAutoDetectedRecord!.date == updated.date) {
      _pendingAutoDetectedRecord = null;
    }

    await _saveToLocal();
    _syncToRestReminder(updated);
    await _syncToFirestore(updated);
    notifyListeners();
  }

  /// Hapus periode tidur
  Future<void> deleteRecord(String id) async {
    _records.removeWhere((r) => r.id == id);
    await _saveToLocal();
    _deleteFromFirestore(id);
    notifyListeners();
  }

  /// Ganti catatan lama dengan catatan baru (misal hasil resolusi tumpang tindih)
  Future<void> replaceRecord(String oldId, SleepRecord newRecord) async {
    await deleteRecord(oldId);
    await addRecord(newRecord);
  }

  // ==========================================
  // SYNC WITH REST REMINDER & FIRESTORE
  // ==========================================

  void _syncToRestReminder(SleepRecord record) {
    RestReminderService.instance.saveReminder(
      type: RestType.night,
      startTime: TimeOfDay(hour: record.startTime.hour, minute: record.startTime.minute),
      endTime: TimeOfDay(hour: record.endTime.hour, minute: record.endTime.minute),
      date: record.startTime,
    );
  }

  Future<void> _syncToFirestore(SleepRecord record) async {
    try {
      if (Firebase.apps.isEmpty) return;
      final uid = record.userId;
      if (uid == 'guest_user') return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('sleep_records')
          .doc(record.id)
          .set(record.toFirestoreMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('[SleepTrackingService] Sync Firestore error: $e');
    }
  }

  Future<void> _deleteFromFirestore(String recordId) async {
    try {
      if (Firebase.apps.isEmpty) return;
      final uid = currentUserId;
      if (uid == 'guest_user') return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('sleep_records')
          .doc(recordId)
          .delete();
    } catch (e) {
      debugPrint('[SleepTrackingService] Delete Firestore error: $e');
    }
  }

  Future<void> _loadFromFirestore() async {
    try {
      if (Firebase.apps.isEmpty) return;
      final uid = currentUserId;
      if (uid == 'guest_user' || uid == 'guest') return;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('sleep_records')
          .limit(100)
          .get();

      if (snapshot.docs.isNotEmpty) {
        bool hasChanges = false;
        for (final doc in snapshot.docs) {
          final rec = SleepRecord.fromMap(doc.data(), doc.id, uid);
          final existingIdx = _records.indexWhere((r) =>
              isMatchingUser(r.userId, rec.userId) &&
              (r.id == rec.id || r.date == rec.date));
          if (existingIdx == -1) {
            _records.add(rec);
            hasChanges = true;
          } else {
            if (rec.updatedAt.isAfter(_records[existingIdx].updatedAt)) {
              final oldRec = _records[existingIdx];
              if (oldRec.id != rec.id) {
                _deleteFromFirestore(oldRec.id);
              }
              _records[existingIdx] = rec;
              hasChanges = true;
            } else if (_records[existingIdx].id != rec.id) {
              _deleteFromFirestore(doc.id);
            }
          }

          if (rec.isConfirmed && _pendingAutoDetectedRecord != null &&
              (_pendingAutoDetectedRecord!.date == rec.date ||
               formatDateKey(_pendingAutoDetectedRecord!.endTime) == rec.date)) {
            _pendingAutoDetectedRecord = null;
            hasChanges = true;
          }
        }
        if (hasChanges) {
          _records.sort((a, b) => a.startTime.compareTo(b.startTime));
          await _saveToLocal();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('[SleepTrackingService] Load Firestore error: $e');
    }
  }

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _firestoreSubscription;

  /// Memulai sinkronisasi real-time Cloud Firestore untuk catatan tidur
  void startFirestoreRealtimeListener() {
    try {
      if (Firebase.apps.isEmpty) return;
      final uid = currentUserId;
      if (uid == 'guest_user' || uid == 'guest') return;

      _firestoreSubscription?.cancel();
      _firestoreSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('sleep_records')
          .limit(100)
          .snapshots()
          .listen((snapshot) {
        bool hasChanges = false;
        for (final doc in snapshot.docs) {
          final rec = SleepRecord.fromMap(doc.data(), doc.id, uid);
          final existingIdx = _records.indexWhere((r) =>
              isMatchingUser(r.userId, rec.userId) &&
              (r.id == rec.id || r.date == rec.date));
          if (existingIdx == -1) {
            _records.add(rec);
            hasChanges = true;
          } else {
            if (_records[existingIdx].id == rec.id) {
              if (_records[existingIdx].updatedAt != rec.updatedAt ||
                  _records[existingIdx].durationMinutes != rec.durationMinutes ||
                  _records[existingIdx].isConfirmed != rec.isConfirmed) {
                _records[existingIdx] = rec;
                hasChanges = true;
              }
            } else if (rec.updatedAt.isAfter(_records[existingIdx].updatedAt)) {
              _records[existingIdx] = rec;
              hasChanges = true;
            }
          }

          if (rec.isConfirmed && _pendingAutoDetectedRecord != null &&
              (_pendingAutoDetectedRecord!.date == rec.date ||
               formatDateKey(_pendingAutoDetectedRecord!.endTime) == rec.date)) {
            _pendingAutoDetectedRecord = null;
            hasChanges = true;
          }
        }
        if (hasChanges) {
          _records.sort((a, b) => a.startTime.compareTo(b.startTime));
          _saveToLocal();
          notifyListeners();
        }
      }, onError: (e) {
        debugPrint('[SleepTrackingService] Firestore realtime error: $e');
      });
    } catch (e) {
      debugPrint('[SleepTrackingService] Realtime listener error: $e');
    }
  }
}

