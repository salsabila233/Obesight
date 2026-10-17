import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/screening_history_model.dart';
import '../screens/skrining/skrining_models.dart';
import 'auth_service.dart';

class ScreeningHistoryService extends ChangeNotifier {
  static final ScreeningHistoryService instance = ScreeningHistoryService._internal();
  ScreeningHistoryService._internal();

  final Map<String, List<ScreeningHistoryItem>> _historyCache = {};
  final Set<String> _loadedUsers = {};
  final Map<String, bool> _loadingStates = {};

  // Prefix penyimpanan persisten per akun di SharedPreferences
  static const String _prefPrefix = 'screening_records_per_account_v3_';

  bool get _isFirebaseAvailable => Firebase.apps.isNotEmpty;

  bool isLoading(String? userId, [String? email]) {
    final cleanId = resolveUserKey(userId, email);
    return _loadingStates[cleanId] ?? false;
  }

  /// Menyelesaikan ID akun unik pengguna secara aman
  String resolveUserKey(String? userId, [String? email]) {
    if (userId != null && userId.trim().isNotEmpty && userId.trim() != 'usr_guest') {
      return userId.trim();
    }
    final authUser = AuthService().currentUser;
    if (authUser != null && authUser.id.isNotEmpty && authUser.id != 'usr_guest') {
      return authUser.id.trim();
    }
    try {
      if (_isFirebaseAvailable) {
        final fbUser = FirebaseAuth.instance.currentUser;
        if (fbUser != null && fbUser.uid.isNotEmpty) {
          return fbUser.uid;
        }
      }
    } catch (_) {}
    if (email != null && email.trim().isNotEmpty) {
      return 'user_${email.trim().toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
    }
    if (authUser != null && authUser.email.isNotEmpty) {
      return 'user_${authUser.email.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
    }
    return 'usr_guest';
  }

  /// Mendapatkan daftar riwayat untuk akun tertentu (kosong [] jika belum pernah skrining)
  List<ScreeningHistoryItem> getHistory(String? userId, [String? email]) {
    final cleanId = resolveUserKey(userId, email);
    final list = _historyCache[cleanId];
    if (list == null) {
      return const [];
    }
    return List.unmodifiable(list);
  }

  /// Memeriksa apakah riwayat untuk akun pengguna telah selesai dimuat
  bool hasLoaded(String? userId, [String? email]) {
    final cleanId = resolveUserKey(userId, email);
    return _loadedUsers.contains(cleanId);
  }

  /// Mengambil data hasil skrining terakhir yang valid (null jika belum pernah skrining)
  ScreeningHistoryItem? getLatestScreening(String? userId, [String? email]) {
    final history = getHistory(userId, email);
    return history.isNotEmpty ? history.first : null;
  }

  /// Memuat riwayat dari Cloud Firestore (`users/{uid}/screenings`) dengan cache offline SharedPreferences
  Future<List<ScreeningHistoryItem>> loadHistory(String? userId, [String? email]) async {
    final cleanId = resolveUserKey(userId, email);
    _loadingStates[cleanId] = true;

    // 1. Muat dari SharedPreferences terlebih dahulu agar tampilan instan (Zero Lag / Offline First)
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_prefPrefix$cleanId';
      final jsonString = prefs.getString(key);

      if (jsonString != null && jsonString.isNotEmpty) {
        final decoded = jsonDecode(jsonString) as List<dynamic>;
        final items = decoded
            .map((item) => ScreeningHistoryItem.fromMap(Map<String, dynamic>.from(item as Map)))
            .where((item) => !item.id.startsWith('seed_'))
            .toList();
        _historyCache[cleanId] = items;
      } else if (!_historyCache.containsKey(cleanId)) {
        _historyCache[cleanId] = [];
      }
    } catch (e) {
      debugPrint('[ScreeningHistoryService] Cache load notice for $cleanId: $e');
      if (!_historyCache.containsKey(cleanId)) {
        _historyCache[cleanId] = [];
      }
    }

    _loadedUsers.add(cleanId);
    notifyListeners();

    // 2. Jika Firebase tersedia dan bukan akun tamu, sinkronkan dengan Cloud Firestore
    if (_isFirebaseAvailable && cleanId != 'usr_guest') {
      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(cleanId)
            .collection('screenings')
            .orderBy('date', descending: true)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final firestoreItems = querySnapshot.docs.map((doc) {
            final data = doc.data();
            return ScreeningHistoryItem.fromMap(data);
          }).toList();

          _historyCache[cleanId] = firestoreItems;
          await _saveToStorage(cleanId, firestoreItems);
        } else {
          // Jika di Firestore masih kosong namun ada riwayat lokal dari sesi sebelumnya, migrasi ke Firestore
          final localItems = _historyCache[cleanId] ?? [];
          if (localItems.isNotEmpty) {
            debugPrint('[ScreeningHistoryService] Memulai migrasi ${localItems.length} sesi skrining lokal ke Firestore users/$cleanId/screenings...');
            for (final item in localItems) {
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(cleanId)
                    .collection('screenings')
                    .doc(item.id)
                    .set(item.toFirestoreMap());
              } catch (migrateErr) {
                debugPrint('[ScreeningHistoryService] Error migrating item ${item.id}: $migrateErr');
              }
            }
          }
        }
      } catch (firestoreErr) {
        debugPrint('[ScreeningHistoryService] Notice fetching Firestore screenings for $cleanId: $firestoreErr');
      }
    }

    _loadingStates[cleanId] = false;
    notifyListeners();
    return getHistory(cleanId);
  }

  /// Menambahkan riwayat skrining baru untuk akun tertentu
  Future<ScreeningHistoryItem> addHistory(
    String? userId,
    SkriningData data, {
    DateTime? customDate,
    String? email,
  }) async {
    final cleanId = resolveUserKey(userId, email);
    final date = customDate ?? data.date ?? DateTime.now();
    data.date = date;

    // Tentukan Tingkat Risiko Berdasarkan Standar Klinis Obesight
    final catLower = data.classificationCategory.toLowerCase();
    final riskLower = data.riskTitle.toLowerCase();
    String risk;
    if (catLower.contains('obesitas') || catLower.contains('obesity') || riskLower.contains('tinggi')) {
      risk = 'Tinggi';
    } else if (catLower.contains('overweight') ||
        riskLower.contains('meningkat') ||
        riskLower.contains('sedang') ||
        riskLower.contains('perhatian')) {
      risk = 'Sedang';
    } else {
      risk = 'Rendah';
    }

    // Tentukan Kategori dengan rentang IMT resmi
    final bmiVal = data.bmi;
    String category;
    if (bmiVal < 18.5) {
      category = 'Underweight (IMT < 18.5)';
    } else if (bmiVal <= 22.9) {
      category = 'Normal (IMT 18.5–22.9)';
    } else if (bmiVal <= 27.0) {
      category = 'Overweight (IMT 25–27)';
    } else {
      category = 'Obesitas (IMT > 27)';
    }

    final newItem = ScreeningHistoryItem(
      id: 'scr_${date.millisecondsSinceEpoch}',
      userId: cleanId,
      date: date,
      bmi: bmiVal,
      risk: risk,
      category: category,
      skriningData: data,
    );

    // 1. Simpan seketika di memori lokal & disk SharedPreferences (Offline-First)
    final currentList = List<ScreeningHistoryItem>.from(_historyCache[cleanId] ?? []);
    currentList.insert(0, newItem);
    _historyCache[cleanId] = currentList;
    await _saveToStorage(cleanId, currentList);
    notifyListeners();

    // 2. Simpan secara permanen ke Cloud Firestore (users/{uid}/screenings/{screeningId})
    if (_isFirebaseAvailable && cleanId != 'usr_guest') {
      try {
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(cleanId)
            .collection('screenings')
            .doc(newItem.id);

        await docRef.set(newItem.toFirestoreMap());
        debugPrint('[ScreeningHistoryService] Sukses menyimpan skrining baru ke Firestore: users/$cleanId/screenings/${newItem.id}');
      } catch (firestoreErr) {
        debugPrint('[ScreeningHistoryService] Notice saving screening session to Firestore: $firestoreErr');
      }
    }

    return newItem;
  }

  /// Menghapus seluruh riwayat untuk akun tertentu (Lokal & Firestore)
  Future<void> clearHistory(String? userId, [String? email]) async {
    final cleanId = resolveUserKey(userId, email);
    _historyCache[cleanId] = [];

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_prefPrefix$cleanId');
    } catch (_) {}

    if (_isFirebaseAvailable && cleanId != 'usr_guest') {
      try {
        final collectionRef = FirebaseFirestore.instance
            .collection('users')
            .doc(cleanId)
            .collection('screenings');
        final snapshots = await collectionRef.get();
        for (final doc in snapshots.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        debugPrint('[ScreeningHistoryService] Notice clearing Firestore history: $e');
      }
    }

    notifyListeners();
  }

  /// Statistik Jumlah Total Skrining per Akun
  int getTotalCount(String? userId, [String? email]) {
    return getHistory(userId, email).length;
  }

  /// Statistik Jumlah Risiko Tinggi per Akun
  int getHighRiskCount(String? userId, [String? email]) {
    return getHistory(userId, email)
        .where((item) => item.risk.toLowerCase().contains('tinggi'))
        .length;
  }

  /// Statistik Jumlah Risiko Sedang per Akun
  int getMediumRiskCount(String? userId, [String? email]) {
    return getHistory(userId, email)
        .where((item) =>
            item.risk.toLowerCase().contains('sedang') ||
            item.risk.toLowerCase().contains('meningkat'))
        .length;
  }

  /// Statistik Jumlah Risiko Rendah per Akun
  int getLowRiskCount(String? userId, [String? email]) {
    return getHistory(userId, email)
        .where((item) =>
            item.risk.toLowerCase().contains('rendah') ||
            item.risk.toLowerCase().contains('terkendali') ||
            item.risk.toLowerCase().contains('normal'))
        .length;
  }

  Future<void> _saveToStorage(String userId, List<ScreeningHistoryItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_prefPrefix$userId';
      final jsonList = items.map((e) => e.toMap()).toList();
      await prefs.setString(key, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('[ScreeningHistoryService] Gagal menyimpan riwayat ke storage: $e');
    }
  }
}
