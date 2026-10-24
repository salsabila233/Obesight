import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'physical_activity_service.dart';
import 'activity_alarm_service.dart';
import 'activity_rest_helper.dart';

enum ActivityTimerStatus {
  idle,
  running,
  paused,
  completed,
}

class ActivityTimerService extends ChangeNotifier with WidgetsBindingObserver {
  static final ActivityTimerService _instance = ActivityTimerService._internal();
  factory ActivityTimerService() => _instance;
  static ActivityTimerService get instance => _instance;

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static const String _storagePrefix = 'obesight_timer_session_';
  static const int _timerRunningNotificationId = 99102;
  static const int _timerNotificationId = 99101;

  ActivityTimerService._internal() {
    WidgetsBinding.instance.addObserver(this);
    _initNotifications();
    restoreSessionFromStorage();
  }

  // State
  Map<String, dynamic>? _activeActivity;
  String? _dateKey;
  int _targetDuration = 0;
  int? _selectedPreset;
  int _accumulatedElapsedSeconds = 0;
  DateTime? _segmentStartTime;
  ActivityTimerStatus _status = ActivityTimerStatus.idle;
  bool _alarmTriggeredForSession = false;
  bool _isTimerScreenActive = false;

  Timer? _ticker;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _notificationsInitialized = false;

  // Firestore Workout Session Tracker
  String? _activeSessionId;
  Future<String?>? _startSessionFuture;
  DateTime? _sessionLocalStartTime;

  // Getters
  String? get activeSessionId => _activeSessionId;
  Map<String, dynamic>? get activeActivity => _activeActivity;
  String? get dateKey => _dateKey;
  int get targetDuration => _targetDuration;
  int? get selectedPreset => _selectedPreset;
  ActivityTimerStatus get status => _status;
  bool get alarmTriggeredForSession => _alarmTriggeredForSession;
  bool get isRunning => _status == ActivityTimerStatus.running;
  bool get isPaused => _status == ActivityTimerStatus.paused;
  bool get isCompleted => _status == ActivityTimerStatus.completed;
  bool get isIdle => _status == ActivityTimerStatus.idle;
  bool get isTimerScreenActive => _isTimerScreenActive;

  void setTimerScreenActive(bool active) {
    if (_isTimerScreenActive != active) {
      _isTimerScreenActive = active;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  bool get hasActiveSession => _activeActivity != null && _status != ActivityTimerStatus.idle;

  /// Hitung detik yang telah berjalan secara real-time berdasarkan selisih waktu
  int get elapsedSeconds {
    if (_status == ActivityTimerStatus.running && _segmentStartTime != null) {
      final diff = DateTime.now().difference(_segmentStartTime!).inSeconds;
      final total = _accumulatedElapsedSeconds + diff;
      if (_targetDuration > 0) {
        return total.clamp(0, _targetDuration);
      }
      return total;
    }
    if (_targetDuration > 0) {
      return _accumulatedElapsedSeconds.clamp(0, _targetDuration);
    }
    return _accumulatedElapsedSeconds;
  }

  /// Sisa waktu dalam detik
  int get secondsRemaining {
    if (_targetDuration <= 0) return 0;
    final remaining = _targetDuration - elapsedSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Cek apakah durasi aktual sudah memenuhi minimal 50% dari target
  bool get meetsMinimum50Percent {
    if (_targetDuration <= 0) return true;
    return elapsedSeconds >= (_targetDuration * 0.5);
  }

  // --- Notification Initialization & Permission ---

  Future<void> _initNotifications() async {
    if (kIsWeb || ActivityAlarmService.isTestMode) return;
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
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  /// Meminta izin notifikasi ke pengguna saat dibutuhkan (Android 13+ & iOS)
  Future<bool> requestNotificationPermission() async {
    if (kIsWeb || ActivityAlarmService.isTestMode) return false;
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
      debugPrint('Error requesting notification permission: $e');
    }
    return false;
  }

  /// Menampilkan notifikasi timer berjalan secara real-time / ongoing
  Future<void> _showRunningNotification() async {
    if (kIsWeb || !_notificationsInitialized || ActivityAlarmService.isTestMode) return;
    try {
      final title = _activeActivity?['title'] as String? ?? 'Aktivitas Fisik';
      final isRest = _activeActivity?['isRest'] == true;
      final m = secondsRemaining ~/ 60;
      final s = secondsRemaining % 60;
      final timeStr = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
      final durationMins = _targetDuration ~/ 60;

      final androidDetails = AndroidNotificationDetails(
        'activity_timer_running_channel',
        'Timer Berjalan',
        channelDescription: 'Status waktu timer aktivitas fisik yang sedang berlangsung',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        ongoing: true,
        onlyAlertOnce: true,
        showWhen: true,
        when: DateTime.now().millisecondsSinceEpoch + (secondsRemaining * 1000),
        usesChronometer: true,
        chronometerCountDown: true,
        visibility: NotificationVisibility.public,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: false,
        presentSound: false,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        id: _timerRunningNotificationId,
        title: isRest ? 'Sesi Istirahat Berlangsung 🌿' : 'Timer aktivitas fisik berjalan',
        body: isRest
            ? 'Sesi: Istirahat • $durationMins menit | Sisa: $timeStr'
            : 'Sesi: $title • $durationMins menit | Sisa waktu: $timeStr',
        notificationDetails: notificationDetails,
      );
    } catch (e) {
      debugPrint('Error showing running notification: $e');
    }
  }

  Future<void> _cancelRunningNotification() async {
    if (kIsWeb || !_notificationsInitialized || ActivityAlarmService.isTestMode) return;
    try {
      await _notificationsPlugin.cancel(id: _timerRunningNotificationId);
    } catch (e) {
      debugPrint('Error canceling running notification: $e');
    }
  }

  Future<void> _scheduleFinishNotification() async {
    if (kIsWeb || !_notificationsInitialized || ActivityAlarmService.isTestMode) return;
    try {
      await _cancelScheduledNotification();

      final remaining = secondsRemaining;
      if (remaining <= 0) return;

      final title = _activeActivity?['title'] as String? ?? 'Aktivitas';
      final isRest = _activeActivity?['isRest'] == true;

      final scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(seconds: remaining));

      const androidDetails = AndroidNotificationDetails(
        'activity_timer_channel',
        'Timer Aktivitas',
        channelDescription: 'Notifikasi saat timer aktivitas atau istirahat selesai',
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
        id: _timerNotificationId,
        title: isRest ? 'Istirahat Selesai! 🌿' : 'Waktu Aktivitas Habis',
        body: isRest
            ? 'Sesi istirahat Anda telah selesai. Tubuh Anda kini lebih segar!'
            : 'Durasi ${title.toLowerCase()} telah selesai.',
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  Future<void> _showCompletionNotification() async {
    if (kIsWeb || !_notificationsInitialized || ActivityAlarmService.isTestMode) return;
    try {
      final title = _activeActivity?['title'] as String? ?? 'Aktivitas';
      final isRest = _activeActivity?['isRest'] == true;

      const androidDetails = AndroidNotificationDetails(
        'activity_timer_channel',
        'Timer Aktivitas',
        channelDescription: 'Notifikasi saat timer aktivitas selesai',
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

      await _notificationsPlugin.show(
        id: _timerNotificationId,
        title: isRest ? 'Istirahat Selesai! 🌿' : 'Waktu Aktivitas Habis',
        body: isRest
            ? 'Sesi istirahat Anda telah selesai. Tubuh Anda kini lebih segar!'
            : 'Durasi ${title.toLowerCase()} telah selesai.',
        notificationDetails: notificationDetails,
      );
    } catch (e) {
      debugPrint('Error showing completion notification: $e');
    }
  }

  Future<void> _cancelScheduledNotification() async {
    if (kIsWeb || !_notificationsInitialized || ActivityAlarmService.isTestMode) return;
    try {
      await _notificationsPlugin.cancel(id: _timerNotificationId);
    } catch (e) {
      debugPrint('Error canceling scheduled notification: $e');
    }
  }

  Future<void> _cancelAllNotifications() async {
    await _cancelRunningNotification();
    await _cancelScheduledNotification();
  }

  // --- Session Persistence (SharedPreferences) ---

  Future<void> _saveSessionToStorage() async {
    if (ActivityAlarmService.isTestMode) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_status == ActivityTimerStatus.idle || _activeActivity == null) {
        await _clearSessionFromStorage();
        return;
      }
      final data = {
        'activeActivity': _activeActivity,
        'dateKey': _dateKey,
        'targetDuration': _targetDuration,
        'selectedPreset': _selectedPreset,
        'accumulatedElapsedSeconds': _accumulatedElapsedSeconds,
        'segmentStartTime': _segmentStartTime?.toIso8601String(),
        'status': _status.name,
        'activeSessionId': _activeSessionId,
        'sessionLocalStartTime': _sessionLocalStartTime?.toIso8601String(),
      };
      await prefs.setString('${_storagePrefix}data', jsonEncode(data));
    } catch (e) {
      debugPrint('[ActivityTimerService] Error saving session to storage: $e');
    }
  }

  Future<void> restoreSessionFromStorage() async {
    if (ActivityAlarmService.isTestMode) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('${_storagePrefix}data');
      if (raw == null || raw.isEmpty) return;

      final data = jsonDecode(raw) as Map<String, dynamic>;
      _activeActivity = data['activeActivity'] != null ? Map<String, dynamic>.from(data['activeActivity'] as Map) : null;
      _dateKey = data['dateKey'] as String?;
      _targetDuration = (data['targetDuration'] as num?)?.toInt() ?? 0;
      _selectedPreset = (data['selectedPreset'] as num?)?.toInt();
      _accumulatedElapsedSeconds = (data['accumulatedElapsedSeconds'] as num?)?.toInt() ?? 0;
      _activeSessionId = data['activeSessionId'] as String?;
      if (data['sessionLocalStartTime'] != null) {
        _sessionLocalStartTime = DateTime.tryParse(data['sessionLocalStartTime'] as String);
      }

      final statusStr = data['status'] as String? ?? 'idle';
      if (data['segmentStartTime'] != null) {
        _segmentStartTime = DateTime.tryParse(data['segmentStartTime'] as String);
      }

      if (statusStr == 'running') {
        _status = ActivityTimerStatus.running;
        // Hitung apakah sudah mencapai atau melampaui waktu selesai saat aplikasi dibuka kembali
        if (secondsRemaining <= 0) {
          _onTimeCompleted();
        } else {
          _startTicker();
          _showRunningNotification();
          _scheduleFinishNotification();
        }
      } else if (statusStr == 'paused') {
        _status = ActivityTimerStatus.paused;
      } else if (statusStr == 'completed') {
        _status = ActivityTimerStatus.completed;
      } else {
        _status = ActivityTimerStatus.idle;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('[ActivityTimerService] Error restoring session from storage: $e');
    }
  }

  Future<void> _clearSessionFromStorage() async {
    if (ActivityAlarmService.isTestMode) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_storagePrefix}data');
    } catch (e) {
      debugPrint('[ActivityTimerService] Error clearing session storage: $e');
    }
  }

  // --- App Lifecycle Observer ---

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkTimerProgress();
      notifyListeners();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_status == ActivityTimerStatus.running) {
        _showRunningNotification();
      }
      _saveSessionToStorage();
    }
  }

  void _checkTimerProgress() {
    if (_status == ActivityTimerStatus.running) {
      if (secondsRemaining <= 0) {
        _onTimeCompleted();
      } else {
        _showRunningNotification();
      }
    }
  }

  // --- Timer Controls ---

  /// Memulai sesi timer baru atau mengganti aktivitas
  void setupSession({
    required Map<String, dynamic> activity,
    int? presetSeconds,
    String? dateKey,
  }) {
    ActivityAlarmService.instance.stopAlarm();
    _alarmTriggeredForSession = false;
    _activeSessionId = null;
    _startSessionFuture = null;
    _sessionLocalStartTime = null;
    _activeActivity = activity;
    _dateKey = dateKey ?? PhysicalActivityService.instance.todayKey;

    _selectedPreset = presetSeconds;
    _targetDuration = presetSeconds ?? 0;
    _accumulatedElapsedSeconds = 0;
    _segmentStartTime = null;
    _status = ActivityTimerStatus.idle;
    _stopTicker();
    _cancelAllNotifications();
    _saveSessionToStorage();
    notifyListeners();
  }

  /// Mengatur durasi timer aktivitas fisik kustom (antara 15 hingga 60 menit)
  void setDurationMinutes(int minutes) {
    final clamped = ActivityRestHelper.clampActivityDuration(minutes);
    setPreset(clamped * 60);
  }

  /// Mengubah pilihan preset durasi (misal 15m, 20m, 30m, 45m, 60m)
  void setPreset(int seconds) {
    ActivityAlarmService.instance.stopAlarm();
    _alarmTriggeredForSession = false;
    _selectedPreset = seconds;
    _targetDuration = seconds;
    _accumulatedElapsedSeconds = 0;
    _segmentStartTime = null;
    _status = ActivityTimerStatus.idle;
    _stopTicker();
    _cancelAllNotifications();
    _saveSessionToStorage();
    notifyListeners();
  }

  /// Mulai atau lanjutkan timer
  Future<void> startOrResume() async {
    if (_status == ActivityTimerStatus.running) return;

    // Pastikan izin notifikasi diminta jika belum ada
    await requestNotificationPermission();

    if (_targetDuration <= 0 && _selectedPreset != null) {
      _targetDuration = _selectedPreset!;
    } else if (_targetDuration <= 0) {
      final isRest = _activeActivity?['isRest'] == true;
      final defaultMinutes = isRest ? 15 : ActivityRestHelper.getRecommendedActivityDuration(_activeActivity);
      _targetDuration = defaultMinutes * 60;
      _selectedPreset = _targetDuration;
    }

    _segmentStartTime = DateTime.now();
    _status = ActivityTimerStatus.running;

    // Catat permulaan sesi ke Cloud Firestore (riwayat_sesi)
    if (_activeSessionId == null && _activeActivity != null && _activeActivity?['isRest'] != true) {
      if (!PhysicalActivityService.isFutureDateKey(_dateKey)) {
        _sessionLocalStartTime ??= DateTime.now();
        _startSessionFuture = PhysicalActivityService.instance.startSession(
          activity: _activeActivity!,
          dateKey: _dateKey,
        );
        _startSessionFuture!.then((sid) {
          if (sid != null) {
            _activeSessionId = sid;
            debugPrint('[ActivityTimerService] Active sessionId terdaftar: $sid');
            _saveSessionToStorage();
          }
        }).catchError((e) {
          debugPrint('[ActivityTimerService] Error startSession Firestore: $e');
        });
      } else {
        debugPrint('[ActivityTimerService] Tidak mencatat sesi Firestore untuk tanggal mendatang: $_dateKey');
      }
    }

    _startTicker();
    _showRunningNotification();
    _scheduleFinishNotification();
    _saveSessionToStorage();
    notifyListeners();
  }

  /// Pause timer
  void pause() {
    if (_status != ActivityTimerStatus.running) return;

    if (_segmentStartTime != null) {
      final diff = DateTime.now().difference(_segmentStartTime!).inSeconds;
      _accumulatedElapsedSeconds += diff;
      if (_targetDuration > 0) {
        _accumulatedElapsedSeconds = _accumulatedElapsedSeconds.clamp(0, _targetDuration);
      }
    }
    _segmentStartTime = null;
    _status = ActivityTimerStatus.paused;

    _stopTicker();
    _cancelRunningNotification();
    _cancelScheduledNotification();
    ActivityAlarmService.instance.stopAlarm();
    _saveSessionToStorage();
    notifyListeners();
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    if (_status == ActivityTimerStatus.running) {
      pause();
    } else {
      await startOrResume();
    }
  }

  /// Ketika waktu habis secara natural (100% / 00:00)
  void _onTimeCompleted() {
    _stopTicker();
    _cancelRunningNotification();
    _cancelScheduledNotification();
    _showCompletionNotification();

    // Pastikan accumulated elapsed seconds mencakup durasi penuh
    _accumulatedElapsedSeconds = _targetDuration;
    _segmentStartTime = null;
    _status = ActivityTimerStatus.completed;

    // Auto-save checklist ke PhysicalActivityService
    _autoSaveChecklistIfEligible();

    // Mainkan alarm tepat satu kali per sesi
    if (!_alarmTriggeredForSession) {
      _alarmTriggeredForSession = true;
      final isRest = _activeActivity?['isRest'] == true;
      if (isRest) {
        ActivityAlarmService.instance.playRestAlarm();
      } else {
        ActivityAlarmService.instance.playActivityAlarm();
      }
    }

    _clearSessionFromStorage();
    notifyListeners();
  }

  /// Helper untuk pengujian unit saat waktu timer habis secara alami (00:00)
  @visibleForTesting
  void triggerTimeCompletedForTesting() {
    _onTimeCompleted();
  }

  /// Auto-save checklist jika memenuhi syarat (>= 50% target atau selesai)
  Future<bool> _autoSaveChecklistIfEligible() async {
    final act = _activeActivity;
    if (act == null) return false;
    final isRest = act['isRest'] == true;
    if (isRest) return true; // Istirahat tidak memiliki checklist aktivitas fisik

    final actId = act['id'] as String? ?? '';
    final dKey = _dateKey ?? PhysicalActivityService.instance.todayKey;

    // Menolak auto-save jika tanggal target merupakan tanggal mendatang
    if (PhysicalActivityService.isFutureDateKey(dKey)) {
      debugPrint('[ActivityTimerService] Menolak autoSaveChecklist: tanggal mendatang ($dKey). Progres hanya dapat dicatat untuk hari ini.');
      return false;
    }

    if (actId.isNotEmpty && meetsMinimum50Percent) {
      // Tunggu future startSession jika masih dalam proses
      if (_activeSessionId == null && _startSessionFuture != null) {
        try {
          final sid = await _startSessionFuture;
          if (sid != null) {
            _activeSessionId = sid;
          }
        } catch (_) {}
      }

      final sessionId = _activeSessionId;
      final startTime = _sessionLocalStartTime;

      bool success = false;
      if (sessionId != null) {
        success = await PhysicalActivityService.instance.finishSession(
          sessionId: sessionId,
          activity: act,
          elapsedSeconds: elapsedSeconds,
          dateKey: dKey,
          localStartTime: startTime,
        );
      } else {
        success = await PhysicalActivityService.instance.completeActivity(
          dKey,
          actId,
          activity: act,
          elapsedSeconds: elapsedSeconds,
        );
      }

      // Bersihkan sesi aktif setelah selesai
      _activeSessionId = null;
      _startSessionFuture = null;
      _sessionLocalStartTime = null;

      return success;
    }
    return false;
  }

  /// Menyelesaikan sesi secara manual (tombol Selesaikan Aktivitas)
  /// Mengembalikan true jika valid (>= 50%) dan berhasil simpan, false jika tidak valid (< 50%) atau gagal simpan
  Future<bool> finishManually() async {
    // Kumpulkan durasi terkini
    if (_status == ActivityTimerStatus.running && _segmentStartTime != null) {
      final diff = DateTime.now().difference(_segmentStartTime!).inSeconds;
      _accumulatedElapsedSeconds += diff;
    }
    _stopTicker();
    _cancelAllNotifications();
    ActivityAlarmService.instance.stopAlarm();
    _segmentStartTime = null;

    final isEligible = meetsMinimum50Percent;
    final dKey = _dateKey ?? PhysicalActivityService.instance.todayKey;
    final isRest = _activeActivity?['isRest'] == true;

    if (!isRest && PhysicalActivityService.isFutureDateKey(dKey)) {
      debugPrint('[ActivityTimerService] Menolak finishManually: tanggal mendatang ($dKey).');
      _status = ActivityTimerStatus.paused;
      _saveSessionToStorage();
      notifyListeners();
      return false;
    }

    if (isEligible) {
      _status = ActivityTimerStatus.completed;
      final saved = await _autoSaveChecklistIfEligible();
      _clearSessionFromStorage();
      notifyListeners();
      return saved;
    } else {
      _status = ActivityTimerStatus.paused;
      _saveSessionToStorage();
      notifyListeners();
      return false;
    }
  }

  /// Membatalkan dan mereset timer
  void cancelSession() {
    final sid = _activeSessionId;
    if (sid != null) {
      PhysicalActivityService.instance.cancelSession(sessionId: sid);
    }
    _activeSessionId = null;
    _startSessionFuture = null;
    _sessionLocalStartTime = null;
    _stopTicker();
    _cancelAllNotifications();
    ActivityAlarmService.instance.stopAlarm();
    _alarmTriggeredForSession = false;
    _activeActivity = null;
    _dateKey = null;
    _targetDuration = 0;
    _selectedPreset = null;
    _accumulatedElapsedSeconds = 0;
    _segmentStartTime = null;
    _status = ActivityTimerStatus.idle;
    _clearSessionFromStorage();
    notifyListeners();
  }

  void _startTicker() {
    _stopTicker();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining <= 0) {
        _onTimeCompleted();
      } else {
        notifyListeners();
      }
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTicker();
    ActivityAlarmService.instance.stopAlarm();
    super.dispose();
  }
}
