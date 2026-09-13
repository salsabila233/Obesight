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

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    required this.role,
    this.avatarUrl,
    this.title,
  });

  bool get isAdmin => role == UserRole.admin;

  String get roleDisplayName => isAdmin ? 'Administrator' : 'Pengguna Biasa';
}
