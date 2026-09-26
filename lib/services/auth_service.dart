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
    isBiodataComplete: false,
  );

  static const UserModel alternativeUserAccount = UserModel(
    id: 'usr_002',
    name: 'Zahra Fitrie',
    email: 'zahrafitrie@gmail.com',
    username: 'zahrafitrie',
    role: UserRole.user,
    title: 'Anggota Aktif ObeSight',
    isBiodataComplete: true,
  );

  static const UserModel defaultAdminAccount = UserModel(
    id: 'adm_001',
    name: 'Dr. Hendra Wijaya, Sp.GK',
    email: 'admin@obesight.com',
    username: 'admin',
    role: UserRole.admin,
    title: 'Kepala Medis & Administrator Sistem',
    isBiodataComplete: true,
  );

  static const UserModel zahraCantikAccount = UserModel(
    id: 'usr_003',
    name: 'Zahra Cantik',
    email: 'zahraaaaa123@gmail.com',
    username: 'zahracantik',
    role: UserRole.user,
    title: 'Anggota Baru ObeSight',
    isBiodataComplete: false,
  );

  static const UserModel akuZahraAccount = UserModel(
    id: 'usr_004',
    name: 'Aku Zahra',
    email: 'zahrafitri@gmail.com',
    username: 'akuzahra',
    role: UserRole.user,
    title: 'Anggota Baru ObeSight',
    isBiodataComplete: false,
  );

  final Map<String, bool> _biodataStatusCache = {
    'usr_001': false,
    'usr_002': true,
    'usr_003': false,
    'usr_004': false,
    'adm_001': true,
  };

  final Map<String, Map<String, String>> _userProfileCache = {
    'usr_001': {
      'name': 'Zahra Fitriana',
      'dob': '12 Juli 2003',
      'gender': 'Perempuan',
      'email': 'zahraafitriana@gmail.com',
      'phone': '089334212098',
      'joined': 'Bergabung sejak Juni 2026',
      'avatar': 'assets/avatar_zahra.png',
      'photo_path': '',
    },
    'usr_002': {
      'name': 'Zahra Fitrie',
      'dob': '15 Mei 2002',
      'gender': 'Perempuan',
      'email': 'zahrafitrie@gmail.com',
      'phone': '081234567890',
      'joined': 'Bergabung sejak Januari 2025',
      'avatar': 'assets/avatar_zahra.png',
      'photo_path': '',
    },
    'adm_001': {
      'name': 'Dr. Hendra Wijaya, Sp.GK',
      'dob': '20 November 1988',
      'gender': 'Laki-laki',
      'email': 'admin@obesight.com',
      'phone': '081198765432',
      'joined': 'Bergabung sejak Januari 2024',
      'avatar': 'assets/avatar_zahra.png',
      'photo_path': '',
    },
    'usr_003': {
      'name': 'Zahra Cantik',
      'dob': '10 Oktober 2003',
      'gender': 'Perempuan',
      'email': 'zahraaaaa123@gmail.com',
      'phone': '089512345678',
      'joined': 'Bergabung sejak September 2025',
      'avatar': 'assets/avatar_zahra.png',
      'photo_path': '',
    },
    'usr_004': {
      'name': 'Aku Zahra',
      'dob': '05 Januari 2004',
      'gender': 'Perempuan',
      'email': 'zahrafitri@gmail.com',
      'phone': '089687654321',
      'joined': 'Bergabung sejak September 2025',
      'avatar': 'assets/avatar_zahra.png',
      'photo_path': '',
    },
  };

  Map<String, String> getUserProfile(String userId) {
    if (_userProfileCache.containsKey(userId)) {
      return _userProfileCache[userId]!;
    }
    if (_currentUser != null && _currentUser!.id == userId) {
      return {
        'name': _currentUser!.name,
        'dob': '12 Juli 2003',
        'gender': 'Perempuan',
        'email': _currentUser!.email,
        'phone': '089334212098',
        'joined': 'Bergabung sejak Juni 2026',
        'avatar': 'assets/avatar_zahra.png',
        'photo_path': '',
      };
    }
    return {
      'name': 'Aisyah Lailatul Fitri Hapsari',
      'dob': '12 Juli 2003',
      'gender': 'Perempuan',
      'email': 'aisyah.hapsari@gmail.com',
      'phone': '089334212098',
      'joined': 'Bergabung sejak Juni 2026',
      'avatar': 'assets/avatar_zahra.png',
      'photo_path': '',
    };
  }

  void updateUserProfile({
    required String userId,
    String? name,
    String? dob,
    String? gender,
    String? email,
    String? phone,
    String? avatar,
    String? photoPath,
    String? joined,
  }) {
    final current = getUserProfile(userId);
    _userProfileCache[userId] = {
      'name': name ?? current['name'] ?? 'User',
      'dob': dob ?? current['dob'] ?? '',
      'gender': gender ?? current['gender'] ?? 'Perempuan',
      'email': email ?? current['email'] ?? '',
      'phone': phone ?? current['phone'] ?? '',
      'joined': joined ?? current['joined'] ?? 'Bergabung sejak Juni 2026',
      'avatar': avatar ?? current['avatar'] ?? 'assets/avatar_zahra.png',
      'photo_path': photoPath ?? current['photo_path'] ?? '',
    };
    if (_currentUser != null && _currentUser!.id == userId) {
      _currentUser = _currentUser!.copyWith(
        name: name ?? _currentUser!.name,
        email: email ?? _currentUser!.email,
      );
    }
  }

  final Map<String, Map<String, dynamic>> _userBmiCache = {
    'usr_001': {
      'bmi': 22.8,
      'category': 'Normal',
      'risk': 'Rendah',
      'weight': 58.0,
      'height': 165.0,
      'gender': 'Perempuan',
      'age': 22,
    },
    'usr_002': {
      'bmi': 22.8,
      'category': 'Normal',
      'risk': 'Rendah',
      'weight': 58.0,
      'height': 165.0,
      'gender': 'Perempuan',
      'age': 22,
    },
    'adm_001': {
      'bmi': 23.5,
      'category': 'Kelebihan Berat Badan',
      'risk': 'Sedang',
      'weight': 68.0,
      'height': 170.0,
      'gender': 'Laki-laki',
      'age': 35,
    },
  };

  bool isBiodataCompleted(String userId) {
    return _biodataStatusCache[userId] ?? false;
  }

  Map<String, dynamic> getUserBmi(String userId) {
    return _userBmiCache[userId] ?? {
      'bmi': 22.8,
      'category': 'Normal',
      'risk': 'Rendah',
      'weight': 58.0,
      'height': 165.0,
      'gender': 'Perempuan',
      'age': 22,
    };
  }

  void updateUserBmi({
    required String userId,
    required double bmi,
    required String category,
    required String risk,
    double? weight,
    double? height,
    String? gender,
    int? age,
  }) {
    final existing = _userBmiCache[userId] ?? {};
    final updated = Map<String, dynamic>.from(existing);
    updated['bmi'] = bmi;
    updated['category'] = category;
    updated['risk'] = risk;
    if (weight != null) updated['weight'] = weight;
    if (height != null) updated['height'] = height;
    if (gender != null) updated['gender'] = gender;
    if (age != null) updated['age'] = age;
    _userBmiCache[userId] = updated;

    if (_currentUser != null && _currentUser!.id == userId) {
      _currentUser = _currentUser!.copyWith(
        bmiScore: bmi,
        bmiCategory: category,
        obesityRisk: risk,
      );
    }
  }

  void updateBiodataStatus({
    required String userId,
    required bool isComplete,
    String? name,
  }) {
    _biodataStatusCache[userId] = isComplete;
    if (_currentUser != null && _currentUser!.id == userId) {
      _currentUser = _currentUser!.copyWith(
        name: name ?? _currentUser!.name,
        isBiodataComplete: isComplete,
      );
    }
  }

  // Available Google accounts in picker (matching reference design)
  List<UserModel> get availableGoogleAccounts => [
        defaultUserAccount.copyWith(
          isBiodataComplete: isBiodataCompleted(defaultUserAccount.id),
          bmiScore: (getUserBmi(defaultUserAccount.id)['bmi'] as num).toDouble(),
          bmiCategory: getUserBmi(defaultUserAccount.id)['category'] as String,
          obesityRisk: getUserBmi(defaultUserAccount.id)['risk'] as String,
        ),
        zahraCantikAccount.copyWith(
          isBiodataComplete: isBiodataCompleted(zahraCantikAccount.id),
          bmiScore: (getUserBmi(zahraCantikAccount.id)['bmi'] as num).toDouble(),
          bmiCategory: getUserBmi(zahraCantikAccount.id)['category'] as String,
          obesityRisk: getUserBmi(zahraCantikAccount.id)['risk'] as String,
        ),
        akuZahraAccount.copyWith(
          isBiodataComplete: isBiodataCompleted(akuZahraAccount.id),
          bmiScore: (getUserBmi(akuZahraAccount.id)['bmi'] as num).toDouble(),
          bmiCategory: getUserBmi(akuZahraAccount.id)['category'] as String,
          obesityRisk: getUserBmi(akuZahraAccount.id)['risk'] as String,
        ),
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
      final bmiInfo = getUserBmi(defaultAdminAccount.id);
      _currentUser = defaultAdminAccount.copyWith(
        isBiodataComplete: isBiodataCompleted(defaultAdminAccount.id),
        bmiScore: (bmiInfo['bmi'] as num).toDouble(),
        bmiCategory: bmiInfo['category'] as String,
        obesityRisk: bmiInfo['risk'] as String,
      );
      return AuthResponse.success(_currentUser);
    }

    // Check Normal User Account 1 (zahraafitriana)
    if ((cleanId == 'zahraafitriana@gmail.com' || cleanId == 'zahraafitriana') &&
        (cleanPass == 'Zahra1234' || cleanPass == 'zahra1234')) {
      final bmiInfo = getUserBmi(defaultUserAccount.id);
      _currentUser = defaultUserAccount.copyWith(
        isBiodataComplete: isBiodataCompleted(defaultUserAccount.id),
        bmiScore: (bmiInfo['bmi'] as num).toDouble(),
        bmiCategory: bmiInfo['category'] as String,
        obesityRisk: bmiInfo['risk'] as String,
      );
      return AuthResponse.success(_currentUser);
    }

    // Check Normal User Account 2 (zahrafitrie)
    if ((cleanId == 'zahrafitrie@gmail.com' || cleanId == 'zahrafitrie') &&
        cleanPass == 'zohf1234') {
      final bmiInfo = getUserBmi(alternativeUserAccount.id);
      _currentUser = alternativeUserAccount.copyWith(
        isBiodataComplete: isBiodataCompleted(alternativeUserAccount.id),
        bmiScore: (bmiInfo['bmi'] as num).toDouble(),
        bmiCategory: bmiInfo['category'] as String,
        obesityRisk: bmiInfo['risk'] as String,
      );
      return AuthResponse.success(_currentUser);
    }

    // Invalid credentials
    return const AuthResponse.failure('Email atau kata sandi salah');
  }

  Future<AuthResponse> loginWithGoogleAccount(UserModel account) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!_biodataStatusCache.containsKey(account.id)) {
      _biodataStatusCache[account.id] = account.isBiodataComplete;
    }
    if (!_userProfileCache.containsKey(account.id)) {
      _userProfileCache[account.id] = {
        'name': account.name,
        'dob': '12 Juli 2003',
        'gender': 'Perempuan',
        'email': account.email,
        'phone': '089334212098',
        'joined': 'Bergabung sejak September 2025',
        'avatar': 'assets/avatar_zahra.png',
      };
    }
    final isComplete = isBiodataCompleted(account.id);
    final bmiInfo = getUserBmi(account.id);
    _currentUser = account.copyWith(
      isBiodataComplete: isComplete,
      bmiScore: (bmiInfo['bmi'] as num).toDouble(),
      bmiCategory: bmiInfo['category'] as String,
      obesityRisk: bmiInfo['risk'] as String,
    );
    return AuthResponse.success(_currentUser);
  }

  void logout() {
    _currentUser = null;
  }
}
