import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { user, admin }

class UserModel {
  final String id;
  final String name;
  final String email;
  final String username;
  final UserRole role;
  final String? avatarUrl;
  final String? photoPath;
  final String? title;
  final String? dob;
  final String? gender;
  final String? phone;
  final bool isBiodataComplete;
  final double bmiScore;
  final String bmiCategory;
  final String obesityRisk;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? joined;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    required this.role,
    this.avatarUrl,
    this.photoPath,
    this.title,
    this.dob,
    this.gender,
    this.phone,
    this.isBiodataComplete = false,
    this.bmiScore = 22.8,
    this.bmiCategory = 'Normal',
    this.obesityRisk = 'Rendah',
    this.createdAt,
    this.updatedAt,
    this.joined,
  });

  bool get isAdmin => role == UserRole.admin;

  String get roleDisplayName => isAdmin ? 'Administrator' : 'Pengguna Biasa';

  /// True jika status [isBiodataComplete] telah aktif atau ketiga syarat gating (Tanggal Lahir, Jenis Kelamin, Nomor Telepon) telah terisi
  bool get hasCompletedRequiredProfile {
    if (isBiodataComplete) return true;
    final validDob = dob != null && dob!.trim().isNotEmpty;
    final validGender = gender != null && gender!.trim().isNotEmpty;
    final validPhone = phone != null && phone!.trim().isNotEmpty;
    return validDob && validGender && validPhone;
  }

  /// Format tanggal bergabung yang rapi
  String get joinedFormatted {
    if (joined != null && joined!.trim().isNotEmpty) {
      return joined!.trim();
    }
    if (createdAt != null) {
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
      return '${createdAt!.day} ${months[createdAt!.month - 1]} ${createdAt!.year}';
    }
    return 'Belum tersedia';
  }

  /// Perkiraan usia dari tanggal lahir jika tersedia
  int? get age {
    if (dob == null || dob!.trim().isEmpty) return null;
    final cleanDob = dob!.trim();

    // 1. Ekstrak 4 digit tahun (contoh "12 Juli 2003" atau "2003-07-12")
    final match = RegExp(r'\b(19\d\d|20\d\d)\b').firstMatch(cleanDob);
    if (match != null) {
      final y = int.tryParse(match.group(1)!);
      if (y != null && y <= DateTime.now().year) {
        return DateTime.now().year - y;
      }
    }

    final parsed = DateTime.tryParse(cleanDob);
    if (parsed != null) {
      var calculatedAge = DateTime.now().year - parsed.year;
      if (DateTime.now().month < parsed.month ||
          (DateTime.now().month == parsed.month &&
              DateTime.now().day < parsed.day)) {
        calculatedAge--;
      }
      return calculatedAge;
    }
    return null;
  }

  /// Gabungan jenis kelamin dan usia dengan dot (contoh: "Perempuan • 23 Tahun")
  String get genderAndAgeDotFormatted {
    final hasGender = gender != null && gender!.trim().isNotEmpty;
    final userAge = age;

    if (hasGender && userAge != null) {
      return '${gender!.trim()} • $userAge Tahun';
    } else if (hasGender) {
      return gender!.trim();
    } else if (userAge != null) {
      return '$userAge Tahun';
    }
    return '--';
  }

  /// Gabungan jenis kelamin dan usia (contoh: "Perempuan, 21 tahun" atau "Laki-laki")
  String get genderAndAgeFormatted {
    final hasGender = gender != null && gender!.trim().isNotEmpty;
    final userAge = age;

    if (hasGender && userAge != null) {
      return '${gender!.trim()}, $userAge tahun';
    } else if (hasGender) {
      return gender!.trim();
    } else if (userAge != null) {
      return '$userAge tahun';
    }
    return '--';
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? parsedCreatedAt;
    final createdVal = map['createdAt'] ?? map['created_at'];
    if (createdVal is Timestamp) {
      parsedCreatedAt = createdVal.toDate();
    } else if (createdVal is String) {
      parsedCreatedAt = DateTime.tryParse(createdVal);
    } else if (createdVal is int) {
      parsedCreatedAt = DateTime.fromMillisecondsSinceEpoch(createdVal);
    }

    DateTime? parsedUpdatedAt;
    final updatedVal = map['updatedAt'] ?? map['updated_at'];
    if (updatedVal is Timestamp) {
      parsedUpdatedAt = updatedVal.toDate();
    } else if (updatedVal is String) {
      parsedUpdatedAt = DateTime.tryParse(updatedVal);
    } else if (updatedVal is int) {
      parsedUpdatedAt = DateTime.fromMillisecondsSinceEpoch(updatedVal);
    }

    return UserModel(
      id: id,
      name: map['name'] as String? ?? 'Pengguna ObeSight',
      email: map['email'] as String? ?? '',
      username:
          map['username'] as String? ??
          (map['email'] != null
              ? (map['email'] as String).split('@').first
              : 'user'),
      role: (map['role'] == 'admin') ? UserRole.admin : UserRole.user,
      avatarUrl:
          (map['photoUrl'] ?? map['avatarUrl'] ?? map['avatar']) as String?,
      photoPath: (map['photoPath'] ?? map['photo_path']) as String?,
      title: map['title'] as String?,
      dob: map['dob'] as String?,
      gender: map['gender'] as String?,
      phone: map['phone'] as String?,
      isBiodataComplete: (map['isBiodataComplete'] as bool?) ?? false,
      bmiScore: (map['bmiScore'] as num?)?.toDouble() ?? 22.8,
      bmiCategory: (map['bmiCategory'] as String?) ?? 'Normal',
      obesityRisk: (map['obesityRisk'] as String?) ?? 'Rendah',
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
      joined: map['joined'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': id,
      'name': name,
      'email': email,
      'username': username,
      'role': isAdmin ? 'admin' : 'user',
      'photoUrl': avatarUrl ?? '',
      'photoPath': photoPath ?? '',
      'title': title ?? '',
      'dob': dob ?? '',
      'gender': gender ?? '',
      'phone': phone ?? '',
      'isBiodataComplete': isBiodataComplete,
      'bmiScore': bmiScore,
      'bmiCategory': bmiCategory,
      'obesityRisk': obesityRisk,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (joined != null) 'joined': joined,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? username,
    UserRole? role,
    String? avatarUrl,
    String? photoPath,
    String? title,
    String? dob,
    String? gender,
    String? phone,
    bool? isBiodataComplete,
    double? bmiScore,
    String? bmiCategory,
    String? obesityRisk,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? joined,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      username: username ?? this.username,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      photoPath: photoPath ?? this.photoPath,
      title: title ?? this.title,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      isBiodataComplete: isBiodataComplete ?? this.isBiodataComplete,
      bmiScore: bmiScore ?? this.bmiScore,
      bmiCategory: bmiCategory ?? this.bmiCategory,
      obesityRisk: obesityRisk ?? this.obesityRisk,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      joined: joined ?? this.joined,
    );
  }
}
