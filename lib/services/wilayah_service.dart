import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Model data representasi wilayah administratif Indonesia (Provinsi, Kabupaten/Kota, Kecamatan)
class RegionItem {
  final String id;
  final String name;

  const RegionItem({
    required this.id,
    required this.name,
  });

  factory RegionItem.fromJson(Map<String, dynamic> json) {
    return RegionItem(
      id: (json['code'] ?? json['id'] ?? '').toString().trim(),
      name: (json['name'] ?? '').toString().trim(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RegionItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => name;
}

/// Layanan terpusat pengelola data wilayah administratif Indonesia
/// Mendukung 38 Provinsi, 514 Kabupaten/Kota, dan 7.285 Kecamatan resmi Kemendagri
class WilayahService {
  WilayahService._internal() {
    _tryLoadLocalFileSync();
  }
  static final WilayahService instance = WilayahService._internal();

  bool _isLoaded = false;
  List<RegionItem> _provinces = [];
  final Map<String, List<RegionItem>> _regenciesByProvince = {};
  final Map<String, List<RegionItem>> _districtsByRegency = {};

  bool get isLoaded => _isLoaded;
  List<RegionItem> get provincesSync => List.unmodifiable(_provinces);

  void _tryLoadLocalFileSync() {
    try {
      final file = File('assets/data/wilayah_indonesia.json');
      if (file.existsSync()) {
        final jsonString = file.readAsStringSync();
        _parseJsonString(jsonString);
      }
    } catch (_) {}
  }

  void _parseJsonString(String jsonString) {
    if (jsonString.isEmpty) return;
    try {
      final Map<String, dynamic> parsed = json.decode(jsonString);

      // Parse Provinces
      final provList = parsed['provinces'] as List? ?? [];
      _provinces = provList
          .map((e) => RegionItem.fromJson(e as Map<String, dynamic>))
          .where((e) => e.id.isNotEmpty && e.name.isNotEmpty)
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      // Parse Regencies
      final regMap = parsed['regencies'] as Map<String, dynamic>? ?? {};
      regMap.forEach((provId, list) {
        if (list is List) {
          final items = list
              .map((e) => RegionItem.fromJson(e as Map<String, dynamic>))
              .where((e) => e.id.isNotEmpty && e.name.isNotEmpty)
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));
          _regenciesByProvince[provId] = items;
        }
      });

      // Parse Districts
      final distMap = parsed['districts'] as Map<String, dynamic>? ?? {};
      distMap.forEach((regId, list) {
        if (list is List) {
          final items = list
              .map((e) => RegionItem.fromJson(e as Map<String, dynamic>))
              .where((e) => e.id.isNotEmpty && e.name.isNotEmpty)
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));
          _districtsByRegency[regId] = items;
        }
      });

      _isLoaded = true;
      debugPrint('[WilayahService] Berhasil memuat ${_provinces.length} provinsi, '
          '${_regenciesByProvince.length} kab/kota group, ${_districtsByRegency.length} distrik group.');
    } catch (e) {
      debugPrint('[WilayahService] Error parsing wilayah JSON: $e');
    }
  }

  /// Menginisialisasi dan memuat dataset wilayah lokal (offline-first)
  Future<void> ensureInitialized() async {
    if (_isLoaded && _provinces.isNotEmpty) return;

    _tryLoadLocalFileSync();
    if (_isLoaded && _provinces.isNotEmpty) return;

    try {
      final jsonString = await rootBundle.loadString('assets/data/wilayah_indonesia.json');
      _parseJsonString(jsonString);
    } catch (e) {
      debugPrint('[WilayahService] rootBundle load failed: $e');
    }

    // Fallback darurat jika asset belum terbaca: inisialisasi minimal agar tidak crash
    _initFallbackData();
  }

  void _initFallbackData() {
    if (_provinces.isNotEmpty) return;
    _provinces = const [
      RegionItem(id: '11', name: 'Aceh'),
      RegionItem(id: '12', name: 'Sumatera Utara'),
      RegionItem(id: '13', name: 'Sumatera Barat'),
      RegionItem(id: '14', name: 'Riau'),
      RegionItem(id: '15', name: 'Jambi'),
      RegionItem(id: '16', name: 'Sumatera Selatan'),
      RegionItem(id: '17', name: 'Bengkulu'),
      RegionItem(id: '18', name: 'Lampung'),
      RegionItem(id: '19', name: 'Kepulauan Bangka Belitung'),
      RegionItem(id: '21', name: 'Kepulauan Riau'),
      RegionItem(id: '31', name: 'DKI Jakarta'),
      RegionItem(id: '32', name: 'Jawa Barat'),
      RegionItem(id: '33', name: 'Jawa Tengah'),
      RegionItem(id: '34', name: 'DI Yogyakarta'),
      RegionItem(id: '35', name: 'Jawa Timur'),
      RegionItem(id: '36', name: 'Banten'),
      RegionItem(id: '51', name: 'Bali'),
      RegionItem(id: '52', name: 'Nusa Tenggara Barat'),
      RegionItem(id: '53', name: 'Nusa Tenggara Timur'),
      RegionItem(id: '61', name: 'Kalimantan Barat'),
      RegionItem(id: '62', name: 'Kalimantan Tengah'),
      RegionItem(id: '63', name: 'Kalimantan Selatan'),
      RegionItem(id: '64', name: 'Kalimantan Timur'),
      RegionItem(id: '65', name: 'Kalimantan Utara'),
      RegionItem(id: '71', name: 'Sulawesi Utara'),
      RegionItem(id: '72', name: 'Sulawesi Tengah'),
      RegionItem(id: '73', name: 'Sulawesi Selatan'),
      RegionItem(id: '74', name: 'Sulawesi Tenggara'),
      RegionItem(id: '75', name: 'Gorontalo'),
      RegionItem(id: '76', name: 'Sulawesi Barat'),
      RegionItem(id: '81', name: 'Maluku'),
      RegionItem(id: '82', name: 'Maluku Utara'),
      RegionItem(id: '91', name: 'Papua Barat'),
      RegionItem(id: '92', name: 'Papua'),
      RegionItem(id: '93', name: 'Papua Selatan'),
      RegionItem(id: '94', name: 'Papua Tengah'),
      RegionItem(id: '95', name: 'Papua Pegunungan'),
      RegionItem(id: '96', name: 'Papua Barat Daya'),
    ];

    _regenciesByProvince['35'] = const [
      RegionItem(id: '35.09', name: 'Kabupaten Jember'),
      RegionItem(id: '35.78', name: 'Kota Surabaya'),
      RegionItem(id: '35.73', name: 'Kota Malang'),
      RegionItem(id: '35.15', name: 'Kabupaten Sidoarjo'),
      RegionItem(id: '35.25', name: 'Kabupaten Gresik'),
      RegionItem(id: '35.10', name: 'Kabupaten Banyuwangi'),
    ];

    _districtsByRegency['35.09'] = const [
      RegionItem(id: '35.09.19', name: 'Sumbersari'),
      RegionItem(id: '35.09.20', name: 'Kaliwates'),
      RegionItem(id: '35.09.21', name: 'Patrang'),
    ];

    _isLoaded = true;
  }

  /// Mengambil daftar seluruh provinsi di Indonesia
  Future<List<RegionItem>> getProvinces() async {
    await ensureInitialized();
    return List.unmodifiable(_provinces);
  }

  /// Mengambil daftar kabupaten/kota berdasarkan ID provinsi
  Future<List<RegionItem>> getRegencies(String provinceId) async {
    await ensureInitialized();
    final cleanId = provinceId.trim();
    if (cleanId.isEmpty) return const [];

    if (_regenciesByProvince.containsKey(cleanId) && _regenciesByProvince[cleanId]!.isNotEmpty) {
      return List.unmodifiable(_regenciesByProvince[cleanId]!);
    }

    // Jika belum ada di cache lokal, coba ambil online via wilayah.id
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final req = await client.getUrl(Uri.parse('https://wilayah.id/api/regencies/$cleanId.json'));
      final res = await req.close();
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        final decoded = json.decode(body);
        final list = (decoded['data'] as List? ?? [])
            .map((e) => RegionItem.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        _regenciesByProvince[cleanId] = list;
        return List.unmodifiable(list);
      }
    } catch (_) {}

    return const [];
  }

  /// Mengambil daftar kecamatan berdasarkan ID kabupaten/kota
  Future<List<RegionItem>> getDistricts(String regencyId) async {
    await ensureInitialized();
    final cleanId = regencyId.trim();
    if (cleanId.isEmpty) return const [];

    if (_districtsByRegency.containsKey(cleanId) && _districtsByRegency[cleanId]!.isNotEmpty) {
      return List.unmodifiable(_districtsByRegency[cleanId]!);
    }

    // Jika belum ada di cache lokal, coba ambil online via wilayah.id
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final req = await client.getUrl(Uri.parse('https://wilayah.id/api/districts/$cleanId.json'));
      final res = await req.close();
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        final decoded = json.decode(body);
        final list = (decoded['data'] as List? ?? [])
            .map((e) => RegionItem.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        _districtsByRegency[cleanId] = list;
        return List.unmodifiable(list);
      }
    } catch (_) {}

    return const [];
  }

  /// Mencari RegionItem Provinsi berdasarkan ID atau Nama
  Future<RegionItem?> findProvince({String? id, String? name}) async {
    await ensureInitialized();
    if (id != null && id.trim().isNotEmpty) {
      final cleanId = id.trim();
      final match = _provinces.where((e) => e.id == cleanId);
      if (match.isNotEmpty) return match.first;
    }
    if (name != null && name.trim().isNotEmpty) {
      final cleanName = name.trim().toLowerCase();
      final match = _provinces.where((e) => e.name.toLowerCase() == cleanName);
      if (match.isNotEmpty) return match.first;
      final partial = _provinces.where((e) => e.name.toLowerCase().contains(cleanName) || cleanName.contains(e.name.toLowerCase()));
      if (partial.isNotEmpty) return partial.first;
    }
    return null;
  }

  /// Mencari RegionItem Kabupaten/Kota berdasarkan Provinsi ID dan Regency ID/Nama
  Future<RegionItem?> findRegency(String provinceId, {String? id, String? name}) async {
    final list = await getRegencies(provinceId);
    if (id != null && id.trim().isNotEmpty) {
      final cleanId = id.trim();
      final match = list.where((e) => e.id == cleanId);
      if (match.isNotEmpty) return match.first;
    }
    if (name != null && name.trim().isNotEmpty) {
      final cleanName = name.trim().toLowerCase().replaceAll('kabupaten ', '').replaceAll('kota ', '').trim();
      final match = list.where((e) {
        final itemClean = e.name.toLowerCase().replaceAll('kabupaten ', '').replaceAll('kota ', '').trim();
        return itemClean == cleanName;
      });
      if (match.isNotEmpty) return match.first;
      final partial = list.where((e) => e.name.toLowerCase().contains(cleanName));
      if (partial.isNotEmpty) return partial.first;
    }
    return null;
  }

  /// Mencari RegionItem Kecamatan berdasarkan Regency ID dan District ID/Nama
  Future<RegionItem?> findDistrict(String regencyId, {String? id, String? name}) async {
    final list = await getDistricts(regencyId);
    if (id != null && id.trim().isNotEmpty) {
      final cleanId = id.trim();
      final match = list.where((e) => e.id == cleanId);
      if (match.isNotEmpty) return match.first;
    }
    if (name != null && name.trim().isNotEmpty) {
      final cleanName = name.trim().toLowerCase().replaceAll('kecamatan ', '').replaceAll('kec. ', '').trim();
      final match = list.where((e) {
        final itemClean = e.name.toLowerCase().replaceAll('kecamatan ', '').replaceAll('kec. ', '').trim();
        return itemClean == cleanName;
      });
      if (match.isNotEmpty) return match.first;
      final partial = list.where((e) => e.name.toLowerCase().contains(cleanName));
      if (partial.isNotEmpty) return partial.first;
    }
    return null;
  }
}
