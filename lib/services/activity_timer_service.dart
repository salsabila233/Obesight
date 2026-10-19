import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'physical_activity_service.dart';
import 'activity_alarm_service.dart';

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

  ActivityTimerService._internal() {
    WidgetsBinding.instance.addObserver(this);
    _initNotifications();
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

  Timer? _ticker;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _notificationsInitialized = false;
  static const int _timerNotificationId = 99101;

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
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  /// Meminta izin notifikasi ke pengguna saat dibutuhkan (Android 13+ & iOS)
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
      debugPrint('Error requesting notification permission: $e');
    }
    return false;
  }

  Future<void> _scheduleFinishNotification() async {
    if (kIsWeb || !_notificationsInitialized) return;
    try {
      await _cancelNotification();

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
        title: isRest ? 'Istirahat Selesai! 🌿' : 'Latihan Selesai! 🎉',
        body: isRest
            ? 'Sesi istirahat Anda telah selesai. Tubuh Anda kini lebih segar!'
            : 'Hebat! Anda telah menyelesaikan sesi $title.',
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  Future<void> _cancelNotification() async {
    if (kIsWeb || !_notificationsInitialized) return;
    try {
      await _notificationsPlugin.cancel(id: _timerNotificationId);
    } catch (e) {
      debugPrint('Error canceling notification: $e');
    }
  }

  // --- App Lifecycle Observer ---

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkTimerProgress();
      notifyListeners();
    }
  }

  void _checkTimerProgress() {
    if (_status == ActivityTimerStatus.running) {
      if (secondsRemaining <= 0) {
        _onTimeCompleted();
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
    _cancelNotification();
    notifyListeners();
  }

  /// Mengubah pilihan preset durasi (misal 30m, 45m, 60m)
  void setPreset(int seconds) {
    ActivityAlarmService.instance.stopAlarm();
    _alarmTriggeredForSession = false;
    _selectedPreset = seconds;
    _targetDuration = seconds;
    _accumulatedElapsedSeconds = 0;
    _segmentStartTime = null;
    _status = ActivityTimerStatus.idle;
    _stopTicker();
    _cancelNotification();
    notifyListeners();
  }

  /// Mulai atau lanjutkan timer
  Future<void> startOrResume() async {
    if (_status == ActivityTimerStatus.running) return;

    // Pastikan izin notifikasi diminta jika belum ada
    await requestNotificationPermission();

    if (_targetDuration <= 0 && _selectedPreset != null) {
      _targetDuration = _selectedPreset!;
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
          }
        }).catchError((e) {
          debugPrint('[ActivityTimerService] Error startSession Firestore: $e');
        });
      } else {
        debugPrint('[ActivityTimerService] Tidak mencatat sesi Firestore untuk tanggal mendatang: $_dateKey');
      }
    }

    _startTicker();
    _scheduleFinishNotification();
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
    _cancelNotification();
    ActivityAlarmService.instance.stopAlarm();
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

  /// Ketika waktu habis secara natural (100%)
  void _onTimeCompleted() {
    _stopTicker();
    _cancelNotification();

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
    _cancelNotification();
    ActivityAlarmService.instance.stopAlarm();
    _segmentStartTime = null;

    final isEligible = meetsMinimum50Percent;
    final dKey = _dateKey ?? PhysicalActivityService.instance.todayKey;
    final isRest = _activeActivity?['isRest'] == true;

    if (!isRest && PhysicalActivityService.isFutureDateKey(dKey)) {
      debugPrint('[ActivityTimerService] Menolak finishManually: tanggal mendatang ($dKey).');
      _status = ActivityTimerStatus.paused;
      notifyListeners();
      return false;
    }

    if (isEligible) {
      _status = ActivityTimerStatus.completed;
      final saved = await _autoSaveChecklistIfEligible();
      notifyListeners();
      return saved;
    } else {
      _status = ActivityTimerStatus.paused;
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
    _cancelNotification();
    ActivityAlarmService.instance.stopAlarm();
    _alarmTriggeredForSession = false;
    _activeActivity = null;
    _dateKey = null;
    _targetDuration = 0;
    _selectedPreset = null;
    _accumulatedElapsedSeconds = 0;
    _segmentStartTime = null;
    _status = ActivityTimerStatus.idle;
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
