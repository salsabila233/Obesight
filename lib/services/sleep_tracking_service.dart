import 'dart:async';
import 'dart:convert';
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

  SleepTrackingService._internal();

  bool _isInitialized = false;

  // Inactivity tracking parameters
  int _minimumInactivityMinutes = 15; // Batas minimum tidak aktif HP (default: 15 menit)
  static const int _minimumNightSleepMinutes = 180; // Minimal 3 jam (180 menit) untuk sesi tidur malam
  DateTime? _lastInactiveTime;
  DateTime? _lastNightInactiveTime;
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
  static const String _sleepChannelId = 'sleep_reminder_channel';
  static const String _sleepChannelName = 'Pengingat Waktu Tidur';

  // Getters
  int get minimumInactivityMinutes => _minimumInactivityMinutes;
  set minimumInactivityMinutes(int val) {
    _minimumInactivityMinutes = val > 0 ? val : 15;
    notifyListeners();
  }

  DateTime? get lastInactiveTime => _lastInactiveTime;
  SleepRecord? get pendingAutoDetectedRecord => _pendingAutoDetectedRecord;

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

  Future<void> initNotifications() async {
    if (kIsWeb) return;
    try {
      tz.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
      );
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
        final granted = await androidPlugin.requestNotificationsPermission();
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
    if (kIsWeb || !_notificationsInitialized || !_reminderEnabled) return;
    try {
      await cancelBedtimeNotification();

      final now = DateTime.now();
      final rTime = reminderTime;
      var scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        rTime.hour,
        rTime.minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final tzScheduled = tz.TZDateTime.from(scheduledDate, tz.local);

      const androidDetails = AndroidNotificationDetails(
        _sleepChannelId,
        _sleepChannelName,
        channelDescription: 'Pengingat harian jadwal waktu istirahat tidur malam',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
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

      await _notificationsPlugin.zonedSchedule(
        id: _sleepReminderNotificationId,
        title: 'Pengingat Waktu Tidur 🌙',
        body: 'Waktu tidurmu semakin dekat (Target: ${_bedtimeTarget.hour.toString().padLeft(2, '0')}.${_bedtimeTarget.minute.toString().padLeft(2, '0')}). Yuk mulai bersiap tidur.',
        scheduledDate: tzScheduled,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
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
    try {
      const androidDetails = AndroidNotificationDetails(
        _sleepChannelId,
        _sleepChannelName,
        channelDescription: 'Pengingat harian jadwal waktu istirahat tidur malam',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
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

      final hStr = _bedtimeTarget.hour.toString().padLeft(2, '0');
      final mStr = _bedtimeTarget.minute.toString().padLeft(2, '0');

      await _notificationsPlugin.show(
        id: _testNotificationId,
        title: 'Pengingat Waktu Tidur 🌙',
        body: 'Waktu tidurmu semakin dekat (Target: $hStr.$mStr). Yuk mulai bersiap untuk beristirahat!',
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
            _records.add(SleepRecord.fromMap(Map<String, dynamic>.from(item)));
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
  // DEVICE INACTIVITY & SCREEN MONITORING
  // ==========================================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      final now = DateTime.now();
      _lastInactiveTime = now;
      // Deteksi titik terakhir layar HP dimatikan di malam hari (pukul 20.00 s.d. 04.30)
      // Setiap kali HP dimatikan di malam hari, perbarui ke titik paling terakhir
      if (now.hour >= 20 || now.hour < 5) {
        _lastNightInactiveTime = now;
      }
      _saveToLocal();
      debugPrint('[SleepTracker] Inactive at $now (lastNightOff: $_lastNightInactiveTime)');
    } else if (state == AppLifecycleState.resumed) {
      // HP kembali aktif / dibuka di pagi hari
      checkDeviceInactivityCandidate();
    }
  }

  /// Memeriksa aktivitas layar mati semalam dan nyala pagi hari (Samsung Health model)
  Future<void> checkDeviceInactivityCandidate() async {
    final now = DateTime.now();
    final todayKey = formatDateKey(now);
    final todayRecs = getRecordsForDate(now);

    // Jika hari ini sudah ada catatan tidur resmi tersimpan, jangan tampilkan pending auto lagi
    if (todayRecs.isNotEmpty) {
      if (_pendingAutoDetectedRecord != null && _pendingAutoDetectedRecord!.date == todayKey) {
        _pendingAutoDetectedRecord = null;
        _saveToLocal();
        notifyListeners();
      }
      return;
    }

    try {
      // 1. Coba periksa native Android BroadcastReceiver timestamp via Platform Channel
      final lastOffMillis = await _platformChannel.invokeMethod<int>('getLastScreenOff');
      final lastOnMillis = await _platformChannel.invokeMethod<int>('getLastScreenOn');

      if (lastOffMillis != null && lastOffMillis > 0 && lastOnMillis != null && lastOnMillis > lastOffMillis) {
        final offDt = DateTime.fromMillisecondsSinceEpoch(lastOffMillis);
        final onDt = DateTime.fromMillisecondsSinceEpoch(lastOnMillis);
        final diffMinutes = onDt.difference(offDt).inMinutes;

        // Syarat sesi tidur malam Samsung Health:
        // Titik terakhir layar mati di rentang malam (>= 20.00 atau < 05.00),
        // layar nyala di pagi hari, dan durasi istirahat substansial minimal 3 jam (180 menit) s.d. 14 jam (840 menit)
        final isNightStart = offDt.hour >= 20 || offDt.hour < 5;
        if (isNightStart && diffMinutes >= _minimumNightSleepMinutes && diffMinutes <= 840) {
          _recordAutomaticSleepCandidate(offDt, onDt);
          await _platformChannel.invokeMethod('clearScreenTimes');
          return;
        }
      }
    } catch (_) {
      // Platform channel tidak tersedia di environment test / non-Android
    }

    // 2. Fallback: Gunakan titik terakhir layar HP dimatikan semalam dari Flutter lifecycle
    if (_lastNightInactiveTime != null) {
      final diff = now.difference(_lastNightInactiveTime!);
      final isMorningOrDay = now.hour >= 5 && now.hour <= 14;

      // Sesi tidur malam yang valid:
      // Mulai semalam, dibuka di pagi/siang hari, dengan durasi minimal 3 jam
      if (diff.inMinutes >= _minimumNightSleepMinutes && diff.inMinutes <= 840 && isMorningOrDay) {
        _recordAutomaticSleepCandidate(_lastNightInactiveTime!, now);
        _lastNightInactiveTime = null;
        _saveToLocal();
        return;
      }
    }
  }

  /// Membuat calon (kandidat) perkiraan waktu tidur otomatis untuk ditinjau pengguna
  void _recordAutomaticSleepCandidate(DateTime start, DateTime end) {
    final dateKey = formatDateKey(end);
    final autoRecord = SleepRecord(
      id: 'auto_${DateTime.now().millisecondsSinceEpoch}',
      userId: currentUserId,
      date: dateKey,
      startTime: start,
      endTime: end,
      source: 'automatic',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Disimpan sebagai calon/kandidat pending untuk diverifikasi pengguna via "Catat waktu ini"
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
  Future<bool> acceptPendingAutoRecord() async {
    if (_pendingAutoDetectedRecord != null) {
      final candidate = _pendingAutoDetectedRecord!;
      // Hapus data yang sama jika ada sebelumnya
      _records.removeWhere((r) =>
          r.userId == candidate.userId &&
          r.date == candidate.date &&
          r.startTime == candidate.startTime &&
          r.endTime == candidate.endTime);

      _records.add(candidate);
      _pendingAutoDetectedRecord = null;
      await _saveToLocal();
      _syncToRestReminder(candidate);
      _syncToFirestore(candidate);
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
    return _records
        .where((r) => r.userId == uid && r.date == key)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  List<SleepRecord> get todayRecords => getRecordsForDate(DateTime.now());

  bool get hasTodayData => todayRecords.isNotEmpty;

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
    const dayNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

    final summaries = <DailySleepSummary>[];
    for (int i = 6; i >= 0; i--) {
      final date = ref.subtract(Duration(days: i));
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
    final list = _records.where((r) => r.userId == currentUserId && r.date == dateKey && r.id != excludeId);
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

  /// Tambah periode tidur baru (mendukung multi-periode)
  Future<void> addRecord(SleepRecord record) async {
    // Validasi: tidak boleh duplikat persis
    _records.removeWhere((r) =>
        r.userId == record.userId &&
        r.date == record.date &&
        r.startTime == record.startTime &&
        r.endTime == record.endTime);

    _records.add(record);
    await _saveToLocal();
    _syncToRestReminder(record);
    _syncToFirestore(record);
    notifyListeners();
  }

  /// Perbarui periode tidur yang sudah ada
  Future<void> updateRecord(SleepRecord updated) async {
    final index = _records.indexWhere((r) => r.id == updated.id);
    if (index != -1) {
      _records[index] = updated;
      await _saveToLocal();
      _syncToRestReminder(updated);
      _syncToFirestore(updated);
      notifyListeners();
    }
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
          .set(record.toMap(), SetOptions(merge: true));
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
      if (uid == 'guest_user') return;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('sleep_records')
          .orderBy('waktu_mulai', descending: true)
          .limit(50)
          .get();

      if (snapshot.docs.isNotEmpty) {
        for (final doc in snapshot.docs) {
          final rec = SleepRecord.fromMap(doc.data(), doc.id);
          final exists = _records.any((r) => r.id == rec.id);
          if (!exists) {
            _records.add(rec);
          }
        }
        await _saveToLocal();
        notifyListeners();
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
      if (uid == 'guest_user') return;

      _firestoreSubscription?.cancel();
      _firestoreSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('sleep_records')
          .orderBy('waktu_mulai', descending: true)
          .limit(100)
          .snapshots()
          .listen((snapshot) {
        bool hasChanges = false;
        for (final doc in snapshot.docs) {
          final rec = SleepRecord.fromMap(doc.data(), doc.id);
          final idx = _records.indexWhere((r) => r.id == rec.id);
          if (idx == -1) {
            _records.add(rec);
            hasChanges = true;
          } else {
            if (_records[idx].updatedAt != rec.updatedAt ||
                _records[idx].durationMinutes != rec.durationMinutes) {
              _records[idx] = rec;
              hasChanges = true;
            }
          }
        }
        if (hasChanges) {
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

