import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Service untuk memutar dan mengelola suara alarm aktivitas fisik dan istirahat.
class ActivityAlarmService {
  static final ActivityAlarmService _instance = ActivityAlarmService._internal();
  factory ActivityAlarmService() => _instance;
  static ActivityAlarmService get instance => _instance;

  ActivityAlarmService._internal();

  /// Mode pengujian untuk menguji logika tanpa memanggil native audio platform
  static bool isTestMode = false;

  AudioPlayer? _player;
  Timer? _autoStopTimer;
  bool _isPlaying = false;
  String? _currentAlarmType; // 'activity' | 'rest'

  bool get isPlaying => _isPlaying;
  String? get currentAlarmType => _currentAlarmType;

  /// Memastikan instance AudioPlayer tersedia
  AudioPlayer? _getPlayer() {
    if (isTestMode) return null;
    if (_player == null) {
      try {
        _player = AudioPlayer();
        _player!.onPlayerComplete.listen((_) {
          // Jika mode non-looping selesai
          if (_player?.releaseMode != ReleaseMode.loop) {
            _isPlaying = false;
            _currentAlarmType = null;
          }
        });
      } catch (e) {
        debugPrint('ActivityAlarmService: Inisialisasi AudioPlayer gagal: $e');
        _player = null;
      }
    }
    return _player;
  }

  /// Memutar alarm aktivitas fisik (tuntas 00:00)
  Future<void> playActivityAlarm() async {
    try {
      _autoStopTimer?.cancel();
      _autoStopTimer = null;
      if (_player != null && !isTestMode) {
        try {
          await _player!.stop();
        } catch (_) {}
      }
      _isPlaying = true;
      _currentAlarmType = 'activity';

      if (!isTestMode) {
        final player = _getPlayer();
        if (player != null) {
          await player.setReleaseMode(ReleaseMode.loop);
          await player.play(AssetSource('audio/activity_alarm.wav'));
        }
      }

      // Batas waktu keamanan maksimal 45 detik agar tidak berdering tanpa henti jika ditinggal
      _autoStopTimer = Timer(const Duration(seconds: 45), () {
        stopAlarm();
      });
    } catch (e) {
      debugPrint('ActivityAlarmService: Gagal memutar alarm aktivitas: $e');
      _isPlaying = false;
      _currentAlarmType = null;
    }
  }

  /// Memutar alarm istirahat (tuntas 00:00)
  Future<void> playRestAlarm() async {
    try {
      _autoStopTimer?.cancel();
      _autoStopTimer = null;
      if (_player != null && !isTestMode) {
        try {
          await _player!.stop();
        } catch (_) {}
      }
      _isPlaying = true;
      _currentAlarmType = 'rest';

      if (!isTestMode) {
        final player = _getPlayer();
        if (player != null) {
          await player.setReleaseMode(ReleaseMode.loop);
          await player.play(AssetSource('audio/rest_alarm.wav'));
        }
      }

      // Batas waktu keamanan maksimal 45 detik
      _autoStopTimer = Timer(const Duration(seconds: 45), () {
        stopAlarm();
      });
    } catch (e) {
      debugPrint('ActivityAlarmService: Gagal memutar alarm istirahat: $e');
      _isPlaying = false;
      _currentAlarmType = null;
    }
  }

  /// Menghentikan pemutaran alarm
  Future<void> stopAlarm() async {
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    if (_player != null && !isTestMode) {
      try {
        await _player!.stop();
      } catch (e) {
        debugPrint('ActivityAlarmService: Gagal menghentikan alarm: $e');
      }
    }
    _isPlaying = false;
    _currentAlarmType = null;
  }

  /// Membersihkan sumber daya audio
  Future<void> dispose() async {
    await stopAlarm();
    if (_player != null && !isTestMode) {
      try {
        await _player?.dispose();
      } catch (e) {
        debugPrint('ActivityAlarmService: Error saat dispose player: $e');
      }
    }
    _player = null;
  }
}
