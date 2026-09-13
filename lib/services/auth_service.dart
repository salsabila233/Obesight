import 'dart:async';
import '../models/user_model.dart';

class AuthResponse {
  final bool isSuccess;
  final UserModel? user;
  final String? errorMessage;

  const AuthResponse.success(this.user)
      : isSuccess = true,
        errorMessage = null;

  const AuthResponse.failure(this.errorMessage)
      : isSuccess = false,
        user = null;
}

class AuthService {
  // Singleton pattern for easy state access across screens
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  // Preset accounts for testing both roles
  static const UserModel defaultUserAccount = UserModel(
    id: 'usr_001',
    name: 'Zahra Fitriana',
    email: 'zahraafitriana@gmail.com',
    username: 'zahraafitriana',
    role: UserRole.user,
    title: 'Anggota Aktif ObeSight',
  );

  static const UserModel alternativeUserAccount = UserModel(
    id: 'usr_002',
    name: 'Zahra Fitrie',
    email: 'zahrafitrie@gmail.com',
    username: 'zahrafitrie',
    role: UserRole.user,
    title: 'Anggota Aktif ObeSight',
  );

  static const UserModel defaultAdminAccount = UserModel(
    id: 'adm_001',
    name: 'Dr. Hendra Wijaya, Sp.GK',
    email: 'admin@obesight.com',
    username: 'admin',
    role: UserRole.admin,
    title: 'Kepala Medis & Administrator Sistem',
  );

  // Available Google accounts in picker
  List<UserModel> get availableGoogleAccounts => [
        defaultUserAccount,
        defaultAdminAccount,
      ];

  Future<AuthResponse> login({
    required String identifier,
    required String password,
  }) async {
    // Simulate brief network delay for realistic feel
    await Future.delayed(const Duration(milliseconds: 600));

    final cleanId = identifier.trim().toLowerCase();
    final cleanPass = password.trim();

    // Check Admin account
    if ((cleanId == 'admin@obesight.com' || cleanId == 'admin') &&
        cleanPass == 'admin123') {
      _currentUser = defaultAdminAccount;
      return const AuthResponse.success(defaultAdminAccount);
    }

    // Check Normal User Account 1 (zahraafitriana)
    if ((cleanId == 'zahraafitriana@gmail.com' || cleanId == 'zahraafitriana') &&
        (cleanPass == 'Zahra1234' || cleanPass == 'zahra1234')) {
      _currentUser = defaultUserAccount;
      return const AuthResponse.success(defaultUserAccount);
    }

    // Check Normal User Account 2 (zahrafitrie)
    if ((cleanId == 'zahrafitrie@gmail.com' || cleanId == 'zahrafitrie') &&
        cleanPass == 'zohf1234') {
      _currentUser = alternativeUserAccount;
      return const AuthResponse.success(alternativeUserAccount);
    }

    // Invalid credentials
    return const AuthResponse.failure('Email atau kata sandi salah');
  }

  Future<AuthResponse> loginWithGoogleAccount(UserModel account) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _currentUser = account;
    return AuthResponse.success(account);
  }

  void logout() {
    _currentUser = null;
  }
}
