enum UserRole {
  user,
  admin,
}

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
  });

  bool get isAdmin => role == UserRole.admin;

  String get roleDisplayName => isAdmin ? 'Administrator' : 'Pengguna Biasa';

  /// True jika ketiga syarat gating (Tanggal Lahir, Jenis Kelamin, Nomor Telepon) telah terisi
  bool get hasCompletedRequiredProfile {
    final validDob = dob != null && dob!.trim().isNotEmpty;
    final validGender = gender != null && gender!.trim().isNotEmpty;
    final validPhone = phone != null && phone!.trim().isNotEmpty;
    return validDob && validGender && validPhone;
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] as String? ?? 'Pengguna ObeSight',
      email: map['email'] as String? ?? '',
      username: map['username'] as String? ?? (map['email'] != null ? (map['email'] as String).split('@').first : 'user'),
      role: (map['role'] == 'admin') ? UserRole.admin : UserRole.user,
      avatarUrl: (map['photoUrl'] ?? map['avatarUrl']) as String?,
      photoPath: (map['photoPath'] ?? map['photo_path']) as String?,
      title: map['title'] as String?,
      dob: map['dob'] as String?,
      gender: map['gender'] as String?,
      phone: map['phone'] as String?,
      isBiodataComplete: (map['isBiodataComplete'] as bool?) ?? false,
      bmiScore: (map['bmiScore'] as num?)?.toDouble() ?? 22.8,
      bmiCategory: (map['bmiCategory'] as String?) ?? 'Normal',
      obesityRisk: (map['obesityRisk'] as String?) ?? 'Rendah',
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
    );
  }
}
