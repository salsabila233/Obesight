import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/app_alert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/skrining/skrining_models.dart';
import 'auth_service.dart';

/// Service to track completed physical activities tied to specific dates
/// and provide clinical physical activity recommendations tailored to
/// user's screening results (PAPDI & KMK Kemenkes No. HK.01.07-MENKES-509-2025).
class PhysicalActivityService extends ChangeNotifier {
  static final PhysicalActivityService _instance = PhysicalActivityService._internal();
  factory PhysicalActivityService() => _instance;
  static PhysicalActivityService get instance => _instance;

  // Dependency injection untuk pengujian unit & widget
  FirebaseAuth? customAuth;
  FirebaseFirestore? customFirestore;

  FirebaseAuth get _auth => customAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore => customFirestore ?? FirebaseFirestore.instance;

  static const String _storageKey = 'obesight_completed_activities_v1';

  // Map of dateKey ('yyyy-MM-dd') -> Set of completed activity IDs
  final Map<String, Set<String>> _completedActivitiesByDate = {};

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  PhysicalActivityService._internal() {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          final list = (entry.value as List<dynamic>).cast<String>();
          _completedActivitiesByDate[entry.key] = list.toSet();
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[PhysicalActivityService] Error loading from storage: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapToSave = <String, List<String>>{};
      for (final entry in _completedActivitiesByDate.entries) {
        mapToSave[entry.key] = entry.value.toList();
      }
      await prefs.setString(_storageKey, jsonEncode(mapToSave));
    } catch (e) {
      debugPrint('[PhysicalActivityService] Error saving to storage: $e');
    }
  }

  /// Reset checklist untuk siklus skrining baru (agar grafik dan progres mulai dari nol/kosong)
  Future<void> resetForNewScreeningCycle() async {
    _completedActivitiesByDate.clear();
    await _saveToStorage();

    // Hentikan pendengar sesi Firestore sementara saat reset
    stopListeningToSessions();

    try {
      final mainDocRef = await getUserMainDocRef();
      if (mainDocRef != null) {
        final snap = await mainDocRef.collection('riwayat_sesi').get();
        for (final doc in snap.docs) {
          await doc.reference.delete();
        }
        await mainDocRef.set({
          'totalSesi': 0,
          'totalDurasiMenit': 0,
          'waktuDiperbarui': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final allDocsSnap = await _firestore
            .collection('progress_aktivitas_fisik')
            .where('idPengguna', isEqualTo: currentUser.uid)
            .get();
        for (final doc in allDocsSnap.docs) {
          final subSnap = await doc.reference.collection('riwayat_sesi').get();
          for (final subDoc in subSnap.docs) {
            await subDoc.reference.delete();
          }
          if (doc.data().containsKey('totalSesi')) {
            await doc.reference.set({
              'totalSesi': 0,
              'totalDurasiMenit': 0,
              'waktuDiperbarui': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          } else {
            await doc.reference.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('[PhysicalActivityService] Reset Firestore sessions error: $e');
    }

    notifyListeners();
  }

  String formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Normalisasi DateTime ke tanggal kalender (hanya tahun, bulan, hari dengan jam, menit, detik = 0)
  static DateTime normalizeDate(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  /// Memeriksa apakah [date] merupakan tanggal di masa mendatang (setelah hari ini berdasarkan kalender)
  static bool isFutureDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.isAfter(today);
  }

  /// Memeriksa apakah [dateKey] (format 'yyyy-MM-dd') merupakan tanggal mendatang (setelah hari ini)
  static bool isFutureDateKey(String? dateKey) {
    if (dateKey == null || dateKey.trim().isEmpty) return false;
    try {
      final parsed = DateTime.parse(dateKey.trim());
      return isFutureDate(parsed);
    } catch (_) {
      return false;
    }
  }

  /// Memeriksa apakah [date] adalah hari ini berdasarkan kalender
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  /// Memeriksa apakah [dateKey] adalah hari ini berdasarkan kalender
  static bool isTodayDateKey(String? dateKey) {
    if (dateKey == null || dateKey.trim().isEmpty) return false;
    try {
      final parsed = DateTime.parse(dateKey.trim());
      return isToday(parsed);
    } catch (_) {
      return false;
    }
  }

  String get todayKey => formatDateKey(DateTime.now());

  bool isCompleted(String dateKey, String activityId) {
    return _completedActivitiesByDate[dateKey]?.contains(activityId) ?? false;
  }

  Map<String, Set<String>> get completedActivitiesByDate => _completedActivitiesByDate;

  Set<String> getCompletedForDate(String dateKey) {
    return _completedActivitiesByDate[dateKey] ?? const <String>{};
  }

  int getCompletedCountForDate(String dateKey, [List<Map<String, dynamic>>? availableActivities]) {
    final completedSet = _completedActivitiesByDate[dateKey];
    if (completedSet == null || completedSet.isEmpty) return 0;
    if (availableActivities != null && availableActivities.isNotEmpty) {
      final availableIds = availableActivities.map((a) => a['id'] as String).toSet();
      return completedSet.intersection(availableIds).length;
    }
    return completedSet.length;
  }

  /// Menghitung fraksi progres harian berdasarkan aktivitas yang benar-benar selesai
  /// sesuai daftar target aktivitas pengguna (misalnya: 0/4, 1/4, ..., 4/4)
  String getProgressFractionForDate(String dateKey, List<Map<String, dynamic>> availableActivities) {
    final total = availableActivities.length;
    final count = getCompletedCountForDate(dateKey, availableActivities);
    return '$count/$total';
  }

  /// Helper untuk mengekstrak angka menit dari teks durasi
  int? _parseDurationMinutes(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toInt();
    if (raw is String) {
      final match = RegExp(r'\d+').firstMatch(raw);
      if (match != null) {
        return int.tryParse(match.group(0)!);
      }
    }
    return null;
  }

  /// Mencari data aktivitas berdasarkan ID
  Map<String, dynamic>? getActivityById(String id) {
    for (final cat in ['Normal', 'Overweight', 'Obesitas I', 'Obesitas II', 'Obesitas III', 'Underweight']) {
      final acts = getActivitiesForCategory(cat);
      for (final act in acts) {
        if (act['id'] == id) {
          return act;
        }
      }
    }
    return null;
  }

  /// Mencari ID aktivitas berdasarkan nama/judul aktivitas
  String? _findActivityIdByName(String name) {
    final cleanName = name.trim().toLowerCase();
    // 1. Prioritas: Cocok persis
    for (final cat in ['Normal', 'Overweight', 'Obesitas I', 'Obesitas II', 'Obesitas III', 'Underweight']) {
      final acts = getActivitiesForCategory(cat);
      for (final act in acts) {
        final actName = (act['name'] as String? ?? '').trim().toLowerCase();
        final actTitle = (act['title'] as String? ?? '').trim().toLowerCase();
        if (cleanName == actName || cleanName == actTitle) {
          return act['id'] as String;
        }
      }
    }
    // 2. Fallback: Cocok sebagian
    for (final cat in ['Normal', 'Overweight', 'Obesitas I', 'Obesitas II', 'Obesitas III', 'Underweight']) {
      final acts = getActivitiesForCategory(cat);
      for (final act in acts) {
        final actName = (act['name'] as String? ?? '').trim().toLowerCase();
        final actTitle = (act['title'] as String? ?? '').trim().toLowerCase();
        if (cleanName.contains(actName) ||
            actName.contains(cleanName) ||
            cleanName.contains(actTitle) ||
            actTitle.contains(cleanName)) {
          return act['id'] as String;
        }
      }
    }
    return null;
  }

  /// Sanitasi nama pengguna agar aman digunakan sebagai ID dokumen Firestore
  String sanitizeDocId(String rawName) {
    var cleaned = rawName.trim().replaceAll('/', '_').replaceAll(RegExp(r'\s+'), '_');
    if (cleaned.isEmpty) {
      cleaned = 'Pengguna';
    }
    return cleaned;
  }

  /// Mendapatkan referensi dokumen utama progress_aktivitas_fisik/{namaPengguna}
  /// dengan verifikasi kepemilikan UID dan pencegahan tabrakan nama pengguna.
  Future<DocumentReference<Map<String, dynamic>>?> getUserMainDocRef({
    String? candidateName,
  }) async {
    if (customAuth == null && customFirestore == null) {
      try {
        if (Firebase.apps.isEmpty) return null;
      } catch (_) {
        return null;
      }
    }

    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;
    final uid = currentUser.uid;

    String rawName = (candidateName ?? currentUser.displayName ?? AuthService().currentUser?.name ?? AuthService().currentUser?.username ?? '').trim();
    if (rawName.isEmpty) {
      rawName = 'Pengguna';
    }

    final sanitizedDocId = sanitizeDocId(rawName);

    // 1. Cek apakah dokumen dengan ID namaPengguna sudah ada
    final candidateRef = _firestore.collection('progress_aktivitas_fisik').doc(sanitizedDocId);
    try {
      final snap = await candidateRef.get();
      if (snap.exists) {
        final existingUid = snap.data()?['idPengguna'] as String?;
        if (existingUid == uid) {
          return candidateRef;
        } else {
          // Ada tabrakan nama dengan akun lain: disambiguasi dengan akhiran UID agar tidak tercampur
          final disambiguatedId = '${sanitizedDocId}_${uid.substring(0, min(6, uid.length))}';
          return _firestore.collection('progress_aktivitas_fisik').doc(disambiguatedId);
        }
      } else {
        // Dokumen belum ada. Cek apakah akun ini sebelumnya sudah punya dokumen utama (misal nama profil diubah)
        try {
          final queryByUid = await _firestore
              .collection('progress_aktivitas_fisik')
              .where('idPengguna', isEqualTo: uid)
              .limit(1)
              .get();

          if (queryByUid.docs.isNotEmpty) {
            final existingDoc = queryByUid.docs.first.reference;
            unawaited(existingDoc.set({
              'idPengguna': uid,
              'namaPengguna': rawName,
              'waktuDiperbarui': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true)));
            return existingDoc;
          }
        } catch (queryErr) {
          debugPrint('[PhysicalActivityService] Query by UID notice: $queryErr');
        }

        return candidateRef;
      }
    } catch (e) {
      debugPrint('[PhysicalActivityService] Error getUserMainDocRef: $e');
      return candidateRef;
    }
  }

  /// Memastikan dokumen utama pengguna di progress_aktivitas_fisik/{namaPengguna} telah tersedia
  Future<DocumentReference<Map<String, dynamic>>?> ensureUserMainDoc({
    String? candidateName,
  }) async {
    if (customAuth == null && customFirestore == null) {
      try {
        if (Firebase.apps.isEmpty) return null;
      } catch (_) {
        return null;
      }
    }

    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    final docRef = await getUserMainDocRef(candidateName: candidateName);
    if (docRef == null) return null;

    String rawName = (candidateName ?? currentUser.displayName ?? AuthService().currentUser?.name ?? AuthService().currentUser?.username ?? 'Pengguna').trim();
    if (rawName.isEmpty) rawName = 'Pengguna';

    bool exists = false;
    try {
      final snap = await docRef.get();
      exists = snap.exists;
    } catch (e) {
      debugPrint('[PhysicalActivityService] Notice ensureUserMainDoc check: $e');
      exists = false;
    }

    if (!exists) {
      try {
        await docRef.set({
          'idPengguna': currentUser.uid,
          'namaPengguna': rawName,
          'totalSesi': 0,
          'totalDurasiMenit': 0,
          'waktuDibuat': FieldValue.serverTimestamp(),
          'waktuDiperbarui': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('[PhysicalActivityService] Dokumen utama dipulihkan/dibuat: ${docRef.id}');
      } catch (e) {
        if (e is FirebaseException) {
          debugPrint('[PhysicalActivityService] ensureUserMainDoc Firestore error [${e.code}]: ${e.message}');
        } else {
          debugPrint('[PhysicalActivityService] Error ensureUserMainDoc set: $e');
        }
      }
    }
    return docRef;
  }

  /// Memulai sesi olahraga baru dan membuat dokumen di subkoleksi riwayat_sesi
  Future<String?> startSession({
    required Map<String, dynamic> activity,
    String? dateKey,
    String? candidateName,
  }) async {
    final dKey = dateKey ?? todayKey;
    if (isFutureDateKey(dKey)) {
      debugPrint('[PhysicalActivityService] Menolak startSession pada tanggal mendatang: $dKey. Progres hanya dapat dicatat untuk hari ini.');
      return null;
    }

    if (customAuth == null && customFirestore == null) {
      try {
        if (Firebase.apps.isEmpty) return null;
      } catch (_) {
        return null;
      }
    }

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('[PhysicalActivityService] startSession: Pengguna belum login.');
      return null;
    }

    final mainDocRef = await ensureUserMainDoc(candidateName: candidateName);
    if (mainDocRef == null) return null;

    final sessionCol = mainDocRef.collection('riwayat_sesi');
    final newSessionDoc = sessionCol.doc(); // Auto-ID

    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(dateKey ?? todayKey);
    } catch (_) {
      parsedDate = DateTime.now();
    }
    final tanggalTimestamp = Timestamp.fromDate(DateTime(parsedDate.year, parsedDate.month, parsedDate.day));

    final actName = (activity['name'] as String?) ?? (activity['title'] as String?) ?? 'Aktivitas Olahraga';

    final sessionData = <String, dynamic>{
      'idPengguna': currentUser.uid,
      'jenisAktivitas': actName,
      'statusSelesai': false,
      'status': 'berlangsung',
      'tanggalAktivitas': tanggalTimestamp,
      'waktuMulai': FieldValue.serverTimestamp(),
      'waktuSelesai': null,
      'durasiMenit': 0,
      'waktuDibuat': FieldValue.serverTimestamp(),
      'waktuDiperbarui': FieldValue.serverTimestamp(),
    };

    try {
      await newSessionDoc.set(sessionData);
      debugPrint('[PhysicalActivityService] Sesi olahraga dimulai: ${newSessionDoc.id} ($actName)');
      return newSessionDoc.id;
    } catch (e) {
      if (e is FirebaseException) {
        debugPrint('[PhysicalActivityService] startSession Firestore error [${e.code}]: ${e.message}');
      } else {
        debugPrint('[PhysicalActivityService] Error startSession: $e');
      }
      return null;
    }
  }

  /// Menyelesaikan sesi olahraga yang sedang berlangsung dan memperbarui ringkasan dokumen utama
  Future<bool> finishSession({
    required String sessionId,
    required Map<String, dynamic> activity,
    required int elapsedSeconds,
    String? dateKey,
    DateTime? localStartTime,
  }) async {
    final dKey = dateKey ?? todayKey;
    if (isFutureDateKey(dKey)) {
      debugPrint('[PhysicalActivityService] Menolak finishSession pada tanggal mendatang: $dKey. Progres hanya dapat dicatat untuk hari ini.');
      return false;
    }

    if (customAuth == null && customFirestore == null) {
      try {
        if (Firebase.apps.isEmpty) return false;
      } catch (_) {
        return false;
      }
    }

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('[PhysicalActivityService] finishSession: Pengguna belum login.');
      return false;
    }

    final mainDocRef = await getUserMainDocRef();
    if (mainDocRef == null) {
      debugPrint('[PhysicalActivityService] finishSession: Gagal mendapatkan referensi dokumen utama.');
      return false;
    }

    final sessionRef = mainDocRef.collection('riwayat_sesi').doc(sessionId);

    // Hitung durasiMenit nyata dari selisih waktu atau elapsedSeconds
    int durasiMenit = (elapsedSeconds / 60).round();
    if (durasiMenit <= 0) {
      if (localStartTime != null) {
        durasiMenit = DateTime.now().difference(localStartTime).inMinutes;
      }
      if (durasiMenit <= 0) durasiMenit = 1;
    }

    final actName = (activity['name'] as String?) ?? (activity['title'] as String?) ?? 'Aktivitas Olahraga';
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(dateKey ?? todayKey);
    } catch (_) {
      parsedDate = DateTime.now();
    }
    final tanggalTimestamp = Timestamp.fromDate(DateTime(parsedDate.year, parsedDate.month, parsedDate.day));

    String rawName = (currentUser.displayName ?? AuthService().currentUser?.name ?? AuthService().currentUser?.username ?? 'Pengguna').trim();
    if (rawName.isEmpty) rawName = 'Pengguna';

    try {
      await _firestore.runTransaction((transaction) async {
        final sessionSnap = await transaction.get(sessionRef);
        final mainSnap = await transaction.get(mainDocRef);

        // 1. Dokumen sesi
        if (sessionSnap.exists) {
          final data = sessionSnap.data()!;
          if (data['statusSelesai'] == true) {
            debugPrint('[PhysicalActivityService] Sesi $sessionId telah selesai sebelumnya. Mencegah duplikasi.');
            return;
          }

          // Hitung durasi aktual dari waktuMulai hingga waktu sekarang
          final waktuMulaiTimestamp = data['waktuMulai'] as Timestamp?;
          if (waktuMulaiTimestamp != null) {
            final diffMinutes = DateTime.now().difference(waktuMulaiTimestamp.toDate()).inMinutes;
            if (diffMinutes > durasiMenit) {
              durasiMenit = diffMinutes;
            }
          }
          if (durasiMenit <= 0) durasiMenit = 1;

          transaction.set(sessionRef, {
            'statusSelesai': true,
            'status': 'selesai',
            'waktuSelesai': FieldValue.serverTimestamp(),
            'durasiMenit': durasiMenit,
            'waktuDiperbarui': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } else {
          // Self-healing: jika dokumen sesi terhapus atau belum dibuat, buat dokumen sesi baru
          debugPrint('[PhysicalActivityService] Dokumen sesi $sessionId tidak ditemukan. Membuat dokumen sesi baru dalam transaksi.');
          transaction.set(sessionRef, {
            'idPengguna': currentUser.uid,
            'jenisAktivitas': actName,
            'statusSelesai': true,
            'status': 'selesai',
            'tanggalAktivitas': tanggalTimestamp,
            'waktuMulai': localStartTime != null ? Timestamp.fromDate(localStartTime) : FieldValue.serverTimestamp(),
            'waktuSelesai': FieldValue.serverTimestamp(),
            'durasiMenit': durasiMenit,
            'waktuDibuat': FieldValue.serverTimestamp(),
            'waktuDiperbarui': FieldValue.serverTimestamp(),
          });
        }

        // 2. Dokumen utama (progress_aktivitas_fisik/{namaPengguna})
        if (!mainSnap.exists) {
          // Self-healing: jika dokumen utama terhapus dari Firebase Console, buat ulang secara otomatis
          debugPrint('[PhysicalActivityService] Dokumen utama ${mainDocRef.id} belum ada. Membuat dokumen utama baru dalam transaksi.');
          transaction.set(mainDocRef, {
            'idPengguna': currentUser.uid,
            'namaPengguna': rawName,
            'totalSesi': 1,
            'totalDurasiMenit': durasiMenit,
            'waktuDibuat': FieldValue.serverTimestamp(),
            'waktuDiperbarui': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.set(mainDocRef, {
            'idPengguna': currentUser.uid,
            'totalSesi': FieldValue.increment(1),
            'totalDurasiMenit': FieldValue.increment(durasiMenit),
            'waktuDiperbarui': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      });

      // Update checklist lokal
      final dKey = dateKey ?? todayKey;
      final actId = activity['id'] as String? ?? _findActivityIdByName(activity['title'] ?? activity['name']) ?? sessionId;
      if (!_completedActivitiesByDate.containsKey(dKey)) {
        _completedActivitiesByDate[dKey] = <String>{};
      }
      _completedActivitiesByDate[dKey]!.add(actId);
      notifyListeners();
      unawaited(_saveToStorage());

      debugPrint('[PhysicalActivityService] BERHASIL menyelesaikan sesi $sessionId ($durasiMenit menit)');
      return true;
    } catch (e) {
      if (e is FirebaseException) {
        debugPrint('[PhysicalActivityService] finishSession Firestore error [${e.code}]: ${e.message}');
      } else {
        debugPrint('[PhysicalActivityService] Error finishSession: $e');
      }
      return false;
    }
  }

  /// Membatalkan sesi olahraga yang belum selesai
  Future<void> cancelSession({required String sessionId}) async {
    if (customAuth == null && customFirestore == null) {
      try {
        if (Firebase.apps.isEmpty) return;
      } catch (_) {
        return;
      }
    }
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final mainDocRef = await getUserMainDocRef();
    if (mainDocRef == null) return;
    try {
      await mainDocRef.collection('riwayat_sesi').doc(sessionId).set({
        'status': 'dibatalkan',
        'waktuDiperbarui': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (e is FirebaseException) {
        debugPrint('[PhysicalActivityService] cancelSession Firestore error [${e.code}]: ${e.message}');
      } else {
        debugPrint('[PhysicalActivityService] Error cancelSession: $e');
      }
    }
  }

  /// Sinkronisasi data aktivitas dari Firestore subkoleksi 'riwayat_sesi'
  Future<void> syncFromFirestore(String dateKey) async {
    if (customAuth == null && customFirestore == null) {
      try {
        if (Firebase.apps.isEmpty) return;
      } catch (_) {
        return;
      }
    }

    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(dateKey);
    } catch (_) {
      parsedDate = DateTime.now();
    }
    final targetTimestamp = Timestamp.fromDate(DateTime(parsedDate.year, parsedDate.month, parsedDate.day));

    _isSyncing = true;
    notifyListeners();

    try {
      if (!_completedActivitiesByDate.containsKey(dateKey)) {
        _completedActivitiesByDate[dateKey] = <String>{};
      }

      final mainDocRef = await getUserMainDocRef();
      if (mainDocRef != null) {
        final sessionSnap = await mainDocRef
            .collection('riwayat_sesi')
            .where('tanggalAktivitas', isEqualTo: targetTimestamp)
            .get();

        if (sessionSnap.docs.isNotEmpty) {
          for (final doc in sessionSnap.docs) {
            final data = doc.data();
            final jenis = data['jenisAktivitas'] as String? ?? '';
            final isDone = data['statusSelesai'] == true;
            final matchedId = _findActivityIdByName(jenis) ?? doc.id;
            if (isDone) {
              _completedActivitiesByDate[dateKey]!.add(matchedId);
            } else {
              _completedActivitiesByDate[dateKey]!.remove(matchedId);
            }
          }
        } else {
          // Fallback membaca dokumen legacy di root koleksi
          final legacySnap = await _firestore
              .collection('progress_aktivitas_fisik')
              .where('idPengguna', isEqualTo: currentUser.uid)
              .where('tanggalAktivitas', isEqualTo: targetTimestamp)
              .get();

          for (final doc in legacySnap.docs) {
            final data = doc.data();
            // Abaikan dokumen utama
            if (data.containsKey('totalSesi')) continue;
            final jenis = data['jenisAktivitas'] as String? ?? '';
            final isDone = data['statusSelesai'] == true;
            final matchedId = _findActivityIdByName(jenis) ?? doc.id;
            if (isDone) {
              _completedActivitiesByDate[dateKey]!.add(matchedId);
            }
          }
        }
      }
      await _saveToStorage();
    } catch (e) {
      debugPrint('[PhysicalActivityService] Notice syncFromFirestore: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Sinkronisasi menyeluruh seluruh sesi aktivitas fisik dari Cloud Firestore untuk pengguna aktif
  Future<void> syncAllSessionsFromFirestore() async {
    if (customAuth == null && customFirestore == null) {
      try {
        if (Firebase.apps.isEmpty) return;
      } catch (_) {
        return;
      }
    }

    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final mainDocRef = await getUserMainDocRef();
      if (mainDocRef != null) {
        final sessionSnap = await mainDocRef.collection('riwayat_sesi').get();
        if (sessionSnap.docs.isNotEmpty) {
          final newMap = <String, Set<String>>{};
          for (final doc in sessionSnap.docs) {
            final data = doc.data();
            final isDone = data['statusSelesai'] == true;
            if (!isDone) continue;

            final ts = data['tanggalAktivitas'] as Timestamp?;
            if (ts == null) continue;
            final d = ts.toDate();
            final dKey = formatDateKey(d);

            final jenis = data['jenisAktivitas'] as String? ?? '';
            final matchedId = _findActivityIdByName(jenis) ?? doc.id;

            if (!newMap.containsKey(dKey)) {
              newMap[dKey] = <String>{};
            }
            newMap[dKey]!.add(matchedId);
          }
          _completedActivitiesByDate.clear();
          _completedActivitiesByDate.addAll(newMap);
          await _saveToStorage();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('[PhysicalActivityService] Notice syncAllSessionsFromFirestore: $e');
    }
  }

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _riwayatSesiSubscription;
  String? _subscribedDateKey;

  /// Mulai mendengarkan pembaruan real-time dari Firestore subkoleksi 'riwayat_sesi' (Requirement 9)
  Future<void> listenToFirestoreSessions(String dateKey) async {
    if (customAuth == null && customFirestore == null) {
      try {
        if (Firebase.apps.isEmpty) return;
      } catch (_) {
        return;
      }
    }

    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    if (_subscribedDateKey == dateKey && _riwayatSesiSubscription != null) {
      return;
    }

    await _riwayatSesiSubscription?.cancel();
    _subscribedDateKey = dateKey;

    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(dateKey);
    } catch (_) {
      parsedDate = DateTime.now();
    }
    final targetTimestamp = Timestamp.fromDate(DateTime(parsedDate.year, parsedDate.month, parsedDate.day));

    try {
      final mainDocRef = await getUserMainDocRef();
      if (mainDocRef == null) return;

      _riwayatSesiSubscription = mainDocRef
          .collection('riwayat_sesi')
          .where('tanggalAktivitas', isEqualTo: targetTimestamp)
          .snapshots()
          .listen((snapshot) {
        if (!_completedActivitiesByDate.containsKey(dateKey)) {
          _completedActivitiesByDate[dateKey] = <String>{};
        }

        final currentCompletedSet = <String>{};
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final jenis = (data['jenisAktivitas'] as String?) ?? '';
          final isDone = data['statusSelesai'] == true;
          final matchedId = _findActivityIdByName(jenis) ?? doc.id;
          if (isDone) {
            currentCompletedSet.add(matchedId);
          }
        }

        _completedActivitiesByDate[dateKey] = currentCompletedSet;
        notifyListeners();
        unawaited(_saveToStorage());
      }, onError: (e) {
        debugPrint('[PhysicalActivityService] Error in riwayat_sesi snapshots: $e');
      });
    } catch (e) {
      debugPrint('[PhysicalActivityService] Error listenToFirestoreSessions: $e');
    }
  }

  /// Menghentikan langganan listener real-time
  void stopListeningToSessions() {
    _riwayatSesiSubscription?.cancel();
    _riwayatSesiSubscription = null;
    _subscribedDateKey = null;
  }

  /// Merekam atau membatalkan sesi langsung dari checklist UI
  Future<bool> _recordDirectSession({
    required String dateKey,
    required String activityId,
    Map<String, dynamic>? activity,
    required bool isCompleted,
    int? elapsedSeconds,
    BuildContext? context,
  }) async {
    if (isFutureDateKey(dateKey)) {
      debugPrint('[PhysicalActivityService] Menolak _recordDirectSession pada tanggal mendatang: $dateKey.');
      return false;
    }

    if (customAuth == null && customFirestore == null) {
      try {
        if (Firebase.apps.isEmpty) return true;
      } catch (_) {
        return true;
      }
    }

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('[PhysicalActivityService] Pengguna belum login. Progres disimpan secara lokal.');
      if (context != null && context.mounted) {
        AppAlert.showError(
          context,
          'Pengguna belum login dengan Firebase Authentication. Progres disimpan secara lokal.',
          duration: const Duration(seconds: 4),
        );
      }
      return true;
    }

    final mainDocRef = await ensureUserMainDoc();
    if (mainDocRef == null) return false;

    final act = activity ?? getActivityById(activityId);
    final jenisAktivitas = (act?['name'] as String?) ?? (act?['title'] as String?) ?? activityId;

    int durasiMenit = 0;
    if (elapsedSeconds != null && elapsedSeconds > 0) {
      durasiMenit = (elapsedSeconds / 60).round();
      if (durasiMenit <= 0) durasiMenit = 1;
    } else if (act != null) {
      durasiMenit = _parseDurationMinutes(act['duration'] ?? act['targetText']) ?? 30;
    }

    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(dateKey);
    } catch (_) {
      parsedDate = DateTime.now();
    }
    final targetTimestamp = Timestamp.fromDate(DateTime(parsedDate.year, parsedDate.month, parsedDate.day));

    try {
      final riwayatCol = mainDocRef.collection('riwayat_sesi');

      final existingSessions = await riwayatCol
          .where('idPengguna', isEqualTo: currentUser.uid)
          .where('jenisAktivitas', isEqualTo: jenisAktivitas)
          .where('tanggalAktivitas', isEqualTo: targetTimestamp)
          .limit(1)
          .get();

      String rawName = (currentUser.displayName ?? AuthService().currentUser?.name ?? AuthService().currentUser?.username ?? 'Pengguna').trim();
      if (rawName.isEmpty) rawName = 'Pengguna';

      if (isCompleted) {
        if (existingSessions.docs.isNotEmpty) {
          final doc = existingSessions.docs.first;
          final wasCompleted = doc.data()['statusSelesai'] == true;
          if (!wasCompleted) {
            await doc.reference.set({
              'statusSelesai': true,
              'status': 'selesai',
              'durasiMenit': durasiMenit,
              'waktuSelesai': FieldValue.serverTimestamp(),
              'waktuDiperbarui': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

            await mainDocRef.set({
              'idPengguna': currentUser.uid,
              'namaPengguna': rawName,
              'totalSesi': FieldValue.increment(1),
              'totalDurasiMenit': FieldValue.increment(durasiMenit),
              'waktuDiperbarui': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
        } else {
          final newDoc = riwayatCol.doc();
          await newDoc.set({
            'idPengguna': currentUser.uid,
            'jenisAktivitas': jenisAktivitas,
            'statusSelesai': true,
            'status': 'selesai',
            'tanggalAktivitas': targetTimestamp,
            'waktuMulai': targetTimestamp,
            'waktuSelesai': FieldValue.serverTimestamp(),
            'durasiMenit': durasiMenit,
            'waktuDibuat': FieldValue.serverTimestamp(),
            'waktuDiperbarui': FieldValue.serverTimestamp(),
          });

          await mainDocRef.set({
            'idPengguna': currentUser.uid,
            'namaPengguna': rawName,
            'totalSesi': FieldValue.increment(1),
            'totalDurasiMenit': FieldValue.increment(durasiMenit),
            'waktuDiperbarui': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      } else {
        if (existingSessions.docs.isNotEmpty) {
          final doc = existingSessions.docs.first;
          final wasCompleted = doc.data()['statusSelesai'] == true;
          final prevDurasi = (doc.data()['durasiMenit'] as num?)?.toInt() ?? durasiMenit;
          if (wasCompleted) {
            await doc.reference.set({
              'statusSelesai': false,
              'status': 'dibatalkan',
              'waktuDiperbarui': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

            await mainDocRef.set({
              'idPengguna': currentUser.uid,
              'namaPengguna': rawName,
              'totalSesi': FieldValue.increment(-1),
              'totalDurasiMenit': FieldValue.increment(-prevDurasi),
              'waktuDiperbarui': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
        }
      }
      return true;
    } catch (e) {
      if (e is FirebaseException) {
        debugPrint('[PhysicalActivityService] Direct session Firestore error [${e.code}]: ${e.message}');
      } else {
        debugPrint('[PhysicalActivityService] Gagal merekam direct session: $e');
      }
      if (context != null && context.mounted) {
        AppAlert.showError(
          context,
          'Gagal menyimpan progres aktivitas ke Firestore.',
        );
      }
      return false;
    }
  }

  /// Menandai aktivitas telah selesai
  Future<bool> completeActivity(
    String dateKey,
    String activityId, {
    Map<String, dynamic>? activity,
    int? elapsedSeconds,
    BuildContext? context,
  }) async {
    if (isFutureDateKey(dateKey)) {
      debugPrint('[PhysicalActivityService] Menolak completeActivity pada tanggal mendatang: $dateKey. Progres hanya dapat dicatat untuk hari ini.');
      if (context != null && context.mounted) {
        AppAlert.showWarning(
          context,
          'Progres latihan hanya dapat dicatat untuk tanggal hari ini.',
        );
      }
      return false;
    }

    if (!_completedActivitiesByDate.containsKey(dateKey)) {
      _completedActivitiesByDate[dateKey] = <String>{};
    }
    _completedActivitiesByDate[dateKey]!.add(activityId);
    notifyListeners();
    unawaited(_saveToStorage());

    final success = await _recordDirectSession(
      dateKey: dateKey,
      activityId: activityId,
      activity: activity,
      isCompleted: true,
      elapsedSeconds: elapsedSeconds,
      context: (context != null && context.mounted) ? context : null,
    );

    if (!success) {
      if (_completedActivitiesByDate.containsKey(dateKey)) {
        _completedActivitiesByDate[dateKey]!.remove(activityId);
        notifyListeners();
        unawaited(_saveToStorage());
      }
    }
    return success;
  }

  /// Menandai aktivitas belum selesai (uncomplete)
  Future<bool> uncompleteActivity(
    String dateKey,
    String activityId, {
    Map<String, dynamic>? activity,
    BuildContext? context,
  }) async {
    if (isFutureDateKey(dateKey)) {
      debugPrint('[PhysicalActivityService] Menolak uncompleteActivity pada tanggal mendatang: $dateKey.');
      if (context != null && context.mounted) {
        AppAlert.showWarning(
          context,
          'Progres latihan hanya dapat dicatat untuk tanggal hari ini.',
        );
      }
      return false;
    }

    if (_completedActivitiesByDate.containsKey(dateKey)) {
      _completedActivitiesByDate[dateKey]!.remove(activityId);
      notifyListeners();
      unawaited(_saveToStorage());
    }

    final success = await _recordDirectSession(
      dateKey: dateKey,
      activityId: activityId,
      activity: activity,
      isCompleted: false,
      context: (context != null && context.mounted) ? context : null,
    );

    if (!success) {
      if (!_completedActivitiesByDate.containsKey(dateKey)) {
        _completedActivitiesByDate[dateKey] = <String>{};
      }
      _completedActivitiesByDate[dateKey]!.add(activityId);
      notifyListeners();
      unawaited(_saveToStorage());
    }
    return success;
  }

  /// Toggle status aktivitas (selesai <-> belum selesai)
  Future<void> toggleActivity({
    required String dateKey,
    required Map<String, dynamic> activity,
    BuildContext? context,
  }) async {
    if (isFutureDateKey(dateKey)) {
      debugPrint('[PhysicalActivityService] Menolak toggleActivity pada tanggal mendatang: $dateKey.');
      if (context != null && context.mounted) {
        AppAlert.showWarning(
          context,
          'Progres latihan hanya dapat dicatat untuk tanggal hari ini.',
        );
      }
      return;
    }

    final actId = activity['id'] as String;
    final currentlyCompleted = isCompleted(dateKey, actId);

    if (currentlyCompleted) {
      await uncompleteActivity(
        dateKey,
        actId,
        activity: activity,
        context: context,
      );
    } else {
      await completeActivity(
        dateKey,
        actId,
        activity: activity,
        context: context,
      );
    }
  }

  /// Migrasi aman data lama dari root progress_aktivitas_fisik ke subkoleksi riwayat_sesi
  /// Data lama TIDAK dihapus untuk menjaga keamanan data histori pengguna.
  Future<int> migrateLegacyActivities() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return 0;

    final mainDocRef = await ensureUserMainDoc();
    if (mainDocRef == null) return 0;

    final riwayatCol = mainDocRef.collection('riwayat_sesi');

    try {
      final legacySnap = await _firestore
          .collection('progress_aktivitas_fisik')
          .where('idPengguna', isEqualTo: currentUser.uid)
          .get();

      int migratedCount = 0;
      int addedDurasi = 0;

      for (final doc in legacySnap.docs) {
        final data = doc.data();
        if (data.containsKey('totalSesi') || doc.id == mainDocRef.id) {
          continue;
        }

        final jenisAktivitas = data['jenisAktivitas'] as String? ?? '';
        final tanggalAktivitas = data['tanggalAktivitas'] as Timestamp?;
        final isSelesai = data['statusSelesai'] == true;
        final durasiMenit = (data['durasiMenit'] as num?)?.toInt() ?? 30;

        final existing = await riwayatCol
            .where('jenisAktivitas', isEqualTo: jenisAktivitas)
            .where('tanggalAktivitas', isEqualTo: tanggalAktivitas)
            .limit(1)
            .get();

        if (existing.docs.isEmpty) {
          await riwayatCol.add({
            'idPengguna': currentUser.uid,
            'jenisAktivitas': jenisAktivitas,
            'statusSelesai': isSelesai,
            'status': isSelesai ? 'selesai' : 'berlangsung',
            'tanggalAktivitas': tanggalAktivitas ?? Timestamp.now(),
            'waktuMulai': data['waktuDibuat'] ?? tanggalAktivitas ?? Timestamp.now(),
            'waktuSelesai': isSelesai ? (data['waktuDiperbarui'] ?? Timestamp.now()) : null,
            'durasiMenit': durasiMenit,
            'waktuDibuat': data['waktuDibuat'] ?? FieldValue.serverTimestamp(),
            'waktuDiperbarui': FieldValue.serverTimestamp(),
            'migratedFromLegacy': true,
          });
          migratedCount++;
          if (isSelesai) {
            addedDurasi += durasiMenit;
          }
        }
      }

      if (migratedCount > 0) {
        await mainDocRef.set({
          'idPengguna': currentUser.uid,
          'totalSesi': FieldValue.increment(migratedCount),
          'totalDurasiMenit': FieldValue.increment(addedDurasi),
          'waktuDiperbarui': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      debugPrint('[PhysicalActivityService] Migrasi selesai: $migratedCount dokumen termigrasi.');
      return migratedCount;
    } catch (e) {
      debugPrint('[PhysicalActivityService] Error migrasi data lama: $e');
      return 0;
    }
  }

  /// Normalisasi kategori skrining ke standar 6 kategori resmi
  static String normalizeCategory(String category) {
    final cat = category.trim().toLowerCase();
    if (cat.contains('underweight') || cat.contains('insufficient') || cat.contains('kurang')) {
      return 'Underweight';
    } else if (cat.contains('normal')) {
      return 'Normal';
    } else if (cat.contains('overweight') || cat.contains('lebih')) {
      return 'Overweight';
    } else if (cat.contains('iii') || cat.contains('morbid') || cat.contains('3')) {
      return 'Obesitas III';
    } else if (cat.contains('ii') || cat.contains('2')) {
      return 'Obesitas II';
    } else if (cat.contains('obesitas') ||
        cat.contains('obesity') ||
        cat.contains('type_i') ||
        cat.contains('level_i') ||
        cat.contains('1')) {
      return 'Obesitas I';
    }
    return 'Overweight';
  }

  /// Mengambil daftar aktivitas olahraga yang disesuaikan secara klinis
  /// berdasarkan kategori skrining pengguna (PAPDI & KMK Kemenkes 2025).
  List<Map<String, dynamic>> getActivitiesForCategory(String category, {SkriningData? skriningData}) {
    final normalized = normalizeCategory(category);

    switch (normalized) {
      case 'Underweight':
        return _getUnderweightActivities(skriningData);
      case 'Normal':
        return _getNormalActivities(skriningData);
      case 'Overweight':
        return _getOverweightActivities(skriningData);
      case 'Obesitas I':
        return _getObesitas1Activities(skriningData);
      case 'Obesitas II':
        return _getObesitas2Activities(skriningData);
      case 'Obesitas III':
        return _getObesitas3Activities(skriningData);
      default:
        return _getOverweightActivities(skriningData);
    }
  }

  /// Helper tips adaptif berdasarkan kebiasaan fisik awal di skrining
  String _getHabitTip(SkriningData? data) {
    final habit = data?.physicalActivity?.trim().toLowerCase() ?? '';
    if (habit.contains('tidak') || habit.contains('jarang') || habit.contains('never')) {
      return 'Berdasarkan skrining Anda (aktivitas awal belum rutin): Awali 10-15 menit pertama dan tingkatkan durasi secara bertahap.';
    } else if (habit.contains('kadang') || habit.contains('1-2') || habit.contains('1 - 2')) {
      return 'Berdasarkan skrining Anda: Tetapkan jadwal 3-4 hari seminggu untuk membentuk kebiasaan olahraga yang konsisten.';
    } else if (habit.contains('sering') || habit.contains('selalu') || habit.contains('3-4') || habit.contains('rutin') || habit.contains('aktif')) {
      return 'Berdasarkan skrining Anda yang sudah aktif: Pertahankan konsistensi latihan dan pastikan waktu istirahat pemulihan otot cukup.';
    }
    return 'Lakukan latihan dengan ritme teratur dan sesuaikan dengan kapasitas kenyamanan tubuh.';
  }

  // =========================================================================
  // 1. KATEGORI NORMAL (IMT 18.5 - 22.9 kg/m²)
  // Fokus: Pemeliharaan Kapasitas Kardiorespirasi & Otot Bebas Lemak
  // Olahraga: Jogging, Bersepeda Outdoor, Renang Aerobik, Gym/Bodyweight, HIIT
  // =========================================================================
  List<Map<String, dynamic>> _getNormalActivities(SkriningData? data) {
    final habitTip = _getHabitTip(data);
    return [
      {
        'id': 'normal_jogging',
        'title': 'Jogging / Lari Santai',
        'name': 'Jogging / Lari Santai',
        'targetText': '30-45 menit',
        'heroImg': 'assets/progress/clean/hero_jogging.png',
        'thumbImg': 'assets/progress/clean/thumb_jogging.png',
        'thumb': 'assets/progress/clean/rec_thumb_jogging.png',
        'icon': 'assets/progress/clean/rec_icon_jogging.png',
        'desc': 'Meningkatkan daya tahan kardiorespirasi, pembakaran kalori, dan menjaga kesehatan jantung.',
        'duration': '30-45 menit',
        'frequency': '3-5x/minggu',
        'intensity': 'Sedang (60-70% HRmax)',
        'calories': '220-380 kkal',
        'aboutTitle': 'Tentang Jogging',
        'aboutDesc':
            'Jogging merupakan aktivitas aerobik sedang yang efektif mempertahankan berat badan ideal, menjaga elastisitas pembuluh darah, dan meningkatkan VO2 max.',
        'benefits': [
          'Mempertahankan kebugaran jantung dan paru-paru dalam rentang optimal',
          'Mendukung regulasi berat badan ideal dan sensitivitas insulin',
          'Memicu pelepasan endorfin untuk meredakan stres harian',
          'Meningkatkan daya tahan tubuh dan kebugaran fungsional',
        ],
        'specs': {
          'duration': '30-45 menit',
          'frequency': '3-5 kali/minggu',
          'intensity': 'Sedang (60-70% HRmax)',
          'calories': '220-380 kkal',
        },
        'tipsTitle': 'Tips Melakukan Jogging',
        'tips': [
          habitTip,
          'Lakukan pemanasan 5-10 menit sebelum mulai berlari.',
          'Gunakan sepatu lari dengan bantalan yang sesuai untuk meredam impak.',
          'Jaga postur tubuh tetap tegak dan pandangan lurus ke depan.',
        ],
        'refLink': 'https://doi.org/10.25182/jgp.2016.11.3.%25p',
      },
      {
        'id': 'normal_cycling',
        'title': 'Bersepeda Outdoor / Santai',
        'name': 'Bersepeda Outdoor',
        'targetText': '30-60 menit',
        'heroImg': 'assets/progress/clean/hero_cycling.png',
        'thumbImg': 'assets/progress/clean/thumb_cycling.png',
        'thumb': 'assets/progress/clean/rec_thumb_cycling.png',
        'icon': 'assets/progress/clean/rec_icon_cycling.png',
        'desc': 'Melatih daya tahan jantung-paru dan kekuatan otot kaki secara dinamis di luar ruangan.',
        'duration': '30-60 menit',
        'frequency': '3-4x/minggu',
        'intensity': 'Sedang (55-70% HRmax)',
        'calories': '200-380 kkal',
        'aboutTitle': 'Tentang Bersepeda Outdoor',
        'aboutDesc':
            'Bersepeda melatih kapasitas aerobik dan kekuatan otot kuadrisep serta betis, memberikan variasi rute yang menyenangkan untuk kesehatan mental.',
        'benefits': [
          'Melatih kebugaran kardiovaskular secara berkelanjutan',
          'Memperkuat otot paha, betis, dan pinggul',
          'Menurunkan hormon stres dan menyegarkan pikiran',
        ],
        'specs': {
          'duration': '30-60 menit',
          'frequency': '3-4 kali/minggu',
          'intensity': 'Sedang (55-70% HRmax)',
          'calories': '200-380 kkal',
        },
        'tipsTitle': 'Tips Bersepeda Outdoor',
        'tips': [
          habitTip,
          'Gunakan helm pelindung kepala dan patuhi rambu lalu lintas.',
          'Pastikan posisi sadel sejajar dengan pinggul saat berdiri.',
          'Bawa air minum untuk menjaga hidrasi sepanjang perjalanan.',
        ],
        'refLink': 'https://doi.org/10.21831/medikora.v14i2.7937',
      },
      {
        'id': 'normal_swimming',
        'title': 'Renang Aerobik (Full Body Workout)',
        'name': 'Renang Aerobik',
        'targetText': '30-45 menit',
        'heroImg': 'assets/progress/clean/hero_swimming.png',
        'thumbImg': 'assets/progress/clean/thumb_swimming.png',
        'thumb': 'assets/progress/clean/rec_thumb_swimming.png',
        'icon': 'assets/progress/clean/rec_icon_swimming.png',
        'desc': 'Melibatkan hampir seluruh kelompok otot tubuh sekaligus meningkatkan kapasitas vital paru-paru.',
        'duration': '30-45 menit',
        'frequency': '2-3x/minggu',
        'intensity': 'Sedang (60-75% HRmax)',
        'calories': '250-450 kkal',
        'aboutTitle': 'Tentang Renang Aerobik',
        'aboutDesc':
            'Berenang melatih kekuatan otot punggung, dada, bahu, dan tungkai sekaligus dengan resistensi alami air tanpa stres benturan gravitasi.',
        'benefits': [
          'Latihan aerobik seluruh tubuh dengan keterlibatan otot maksimal',
          'Meningkatkan kapasitas paru-paru dan ritme pernapasan',
          'Membakar kalori tinggi sekaligus mengencangkan otot tubuh',
        ],
        'specs': {
          'duration': '30-45 menit',
          'frequency': '2-3 kali/minggu',
          'intensity': 'Sedang (60-75% HRmax)',
          'calories': '250-450 kkal',
        },
        'tipsTitle': 'Tips Renang Aerobik',
        'tips': [
          habitTip,
          'Awali dengan pemanasan peregangan bahu dan kaki di tepi kolam.',
          'Kombinasikan gaya dada dan gaya bebas untuk variasi kelompok otot.',
          'Minum air setelah sesi renang untuk mencegah dehidrasi tersembunyi.',
        ],
        'refLink': 'https://doi.org/10.25182/jgp.2016.11.3.%25p',
      },
      {
        'id': 'normal_bodyweight',
        'title': 'Latihan Kekuatan Otot (Gym / Bodyweight)',
        'name': 'Latihan Kekuatan (Strength)',
        'targetText': '25-45 menit',
        'heroImg': 'assets/progress/clean/hero_bodyweight.png',
        'thumbImg': 'assets/progress/clean/thumb_bodyweight.png',
        'thumb': 'assets/progress/clean/rec_thumb_bodyweight.png',
        'icon': 'assets/progress/clean/rec_icon_bodyweight.png',
        'desc': 'Menjaga massa otot bebas lemak (Fat-Free Mass) dan kepadatan tulang agar metabolisme basal tetap prima.',
        'duration': '25-45 menit',
        'frequency': '2-3x/minggu',
        'intensity': 'Sedang-Tinggi (65-80% HRmax)',
        'calories': '180-320 kkal',
        'aboutTitle': 'Tentang Latihan Kekuatan',
        'aboutDesc':
            'Sesuai panduan PAPDI dan Kemenkes, latihan resistensi 2 kali seminggu esensial untuk menjaga massa otot dan mencegah penurunan laju metabolisme basal.',
        'benefits': [
          'Mempertahankan dan mengencangkan massa otot rangka',
          'Mendukung kepadatan tulang dan postur tubuh',
          'Meningkatkan pembakaran energi jangka panjang (BMR)',
        ],
        'specs': {
          'duration': '25-45 menit',
          'frequency': '2-3 kali/minggu',
          'intensity': 'Sedang-Tinggi (65-80% HRmax)',
          'calories': '180-320 kkal',
        },
        'tipsTitle': 'Tips Latihan Kekuatan',
        'tips': [
          habitTip,
          'Fokus pada gerakan kompon: squat, push-up, lunge, dan plank.',
          'Beri jeda istirahat 48 jam untuk kelompok otot yang sama.',
          'Lakukan pendinginan statis setelah sesi latihan.',
        ],
        'refLink': 'https://doi.org/10.21831/jk.v8i1.31208',
      },
      {
        'id': 'normal_hiit',
        'title': 'Senam Aerobik Dinamis & HIIT',
        'name': 'Senam Aerobik & HIIT',
        'targetText': '20-30 menit',
        'heroImg': 'assets/progress/clean/hero_hiit.png',
        'thumbImg': 'assets/progress/clean/thumb_hiit.png',
        'thumb': 'assets/progress/clean/rec_thumb_hiit.png',
        'icon': 'assets/progress/clean/rec_icon_hiit.png',
        'desc': 'Interval intensitas sedang-tinggi untuk menantang kapasitas jantung dan efisiensi metabolik.',
        'duration': '20-30 menit',
        'frequency': '2x/minggu',
        'intensity': 'Tinggi (75-85% HRmax)',
        'calories': '220-400 kkal',
        'aboutTitle': 'Tentang Senam Dinamis & HIIT',
        'aboutDesc':
            'Kombinasi gerak berirama dan interval intensif untuk menstimulasi fungsi mitokondria otot dan ambang batas laktat.',
        'benefits': [
          'Meningkatkan pembakaran kalori pasca latihan (EPOC)',
          'Melatih koordinasi, kelincahan, dan kapasitas anaerobik',
          'Variasi dinamis yang menyenangkan dan efisien waktu',
        ],
        'specs': {
          'duration': '20-30 menit',
          'frequency': '2 kali/minggu',
          'intensity': 'Tinggi (75-85% HRmax)',
          'calories': '220-400 kkal',
        },
        'tipsTitle': 'Tips Senam Dinamis & HIIT',
        'tips': [
          habitTip,
          'Wajib pemanasan menyeluruh 5-10 menit sebelum masuk interval.',
          'Lakukan gerakan dengan kontrol teknik sebelum meningkatkan kecepatan.',
          'Cukupi kebutuhan cairan sebelum, saat, dan sesudah latihan.',
        ],
        'refLink': 'https://doi.org/10.15294/jpes.v8i2.31208',
      },
    ];
  }

  // =========================================================================
  // 2. KATEGORI OVERWEIGHT (IMT 23.0 - 24.9 kg/m²)
  // Fokus: Defisit Energi Bertahap, Kardio Ramah Sendi & Aktivitas NEAT
  // Olahraga: Jalan Cepat, Senam Low-Impact, Bersepeda, Beban Terkontrol, Walk-Jog
  // =========================================================================
  List<Map<String, dynamic>> _getOverweightActivities(SkriningData? data) {
    final habitTip = _getHabitTip(data);
    return [
      {
        'id': 'overweight_brisk_walk',
        'title': 'Jalan Cepat (Brisk Walking 5 km/jam)',
        'name': 'Jalan Cepat (Brisk Walking)',
        'targetText': '35-50 menit',
        'heroImg': 'assets/progress/clean/hero_jogging.png',
        'thumbImg': 'assets/progress/clean/thumb_jogging.png',
        'thumb': 'assets/progress/clean/rec_thumb_jogging.png',
        'icon': 'assets/progress/clean/rec_icon_jogging.png',
        'desc': 'Olahraga kardio low-impact utama membakar timbunan kalori tanpa menimbulkan beban berlebih pada sendi lutut.',
        'duration': '35-50 menit',
        'frequency': '5x/minggu',
        'intensity': 'Sedang (55-65% HRmax)',
        'calories': '200-350 kkal',
        'safetyNotes':
            'Gunakan sepatu yang nyaman dengan sol peredam impak untuk menjaga persendian lutut dan tumit.',
        'aboutTitle': 'Tentang Jalan Cepat untuk Overweight',
        'aboutDesc':
            'Berdasarkan pedoman klinis PAPDI dan Kemenkes, jalan cepat dengan kecepatan konstan merupakan modalitas utama untuk memicu pembakaran lemak viseral secara aman dan berkelanjutan.',
        'benefits': [
          'Membakar kalori dan timbunan lemak tubuh dalam zona pembakaran lemak (fat-burn zone)',
          'Sangat ramah terhadap sendi lutut dan pinggul dibandingkan lari sprint',
          'Meningkatkan sensitivitas insulin dan menurunkan tekanan darah',
          'Mendukung target 150-200 menit aktivitas aerobik per minggu',
        ],
        'specs': {
          'duration': '35-50 menit',
          'frequency': '5 kali/minggu',
          'intensity': 'Sedang (55-65% HRmax)',
          'calories': '200-350 kkal',
        },
        'tipsTitle': 'Tips Jalan Cepat',
        'tips': [
          habitTip,
          'Awali dengan jalan santai 5 menit sebagai pemanasan bertahap.',
          'Pertahankan langkah tegap dengan ayunan lengan ritmis di samping tubuh.',
          'Pilih lintasan datar yang aman seperti taman atau treadmill.',
        ],
        'refLink': 'https://doi.org/10.25182/jgp.2016.11.3.%25p',
      },
      {
        'id': 'overweight_aerobic_dance',
        'title': 'Senam Aerobik Low-Impact',
        'name': 'Senam Aerobik Low-Impact',
        'targetText': '30-45 menit',
        'heroImg': 'assets/progress/clean/hero_hiit.png',
        'thumbImg': 'assets/progress/clean/thumb_hiit.png',
        'thumb': 'assets/progress/clean/rec_thumb_hiit.png',
        'icon': 'assets/progress/clean/rec_icon_hiit.png',
        'desc': 'Gerakan senam ritmis tanpa lompatan tinggi untuk memacu pengeluaran energi dengan aman.',
        'duration': '30-45 menit',
        'frequency': '3-4x/minggu',
        'intensity': 'Sedang (60-70% HRmax)',
        'calories': '220-380 kkal',
        'safetyNotes':
            'Hindari gerakan melompat tinggi. Pastikan satu kaki selalu menempel di lantai (low-impact).',
        'aboutTitle': 'Tentang Senam Aerobik Low-Impact',
        'aboutDesc':
            'Senam ritmis dengan tempo musik sedang menggerakkan seluruh kelompok otot besar untuk membakar kalori tanpa risiko cedera tendon akibat benturan keras.',
        'benefits': [
          'Pengeluaran kalori signifikan tanpa hentakan pada sendi',
          'Melatih koordinasi gerak tubuh dan elastisitas otot',
          'Meningkatkan suasana hati dan motivasi berolahraga rutin',
        ],
        'specs': {
          'duration': '30-45 menit',
          'frequency': '3-4 kali/minggu',
          'intensity': 'Sedang (60-70% HRmax)',
          'calories': '220-380 kkal',
        },
        'tipsTitle': 'Tips Senam Aerobik',
        'tips': [
          habitTip,
          'Ikuti instruksi gerakan dengan ritme yang nyaman.',
          'Gunakan matras atau lantai kayu/karet yang tidak licin.',
          'Minum sedikit air di sela sesi untuk menjaga hidrasi.',
        ],
        'refLink': 'https://doi.org/10.21831/medikora.v14i2.7937',
      },
      {
        'id': 'overweight_cycling',
        'title': 'Bersepeda Teratur (Outdoor / Statis)',
        'name': 'Bersepeda Teratur',
        'targetText': '30-45 menit',
        'heroImg': 'assets/progress/clean/hero_cycling.png',
        'thumbImg': 'assets/progress/clean/thumb_cycling.png',
        'thumb': 'assets/progress/clean/rec_thumb_cycling.png',
        'icon': 'assets/progress/clean/rec_icon_cycling.png',
        'desc': 'Berat badan bertumpu pada sadel sehingga mengurangi tekanan kompresi pada persendian lutut hingga 60%.',
        'duration': '30-45 menit',
        'frequency': '4-5x/minggu',
        'intensity': 'Sedang (55-70% HRmax)',
        'calories': '220-400 kkal',
        'safetyNotes':
            'Pastikan posisi sadel diatur agar lutut hanya menekuk sedikit (25-30 derajat) di titik pedal terbawah.',
        'aboutTitle': 'Tentang Bersepeda untuk Overweight',
        'aboutDesc':
            'Bersepeda sangat dianjurkan oleh konsensus PAPDI karena memindahkan beban berat badan dari persendian lutut ke sadel sepeda.',
        'benefits': [
          'Melindungi sendi lutut dari beban kompresi saat berolahraga',
          'Memperkuat otot paha, betis, dan gluteus',
          'Mendukung program defisit energi berkelanjutan',
        ],
        'specs': {
          'duration': '30-45 menit',
          'frequency': '4-5 kali/minggu',
          'intensity': 'Sedang (55-70% HRmax)',
          'calories': '220-400 kkal',
        },
        'tipsTitle': 'Tips Bersepeda',
        'tips': [
          habitTip,
          'Mulai kayuhan dengan resistensi ringan selama 5 menit pertama.',
          'Pertahankan irama kayuhan konstan sekitar 60-80 RPM.',
          'Jaga posisi punggung tetap tegak dan rileks.',
        ],
        'refLink': 'https://doi.org/10.21831/medikora.v14i2.7937',
      },
      {
        'id': 'overweight_bodyweight',
        'title': 'Latihan Beban Tubuh Terkontrol',
        'name': 'Latihan Beban Terkontrol',
        'targetText': '20-35 menit',
        'heroImg': 'assets/progress/clean/hero_bodyweight.png',
        'thumbImg': 'assets/progress/clean/thumb_bodyweight.png',
        'thumb': 'assets/progress/clean/rec_thumb_bodyweight.png',
        'icon': 'assets/progress/clean/rec_icon_bodyweight.png',
        'desc': 'Mempertahankan massa otot bebas lemak saat proses penurunan berat badan agar laju metabolisme BMR tidak menurun.',
        'duration': '20-35 menit',
        'frequency': '2-3x/minggu',
        'intensity': 'Sedang (55-65% HRmax)',
        'calories': '140-260 kkal',
        'aboutTitle': 'Tentang Latihan Beban Terkontrol',
        'aboutDesc':
            'Latihan penguatan otot penting agar berat badan yang turun berasal dari massa lemak, bukan dari penyusutan massa otot.',
        'benefits': [
          'Mencegah penurunan laju metabolisme basal selama defisit kalori',
          'Meningkatkan sensitivitas reseptor insulin terhadap glukosa',
          'Memperkuat stabilitas sendi pinggul dan lutut',
        ],
        'specs': {
          'duration': '20-35 menit',
          'frequency': '2-3 kali/minggu',
          'intensity': 'Sedang (55-65% HRmax)',
          'calories': '140-260 kkal',
        },
        'tipsTitle': 'Tips Latihan Beban',
        'tips': [
          habitTip,
          'Pilih variasi gerakan aman: wall push-up, chair squat, dan glute bridge.',
          'Lakukan 2-3 set dengan 10-12 repetisi terkontrol pada tiap gerakan.',
          'Jangan menahan napas saat melakukan kontraksi otot.',
        ],
        'refLink': 'https://doi.org/10.21831/jk.v8i1.31208',
      },
      {
        'id': 'overweight_walk_jog',
        'title': 'Jogging Bertahap (Walk-Jog Interval)',
        'name': 'Jogging Bertahap',
        'targetText': '25-40 menit',
        'heroImg': 'assets/progress/clean/hero_jogging.png',
        'thumbImg': 'assets/progress/clean/thumb_jogging.png',
        'thumb': 'assets/progress/clean/rec_thumb_jogging.png',
        'icon': 'assets/progress/clean/rec_icon_jogging.png',
        'desc': 'Kombinasi 3 menit jalan cepat disusul 1 menit lari santai untuk adaptasi kapasitas kardio.',
        'duration': '25-40 menit',
        'frequency': '3x/minggu',
        'intensity': 'Sedang (60-70% HRmax)',
        'calories': '200-360 kkal',
        'safetyNotes':
            'Bila timbul rasa sakit atau pegal tajam pada sendi lutut, segera beralih penuh ke jalan santai.',
        'aboutTitle': 'Tentang Walk-Jog Interval',
        'aboutDesc':
            'Metode interval jalan-jogging memungkinkan tubuh meningkatkan kapasitas aerobik tanpa kelelahan mendadak atau cedera sendi.',
        'benefits': [
          'Meningkatkan efisiensi pembakaran kalori per menit',
          'Membiasakan sistem kardiometabolik beradaptasi secara progresif',
          'Membantu target pengurangan lemak visceral perut',
        ],
        'specs': {
          'duration': '25-40 menit',
          'frequency': '3 kali/minggu',
          'intensity': 'Sedang (60-70% HRmax)',
          'calories': '200-360 kkal',
        },
        'tipsTitle': 'Tips Walk-Jog Interval',
        'tips': [
          habitTip,
          'Gunakan rasio 3 menit jalan cepat dan 1 menit jog santai.',
          'Tingkatkan porsi jogging secara perlahan setelah 2-3 minggu latihan rutin.',
          'Lakukan peregangan betis dan paha belakang setelah selesai.',
        ],
        'refLink': 'https://doi.org/10.25182/jgp.2016.11.3.%25p',
      },
    ];
  }

  // =========================================================================
  // 3. KATEGORI OBESITAS I (IMT 25.0 - 29.9 kg/m²)
  // Fokus: Proteksi Sendi Wajib (Low-Impact), Akumulasi 200-250 mnt/minggu
  // Olahraga: Berenang/Aquarobics, Sepeda Statis, Jalan Kaki Low-Impact, Penguatan Penyangga
  // =========================================================================
  List<Map<String, dynamic>> _getObesitas1Activities(SkriningData? data) {
    final habitTip = _getHabitTip(data);
    return [
      {
        'id': 'obesitas1_aquarobics',
        'title': 'Berenang / Senam Air (Aquarobics)',
        'name': 'Berenang / Senam Air',
        'targetText': '30-45 menit',
        'heroImg': 'assets/progress/clean/hero_swimming.png',
        'thumbImg': 'assets/progress/clean/thumb_swimming.png',
        'thumb': 'assets/progress/clean/rec_thumb_swimming.png',
        'icon': 'assets/progress/clean/rec_icon_swimming.png',
        'desc': 'Daya apung air menopang hingga 90% berat tubuh sehingga persendian lutut 100% bebas dari benturan kompresi.',
        'duration': '30-45 menit',
        'frequency': '3-4x/minggu',
        'intensity': 'Sedang Ramah Sendi (50-65% HRmax)',
        'calories': '200-380 kkal',
        'safetyNotes':
            'Pilihan utama klinis PAPDI & Kemenkes untuk obesitas karena bebas risiko trauma sendi lutut dan pergelangan kaki.',
        'aboutTitle': 'Tentang Senam Air & Renang untuk Obesitas',
        'aboutDesc':
            'Pada Obesitas I, tekanan pada sendi lutut saat berjalan meningkat 4 kali lipat. Berolahraga di dalam air mengeliminasi tekanan gravitasi tersebut sehingga kalori terbakar maksimal tanpa rasa nyeri.',
        'benefits': [
          'Melindungi sendi lutut dan tulang rawan dari risiko osteoartritis',
          'Resistensi air mengencangkan otot tubuh secara merata',
          'Mendukung penurunan 5-10% berat badan dalam program komprehensif',
        ],
        'specs': {
          'duration': '30-45 menit',
          'frequency': '3-4 kali/minggu',
          'intensity': 'Sedang Ramah Sendi (50-65% HRmax)',
          'calories': '200-380 kkal',
        },
        'tipsTitle': 'Tips Senam Air',
        'tips': [
          habitTip,
          'Lakukan gerakan berjalan atau mengayuh tangan di kolam setinggi dada.',
          'Gunakan kolam dangkal bila belum mahir berenang.',
          'Pastikan cukup minum air sebelum dan sesudah sesi latihan.',
        ],
        'refLink': 'https://keslan.kemkes.go.id/unduhan/KMK%20No.%20HK.01.07-MENKES-509-2025.pdf',
      },
      {
        'id': 'obesitas1_stationary_bike',
        'title': 'Bersepeda Statis (Stationary Bike)',
        'name': 'Bersepeda Statis',
        'targetText': '30-45 menit',
        'heroImg': 'assets/progress/clean/hero_cycling.png',
        'thumbImg': 'assets/progress/clean/thumb_cycling.png',
        'thumb': 'assets/progress/clean/rec_thumb_cycling.png',
        'icon': 'assets/progress/clean/rec_icon_cycling.png',
        'desc': 'Beban tubuh dialihkan ke sadel sepeda, memberikan latihan kardiorespirasi unggulan tanpa getaran benturan.',
        'duration': '30-45 menit',
        'frequency': '4-5x/minggu',
        'intensity': 'Sedang Terkontrol (50-60% HRmax)',
        'calories': '180-320 kkal',
        'safetyNotes':
            'Atur resistensi kayuhan ringan-sedang agar beban tidak menumpuk di tempurung lutut.',
        'aboutTitle': 'Tentang Bersepeda Statis',
        'aboutDesc':
            'Sepeda statis memberikan kontrol denyut jantung dan kecepatan yang sangat stabil, bebas dari risiko terjatuh di jalan raya dan minim kompresi sendi.',
        'benefits': [
          'Beban gravitasi pada persendian lutut sangat minimal',
          'Efektif melatih sirkulasi darah vena dan otot tungkai',
          'Dapat dilakukan di dalam ruangan dengan suhu sejuk',
        ],
        'specs': {
          'duration': '30-45 menit',
          'frequency': '4-5 kali/minggu',
          'intensity': 'Sedang Terkontrol (50-60% HRmax)',
          'calories': '180-320 kkal',
        },
        'tipsTitle': 'Tips Bersepeda Statis',
        'tips': [
          habitTip,
          'Sesuaikan tinggi sadel agar saat pedal di bawah, lutut hanya sedikit tertekuk.',
          'Kayuh dengan irama konstan tanpa tergesa-gesa.',
          'Jaga posisi punggung tetap tegak dan rileks.',
        ],
        'refLink': 'https://papdi.or.id/pdfs/1422/Soft%20copy%20konsensus%20obesitas.pdf',
      },
      {
        'id': 'obesitas1_low_impact_walk',
        'title': 'Jalan Kaki Rendah Beban (Low-Impact Walk)',
        'name': 'Jalan Kaki Low-Impact',
        'targetText': '30-40 menit',
        'heroImg': 'assets/progress/clean/hero_jogging.png',
        'thumbImg': 'assets/progress/clean/thumb_jogging.png',
        'thumb': 'assets/progress/clean/rec_thumb_jogging.png',
        'icon': 'assets/progress/clean/rec_icon_jogging.png',
        'desc': 'Aktivitas aerobik ramah sendi untuk mengakumulasikan target 200-250 menit/minggu secara konsisten.',
        'duration': '30-40 menit',
        'frequency': '5x/minggu',
        'intensity': 'Sedang (50-60% HRmax)',
        'calories': '160-300 kkal',
        'safetyNotes':
            'Hindari lari cepat di atas aspal keras. Wajib gunakan sepatu olahraga dengan bantalan empuk.',
        'aboutTitle': 'Tentang Jalan Kaki Low-Impact',
        'aboutDesc':
            'Jalan santai ritmis di lintasan datar membantu membakar lemak dan menurunkan tekanan darah tanpa menimbulkan peradangan pada sendi pergelangan kaki.',
        'benefits': [
          'Membantu akumulasi 200-250 menit aktivitas aerobik per minggu',
          'Melindungi sendi lutut dari cedera osteoarthritis',
          'Meningkatkan toleransi fisik dan kebugaran jantung-paru',
        ],
        'specs': {
          'duration': '30-40 menit',
          'frequency': '5 kali/minggu',
          'intensity': 'Sedang (50-60% HRmax)',
          'calories': '160-300 kkal',
        },
        'tipsTitle': 'Tips Jalan Rendah Beban',
        'tips': [
          habitTip,
          'Pemanasan 5-10 menit dengan putaran engkel dan lutut perlahan.',
          'Bisa dibagi menjadi 2 sesi (20 menit pagi dan 20 menit sore) bila perlu.',
          'Pilih lintasan datar di rumput, trek karet, atau treadmill datar.',
        ],
        'refLink': 'https://keslan.kemkes.go.id/unduhan/KMK%20No.%20HK.01.07-MENKES-509-2025.pdf',
      },
      {
        'id': 'obesitas1_joint_strength',
        'title': 'Latihan Kekuatan Penyangga Sendi',
        'name': 'Latihan Penguatan Sendi',
        'targetText': '20-30 menit',
        'heroImg': 'assets/progress/clean/hero_bodyweight.png',
        'thumbImg': 'assets/progress/clean/thumb_bodyweight.png',
        'thumb': 'assets/progress/clean/rec_thumb_bodyweight.png',
        'icon': 'assets/progress/clean/rec_icon_bodyweight.png',
        'desc': 'Memperkuat otot kuadrisep dan pinggul penopang sendi dengan gerakan stabil tanpa loncatan.',
        'duration': '20-30 menit',
        'frequency': '2-3x/minggu',
        'intensity': 'Ringan-Sedang (50% HRmax)',
        'calories': '120-200 kkal',
        'safetyNotes':
            'Dilarang melakukan gerakan melompat (jumping jack/burpee) atau squat terlalu dalam untuk mencegah cedera meniskus.',
        'aboutTitle': 'Tentang Penguatan Penyangga Sendi',
        'aboutDesc':
            'Latihan resistensi terkontrol memperkuat otot paha depan (kuadrisep) yang berfungsi sebagai penyerap getaran alami persendian lutut.',
        'benefits': [
          'Memperkuat otot penopang lutut dan tulang belakang',
          'Mencegah penyusutan massa otot selama menjalani Terapi Nutrisi Medis',
          'Meningkatkan kestabilan saat berjalan dan menaiki tangga',
        ],
        'specs': {
          'duration': '20-30 menit',
          'frequency': '2-3 kali/minggu',
          'intensity': 'Ringan-Sedang (50% HRmax)',
          'calories': '120-200 kkal',
        },
        'tipsTitle': 'Tips Penguatan Sendi',
        'tips': [
          habitTip,
          'Gunakan bantuan kursi untuk latihan bangkit-duduk (chair squat) terkontrol.',
          'Lakukan wall push-up dengan posisi tangan selebar bahu.',
          'Gunakan tempo lambat 2-3 detik naik dan 2-3 detik turun.',
        ],
        'refLink': 'https://doi.org/10.21831/jk.v8i1.31208',
      },
    ];
  }

  // =========================================================================
  // 4. KATEGORI OBESITAS II (IMT 30.0 - 34.9 kg/m²)
  // Fokus: Non-Weight Bearing, Fraksionasi Durasi, Proteksi Sendi Maksimal
  // Olahraga: Renang & Terapi Air, Sepeda Reclined, Latihan Kursi, Jalan Fraksionasi
  // =========================================================================
  List<Map<String, dynamic>> _getObesitas2Activities(SkriningData? data) {
    final habitTip = _getHabitTip(data);
    return [
      {
        'id': 'obesitas2_water_therapy',
        'title': 'Renang Santai & Terapi Air (Water Aerobics)',
        'name': 'Renang & Terapi Air',
        'targetText': '30-45 menit',
        'heroImg': 'assets/progress/clean/hero_swimming.png',
        'thumbImg': 'assets/progress/clean/thumb_swimming.png',
        'thumb': 'assets/progress/clean/rec_thumb_swimming.png',
        'icon': 'assets/progress/clean/rec_icon_swimming.png',
        'desc': 'Aktivitas kardio non-weight bearing paling aman; air menopang 90% berat badan tanpa membebani lutut dan pinggul.',
        'duration': '30-45 menit',
        'frequency': '3-4x/minggu',
        'intensity': 'Ringan-Sedang (45-60% HRmax)',
        'calories': '160-300 kkal',
        'safetyNotes':
            'Gunakan kolam dangkal bila belum mahir berenang. Lakukan gerakan ayunan tangan dan langkah santai di dalam air.',
        'aboutTitle': 'Tentang Terapi Air untuk Obesitas II',
        'aboutDesc':
            'Pada Obesitas II, olahraga di darat sering menimbulkan nyeri lutut. Terapi air memungkinkan pasien bergerak bebas dengan daya apung air, memperlancar sirkulasi darah tanpa sedikit pun tekanan pada tulang rawan sendi.',
        'benefits': [
          'Bebas 100% dari benturan gravitasi pada sendi lutut dan tulang belakang',
          'Membantu sirkulasi vena dan mengurangi pembengkakan kaki',
          'Membakar kalori secara nyaman tanpa risiko jatuh atau kepanasan',
        ],
        'specs': {
          'duration': '30-45 menit',
          'frequency': '3-4 kali/minggu',
          'intensity': 'Ringan-Sedang (45-60% HRmax)',
          'calories': '160-300 kkal',
        },
        'tipsTitle': 'Tips Terapi Air',
        'tips': [
          habitTip,
          'Berjalanlah maju-mundur di kolam air setinggi dada selama 15-20 menit.',
          'Gunakan papan pelampung untuk latihan kayuhan kaki santai.',
          'Selalu keringkan tubuh dan ganti pakaian setelah sesi selesai.',
        ],
        'refLink': 'https://keslan.kemkes.go.id/unduhan/KMK%20No.%20HK.01.07-MENKES-509-2025.pdf',
      },
      {
        'id': 'obesitas2_recumbent_bike',
        'title': 'Sepeda Statis Reclined (Senderan Punggung)',
        'name': 'Sepeda Statis Reclined',
        'targetText': '25-40 menit',
        'heroImg': 'assets/progress/clean/hero_cycling.png',
        'thumbImg': 'assets/progress/clean/thumb_cycling.png',
        'thumb': 'assets/progress/clean/rec_thumb_cycling.png',
        'icon': 'assets/progress/clean/rec_icon_cycling.png',
        'desc': 'Sandaran punggung ergonomis menopang tubuh dengan posisi kaki ke depan, meminimalkan kompresi lutut.',
        'duration': '25-40 menit',
        'frequency': '4-5x/minggu',
        'intensity': 'Ringan-Sedang (45-55% HRmax)',
        'calories': '140-260 kkal',
        'safetyNotes':
            'Jangan berdiri saat mengayuh. Selalu duduk stabil bersandar dan jaga denyut nadi dalam batas nyaman (talk test).',
        'aboutTitle': 'Tentang Sepeda Statis Reclined',
        'aboutDesc':
            'Sepeda statis bersandar (recumbent) memberikan penyangga penuh pada tulang belakang lumbal dan panggul, menjadikannya pilihan kardio darat paling aman bagi Obesitas Tingkat II.',
        'benefits': [
          'Sangat aman bagi penderita dengan gejala nyeri punggung bawah atau lutut',
          'Membantu sirkulasi darah tanpa memicu pembengkakan kaki',
          'Mendukung program penurunan berat badan di bawah pengawasan medis',
        ],
        'specs': {
          'duration': '25-40 menit',
          'frequency': '4-5 kali/minggu',
          'intensity': 'Ringan-Sedang (45-55% HRmax)',
          'calories': '140-260 kkal',
        },
        'tipsTitle': 'Tips Sepeda Statis Reclined',
        'tips': [
          habitTip,
          'Mulai dengan kayuhan santai 5 menit pertama.',
          'Bila lelah, kurangi kecepatan kayuhan namun jangan berhenti mendadak.',
          'Siapkan air minum di dekat sepeda untuk hidrasi teratur.',
        ],
        'refLink': 'https://papdi.or.id/pdfs/1422/Soft%20copy%20konsensus%20obesitas.pdf',
      },
      {
        'id': 'obesitas2_chair_workout',
        'title': 'Latihan Penguatan di Kursi (Chair Workout)',
        'name': 'Latihan Penguatan di Kursi',
        'targetText': '15-25 menit',
        'heroImg': 'assets/progress/clean/hero_bodyweight.png',
        'thumbImg': 'assets/progress/clean/thumb_bodyweight.png',
        'thumb': 'assets/progress/clean/rec_thumb_bodyweight.png',
        'icon': 'assets/progress/clean/rec_icon_bodyweight.png',
        'desc': 'Latihan penguatan otot paha, betis, dan lengan dalam posisi duduk stabil di atas kursi.',
        'duration': '15-25 menit',
        'frequency': '3x/minggu',
        'intensity': 'Ringan (40-50% HRmax)',
        'calories': '80-150 kkal',
        'safetyNotes':
            'Gunakan kursi yang stabil dan tidak beroda. Jangan melakukan gerakan sentakan mendadak.',
        'aboutTitle': 'Tentang Latihan Penguatan Kursi',
        'aboutDesc':
            'Gerakan seated leg extension, seated calf raise, dan seated arm reach melatih kelompok otot utama tanpa menanggung beban gravitasi penuh tubuh saat berdiri.',
        'benefits': [
          'Memperkuat otot paha tanpa membebani persendian',
          'Meningkatkan kestabilan saat bangkit dari posisi duduk',
          'Aman dari risiko kehilangan keseimbangan',
        ],
        'specs': {
          'duration': '15-25 menit',
          'frequency': '3 kali/minggu',
          'intensity': 'Ringan (40-50% HRmax)',
          'calories': '80-150 kkal',
        },
        'tipsTitle': 'Tips Latihan Kursi',
        'tips': [
          habitTip,
          'Duduk tegak di kursi dengan punggung menempel pada sandaran.',
          'Lakukan gerakan mengangkat ujung kaki (leg extension) secara bergantian.',
          'Tahan 2-3 detik di atas lalu turunkan perlahan.',
        ],
        'refLink': 'https://doi.org/10.21831/jk.v8i1.31208',
      },
      {
        'id': 'obesitas2_fractional_walk',
        'title': 'Jalan Santai Fraksionasi (2 Sesi x 15 Menit)',
        'name': 'Jalan Santai Fraksionasi',
        'targetText': '2 sesi x 15 menit',
        'heroImg': 'assets/progress/clean/hero_jogging.png',
        'thumbImg': 'assets/progress/clean/thumb_jogging.png',
        'thumb': 'assets/progress/clean/rec_thumb_jogging.png',
        'icon': 'assets/progress/clean/rec_icon_jogging.png',
        'desc': 'Membagi jalan santai menjadi 2 sesi 15 menit (pagi dan sore) untuk menjaga kenyamanan persendian.',
        'duration': '2 sesi x 15 menit',
        'frequency': '4-5x/minggu',
        'intensity': 'Ringan (40-50% HRmax)',
        'calories': '120-200 kkal',
        'safetyNotes':
            'Hindari jalan menanjak atau menurun terjal. Hentikan jika timbul nyeri lutut, nyeri dada, atau napas tersengal.',
        'aboutTitle': 'Tentang Jalan Fraksionasi',
        'aboutDesc':
            'Pendekatan fraksionasi (membagi durasi latihan menjadi 2 kali 15 menit sehari) terbukti sama efektifnya membakar kalori harian namun jauh lebih ramah terhadap toleransi sendi.',
        'benefits': [
          'Mencegah akumulasi kelelahan pada otot dan sendi tungkai',
          'Menjaga tubuh tetap aktif dan memecah waktu duduk lama (sedentary time)',
          'Meningkatkan kapasitas sirkulasi pernapasan secara aman',
        ],
        'specs': {
          'duration': '2 sesi x 15 menit',
          'frequency': '4-5 kali/minggu',
          'intensity': 'Ringan (40-50% HRmax)',
          'calories': '120-200 kkal',
        },
        'tipsTitle': 'Tips Jalan Fraksionasi',
        'tips': [
          habitTip,
          'Lakukan sesi 1: 15 menit di pagi hari sebelum beraktivitas.',
          'Lakukan sesi 2: 15 menit di sore hari menjelang matahari terbenam.',
          'Gunakan sepatu yang empuk dan fleksibel.',
        ],
        'refLink': 'https://papdi.or.id/pdfs/1422/Soft%20copy%20konsensus%20obesitas.pdf',
      },
    ];
  }

  // =========================================================================
  // 5. KATEGORI OBESITAS III (Sangat Ringan, Fungsional, Perlindungan Total & Medis)
  // =========================================================================
  List<Map<String, dynamic>> _getObesitas3Activities(SkriningData? data) {
    final habitTip = _getHabitTip(data);

    return [
      {
        'id': 'obesitas3_hydrotherapy',
        'title': 'Terapi Gerak Air Terawasi (Hydrotherapy)',
        'name': 'Terapi Gerak Air (Hydrotherapy)',
        'targetText': '15-20 menit',
        'heroImg': 'assets/progress/clean/hero_swimming.png',
        'thumbImg': 'assets/progress/clean/thumb_swimming.png',
        'thumb': 'assets/progress/clean/rec_thumb_swimming.png',
        'icon': 'assets/progress/clean/rec_icon_swimming.png',
        'desc':
            'Gerak fungsional dan berjalan di air kolam setinggi dada dengan daya apung yang meniadakan 90% beban gravitasi sendi.',
        'duration': '15-20 menit',
        'frequency': '2-3x/minggu',
        'intensity': 'Sangat Ringan-Ringan (30-45% HRmax)',
        'calories': '80-140 kkal',
        'safetyNotes':
            'Wajib didampingi dan pastikan suhu air nyaman (tidak terlalu dingin). Hentikan jika lemas, sesak, atau dada berdebar.',
        'aboutTitle': 'Tentang Terapi Gerak Air Terawasi',
        'aboutDesc':
            'Pada Obesitas Kelas III (Morbid), daya apung air (buoyancy) menghilangkan hingga 90% beban gravitasi pada sendi dan tulang belakang, menjadikannya modalitas paling aman untuk mengaktifkan metabolisme tanpa trauma muskuloskeletal.',
        'benefits': [
          'Menghilangkan tekanan kompresi pada sendi lutut, panggul, dan tulang belakang',
          'Membantu pembakaran kalori metabolik tanpa risiko cedera benturan mekanis',
          'Meningkatkan kelancaran aliran darah balik vena dan mengurangi pembengkakan tungkai',
        ],
        'specs': {
          'duration': '15-20 menit',
          'frequency': '2-3 kali/minggu',
          'intensity': 'Sangat Ringan-Ringan (30-45% HRmax)',
          'calories': '80-140 kkal',
        },
        'tipsTitle': 'Tips Terapi Air',
        'tips': [
          habitTip,
          'Cukup berjalan santai maju, mundur, dan menyamping di kolam setinggi dada.',
          'Gunakan pegangan pinggir kolam jika keseimbangan masih terasa goyah.',
          'Awali dengan durasi 10 menit dan tingkatkan perlahan sesuai daya tahan tubuh.',
        ],
        'refLink':
            'https://keslan.kemkes.go.id/unduhan/KMK%20No.%20HK.01.07-MENKES-509-2025.pdf',
      },
      {
        'id': 'obesitas3_recumbent_bike',
        'title': 'Sepeda Statis Recumbent (Kayuhan Sangat Santai)',
        'name': 'Sepeda Statis Recumbent',
        'targetText': '10-15 menit',
        'heroImg': 'assets/progress/clean/hero_cycling.png',
        'thumbImg': 'assets/progress/clean/thumb_cycling.png',
        'thumb': 'assets/progress/clean/rec_thumb_cycling.png',
        'icon': 'assets/progress/clean/rec_icon_cycling.png',
        'desc':
            'Posisi duduk bersandar menyangga punggung dan panggul secara optimal dengan kayuhan sangat ringan tanpa beban gir.',
        'duration': '10-15 menit',
        'frequency': '3-4x/minggu',
        'intensity': 'Sangat Ringan (30-45% HRmax)',
        'calories': '60-110 kkal',
        'safetyNotes':
            'Wajib konsultasi dokter sebelum memulai. Hentikan latihan jika sesak napas, pusing berputar, atau denyut nadi melonjak tinggi.',
        'aboutTitle': 'Tentang Sepeda Statis Recumbent',
        'aboutDesc':
            'Recumbent bike memiliki sandaran punggung yang kokoh dan posisi pedal di depan badan sehingga beban gravitasi pada tulang belakang dan lutut hampir nol, menjaga stabilitas sirkulasi kardiopulmonal.',
        'benefits': [
          'Memberikan proteksi total bagi persendian lutut dan tulang belakang',
          'Membantu aktivasi sirkulasi kardiopulmonal tanpa risiko pusing postural',
          'Mencegah risiko kelelahan ekstrem dan sesak napas',
        ],
        'specs': {
          'duration': '10-15 menit',
          'frequency': '3-4 kali/minggu',
          'intensity': 'Sangat Ringan (30-45% HRmax)',
          'calories': '60-110 kkal',
        },
        'tipsTitle': 'Tips Recumbent Bike',
        'tips': [
          habitTip,
          'Atur posisi kursi agar punggung tersangga penuh dengan nyaman.',
          'Kayuh dengan ritme sangat santai tanpa hambatan resistensi beban berat.',
          'Beri jeda istirahat 1-2 menit tiap mengayuh 5 menit bila diperlukan.',
        ],
        'refLink':
            'https://keslan.kemkes.go.id/unduhan/KMK%20No.%20HK.01.07-MENKES-509-2025.pdf',
      },
      {
        'id': 'obesitas3_seated_rom',
        'title': 'Gerak Sendi Duduk (Seated Range of Motion)',
        'name': 'Gerak Sendi Duduk (Seated ROM)',
        'targetText': '10-15 menit',
        'heroImg': 'assets/progress/clean/hero_bodyweight.png',
        'thumbImg': 'assets/progress/clean/thumb_bodyweight.png',
        'thumb': 'assets/progress/clean/rec_thumb_bodyweight.png',
        'icon': 'assets/progress/clean/rec_icon_bodyweight.png',
        'desc':
            'Rotasi pergelangan kaki, lutut santai, bahu, dan leher secara lembut dalam posisi duduk tegak di kursi bersandar kokoh.',
        'duration': '10-15 menit',
        'frequency': '3-5x/minggu',
        'intensity': 'Sangat Ringan (30-40% HRmax)',
        'calories': '40-70 kkal',
        'safetyNotes':
            'Gunakan kursi yang kokoh dengan sandaran punggung dan tanpa roda. Pastikan telapak kaki menapak rata di lantai.',
        'aboutTitle': 'Tentang Gerak Sendi Duduk',
        'aboutDesc':
            'Mempertahankan jangkauan gerak sendi (Range of Motion) tubuh bagian atas dan bawah agar terhindar dari kekakuan muskuloskeletal dan edema tungkai bawah.',
        'benefits': [
          'Memperlancar sirkulasi darah ke ujung jari kaki dan tangan',
          'Meringankan ketegangan otot pada leher, bahu, dan punggung',
          'Mencegah risiko pembengkakan cairan (edema) pada tungkai',
        ],
        'specs': {
          'duration': '10-15 menit',
          'frequency': '3-5 kali/minggu',
          'intensity': 'Sangat Ringan (30-40% HRmax)',
          'calories': '40-70 kkal',
        },
        'tipsTitle': 'Tips Gerak Sendi Duduk',
        'tips': [
          habitTip,
          'Lakukan gerakan ankle pump (dorong dan tarik pergelangan kaki) perlahan.',
          'Angkat kedua bahu perlahan ke arah telinga lalu turunkan rileks.',
          'Lakukan seluruh gerakan secara ritmis dan tenang tanpa hentakan.',
        ],
        'refLink': 'https://doi.org/10.21831/jk.v8i1.31208',
      },
      {
        'id': 'obesitas3_breathing',
        'title': 'Latihan Pernapasan Diafragma & Postur Terkendali',
        'name': 'Latihan Pernapasan Diafragma',
        'targetText': '10-15 menit',
        'heroImg': 'assets/progress/clean/hero_yoga.png',
        'thumbImg': 'assets/progress/clean/thumb_yoga.png',
        'thumb': 'assets/progress/clean/rec_thumb_yoga.png',
        'icon': 'assets/progress/clean/rec_icon_yoga.png',
        'desc':
            'Latihan pernapasan diafragma terfokus untuk melatih kapasitas paru-paru yang tertekan oleh lemak intra-abdomen.',
        'duration': '10-15 menit',
        'frequency': 'Setiap hari',
        'intensity': 'Sangat Ringan',
        'calories': '30-50 kkal',
        'safetyNotes':
            'Bernapaslah dengan ritme wajar. Bila merasa pusing atau hiperventilasi, rileks dan bernapaslah biasa.',
        'aboutTitle': 'Tentang Latihan Pernapasan Diafragma',
        'aboutDesc':
            'Pada obesitas tingkat lanjut, tumpukan lemak intra-abdomen membatasi gerak kubah diafragma. Latihan pernapasan dalam melatih kembali otot diafragma dan memaksimalkan saturasi oksigen.',
        'benefits': [
          'Memperluas kapasitas fungsional ventilasi paru-paru',
          'Meringankan kerja otot bantu napas di leher dan bahu',
          'Menstimulasi sistem saraf parasimpatis untuk meredakan kecemasan',
        ],
        'specs': {
          'duration': '10-15 menit',
          'frequency': 'Setiap hari',
          'intensity': 'Sangat Ringan',
          'calories': '30-50 kkal',
        },
        'tipsTitle': 'Tips Pernapasan Diafragma',
        'tips': [
          habitTip,
          'Duduk santai dengan satu tangan di dada dan satu tangan di perut atas.',
          'Tarik napas perlahan melalui hidung (3 detik) hingga perut mengembang.',
          'Hembuskan napas perlahan melalui bibir mengerucut (pursed-lip) 4-5 detik.',
        ],
        'refLink': 'https://doi.org/10.48144/jiks.v9i2.56',
      },
    ];
  }

  // =========================================================================
  // 6. KATEGORI UNDERWEIGHT (Peningkatan Massa Otot & Batasi Kardio Panjang)
  // =========================================================================
  List<Map<String, dynamic>> _getUnderweightActivities(SkriningData? data) {
    final habitTip = _getHabitTip(data);

    return [
      {
        'id': 'underweight_strength',
        'title': 'Latihan Beban & Angkat Beban (Strength Training)',
        'name': 'Latihan Beban & Kekuatan (Strength)',
        'targetText': '25-35 menit',
        'heroImg': 'assets/progress/clean/hero_bodyweight.png',
        'thumbImg': 'assets/progress/clean/thumb_bodyweight.png',
        'thumb': 'assets/progress/clean/rec_thumb_bodyweight.png',
        'icon': 'assets/progress/clean/rec_icon_bodyweight.png',
        'desc':
            'Fokus utama stimulasi hipertrofi serat otot melalui latihan beban bertahap untuk menambah berat badan sehat berupa massa otot padat.',
        'duration': '25-35 menit',
        'frequency': '3-4x/minggu',
        'intensity': 'Sedang (55-70% HRmax)',
        'calories': '130-220 kkal',
        'safetyNotes':
            'Pastikan asupan makanan kaya protein dan kalori kompleks dikonsumsi dalam 1-2 jam setelah sesi latihan beban.',
        'aboutTitle': 'Tentang Latihan Kekuatan untuk Underweight',
        'aboutDesc':
            'Pada kategori berat badan kurang, peningkatan berat badan harus diprioritaskan pada penambahan massa otot bebas lemak (lean muscle mass). Latihan resistensi memberikan sinyal biologis penting untuk sintesis protein otot.',
        'benefits': [
          'Memicu hipertrofi dan sintesis pembentukan massa otot baru',
          'Meningkatkan nafsu makan alami dan efisiensi metabolisme gizi',
          'Meningkatkan kepadatan mineral tulang dan kekuatan fungsional',
          'Membentuk postur tubuh yang lebih kokoh, berisi, dan tegap',
        ],
        'specs': {
          'duration': '25-35 menit',
          'frequency': '3-4 kali/minggu',
          'intensity': 'Sedang (55-70% HRmax)',
          'calories': '130-220 kkal',
        },
        'tipsTitle': 'Tips Latihan Beban',
        'tips': [
          habitTip,
          'Fokus pada rentang 8-12 repetisi dengan beban terkontrol (dumbbell ringan / resistance band).',
          'Gunakan gerakan majemuk: goblet squat, dumbbell bench press, dan seated row.',
          'Beri jeda istirahat 60-90 detik antar set agar tenaga pulih maksimal.',
        ],
        'refLink': 'https://doi.org/10.21831/jk.v8i1.31208',
      },
      {
        'id': 'underweight_calisthenics',
        'title': 'Kalistenik Kompon (Push-up, Inverted Row & Squat)',
        'name': 'Kalistenik Kompon (Bodyweight)',
        'targetText': '20-30 menit',
        'heroImg': 'assets/progress/clean/hero_bodyweight.png',
        'thumbImg': 'assets/progress/clean/thumb_bodyweight.png',
        'thumb': 'assets/progress/clean/rec_thumb_bodyweight.png',
        'icon': 'assets/progress/clean/rec_icon_bodyweight.png',
        'desc':
            'Latihan penguatan otot majemuk memanfaatkan beban tubuh sendiri dengan variasi knee push-up, glute bridge, dan chair dips.',
        'duration': '20-30 menit',
        'frequency': '3x/minggu',
        'intensity': 'Sedang (50-65% HRmax)',
        'calories': '110-180 kkal',
        'safetyNotes':
            'Gunakan tumpuan lutut jika push-up standar masih terasa berat. Jangan memaksakan repetisi jika bentuk postur mulai melengkung.',
        'aboutTitle': 'Tentang Kalistenik Kompon',
        'aboutDesc':
            'Gerakan gabungan (compound movement) merekrut banyak kelompok otot secara simultan, merangsang pelepasan hormon pertumbuhan alami tubuh untuk membangun massa otot fungsional.',
        'benefits': [
          'Membangun fondasi kekuatan fungsional seluruh tubuh',
          'Meningkatkan koordinasi neuromuskular dan kontrol gerak',
          'Dapat dilakukan di mana saja secara fleksibel tanpa peralatan rumit',
        ],
        'specs': {
          'duration': '20-30 menit',
          'frequency': '3 kali/minggu',
          'intensity': 'Sedang (50-65% HRmax)',
          'calories': '110-180 kkal',
        },
        'tipsTitle': 'Tips Kalistenik',
        'tips': [
          habitTip,
          'Lakukan knee push-up 3 set x 8-10 repetisi dengan teknik rapi.',
          'Lakukan bodyweight squat dengan tempo terkontrol (turun 2 detik, naik 1 detik).',
          'Jaga ritme napas: hembuskan saat mendorong/mengangkat badan.',
        ],
        'refLink': 'https://doi.org/10.21831/jk.v8i1.31208',
      },
      {
        'id': 'underweight_core',
        'title': 'Latihan Otot Inti & Stabilitas Postur (Core & Plank)',
        'name': 'Latihan Otot Inti & Postur',
        'targetText': '15-20 menit',
        'heroImg': 'assets/progress/clean/hero_bodyweight.png',
        'thumbImg': 'assets/progress/clean/thumb_bodyweight.png',
        'thumb': 'assets/progress/clean/rec_thumb_bodyweight.png',
        'icon': 'assets/progress/clean/rec_icon_bodyweight.png',
        'desc':
            'Memperkuat otot transversus abdominis, dinding perut, dan punggung bawah untuk memperbaiki postur tubuh yang bungkuk.',
        'duration': '15-20 menit',
        'frequency': '3x/minggu',
        'intensity': 'Sedang (50-65% HRmax)',
        'calories': '80-140 kkal',
        'safetyNotes':
            'Jaga punggung tetap rata sejajar, hindari pinggang melengkung ke bawah saat menahan posisi plank.',
        'aboutTitle': 'Tentang Latihan Otot Inti & Postur',
        'aboutDesc':
            'Penguatan otot penopang tulang belakang membantu mengatasi postur tubuh bungkuk yang kerap terjadi pada individu dengan massa otot kurang, memberikan kestabilan sentral yang kuat.',
        'benefits': [
          'Mengoreksi postur tubuh agar tampak lebih tegap dan percaya diri',
          'Memperkuat stabilitas panggul dan tulang belakang',
          'Mencegah risiko nyeri punggung saat beraktivitas harian',
        ],
        'specs': {
          'duration': '15-20 menit',
          'frequency': '3 kali/minggu',
          'intensity': 'Sedang (50-65% HRmax)',
          'calories': '80-140 kkal',
        },
        'tipsTitle': 'Tips Latihan Inti',
        'tips': [
          habitTip,
          'Tahan plank 20-30 detik dengan garis bahu, pinggul, dan tumit sejajar lurus.',
          'Kombinasikan dengan bird-dog 8-10 repetisi per sisi untuk keseimbangan.',
          'Pertahankan pernapasan teratur, hindari menahan napas saat kontraksi.',
        ],
        'refLink': 'https://doi.org/10.21831/jk.v8i1.31208',
      },
      {
        'id': 'underweight_recovery',
        'title': 'Peregangan Pemulihan & Mobilitas (Stretching & Light Walk)',
        'name': 'Peregangan Pemulihan & Mobilitas',
        'targetText': '15-20 menit',
        'heroImg': 'assets/progress/clean/hero_yoga.png',
        'thumbImg': 'assets/progress/clean/thumb_yoga.png',
        'thumb': 'assets/progress/clean/rec_thumb_yoga.png',
        'icon': 'assets/progress/clean/rec_icon_yoga.png',
        'desc':
            'Peregangan relaksasi dan jalan rileks singkat untuk melancarkan sirkulasi tanpa membakar surplus kalori yang dibutuhkan tubuh.',
        'duration': '15-20 menit',
        'frequency': '2-3x/minggu',
        'intensity': 'Ringan (35-45% HRmax)',
        'calories': '60-100 kkal',
        'safetyNotes':
            'Batasi kardio durasi panjang (seperti lari jarak jauh atau maraton) agar kalori surplus makanan tidak terbuang percuma.',
        'aboutTitle': 'Tentang Pemulihan & Batasan Kardio',
        'aboutDesc':
            'Bagi individu dengan berat badan kurang, olahraga kardio berdurasi panjang kontraproduktif karena menghabiskan kalori surplus yang seharusnya digunakan untuk sintesis otot. Peregangan pemulihan ringan melancarkan sirkulasi tanpa pembakaran kalori berlebih.',
        'benefits': [
          'Mempercepat pemulihan mikro lesi serat otot pasca latihan kekuatan',
          'Meningkatkan fleksibilitas persendian dan mobilitas gerak tubuh',
          'Mencegah defisit kalori tak terduga agar target kenaikan berat badan tercapai',
        ],
        'specs': {
          'duration': '15-20 menit',
          'frequency': '2-3 kali/minggu',
          'intensity': 'Ringan (35-45% HRmax)',
          'calories': '60-100 kkal',
        },
        'tipsTitle': 'Tips Peregangan Pemulihan',
        'tips': [
          habitTip,
          'Lakukan peregangan dinamis dan statis lembut pada otot paha, dada, dan punggung.',
          'Hindari kardio lari cepat berdurasi lama (>30 menit).',
          'Minum susu atau konsumsi camilan bernutrisi padat sesaat setelah sesi latihan.',
        ],
        'refLink': 'https://doi.org/10.25182/jgp.2016.11.3.%25p',
      },
    ];
  }
}

