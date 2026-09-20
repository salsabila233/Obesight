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
  final String? title;
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
    this.title,
    this.isBiodataComplete = false,
    this.bmiScore = 22.8,
    this.bmiCategory = 'Normal',
    this.obesityRisk = 'Rendah',
  });

  bool get isAdmin => role == UserRole.admin;

  String get roleDisplayName => isAdmin ? 'Administrator' : 'Pengguna Biasa';

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? username,
    UserRole? role,
    String? avatarUrl,
    String? title,
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
      title: title ?? this.title,
      isBiodataComplete: isBiodataComplete ?? this.isBiodataComplete,
      bmiScore: bmiScore ?? this.bmiScore,
      bmiCategory: bmiCategory ?? this.bmiCategory,
      obesityRisk: obesityRisk ?? this.obesityRisk,
    );
  }
}
