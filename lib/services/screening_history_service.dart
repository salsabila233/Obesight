import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/screening_history_model.dart';
import '../screens/skrining/skrining_models.dart';
import 'auth_service.dart';

class ScreeningHistoryService extends ChangeNotifier {
  static final ScreeningHistoryService instance = ScreeningHistoryService._internal();
  ScreeningHistoryService._internal();

  final Map<String, List<ScreeningHistoryItem>> _historyCache = {};
  final Set<String> _loadedUsers = {};

  // Prefix penyimpanan persisten per akun
  static const String _prefPrefix = 'screening_records_per_account_v3_';

  /// Menyelesaikan ID akun unik pengguna secara aman
  String resolveUserKey(String? userId, [String? email]) {
    if (userId != null && userId.trim().isNotEmpty && userId.trim() != 'usr_guest') {
      return userId.trim();
    }
    final authUser = AuthService().currentUser;
    if (authUser != null && authUser.id.isNotEmpty && authUser.id != 'usr_guest') {
      return authUser.id.trim();
    }
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

  /// Memuat riwayat dari SharedPreferences untuk akun tertentu
  Future<List<ScreeningHistoryItem>> loadHistory(String? userId, [String? email]) async {
    final cleanId = resolveUserKey(userId, email);

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_prefPrefix$cleanId';
      final jsonString = prefs.getString(key);

      if (jsonString != null && jsonString.isNotEmpty) {
        final decoded = jsonDecode(jsonString) as List<dynamic>;
        final items = decoded
            .map((item) => ScreeningHistoryItem.fromMap(Map<String, dynamic>.from(item as Map)))
            // Pastikan tidak ada data dummy/seed lama
            .where((item) => !item.id.startsWith('seed_'))
            .toList();
        _historyCache[cleanId] = items;
      } else {
        // Akun belum pernah melakukan skrining: kosong [] (0 semua)
        _historyCache[cleanId] = [];
      }
    } catch (e) {
      debugPrint('[ScreeningHistoryService] Error loading history for $cleanId: $e');
      _historyCache[cleanId] = [];
    }

    _loadedUsers.add(cleanId);
    notifyListeners();
    return getHistory(cleanId);
  }

  /// Menambahkan riwayat skrining baru untuk akun tertentu
  Future<ScreeningHistoryItem> addHistory(String? userId, SkriningData data, {DateTime? customDate, String? email}) async {
    final cleanId = resolveUserKey(userId, email);
    final date = customDate ?? data.date ?? DateTime.now();
    data.date = date;

    // Tentukan Risk
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

    // Ambil list riwayat akun saat ini
    final currentList = List<ScreeningHistoryItem>.from(_historyCache[cleanId] ?? []);
    // Sisipkan hasil skrining terbaru di posisi teratas
    currentList.insert(0, newItem);
    _historyCache[cleanId] = currentList;

    await _saveToStorage(cleanId, currentList);
    notifyListeners();
    return newItem;
  }

  /// Menghapus seluruh riwayat untuk akun tertentu
  Future<void> clearHistory(String? userId, [String? email]) async {
    final cleanId = resolveUserKey(userId, email);
    _historyCache[cleanId] = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_prefPrefix$cleanId');
    } catch (_) {}
    notifyListeners();
  }

  /// Statistik Jumlah Total Skrining per Akun
  int getTotalCount(String? userId, [String? email]) {
    return getHistory(userId, email).length;
  }

  /// Statistik Jumlah Risiko Tinggi per Akun
  int getHighRiskCount(String? userId, [String? email]) {
    return getHistory(userId, email).where((item) => item.risk.toLowerCase().contains('tinggi')).length;
  }

  /// Statistik Jumlah Risiko Sedang per Akun
  int getMediumRiskCount(String? userId, [String? email]) {
    return getHistory(userId, email).where((item) =>
        item.risk.toLowerCase().contains('sedang') || item.risk.toLowerCase().contains('meningkat')).length;
  }

  /// Statistik Jumlah Risiko Rendah per Akun
  int getLowRiskCount(String? userId, [String? email]) {
    return getHistory(userId, email).where((item) =>
        item.risk.toLowerCase().contains('rendah') ||
        item.risk.toLowerCase().contains('terkendali') ||
        item.risk.toLowerCase().contains('normal')).length;
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
