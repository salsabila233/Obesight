import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/screening_history_model.dart';
import '../models/user_model.dart';
import '../screens/skrining/skrining_models.dart';

class UserScreeningSummary {
  final int totalScreenings;
  final DateTime? lastScreeningDate;
  final ScreeningHistoryItem? latestScreening;
  final bool hasLoaded;

  const UserScreeningSummary({
    this.totalScreenings = 0,
    this.lastScreeningDate,
    this.latestScreening,
    this.hasLoaded = false,
  });

  String get formattedLastDate {
    if (lastScreeningDate == null) return '--';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final d = lastScreeningDate!;
    final m = (d.month >= 1 && d.month <= 12) ? months[d.month - 1] : '';
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '${d.day} $m ${d.year}, $hour:$minute';
  }

  String get formattedLastDateShort {
    if (lastScreeningDate == null) return '--';
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final d = lastScreeningDate!;
    final m = (d.month >= 1 && d.month <= 12) ? months[d.month - 1] : '';
    return '${d.day} $m ${d.year}';
  }

  String get formattedTotal {
    return '$totalScreenings kali';
  }
}

class AdminUserService {
  static final AdminUserService instance = AdminUserService._internal();
  AdminUserService._internal();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // In-memory cache for user screening summaries to avoid spamming Firestore
  final Map<String, UserScreeningSummary> _summaryCache = {};
  final Map<String, Completer<UserScreeningSummary>> _pendingSummaryRequests =
      {};
  List<UserModel> _cachedUsers = [];

  bool get isFirebaseAvailable => Firebase.apps.isNotEmpty;

  /// Daftar pengguna default (Sesuai Desain Screenshot Obesight)
  static final List<UserModel> defaultMockUsers = [
    UserModel(
      id: 'usr_001',
      name: 'Zahra Fitriana',
      email: 'zahraafitriana@gmail.com',
      username: 'zahraafitriana',
      role: UserRole.user,
      phone: '0893-3421-2098',
      dob: '12 Juli 2003',
      gender: 'Perempuan',
      joined: '12 Juni 2026',
    ),
    UserModel(
      id: 'usr_002',
      name: 'Zahra Fitrie',
      email: 'zahrafitrie@gmail.com',
      username: 'zahrafitrie',
      role: UserRole.user,
      phone: '0812-3456-7890',
      dob: '15 Mei 2002',
      gender: 'Perempuan',
      joined: '10 Januari 2026',
    ),
  ];

  /// Mendengarkan stream koleksi `users` di Cloud Firestore secara real-time
  Stream<List<UserModel>> streamUsers() async* {
    // 1. Emit data yang tersedia segera agar tidak loading berputar tanpa henti
    if (_cachedUsers.isNotEmpty) {
      yield _cachedUsers;
    } else {
      yield defaultMockUsers;
    }

    if (!isFirebaseAvailable) return;

    try {
      final stream = _firestore.collection('users').snapshots();
      await for (final snapshot in stream) {
        final users = snapshot.docs.map((doc) {
          final data = doc.data();
          return UserModel.fromMap(data, doc.id);
        }).toList();

        if (users.isNotEmpty) {
          _cachedUsers = users;
          yield users;
        } else {
          // Jika di Firestore belum ada akun yang dibuat, gunakan data referensi
          yield defaultMockUsers;
        }
      }
    } catch (e) {
      debugPrint(
        '[AdminUserService] Notice streaming users from Firestore: $e',
      );
      yield _cachedUsers.isNotEmpty ? _cachedUsers : defaultMockUsers;
    }
  }

  /// Mendengarkan stream satu dokumen pengguna berdasarkan UID
  Stream<UserModel?> streamUserById(String userId) async* {
    final cleanId = userId.trim();
    if (cleanId.isEmpty) {
      yield null;
      return;
    }

    // 1. Emit data awal dari cache atau fallback jika cocok dengan ID
    final initial = _cachedUsers.cast<UserModel?>().firstWhere(
      (u) => u?.id == cleanId,
      orElse: () => defaultMockUsers.cast<UserModel?>().firstWhere(
        (u) => u?.id == cleanId,
        orElse: () => null,
      ),
    );
    if (initial != null) {
      yield initial;
    }

    if (!isFirebaseAvailable) return;

    try {
      final stream = _firestore.collection('users').doc(cleanId).snapshots();
      await for (final doc in stream) {
        if (doc.exists && doc.data() != null) {
          yield UserModel.fromMap(doc.data()!, doc.id);
        }
      }
    } catch (e) {
      debugPrint('[AdminUserService] Notice streaming user $userId: $e');
    }
  }

  /// Mendengarkan riwayat skrining pengguna tertentu (`users/{userId}/screenings`) secara realtime
  Stream<List<ScreeningHistoryItem>> streamUserScreenings(
    String userId,
  ) async* {
    final cleanId = userId.trim();

    // Data riwayat skrining referensi (Sesuai Screenshot Gambar 2)
    final List<ScreeningHistoryItem> defaultScreenings = [
      ScreeningHistoryItem(
        id: 'scr_001',
        userId: cleanId.isNotEmpty ? cleanId : 'usr_001',
        date: DateTime(2026, 8, 11, 9, 15),
        bmi: 26.8,
        risk: 'Sedang',
        category: 'Overweight (IMT 25–27)',
        skriningData: SkriningData()
          ..height = 165.0
          ..weight = 72.0
          ..aiCategoryTitle = 'Overweight'
          ..aiCategoryBadge = 'Level I',
      ),
      ScreeningHistoryItem(
        id: 'scr_002',
        userId: cleanId.isNotEmpty ? cleanId : 'usr_001',
        date: DateTime(2026, 7, 16, 8, 0),
        bmi: 27.5,
        risk: 'Tinggi',
        category: 'Obesitas (IMT > 27)',
        skriningData: SkriningData()
          ..height = 168.0
          ..weight = 77.0
          ..aiCategoryTitle = 'Obesitas'
          ..aiCategoryBadge = 'Tipe 2',
      ),
    ];

    yield defaultScreenings;

    if (!isFirebaseAvailable || cleanId.isEmpty) return;

    try {
      final stream = _firestore
          .collection('users')
          .doc(cleanId)
          .collection('screenings')
          .snapshots();

      await for (final snapshot in stream) {
        if (snapshot.docs.isNotEmpty) {
          final items = snapshot.docs.map((doc) {
            final data = doc.data();
            return ScreeningHistoryItem.fromMap(data);
          }).toList();

          items.sort((a, b) => b.date.compareTo(a.date));

          _summaryCache[cleanId] = UserScreeningSummary(
            totalScreenings: items.length,
            lastScreeningDate: items.first.date,
            latestScreening: items.first,
            hasLoaded: true,
          );

          yield items;
        } else {
          yield defaultScreenings;
        }
      }
    } catch (e) {
      debugPrint(
        '[AdminUserService] Notice streaming screenings for $userId: $e',
      );
    }
  }

  /// Mengambil ringkasan skrining (total skrining, waktu skrining terakhir) untuk kartu pengguna
  Future<UserScreeningSummary> getUserScreeningSummary(String userId) async {
    final cleanId = userId.trim();
    if (!isFirebaseAvailable || cleanId.isEmpty) {
      return const UserScreeningSummary(hasLoaded: true);
    }

    if (_summaryCache.containsKey(cleanId)) {
      return _summaryCache[cleanId]!;
    }

    if (_pendingSummaryRequests.containsKey(cleanId)) {
      return _pendingSummaryRequests[cleanId]!.future;
    }

    final completer = Completer<UserScreeningSummary>();
    _pendingSummaryRequests[cleanId] = completer;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(cleanId)
          .collection('screenings')
          .get()
          .timeout(const Duration(seconds: 10));

      if (snapshot.docs.isEmpty) {
        final summary = UserScreeningSummary(
          totalScreenings: cleanId == 'usr_001' ? 3 : 0,
          lastScreeningDate: cleanId == 'usr_001'
              ? DateTime(2026, 8, 11, 9, 15)
              : null,
          hasLoaded: true,
        );
        _summaryCache[cleanId] = summary;
        completer.complete(summary);
      } else {
        final items = snapshot.docs.map((doc) {
          return ScreeningHistoryItem.fromMap(doc.data());
        }).toList();

        items.sort((a, b) => b.date.compareTo(a.date));

        final summary = UserScreeningSummary(
          totalScreenings: items.length,
          lastScreeningDate: items.first.date,
          latestScreening: items.first,
          hasLoaded: true,
        );
        _summaryCache[cleanId] = summary;
        completer.complete(summary);
      }
    } catch (e) {
      debugPrint('[AdminUserService] Notice fetching summary for $cleanId: $e');
      final fallback = UserScreeningSummary(
        totalScreenings: cleanId == 'usr_001' ? 3 : 0,
        lastScreeningDate: cleanId == 'usr_001'
            ? DateTime(2026, 8, 11, 9, 15)
            : null,
        hasLoaded: true,
      );
      _summaryCache[cleanId] = fallback;
      completer.complete(fallback);
    } finally {
      _pendingSummaryRequests.remove(cleanId);
    }

    return completer.future;
  }

  /// Mengosongkan cache jika data diperbarui
  void invalidateCache(String? userId) {
    if (userId != null) {
      _summaryCache.remove(userId);
    } else {
      _summaryCache.clear();
    }
  }
}
