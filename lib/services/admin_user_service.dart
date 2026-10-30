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

  /// Mendengarkan stream koleksi `users` di Cloud Firestore secara real-time.
  /// Menampilkan semua akun pengguna dan admin secara global tanpa filter
  /// berdasarkan akun admin login atau perangkat tertentu.
  Stream<List<UserModel>> streamUsers() {
    if (!isFirebaseAvailable) {
      return Stream.value(_cachedUsers);
    }

    return _firestore.collection('users').snapshots().map((snapshot) {
      final users = snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data(), doc.id);
      }).toList();

      // Urutkan akun secara konsisten (pendaftaran terbaru terlebih dahulu, atau nama)
      // agar seluruh admin melihat urutan daftar yang seragam
      users.sort((a, b) {
        if (a.createdAt != null && b.createdAt != null) {
          return b.createdAt!.compareTo(a.createdAt!);
        }
        if (a.createdAt != null) return -1;
        if (b.createdAt != null) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      _cachedUsers = users;
      return users;
    });
  }

  /// Mendengarkan stream satu dokumen pengguna berdasarkan UID langsung dari Firestore
  Stream<UserModel?> streamUserById(String userId) {
    final cleanId = userId.trim();
    if (cleanId.isEmpty) {
      return Stream.value(null);
    }

    if (!isFirebaseAvailable) {
      final cached = _cachedUsers.cast<UserModel?>().firstWhere(
        (u) => u?.id == cleanId,
        orElse: () => null,
      );
      return Stream.value(cached);
    }

    return _firestore.collection('users').doc(cleanId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  /// Mendengarkan riwayat skrining pengguna tertentu (`users/{userId}/screenings`) secara realtime
  Stream<List<ScreeningHistoryItem>> streamUserScreenings(String userId) {
    final cleanId = userId.trim();
    if (!isFirebaseAvailable || cleanId.isEmpty) {
      return Stream.value(const <ScreeningHistoryItem>[]);
    }

    return _firestore
        .collection('users')
        .doc(cleanId)
        .collection('screenings')
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs.map((doc) {
        final data = doc.data();
        return ScreeningHistoryItem.fromMap(data);
      }).toList();

      items.sort((a, b) => b.date.compareTo(a.date));

      if (items.isNotEmpty) {
        _summaryCache[cleanId] = UserScreeningSummary(
          totalScreenings: items.length,
          lastScreeningDate: items.first.date,
          latestScreening: items.first,
          hasLoaded: true,
        );
      } else {
        _summaryCache[cleanId] = const UserScreeningSummary(
          totalScreenings: 0,
          hasLoaded: true,
        );
      }

      return items;
    });
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
        const summary = UserScreeningSummary(
          totalScreenings: 0,
          lastScreeningDate: null,
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
      const fallback = UserScreeningSummary(
        totalScreenings: 0,
        lastScreeningDate: null,
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
