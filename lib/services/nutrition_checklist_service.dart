import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/nutrition_meal_model.dart';
import 'calorie_target_service.dart';
import 'meal_plan_service.dart';
import 'auth_service.dart';

/// Service untuk memantau menu makanan dan minuman yang telah dikonsumsi (diceklis) per tanggal.
/// Mendukung penyimpanan offline-first di SharedPreferences dan sinkronisasi real-time
/// ke Google Cloud Firestore (project 'obesight') di bawah path:
/// `users/{uid}/nutrition_progress/{yyyy-MM-dd}`
class NutritionChecklistService extends ChangeNotifier {
  static final NutritionChecklistService _instance =
      NutritionChecklistService._internal();
  factory NutritionChecklistService() => _instance;
  static NutritionChecklistService get instance => _instance;

  static const String _prefKey = 'nutrition_checklist_completed_v1';
  static const String _migrationPrefix = 'nutrition_migrated_v1_';

  // Map dari dateKey ('yyyy-MM-dd') -> Set of completed item IDs
  final Map<String, Set<String>> _completedItemsByDate = {};

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _firestoreSubscription;

  bool get _isFirebaseAvailable => Firebase.apps.isNotEmpty;

  String? _cachedActiveUid;

  String? get _currentFirebaseUid {
    try {
      if (_isFirebaseAvailable) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && user.uid.isNotEmpty) {
          _cachedActiveUid = user.uid;
          return user.uid;
        }
      }
    } catch (e) {
      debugPrint('[NutritionChecklistService] Notice checking Firebase Auth UID: $e');
    }
    try {
      final authUser = AuthService().currentUser;
      if (authUser != null &&
          authUser.id.isNotEmpty &&
          !authUser.id.startsWith('usr_') &&
          !authUser.id.startsWith('adm_')) {
        _cachedActiveUid = authUser.id;
        return authUser.id;
      }
    } catch (e) {
      debugPrint('[NutritionChecklistService] Notice checking AuthService user: $e');
    }
    return _cachedActiveUid;
  }

  NutritionChecklistService._internal() {
    _loadFromStorage().then((_) {
      _initAuthAndFirestoreSync();
    });
  }

  void _initAuthAndFirestoreSync() {
    if (!_isFirebaseAvailable) return;
    try {
      // 1. Sinkronisasi awal jika sudah ada akun aktif yang login
      final initialUid = _currentFirebaseUid;
      if (initialUid != null) {
        debugPrint('[NutritionChecklistService] Terdeteksi akun login: $initialUid. Memulai sinkronisasi...');
        _startFirestoreListener(initialUid);
        _migrateLegacyDataToFirestore(initialUid);
      }

      // 2. Pasang pendengar perubahan autentikasi (login/logout/switch user)
      _authSubscription?.cancel();
      _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
        final activeUid = user?.uid ?? _currentFirebaseUid;
        if (activeUid != null) {
          debugPrint('[NutritionChecklistService] Auth state change terdeteksi: $activeUid');
          _startFirestoreListener(activeUid);
          _migrateLegacyDataToFirestore(activeUid);
        } else {
          _firestoreSubscription?.cancel();
          _firestoreSubscription = null;
        }
      });
    } catch (e) {
      debugPrint('[NutritionChecklistService] Init auth/Firestore sync notice: $e');
    }
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUid = prefs.getString('obesight_active_user_id');
      if (savedUid != null && savedUid.isNotEmpty && !savedUid.startsWith('usr_') && !savedUid.startsWith('adm_')) {
        _cachedActiveUid = savedUid;
      }

      final jsonString = prefs.getString(_prefKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
        _completedItemsByDate.clear();
        decoded.forEach((key, val) {
          if (val is List) {
            _completedItemsByDate[key] = val.map((e) => e.toString()).toSet();
          }
        });
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[NutritionChecklistService] Error loading from storage: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapToSerialize = <String, List<String>>{};
      _completedItemsByDate.forEach((key, set) {
        mapToSerialize[key] = set.toList();
      });
      await prefs.setString(_prefKey, jsonEncode(mapToSerialize));
    } catch (e) {
      debugPrint('[NutritionChecklistService] Error saving to storage: $e');
    }
  }

  /// Reset checklist untuk siklus skrining baru (agar grafik dan progres mulai dari nol/kosong)
  Future<void> resetForNewScreeningCycle() async {
    _completedItemsByDate.clear();
    await _saveToStorage();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.uid.isNotEmpty) {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('nutrition_progress')
            .get();
        for (final doc in snap.docs) {
          await doc.reference.delete();
        }

        final rootSnap = await FirebaseFirestore.instance
            .collection('nutrition_progress')
            .where('userId', isEqualTo: user.uid)
            .get();
        for (final doc in rootSnap.docs) {
          await doc.reference.delete();
        }
      }
    } catch (e) {
      debugPrint('[NutritionChecklistService] Reset Firestore error: $e');
    }

    notifyListeners();
  }

  /// Memulai pendengar dokumen Firestore secara real-time untuk pengguna aktif
  void _startFirestoreListener(String uid) {
    try {
      _firestoreSubscription?.cancel();
      _firestoreSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('nutrition_progress')
          .snapshots()
          .listen((snapshot) {
        final syncedMap = <String, Set<String>>{};
        for (final doc in snapshot.docs) {
          final dateKey = doc.id;
          final data = doc.data();
          final items = data['items'] as List<dynamic>? ?? [];
          final itemIds = items
              .map((it) => (it is Map ? it['mealId']?.toString() : null))
              .whereType<String>()
              .toSet();

          if (itemIds.isNotEmpty) {
            syncedMap[dateKey] = itemIds;
          }
        }
        _completedItemsByDate.clear();
        _completedItemsByDate.addAll(syncedMap);
        _saveToStorage();
        notifyListeners();
      }, onError: (err) {
        debugPrint('[NutritionChecklistService] Firestore realtime listener notice: $err');
      });
    } catch (e) {
      debugPrint('[NutritionChecklistService] Start Firestore listener error: $e');
    }
  }

  /// Migrasi data dari SharedPreferences ke Cloud Firestore
  Future<void> _migrateLegacyDataToFirestore(String uid, {bool force = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final migrationKey = '$_migrationPrefix$uid';
      if (!force && prefs.getBool(migrationKey) == true) {
        debugPrint('[NutritionChecklistService] Data lokal sudah termigrasi untuk UID: $uid');
        return;
      }

      if (_completedItemsByDate.isEmpty) {
        await prefs.setBool(migrationKey, true);
        return;
      }

      debugPrint('[NutritionChecklistService] Memulai migrasi ${_completedItemsByDate.length} tanggal ke Firestore untuk $uid...');

      final rawCategory = CalorieTargetService.getLatestScreeningCategoryRaw(userId: uid);
      if (rawCategory == null) {
        debugPrint('[NutritionChecklistService] Skip migrasi: pengguna $uid belum memiliki hasil skrining.');
        return;
      }
      final group = CalorieTargetService.resolveGroup(rawCategory);
      final targetCalories = CalorieTargetService.getDailyCalorieTarget(group);

      for (final entry in _completedItemsByDate.entries) {
        final dateKey = entry.key;
        final itemIds = entry.value;
        if (itemIds.isEmpty) continue;

        final parsedDate = DateTime.tryParse(dateKey) ?? DateTime.now();
        final dailyMeals = MealPlanService.getDailyPlanForDate(date: parsedDate, group: group);

        final items = <Map<String, dynamic>>[];
        int consumed = 0;
        for (final id in itemIds) {
          final meal = dailyMeals.firstWhere(
            (m) => m.id == id,
            orElse: () => MealPlanService.getMealById(id) ?? _createFallbackMeal(id),
          );
          consumed += meal.calories;
          items.add({
            'mealId': meal.id,
            'name': meal.name,
            'type': meal.type,
            'mealTime': meal.mealTime,
            'calories': meal.calories,
            'protein': meal.protein,
            'carbs': meal.carbs,
            'fat': meal.fat,
            'portionGram': meal.portionGram,
            'checkedAt': Timestamp.fromDate(parsedDate),
          });
        }

        final docPayload = <String, dynamic>{
          'userId': uid,
          'date': dateKey,
          'categoryAtThatTime': rawCategory,
          'targetCalories': targetCalories,
          'consumedCalories': consumed,
          'completedCount': itemIds.length,
          'totalCount': dailyMeals.length,
          'plannedMealIds': dailyMeals.map((m) => m.id).toList(),
          'items': items,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // 1. Simpan di sub-koleksi users/{uid}/nutrition_progress/{dateKey}
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('nutrition_progress')
            .doc(dateKey);
        await docRef.set(docPayload, SetOptions(merge: true));

        // 2. Simpan di koleksi utama nutrition_progress/{uid_dateKey} (muncul langsung di panel kiri console)
        final rootRef = FirebaseFirestore.instance
            .collection('nutrition_progress')
            .doc('${uid}_$dateKey');
        await rootRef.set(docPayload, SetOptions(merge: true));

        debugPrint('[NutritionChecklistService] Berhasil migrasi tanggal $dateKey ke Firestore (Root & Sub-koleksi)!');
      }

      await prefs.setBool(migrationKey, true);
      debugPrint('[NutritionChecklistService] Migrasi ke Firestore selesai untuk $uid!');
    } catch (e) {
      debugPrint('[NutritionChecklistService] Error during legacy migration: $e');
    }
  }

  /// Inisialisasi dokumen progress hari ini secara otomatis saat halaman dibuka
  /// agar koleksi 'nutrition_progress' langsung muncul di panel kiri Firebase Console
  Future<void> initDailyProgressIfNeeded({String? dateKey}) async {
    final uid = _currentFirebaseUid;
    if (uid == null || uid.isEmpty) return;

    final targetDateKey = dateKey ?? todayKey;
    final parsedDate = DateTime.tryParse(targetDateKey) ?? DateTime.now();
    final rawCategory = CalorieTargetService.getLatestScreeningCategoryRaw(userId: uid);
    if (rawCategory == null) {
      debugPrint('[NutritionChecklistService] Skip inisialisasi progress harian: pengguna $uid belum memiliki hasil skrining.');
      return;
    }
    final group = CalorieTargetService.resolveGroup(rawCategory);
    final targetCalories = CalorieTargetService.getDailyCalorieTarget(group);
    final dailyMeals = MealPlanService.getDailyPlanForDate(date: parsedDate, group: group);

    final completedIds = getCompletedForDate(targetDateKey);
    final items = <Map<String, dynamic>>[];
    int consumed = 0;

    for (final id in completedIds) {
      final meal = dailyMeals.firstWhere(
        (m) => m.id == id,
        orElse: () => MealPlanService.getMealById(id) ?? _createFallbackMeal(id),
      );
      consumed += meal.calories;
      items.add({
        'mealId': meal.id,
        'name': meal.name,
        'type': meal.type,
        'mealTime': meal.mealTime,
        'calories': meal.calories,
        'protein': meal.protein,
        'carbs': meal.carbs,
        'fat': meal.fat,
        'portionGram': meal.portionGram,
        'checkedAt': Timestamp.now(),
      });
    }

    final payload = <String, dynamic>{
      'userId': uid,
      'date': targetDateKey,
      'categoryAtThatTime': rawCategory,
      'targetCalories': targetCalories,
      'consumedCalories': consumed,
      'completedCount': items.length,
      'totalCount': dailyMeals.length,
      'plannedMealIds': dailyMeals.map((m) => m.id).toList(),
      'items': items,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      // Simpan di Koleksi Utama 'nutrition_progress'
      final rootRef = FirebaseFirestore.instance
          .collection('nutrition_progress')
          .doc('${uid}_$targetDateKey');
      final rootSnap = await rootRef.get();
      if (!rootSnap.exists) {
        payload['createdAt'] = FieldValue.serverTimestamp();
      }
      await rootRef.set(payload, SetOptions(merge: true));

      // Simpan juga di sub-koleksi users/{uid}/nutrition_progress
      final subRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('nutrition_progress')
          .doc(targetDateKey);
      await subRef.set(payload, SetOptions(merge: true));

      debugPrint('[NutritionChecklistService] Inisialisasi progress $targetDateKey berhasil disimpan ke Firestore!');
    } catch (e) {
      debugPrint('[NutritionChecklistService] Notice inisialisasi progress ke Firestore: $e');
    }
  }

  /// Sinkronisasi paksa seluruh data lokal ke Firestore untuk pengguna aktif
  Future<void> syncAllToFirestore() async {
    final uid = _currentFirebaseUid;
    if (uid == null || uid.isEmpty) return;
    final rawCategory = CalorieTargetService.getLatestScreeningCategoryRaw(userId: uid);
    if (rawCategory == null) {
      debugPrint('[NutritionChecklistService] Skip syncAllToFirestore: pengguna $uid belum memiliki hasil skrining.');
      return;
    }
    await initDailyProgressIfNeeded();
    await _migrateLegacyDataToFirestore(uid, force: true);
  }

  String formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String get todayKey => formatDateKey(DateTime.now());

  bool isCompleted(String dateKey, String itemId) {
    return _completedItemsByDate[dateKey]?.contains(itemId) ?? false;
  }

  Map<String, Set<String>> get completedItemsByDate => _completedItemsByDate;

  Set<String> getCompletedForDate(String dateKey) {
    return _completedItemsByDate[dateKey] ?? const <String>{};
  }

  int getCompletedCountForDate(String dateKey) {
    return _completedItemsByDate[dateKey]?.length ?? 0;
  }

  /// Menandai item telah dikonsumsi (permanen, tidak bisa uncheck).
  /// Menyimpan offline ke SharedPreferences seketika, lalu menyinkronkan
  /// ke Cloud Firestore (`users/{uid}/nutrition_progress/{dateKey}`).
  Future<void> completeItem(
    String dateKey,
    String itemId, {
    NutritionMealModel? meal,
    List<NutritionMealModel>? dailyMeals,
  }) async {
    // Tidak dapat menandai ceklis jika belum ada hasil skrining
    final rawCategory = CalorieTargetService.getLatestScreeningCategoryRaw(userId: _currentFirebaseUid);
    if (rawCategory == null) {
      debugPrint('[NutritionChecklistService] Ceklis diabaikan: pengguna belum memiliki hasil skrining.');
      return;
    }

    if (!_completedItemsByDate.containsKey(dateKey)) {
      _completedItemsByDate[dateKey] = <String>{};
    }
    // Jika sudah ada dalam Set, abaikan (permanen)
    if (!_completedItemsByDate[dateKey]!.add(itemId)) {
      return;
    }

    // 1. Simpan seketika di memori & disk lokal (Offline-First)
    notifyListeners();
    await _saveToStorage();

    // 2. Sinkronkan ke Firebase Cloud Firestore
    final uid = _currentFirebaseUid;
    debugPrint('[NutritionChecklistService] completeItem: dateKey=$dateKey, itemId=$itemId, UID=$uid');
    if (uid == null || uid.isEmpty) {
      debugPrint('[NutritionChecklistService] Peringatan: Akun Firebase Auth belum aktif, data hanya tersimpan di memori/storage lokal.');
      return;
    }

    try {
      await _syncItemToFirestore(
        uid: uid,
        dateKey: dateKey,
        itemId: itemId,
        meal: meal,
        dailyMeals: dailyMeals,
      );
    } catch (e) {
      debugPrint('[NutritionChecklistService] Notice syncing item to Firestore: $e');
    }
  }

  /// Sinkronisasi item yang diceklis ke dokumen Firestore dengan transaksi / merge aman
  Future<void> _syncItemToFirestore({
    required String uid,
    required String dateKey,
    required String itemId,
    NutritionMealModel? meal,
    List<NutritionMealModel>? dailyMeals,
  }) async {
    final rawCategory = CalorieTargetService.getLatestScreeningCategoryRaw(userId: uid);
    if (rawCategory == null) {
      debugPrint('[NutritionChecklistService] Skip sync item ke Firestore: pengguna belum memiliki hasil skrining.');
      return;
    }
    final group = CalorieTargetService.resolveGroup(rawCategory);
    final targetCalories = CalorieTargetService.getDailyCalorieTarget(group);

    final parsedDate = DateTime.tryParse(dateKey) ?? DateTime.now();
    final effectiveDailyMeals = dailyMeals ?? MealPlanService.getDailyPlanForDate(date: parsedDate, group: group);

    final effectiveMeal = meal ??
        effectiveDailyMeals.firstWhere(
          (m) => m.id == itemId,
          orElse: () => MealPlanService.getMealById(itemId) ?? _createFallbackMeal(itemId),
        );

    final itemMap = <String, dynamic>{
      'mealId': effectiveMeal.id,
      'name': effectiveMeal.name,
      'type': effectiveMeal.type,
      'mealTime': effectiveMeal.mealTime,
      'calories': effectiveMeal.calories,
      'protein': effectiveMeal.protein,
      'carbs': effectiveMeal.carbs,
      'fat': effectiveMeal.fat,
      'portionGram': effectiveMeal.portionGram,
      'checkedAt': Timestamp.now(),
    };

    final plannedMealIds = effectiveDailyMeals.map((m) => m.id).toList();
    final consumedCalories = getConsumedCaloriesForDate(dateKey, effectiveDailyMeals);
    final totalCount = effectiveDailyMeals.length;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('nutrition_progress')
        .doc(dateKey);

    try {
      debugPrint('[NutritionChecklistService] Menyimpan ke Firestore: users/$uid/nutrition_progress/$dateKey (item: $itemId)...');
      final docSnap = await docRef.get();
      final existingData = docSnap.data();
      final existingItems = List<Map<String, dynamic>>.from(
        (existingData?['items'] as List<dynamic>? ?? []).map((e) => Map<String, dynamic>.from(e as Map)),
      );

      final idx = existingItems.indexWhere((it) => it['mealId'] == itemId);
      if (idx >= 0) {
        existingItems[idx] = itemMap;
      } else {
        existingItems.add(itemMap);
      }

      final payload = <String, dynamic>{
        'userId': uid,
        'date': dateKey,
        'categoryAtThatTime': rawCategory,
        'targetCalories': targetCalories,
        'consumedCalories': consumedCalories,
        'completedCount': existingItems.length,
        'totalCount': totalCount,
        'plannedMealIds': plannedMealIds,
        'items': existingItems,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!docSnap.exists) {
        payload['createdAt'] = FieldValue.serverTimestamp();
      }

      // 1. Simpan di sub-koleksi users/{uid}/nutrition_progress
      await docRef.set(payload, SetOptions(merge: true));

      // 2. Simpan di koleksi utama 'nutrition_progress' (muncul di panel kiri Firebase Console!)
      final rootRef = FirebaseFirestore.instance
          .collection('nutrition_progress')
          .doc('${uid}_$dateKey');
      await rootRef.set(payload, SetOptions(merge: true));

      debugPrint('[NutritionChecklistService] BERHASIL tersimpan di Firestore (Root & Sub-koleksi): nutrition_progress/${uid}_$dateKey');
    } catch (e) {
      debugPrint('[NutritionChecklistService] GAGAL menyimpan ke Firestore: $e');
    }
  }

  /// Fallback representasi menu jika item tidak ditemukan di database
  NutritionMealModel _createFallbackMeal(String id) {
    return NutritionMealModel(
      id: id,
      name: 'Menu Makanan/Minuman',
      type: id.startsWith('drink') ? 'drink' : 'food',
      mealTime: 'Makanan',
      category: 'Makanan',
      calories: 150,
      protein: 5.0,
      carbs: 20.0,
      fat: 3.0,
      portionGram: 100,
      pills: const [],
      thumbImg: '',
      heroImg: '',
      desc: '',
      detailDesc: '',
      benefits: const [],
    );
  }

  /// Pembatalan centang (jika diperlukan untuk pengujian atau reset).
  Future<void> uncompleteItem(String dateKey, String itemId) async {
    if (_completedItemsByDate.containsKey(dateKey)) {
      if (_completedItemsByDate[dateKey]!.remove(itemId)) {
        notifyListeners();
        await _saveToStorage();
      }
    }
  }

  /// Toggle centang (dipertahankan untuk kompatibilitas ke belakang).
  Future<void> toggleItem(String dateKey, String itemId) async {
    if (!_completedItemsByDate.containsKey(dateKey)) {
      _completedItemsByDate[dateKey] = <String>{};
    }
    final set = _completedItemsByDate[dateKey]!;
    if (set.contains(itemId)) {
      set.remove(itemId);
    } else {
      set.add(itemId);
    }
    notifyListeners();
    await _saveToStorage();
  }

  /// Menghitung total kalori yang telah terkonsumsi pada tanggal tertentu
  /// berdasarkan daftar menu hari itu.
  int getConsumedCaloriesForDate(String dateKey, List<NutritionMealModel> dailyMeals) {
    final completed = getCompletedForDate(dateKey);
    int sum = 0;
    for (final meal in dailyMeals) {
      if (completed.contains(meal.id)) {
        sum += meal.calories;
      }
    }
    return sum;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _firestoreSubscription?.cancel();
    super.dispose();
  }
}
