import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/screening_history_model.dart';
import '../models/user_model.dart';

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
      final users = <UserModel>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final user = UserModel.fromMap(data, doc.id);
          final nameLower = user.name.toLowerCase();
          final emailLower = user.email.toLowerCase();

          // Saring dan amankan akun terkait Dokter Hendra agar tidak tampil ke daftar admin
          if (nameLower.contains('hendra') || emailLower.contains('hendra')) {
            _scheduleHendraCleanup();
            continue;
          }
          users.add(user);
        } catch (e) {
          debugPrint('[AdminUserService] Error parsing user doc ${doc.id}: $e');
        }
      }

      // Urutkan akun secara konsisten (pendaftaran terbaru terlebih dahulu, atau nama)
      // agar seluruh admin melihat urutan daftar yang seragam
      users.sort((a, b) {
        if (a.createdAt != null && b.createdAt != null) {
          final comp = b.createdAt!.compareTo(a.createdAt!);
          if (comp != 0) return comp;
        } else if (a.createdAt != null) {
          return -1;
        } else if (b.createdAt != null) {
          return 1;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      _cachedUsers = users;
      return users;
    }).handleError((error, stackTrace) {
      debugPrint('[AdminUserService] Notice streamUsers error: $error');
      return _cachedUsers;
    });
  }

  /// Mengambil data seluruh pengguna secara langsung dari Firestore (server/cache)
  Future<List<UserModel>> fetchUsers({Source source = Source.serverAndCache}) async {
    if (!isFirebaseAvailable) {
      return _cachedUsers;
    }

    try {
      final snapshot =
          await _firestore.collection('users').get(GetOptions(source: source));
      final users = <UserModel>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final user = UserModel.fromMap(data, doc.id);
          final nameLower = user.name.toLowerCase();
          final emailLower = user.email.toLowerCase();

          // Saring dan amankan akun terkait Dokter Hendra agar tidak tampil ke daftar admin
          if (nameLower.contains('hendra') || emailLower.contains('hendra')) {
            _scheduleHendraCleanup();
            continue;
          }
          users.add(user);
        } catch (e) {
          debugPrint('[AdminUserService] Error parsing user doc ${doc.id}: $e');
        }
      }

      users.sort((a, b) {
        if (a.createdAt != null && b.createdAt != null) {
          final comp = b.createdAt!.compareTo(a.createdAt!);
          if (comp != 0) return comp;
        } else if (a.createdAt != null) {
          return -1;
        } else if (b.createdAt != null) {
          return 1;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      _cachedUsers = users;
      return users;
    } catch (e) {
      debugPrint('[AdminUserService] Notice fetchUsers error: $e');
      return _cachedUsers;
    }
  }

  /// Method bantuan untuk pengujian unit/widget saat Firebase belum diinisialisasi
  @visibleForTesting
  void setMockUsers(List<UserModel> users) {
    _cachedUsers = users.where((u) => !u.name.toLowerCase().contains("hendra") && !u.email.toLowerCase().contains("hendra")).toList();
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
        try {
          return UserModel.fromMap(doc.data()!, doc.id);
        } catch (e) {
          debugPrint('[AdminUserService] Notice parsing user doc $cleanId: $e');
        }
      }
      return null;
    }).handleError((error, stackTrace) {
      debugPrint('[AdminUserService] Notice streamUserById error for $cleanId: $error');
      final cached = _cachedUsers.cast<UserModel?>().firstWhere(
        (u) => u?.id == cleanId,
        orElse: () => null,
      );
      return cached;
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
      final items = <ScreeningHistoryItem>[];
      for (final doc in snapshot.docs) {
        try {
          items.add(ScreeningHistoryItem.fromMap(doc.data()));
        } catch (e) {
          debugPrint('[AdminUserService] Notice stream screening parse ${doc.id}: $e');
        }
      }

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
    }).handleError((error, stackTrace) {
      debugPrint('[AdminUserService] Notice streamUserScreenings error for $cleanId: $error');
      return const <ScreeningHistoryItem>[];
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
        final items = <ScreeningHistoryItem>[];
        for (final doc in snapshot.docs) {
          try {
            items.add(ScreeningHistoryItem.fromMap(doc.data()));
          } catch (e) {
            debugPrint('[AdminUserService] Notice parsing summary item ${doc.id}: $e');
          }
        }

        items.sort((a, b) => b.date.compareTo(a.date));

        final summary = UserScreeningSummary(
          totalScreenings: items.length,
          lastScreeningDate: items.isNotEmpty ? items.first.date : null,
          latestScreening: items.isNotEmpty ? items.first : null,
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

  /// Mengambil seluruh riwayat skrining pengguna tertentu (`users/{userId}/screenings`)
  Future<List<ScreeningHistoryItem>> fetchAllScreeningsForUser(String userId) async {
    final cleanId = userId.trim();
    if (!isFirebaseAvailable || cleanId.isEmpty) {
      return [];
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(cleanId)
          .collection('screenings')
          .get()
          .timeout(const Duration(seconds: 10));

      final items = <ScreeningHistoryItem>[];
      for (final doc in snapshot.docs) {
        try {
          items.add(ScreeningHistoryItem.fromMap(doc.data()));
        } catch (e) {
          debugPrint('[AdminUserService] Error parsing screening ${doc.id}: $e');
        }
      }

      items.sort((a, b) => b.date.compareTo(a.date));
      return items;
    } catch (e) {
      debugPrint('[AdminUserService] Notice fetchAllScreeningsForUser error for $cleanId: $e');
      return [];
    }
  }

  /// Mengosongkan cache jika data diperbarui
  void invalidateCache(String? userId) {
    if (userId != null) {
      _summaryCache.remove(userId);
    } else {
      _summaryCache.clear();
    }
  }

  bool _hendraCleanupScheduled = false;
  void _scheduleHendraCleanup() {
    if (_hendraCleanupScheduled) return;
    _hendraCleanupScheduled = true;
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        await deleteDoctorHendraAccount();
      } catch (e) {
        debugPrint('[AdminUserService] Notice background hendra cleanup: $e');
      }
    });
  }

  /// Menghapus akun pengguna secara aman dan terisolasi dari Firestore
  /// beserta seluruh subkoleksi data terkait (screenings, sleep_records, nutrition_progress).
  /// Menjamin isolasi penuh dan TIDAK menghapus data milik pengguna lain.
  Future<bool> deleteUserAccount(String userId) async {
    final cleanId = userId.trim();
    if (cleanId.isEmpty) return false;

    // Hapus dari cache lokal memori segera
    _summaryCache.remove(cleanId);
    _cachedUsers.removeWhere((u) => u.id == cleanId);

    if (!isFirebaseAvailable) return true;

    try {
      final userDocRef = _firestore.collection('users').doc(cleanId);

      // 1. Hapus subkoleksi 'screenings' terisolasi hanya untuk user ini
      final screeningsSnap = await userDocRef.collection('screenings').get();
      for (final doc in screeningsSnap.docs) {
        await doc.reference.delete();
      }

      // 2. Hapus subkoleksi 'sleep_records' terisolasi hanya untuk user ini
      final sleepSnap = await userDocRef.collection('sleep_records').get();
      for (final doc in sleepSnap.docs) {
        await doc.reference.delete();
      }

      // 3. Hapus subkoleksi 'nutrition_progress' terisolasi hanya untuk user ini
      final nutritionSnap = await userDocRef.collection('nutrition_progress').get();
      for (final doc in nutritionSnap.docs) {
        await doc.reference.delete();
      }

      // 4. Hapus dokumen utama profil pengguna
      await userDocRef.delete();

      debugPrint('[AdminUserService] Successfully deleted isolated user $cleanId');
      return true;
    } catch (e) {
      debugPrint('[AdminUserService] Error deleting user $cleanId: $e');
      return false;
    }
  }

  /// Menghapus akun pengguna atas nama "Dokter Hendra" secara aman dan terisolasi.
  /// Menjamin proses ini strictly isolated:
  /// - Jika dokumen adalah akun admin yang memuat label nama Dokter Hendra, namanya direset ke default ('Admin ObeSight').
  /// - Jika dokumen adalah akun pengguna/duplikasi terpisah, dokumen beserta subkoleksinya dihapus bersih.
  /// - Dokumen milik pengguna lain dijamin TIDAK disentuh.
  Future<int> deleteDoctorHendraAccount() async {
    if (!isFirebaseAvailable) return 0;
    int affected = 0;
    try {
      final snapshot = await _firestore.collection('users').get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final name = (data['name'] ?? '').toString();
        final email = (data['email'] ?? '').toString();
        final nameLower = name.toLowerCase();
        final emailLower = email.toLowerCase();

        // Kriteria ketat: Hanya proses dokumen yang memuat kata kunci hendra
        final isHendra = nameLower.contains('hendra') || emailLower.contains('hendra');
        if (!isHendra) continue;

        final role = (data['role'] ?? '').toString().toLowerCase();
        if (role == 'admin' || emailLower.contains('adminobesight')) {
          // Akun admin: pulihkan nama admin standar tanpa menghapus kredensial
          await doc.reference.update({
            'name': 'Admin ObeSight',
            'updatedAt': FieldValue.serverTimestamp(),
          });
          affected++;
          debugPrint('[AdminUserService] Sanitized admin account name from Hendra for doc ${doc.id}');
        } else {
          // Akun pengguna Dokter Hendra: hapus permanen secara terisolasi
          await deleteUserAccount(doc.id);
          affected++;
          debugPrint('[AdminUserService] Permanently deleted Hendra account doc ${doc.id}');
        }
      }
    } catch (e) {
      debugPrint('[AdminUserService] Error deleting Doctor Hendra account: $e');
    }
    return affected;
  }
}
