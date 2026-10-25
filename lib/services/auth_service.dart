import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'email_service.dart';

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

class OtpResponse {
  final bool isSuccess;
  final String? otp;
  final String? errorMessage;

  const OtpResponse.success(this.otp, [this.errorMessage]) : isSuccess = true;
  const OtpResponse.failure(this.errorMessage)
      : isSuccess = false,
        otp = null;
}

class AuthService {
  // Singleton pattern for easy state access across screens
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// Web Client ID opsional yang dapat dikonfigurasi dari Firebase Console
  /// (Authentication -> Sign-in method -> Google -> Web SDK configuration -> Web client ID)
  static String? webClientId;

  bool get isFirebaseAvailable => Firebase.apps.isNotEmpty;
  FirebaseAuth get _firebaseAuth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
    serverClientId: webClientId,
  );
  GoogleSignIn get googleSignIn => _googleSignIn;

  @visibleForTesting
  set googleSignInInstance(GoogleSignIn instance) {
    _googleSignIn = instance;
  }

  /// Memungkinkan konfigurasi client ID secara dinamis
  void configureGoogleSignIn({String? serverClientId, String? clientId}) {
    webClientId = serverClientId;
    _googleSignIn = GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: serverClientId,
      clientId: clientId,
    );
  }

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  /// Stream reaktif perubahan status autentikasi dari Firebase Auth
  Stream<User?> get authStateChanges =>
      isFirebaseAvailable ? _firebaseAuth.authStateChanges() : Stream.value(null);

  /// Akun Firebase Auth aktif saat ini (jika ada)
  User? get firebaseCurrentUser =>
      isFirebaseAvailable ? _firebaseAuth.currentUser : null;

  static const String _keyActiveUserId = 'obesight_active_user_id';
  static const String _keyActiveUserEmail = 'obesight_active_user_email';
  static const String _keyActiveUserName = 'obesight_active_user_name';
  static const String _keyActiveUserDob = 'obesight_active_user_dob';
  static const String _keyActiveUserGender = 'obesight_active_user_gender';
  static const String _keyActiveUserPhone = 'obesight_active_user_phone';
  static const String _keyActiveUserIsBiodataComplete = 'obesight_active_user_is_biodata_complete';
  static const String _keyActiveUserRole = 'obesight_active_user_role';
  static const String _keyActiveUserAvatar = 'obesight_active_user_avatar';
  static const String _keyActiveUserBmiScore = 'obesight_active_user_bmi_score';
  static const String _keyActiveUserBmiCategory = 'obesight_active_user_bmi_category';
  static const String _keyActiveUserObesityRisk = 'obesight_active_user_obesity_risk';

  static const String _keyDeletedAccounts = 'obesight_deleted_accounts';
  static const String _keyCustomPasswords = 'obesight_custom_passwords';
  static const String _keyCustomEmails = 'obesight_custom_emails';

  final Set<String> _deletedAccounts = {};
  final Map<String, String> _customPasswords = {};
  final Map<String, String> _customEmails = {};
  final Map<String, String> _activeOtps = {};
  final Map<String, DateTime> _activeOtpExpiry = {};

  void _saveSession(UserModel user) {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_keyActiveUserId, user.id);
      prefs.setString(_keyActiveUserEmail, user.email);
      prefs.setString(_keyActiveUserName, user.name);
      prefs.setString(_keyActiveUserDob, user.dob ?? '');
      prefs.setString(_keyActiveUserGender, user.gender ?? '');
      prefs.setString(_keyActiveUserPhone, user.phone ?? '');
      prefs.setBool(_keyActiveUserIsBiodataComplete, user.isBiodataComplete);
      prefs.setString(_keyActiveUserRole, user.isAdmin ? 'admin' : 'user');
      if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
        prefs.setString(_keyActiveUserAvatar, user.avatarUrl!);
      }
      prefs.setDouble(_keyActiveUserBmiScore, user.bmiScore);
      prefs.setString(_keyActiveUserBmiCategory, user.bmiCategory);
      prefs.setString(_keyActiveUserObesityRisk, user.obesityRisk);
    }).catchError((e) {
      debugPrint('Notice saving session to SharedPreferences: $e');
    });
  }

  void _clearSession() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove(_keyActiveUserId);
      prefs.remove(_keyActiveUserEmail);
      prefs.remove(_keyActiveUserName);
      prefs.remove(_keyActiveUserDob);
      prefs.remove(_keyActiveUserGender);
      prefs.remove(_keyActiveUserPhone);
      prefs.remove(_keyActiveUserIsBiodataComplete);
      prefs.remove(_keyActiveUserRole);
      prefs.remove(_keyActiveUserAvatar);
      prefs.remove(_keyActiveUserBmiScore);
      prefs.remove(_keyActiveUserBmiCategory);
      prefs.remove(_keyActiveUserObesityRisk);
    }).catchError((e) {
      debugPrint('Notice clearing session from SharedPreferences: $e');
    });
  }

  /// Memulihkan sesi login pengguna secara persisten saat aplikasi dibuka kembali (Cold Start)
  /// 1. Cek sesi aktif di Firebase Authentication (FirebaseAuth.instance.currentUser)
  /// 2. Ambil data profil, kelengkapan biodata, dan riwayat IMT langsung dari Cloud Firestore users/{uid}
  /// 3. Jika koneksi offline / lambat, pulihkan dari SharedPreferences & cache lokal tanpa logout
  Future<UserModel?> restorePersistentSession() async {
    try {
      try {
        final prefs = await SharedPreferences.getInstance();
        final deleted = prefs.getStringList(_keyDeletedAccounts);
        if (deleted != null) {
          _deletedAccounts.addAll(deleted.map((e) => e.toLowerCase()));
        }
      } catch (_) {}

      // 1. Cek Firebase Authentication aktif (dengan toleransi cold start async)
      if (isFirebaseAvailable) {
        User? firebaseUser = _firebaseAuth.currentUser;
        if (firebaseUser == null) {
          try {
            firebaseUser = await _firebaseAuth
                .authStateChanges()
                .first
                .timeout(const Duration(milliseconds: 1200));
          } catch (_) {
            firebaseUser = _firebaseAuth.currentUser;
          }
        }

        if (firebaseUser != null) {
          final uid = firebaseUser.uid;

          if (_deletedAccounts.contains(firebaseUser.email?.toLowerCase())) {
            await logout();
            return null;
          }

          // Baca SharedPreferences sebagai fallback instan (offline / slow network)
          String? localName;
          String? localEmail;
          String? localDob;
          String? localGender;
          String? localPhone;
          bool? localIsGated;
          String? localRole;
          String? localAvatar;
          double? localBmi;
          String? localCategory;
          String? localRisk;

          try {
            final prefs = await SharedPreferences.getInstance();
            if (prefs.getString(_keyActiveUserId) == uid) {
              localName = prefs.getString(_keyActiveUserName);
              localEmail = prefs.getString(_keyActiveUserEmail);
              localDob = prefs.getString(_keyActiveUserDob);
              localGender = prefs.getString(_keyActiveUserGender);
              localPhone = prefs.getString(_keyActiveUserPhone);
              localIsGated = prefs.getBool(_keyActiveUserIsBiodataComplete);
              localRole = prefs.getString(_keyActiveUserRole);
              localAvatar = prefs.getString(_keyActiveUserAvatar);
              localBmi = prefs.getDouble(_keyActiveUserBmiScore);
              localCategory = prefs.getString(_keyActiveUserBmiCategory);
              localRisk = prefs.getString(_keyActiveUserObesityRisk);
            }
          } catch (e) {
            debugPrint('Prefs read notice on restore: $e');
          }

          try {
            final doc = await _firestore.collection('users').doc(uid).get().timeout(
              const Duration(seconds: 4),
              onTimeout: () => throw TimeoutException('Firestore timeout'),
            );

            if (doc.exists && doc.data() != null) {
              final data = doc.data()!;
              // Prioritaskan dokumen Cloud Firestore users/{uid} yang memuat update terbaru dari Edit Profil
              final rawDocName = (data['name'] as String?)?.trim();
              final name = (rawDocName != null && rawDocName.isNotEmpty)
                  ? rawDocName
                  : (firebaseUser.displayName?.trim().isNotEmpty == true
                      ? firebaseUser.displayName!.trim()
                      : (localName?.trim().isNotEmpty == true ? localName!.trim() : 'Pengguna ObeSight'));

              final rawDocEmail = (data['email'] as String?)?.trim();
              final email = (rawDocEmail != null && rawDocEmail.isNotEmpty)
                  ? rawDocEmail
                  : (firebaseUser.email?.trim().isNotEmpty == true
                      ? firebaseUser.email!.trim()
                      : (localEmail?.trim().isNotEmpty == true ? localEmail!.trim() : ''));

              final photoUrl = (data['photoUrl'] ?? data['photoPath'] ?? data['avatar']) as String? ??
                  (firebaseUser.photoURL ?? localAvatar ?? '');
              final dob = (data['dob'] as String?)?.trim() ?? localDob ?? '';
              final rawGender = (data['gender'] as String?)?.trim() ?? localGender ?? '';
              final phone = (data['phone'] as String?)?.trim() ?? localPhone ?? '';
              final roleStr = (data['role'] as String?) ?? localRole ?? 'user';
              final isGated = (data['isBiodataComplete'] == true) ||
                  (localIsGated == true) ||
                  (dob.isNotEmpty && rawGender.isNotEmpty && phone.isNotEmpty);
              final gender = rawGender.isNotEmpty ? rawGender : 'Perempuan';

              final bmiScore = (data['bmiScore'] as num?)?.toDouble() ?? localBmi ?? 22.8;
              final bmiCategory = (data['bmiCategory'] as String?) ?? localCategory ?? 'Normal';
              final obesityRisk = (data['obesityRisk'] as String?) ?? localRisk ?? 'Rendah';

              // Sinkronisasi memori lokal dengan data Firestore terbaru
              _userProfileCache[uid] = {
                'name': name,
                'dob': dob,
                'gender': gender,
                'email': email,
                'phone': phone,
                'joined': (data['joined'] as String?) ?? 'Bergabung sejak ${DateTime.now().year}',
                'avatar': photoUrl.isNotEmpty ? photoUrl : 'assets/avatar_zahra.png',
                'photo_path': photoUrl,
              };
              _biodataStatusCache[uid] = isGated;
              _userBmiCache[uid] = {
                'bmi': bmiScore,
                'category': bmiCategory,
                'risk': obesityRisk,
                'weight': (data['weight'] as num?)?.toDouble() ?? 58.0,
                'height': (data['height'] as num?)?.toDouble() ?? 165.0,
                'gender': gender,
                'age': (data['age'] as num?)?.toInt() ?? 22,
              };

              _currentUser = UserModel(
                id: uid,
                name: name,
                email: email,
                username: email.contains('@') ? email.split('@').first : (email.isNotEmpty ? email : 'user'),
                role: roleStr == 'admin' ? UserRole.admin : UserRole.user,
                avatarUrl: photoUrl.isNotEmpty ? photoUrl : null,
                photoPath: photoUrl.isNotEmpty ? photoUrl : null,
                dob: dob,
                gender: gender,
                phone: phone,
                isBiodataComplete: isGated,
                bmiScore: bmiScore,
                bmiCategory: bmiCategory,
                obesityRisk: obesityRisk,
              );

              _saveSession(_currentUser!);

              // Sinkronisasi displayName di Firebase Auth jika belum diperbarui
              if (firebaseUser.displayName != name && name != 'Pengguna ObeSight') {
                try {
                  await firebaseUser.updateDisplayName(name);
                } catch (_) {}
              }

              profileUpdateNotifier.value++;
              return _currentUser;
            }
          } catch (e) {
            debugPrint('Firestore fetch on restore session: $e');
          }

          // Fallback lokal jika Firestore offline namun firebaseUser masih login
          final cached = _userProfileCache[uid];
          final isGated = (localIsGated == true) ||
              (_biodataStatusCache[uid] == true) ||
              ((localDob?.isNotEmpty ?? false) && (localGender?.isNotEmpty ?? false) && (localPhone?.isNotEmpty ?? false)) ||
              isBiodataCompleted(uid);
          final bmiInfo = getUserBmi(uid);

          final name = localName ?? (cached != null ? cached['name'] : null) ?? firebaseUser.displayName ?? 'Pengguna ObeSight';
          final email = localEmail ?? (cached != null ? cached['email'] : null) ?? firebaseUser.email ?? '';
          final dob = localDob ?? (cached != null ? cached['dob'] : null) ?? '';
          final gender = localGender ?? (cached != null ? cached['gender'] : null) ?? 'Perempuan';
          final phone = localPhone ?? (cached != null ? cached['phone'] : null) ?? '';
          final photoUrl = localAvatar ?? (cached != null ? cached['avatar'] : null) ?? firebaseUser.photoURL;

          _userProfileCache[uid] = {
            'name': name,
            'dob': dob,
            'gender': gender,
            'email': email,
            'phone': phone,
            'joined': cached?['joined'] ?? 'Bergabung sejak ${DateTime.now().year}',
            'avatar': photoUrl ?? 'assets/avatar_zahra.png',
            'photo_path': photoUrl ?? '',
          };

          _currentUser = UserModel(
            id: uid,
            name: name,
            email: email,
            username: (email.isNotEmpty ? email : 'user').split('@').first,
            role: localRole == 'admin' ? UserRole.admin : UserRole.user,
            avatarUrl: photoUrl,
            photoPath: photoUrl,
            dob: dob,
            gender: gender,
            phone: phone,
            isBiodataComplete: isGated,
            bmiScore: localBmi ?? (bmiInfo['bmi'] as num?)?.toDouble() ?? 22.8,
            bmiCategory: localCategory ?? (bmiInfo['category'] as String?) ?? 'Normal',
            obesityRisk: localRisk ?? (bmiInfo['risk'] as String?) ?? 'Rendah',
          );

          _saveSession(_currentUser!);
          profileUpdateNotifier.value++;
          return _currentUser;
        }
      }

      // 2. Cek SharedPreferences jika pengguna pernah login dengan preset / akun lokal
      try {
        final prefs = await SharedPreferences.getInstance();
        final savedUid = prefs.getString(_keyActiveUserId);
        if (savedUid != null && savedUid.isNotEmpty) {
          // Cari di daftar akun preset atau cache lokal
          final cached = getUserProfile(savedUid);
          final isGated = prefs.getBool(_keyActiveUserIsBiodataComplete) ?? isBiodataCompleted(savedUid);
          final bmiInfo = getUserBmi(savedUid);
          final savedName = prefs.getString(_keyActiveUserName) ?? cached['name'] ?? 'User';
          final savedEmail = prefs.getString(_keyActiveUserEmail) ?? cached['email'] ?? '';
          final savedDob = prefs.getString(_keyActiveUserDob) ?? cached['dob'] ?? '';
          final savedGender = prefs.getString(_keyActiveUserGender) ?? cached['gender'] ?? 'Perempuan';
          final savedPhone = prefs.getString(_keyActiveUserPhone) ?? cached['phone'] ?? '';
          final savedRole = prefs.getString(_keyActiveUserRole) == 'admin' || savedUid == 'adm_001'
              ? UserRole.admin
              : UserRole.user;

          _userProfileCache[savedUid] = {
            'name': savedName,
            'dob': savedDob,
            'gender': savedGender,
            'email': savedEmail,
            'phone': savedPhone,
            'joined': cached['joined'] ?? 'Bergabung sejak Juni 2026',
            'avatar': prefs.getString(_keyActiveUserAvatar) ?? cached['avatar'] ?? 'assets/avatar_zahra.png',
            'photo_path': prefs.getString(_keyActiveUserAvatar) ?? cached['photo_path'] ?? '',
          };

          _currentUser = UserModel(
            id: savedUid,
            name: savedName,
            email: savedEmail,
            username: (savedEmail.isNotEmpty ? savedEmail : 'user').split('@').first,
            role: savedRole,
            avatarUrl: prefs.getString(_keyActiveUserAvatar) ?? cached['avatar'],
            photoPath: prefs.getString(_keyActiveUserAvatar) ?? cached['photo_path'],
            dob: savedDob,
            gender: savedGender,
            phone: savedPhone,
            isBiodataComplete: isGated,
            bmiScore: prefs.getDouble(_keyActiveUserBmiScore) ?? (bmiInfo['bmi'] as num?)?.toDouble() ?? 22.8,
            bmiCategory: prefs.getString(_keyActiveUserBmiCategory) ?? (bmiInfo['category'] as String?) ?? 'Normal',
            obesityRisk: prefs.getString(_keyActiveUserObesityRisk) ?? (bmiInfo['risk'] as String?) ?? 'Rendah',
          );

          profileUpdateNotifier.value++;
          return _currentUser;
        }
      } catch (e) {
        debugPrint('SharedPreferences check on restore session: $e');
      }
    } catch (e) {
      debugPrint('General error in restorePersistentSession: $e');
    }

    return null;
  }

  // Notifier to trigger real-time updates across screens whenever profile or avatar changes
  final ValueNotifier<int> profileUpdateNotifier = ValueNotifier<int>(0);

  // Preset accounts for testing both roles and offline compatibility
  static const UserModel defaultUserAccount = UserModel(
    id: 'usr_001',
    name: 'Zahra Fitriana',
    email: 'zahraafitriana@gmail.com',
    username: 'zahraafitriana',
    role: UserRole.user,
    title: 'Anggota Aktif ObeSight',
    isBiodataComplete: false,
    dob: '',
    gender: 'Perempuan',
    phone: '',
  );

  static const UserModel alternativeUserAccount = UserModel(
    id: 'usr_002',
    name: 'Zahra Fitrie',
    email: 'zahrafitrie@gmail.com',
    username: 'zahrafitrie',
    role: UserRole.user,
    title: 'Anggota Aktif ObeSight',
    isBiodataComplete: true,
    dob: '15 Mei 2002',
    gender: 'Perempuan',
    phone: '081234567890',
  );

  static const UserModel defaultAdminAccount = UserModel(
    id: 'adm_001',
    name: 'Dr. Hendra Wijaya, Sp.GK',
    email: 'adminobesight@gmail.com',
    username: 'admin',
    role: UserRole.admin,
    title: 'Kepala Medis & Administrator Sistem',
    isBiodataComplete: true,
    dob: '20 November 1988',
    gender: 'Laki-laki',
    phone: '081198765432',
  );

  static const UserModel zahraCantikAccount = UserModel(
    id: 'usr_003',
    name: 'Zahra Cantik',
    email: 'zahraaaaa123@gmail.com',
    username: 'zahracantik',
    role: UserRole.user,
    title: 'Anggota Baru ObeSight',
    isBiodataComplete: false,
    dob: '',
    gender: 'Perempuan',
    phone: '',
  );

  static const UserModel akuZahraAccount = UserModel(
    id: 'usr_004',
    name: 'Aku Zahra',
    email: 'zahrafitri@gmail.com',
    username: 'akuzahra',
    role: UserRole.user,
    title: 'Anggota Baru ObeSight',
    isBiodataComplete: false,
    dob: '',
    gender: 'Perempuan',
    phone: '',
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
      'dob': '',
      'gender': 'Perempuan',
      'email': 'zahraafitriana@gmail.com',
      'phone': '',
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
      'email': 'adminobesight@gmail.com',
      'phone': '081198765432',
      'joined': 'Bergabung sejak Januari 2024',
      'avatar': 'assets/avatar_zahra.png',
      'photo_path': '',
    },
    'usr_003': {
      'name': 'Zahra Cantik',
      'dob': '',
      'gender': 'Perempuan',
      'email': 'zahraaaaa123@gmail.com',
      'phone': '',
      'joined': 'Bergabung sejak September 2025',
      'avatar': 'assets/avatar_zahra.png',
      'photo_path': '',
    },
    'usr_004': {
      'name': 'Aku Zahra',
      'dob': '',
      'gender': 'Perempuan',
      'email': 'zahrafitri@gmail.com',
      'phone': '',
      'joined': 'Bergabung sejak September 2025',
      'avatar': 'assets/avatar_zahra.png',
      'photo_path': '',
    },
  };

  /// Stream of user document snapshot in Firestore for real-time syncing
  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }

  /// Get current cached profile data (Memprioritaskan data profil pengguna aktif yang terbaru)
  Map<String, String> getUserProfile(String userId) {
    if (_currentUser != null && _currentUser!.id == userId) {
      final cached = _userProfileCache[userId];
      return {
        'name': _currentUser!.name.isNotEmpty ? _currentUser!.name : (cached?['name'] ?? 'Pengguna ObeSight'),
        'dob': _currentUser!.dob ?? cached?['dob'] ?? '',
        'gender': _currentUser!.gender ?? cached?['gender'] ?? 'Perempuan',
        'email': _currentUser!.email.isNotEmpty ? _currentUser!.email : (cached?['email'] ?? ''),
        'phone': _currentUser!.phone ?? cached?['phone'] ?? '',
        'joined': cached?['joined'] ?? 'Bergabung sejak Juni 2026',
        'avatar': _currentUser!.avatarUrl ?? cached?['avatar'] ?? 'assets/avatar_zahra.png',
        'photo_path': _currentUser!.photoPath ?? cached?['photo_path'] ?? '',
      };
    }
    if (_userProfileCache.containsKey(userId)) {
      return _userProfileCache[userId]!;
    }
    return {
      'name': 'Pengguna ObeSight',
      'dob': '',
      'gender': 'Perempuan',
      'email': '',
      'phone': '',
      'joined': 'Bergabung sejak Juni 2026',
      'avatar': 'assets/avatar_zahra.png',
      'photo_path': '',
    };
  }

  /// Mengambil data profil terbaru langsung dari dokumen Cloud Firestore (`users/{uid}`)
  Future<UserModel?> fetchUserProfile(String userId) async {
    if (!isFirebaseAvailable) return _currentUser;
    try {
      final doc = await _firestore.collection('users').doc(userId).get().timeout(
        const Duration(seconds: 4),
        onTimeout: () => throw TimeoutException('Firestore timeout'),
      );
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final rawName = (data['name'] as String?)?.trim();
        final rawEmail = (data['email'] as String?)?.trim();
        final photoUrl = (data['photoUrl'] ?? data['photoPath'] ?? data['avatar']) as String?;
        final dob = (data['dob'] as String?)?.trim() ?? '';
        final rawGender = (data['gender'] as String?)?.trim() ?? '';
        final phone = (data['phone'] as String?)?.trim() ?? '';
        final roleStr = data['role'] as String? ?? 'user';
        final isComplete = (data['isBiodataComplete'] == true) ||
            (dob.isNotEmpty && rawGender.isNotEmpty && phone.isNotEmpty);
        final gender = rawGender.isNotEmpty ? rawGender : 'Perempuan';

        final existingProfile = getUserProfile(userId);
        final name = (rawName != null && rawName.isNotEmpty) ? rawName : existingProfile['name']!;
        final email = (rawEmail != null && rawEmail.isNotEmpty) ? rawEmail : existingProfile['email']!;

        final updatedProfile = {
          'name': name,
          'dob': dob,
          'gender': gender,
          'email': email,
          'phone': phone,
          'joined': (data['joined'] as String?) ?? existingProfile['joined'] ?? 'Bergabung sejak ${DateTime.now().year}',
          'avatar': (photoUrl != null && photoUrl.isNotEmpty) ? photoUrl : (existingProfile['avatar'] ?? 'assets/avatar_zahra.png'),
          'photo_path': photoUrl ?? existingProfile['photo_path'] ?? '',
        };

        _userProfileCache[userId] = updatedProfile;
        _biodataStatusCache[userId] = isComplete;

        if (_currentUser != null && _currentUser!.id == userId) {
          _currentUser = _currentUser!.copyWith(
            name: name,
            email: email,
            dob: dob,
            gender: gender,
            phone: phone,
            avatarUrl: photoUrl,
            photoPath: photoUrl,
            role: roleStr == 'admin' ? UserRole.admin : UserRole.user,
            isBiodataComplete: isComplete,
          );
          _saveSession(_currentUser!);
        }

        profileUpdateNotifier.value++;
        return _currentUser;
      }
    } catch (e) {
      debugPrint('Error fetching latest user profile from Firestore: $e');
    }
    return _currentUser;
  }

  /// Update user profile both locally and automatically to Firestore (users/{uid})
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? dob,
    String? gender,
    String? email,
    String? phone,
    String? avatar,
    String? photoPath,
    String? joined,
  }) async {
    final current = getUserProfile(userId);
    final updatedMap = {
      'name': name ?? current['name'] ?? 'User',
      'dob': dob ?? current['dob'] ?? '',
      'gender': gender ?? current['gender'] ?? 'Perempuan',
      'email': email ?? current['email'] ?? '',
      'phone': phone ?? current['phone'] ?? '',
      'joined': joined ?? current['joined'] ?? 'Bergabung sejak Juni 2026',
      'avatar': avatar ?? current['avatar'] ?? 'assets/avatar_zahra.png',
      'photo_path': photoPath ?? current['photo_path'] ?? '',
    };
    _userProfileCache[userId] = updatedMap;

    // Check gating status: dob, gender, phone must all be non-empty
    final isGatedComplete = (updatedMap['dob']?.isNotEmpty ?? false) &&
        (updatedMap['gender']?.isNotEmpty ?? false) &&
        (updatedMap['phone']?.isNotEmpty ?? false);

    _biodataStatusCache[userId] = isGatedComplete;

    if (_currentUser != null && _currentUser!.id == userId) {
      _currentUser = _currentUser!.copyWith(
        name: updatedMap['name'],
        email: updatedMap['email'],
        dob: updatedMap['dob'],
        gender: updatedMap['gender'],
        phone: updatedMap['phone'],
        avatarUrl: updatedMap['avatar'],
        photoPath: updatedMap['photo_path'],
        isBiodataComplete: isGatedComplete,
      );
      _saveSession(_currentUser!);
    }

    // Persist to Cloud Firestore users/{uid}
    try {
      final firestoreData = <String, dynamic>{
        'name': updatedMap['name'],
        'email': updatedMap['email'],
        'dob': updatedMap['dob'],
        'gender': updatedMap['gender'],
        'phone': updatedMap['phone'],
        'isBiodataComplete': isGatedComplete,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (photoPath != null) {
        firestoreData['photoPath'] = photoPath;
        firestoreData['photoUrl'] = photoPath;
      }
      if (avatar != null) {
        firestoreData['avatar'] = avatar;
      }
      await _firestore.collection('users').doc(userId).set(firestoreData, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Notice saving to Firestore user doc: $e');
    }

    // Sinkronkan displayName pada akun Firebase Auth aktif
    if (firebaseCurrentUser != null && updatedMap['name'] != null && updatedMap['name']!.trim().isNotEmpty) {
      try {
        await firebaseCurrentUser!.updateDisplayName(updatedMap['name']!.trim());
      } catch (_) {}
    }

    // Notify listeners for real-time reactivity
    profileUpdateNotifier.value++;
  }

  /// System gating check: verifies if dob, gender, and phone are complete in Firestore/cache
  Future<bool> checkProfileGating(String userId) async {
    // 1. First check local memory for fast response
    final local = getUserProfile(userId);
    final localHasDob = local['dob'] != null && local['dob']!.trim().isNotEmpty;
    final localHasGender = local['gender'] != null && local['gender']!.trim().isNotEmpty;
    final localHasPhone = local['phone'] != null && local['phone']!.trim().isNotEmpty;

    if (localHasDob && localHasGender && localHasPhone) {
      return true;
    }

    // 2. Cross-verify with Firestore users/{uid}
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final dob = (data['dob'] as String?)?.trim() ?? '';
        final gender = (data['gender'] as String?)?.trim() ?? '';
        final phone = (data['phone'] as String?)?.trim() ?? '';

        final isComplete = dob.isNotEmpty && gender.isNotEmpty && phone.isNotEmpty;
        if (isComplete) {
          _biodataStatusCache[userId] = true;
          // Synchronize local cache
          updateUserProfile(
            userId: userId,
            dob: dob,
            gender: gender,
            phone: phone,
            name: data['name'] as String?,
            email: data['email'] as String?,
            photoPath: (data['photoPath'] ?? data['photoUrl']) as String?,
          );
          return true;
        }
      }
    } catch (e) {
      debugPrint('Firestore checkProfileGating check: $e');
    }

    return false;
  }

  bool isProfileComplete(String userId) {
    final profile = getUserProfile(userId);
    final hasDob = (profile['dob']?.trim().isNotEmpty ?? false);
    final hasGender = (profile['gender']?.trim().isNotEmpty ?? false);
    final hasPhone = (profile['phone']?.trim().isNotEmpty ?? false);
    return hasDob && hasGender && hasPhone;
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
    return isProfileComplete(userId);
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

    try {
      _firestore.collection('users').doc(userId).set({
        'bmiScore': bmi,
        'bmiCategory': category,
        'obesityRisk': risk,
        'weight': weight,
        'height': height,
        'gender': gender,
        'age': age,
      }, SetOptions(merge: true));
    } catch (_) {}

    profileUpdateNotifier.value++;
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
    profileUpdateNotifier.value++;
  }

  // Preset accounts list for UI pickers
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

  // -------------------------------------------------------------
  // BAGIAN 2: INTEGRASI GOOGLE SIGN-IN ASLI & FIREBASE AUTH
  // -------------------------------------------------------------

  /// Masuk dengan Google menggunakan package google_sign_in resmi
  /// yang langsung memunculkan dialog akun Google native bawaan perangkat
  /// dan menghubungkan akun ke Firebase Auth & Cloud Firestore.
  Future<AuthResponse> signInWithGoogle() async {
    try {
      if (!isFirebaseAvailable) {
        return const AuthResponse.failure(
          'Firebase belum terinisialisasi. Pastikan koneksi internet aktif saat membuka aplikasi.',
        );
      }

      UserCredential userCredential;
      String? fallbackDisplayName;
      String? fallbackEmail;
      String? fallbackPhotoUrl;

      // Platform Web: gunakan signInWithPopup resmi dari Firebase Auth
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        userCredential = await _firebaseAuth.signInWithPopup(googleProvider);
      } else {
        // Platform Mobile (Android / iOS):
        // 1. Reset sesi Google sebelumnya agar dialog pemilih akun Google native selalu muncul
        try {
          await _googleSignIn.signOut();
        } catch (_) {}

        // 2. Panggil dialog native Google Sign-In
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          return const AuthResponse.failure('Proses masuk dengan Google dibatalkan.');
        }

        fallbackDisplayName = googleUser.displayName;
        fallbackEmail = googleUser.email;
        fallbackPhotoUrl = googleUser.photoUrl;

        // 3. Dapatkan token autentikasi resmi (accessToken & idToken)
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        // 4. Validasi keberadaan token
        if (googleAuth.idToken == null && googleAuth.accessToken == null) {
          return const AuthResponse.failure(
            'Tidak berhasil memperoleh token autentikasi dari Google. Pastikan Google Play Services aktif dan koneksi internet stabil.',
          );
        }

        // 5. Buat kredensial OAuth untuk Firebase Auth
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // 6. Masuk ke Firebase Auth menggunakan kredensial Google
        userCredential = await _firebaseAuth.signInWithCredential(credential);
      }

      final User? firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        return const AuthResponse.failure('Gagal mendapatkan profil pengguna dari Google.');
      }

      final uid = firebaseUser.uid;
      final defaultName = (firebaseUser.displayName != null && firebaseUser.displayName!.trim().isNotEmpty)
          ? firebaseUser.displayName!.trim()
          : ((fallbackDisplayName != null && fallbackDisplayName.trim().isNotEmpty)
              ? fallbackDisplayName.trim()
              : 'Pengguna Google');
      final email = firebaseUser.email ?? fallbackEmail ?? '';
      final photoUrl = firebaseUser.photoURL ?? fallbackPhotoUrl ?? '';

      bool isProfileCompleted = false;
      String dob = '';
      String gender = 'Perempuan';
      String phone = '';
      String name = defaultName;

      // 7. Simpan / Perbarui data ke Cloud Firestore users/{uid} secara aman dengan timeout & fallback
      try {
        final userDocRef = _firestore.collection('users').doc(uid);
        final userDoc = await userDocRef.get().timeout(
          const Duration(seconds: 6),
          onTimeout: () => throw TimeoutException('Waktu sinkronisasi Firestore habis'),
        );

        if (!userDoc.exists) {
          // Pengguna baru pertama kali login dengan Google
          await userDocRef.set({
            'uid': uid,
            'name': defaultName,
            'email': email,
            'photoUrl': photoUrl,
            'photoPath': photoUrl,
            'phone': '',
            'dob': '',
            'gender': '',
            'role': 'user',
            'isBiodataComplete': false,
            'createdAt': FieldValue.serverTimestamp(),
            'lastLoginAt': FieldValue.serverTimestamp(),
            'authProvider': 'google',
          }).timeout(const Duration(seconds: 6));
        } else {
          // Pengguna lama: ambil data profil yang sudah ada di Firestore
          final data = userDoc.data() ?? {};
          final firestoreName = (data['name'] as String?)?.trim();
          if (firestoreName != null && firestoreName.isNotEmpty) {
            name = firestoreName; // Prioritaskan nama terbaru dari dokumen Firestore users/{uid}!
          }
          dob = (data['dob'] as String?)?.trim() ?? '';
          gender = (data['gender'] as String?)?.trim() ?? 'Perempuan';
          phone = (data['phone'] as String?)?.trim() ?? '';
          isProfileCompleted = (data['isBiodataComplete'] == true) ||
              (dob.isNotEmpty && gender.isNotEmpty && phone.isNotEmpty);

          // Update timestamp login tanpa menimpa nama profil kustom pengguna di Firestore
          await userDocRef.set({
            'name': name,
            'email': email,
            if (photoUrl.isNotEmpty && ((data['photoUrl'] as String?)?.isEmpty ?? true)) 'photoUrl': photoUrl,
            if (photoUrl.isNotEmpty && ((data['photoPath'] as String?)?.isEmpty ?? true)) 'photoPath': photoUrl,
            'isBiodataComplete': isProfileCompleted,
            'lastLoginAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true)).timeout(const Duration(seconds: 6));
        }
      } catch (firestoreError) {
        debugPrint('Peringatan saat sinkronisasi Firestore users/$uid: $firestoreError');
        // Fallback aman jika Firestore offline / lambat: gunakan data cache lokal
        final cached = _userProfileCache[uid];
        if (cached != null) {
          final cachedName = cached['name']?.trim();
          if (cachedName != null && cachedName.isNotEmpty) {
            name = cachedName;
          }
          dob = cached['dob'] ?? '';
          gender = cached['gender'] ?? 'Perempuan';
          phone = cached['phone'] ?? '';
          isProfileCompleted = (_biodataStatusCache[uid] == true) ||
              (dob.isNotEmpty && gender.isNotEmpty && phone.isNotEmpty);
        }
      }

      // 8. Update cache lokal aplikasi
      _userProfileCache[uid] = {
        'name': name,
        'dob': dob,
        'gender': gender,
        'email': email,
        'phone': phone,
        'joined': 'Bergabung sejak ${DateTime.now().year}',
        'avatar': photoUrl.isNotEmpty ? photoUrl : 'assets/avatar_zahra.png',
        'photo_path': photoUrl,
      };
      _biodataStatusCache[uid] = isProfileCompleted;

      _currentUser = UserModel(
        id: uid,
        name: name,
        email: email,
        username: email.contains('@') ? email.split('@').first : (email.isNotEmpty ? email : 'user'),
        role: UserRole.user,
        avatarUrl: photoUrl.isNotEmpty ? photoUrl : null,
        photoPath: photoUrl.isNotEmpty ? photoUrl : null,
        dob: dob,
        gender: gender,
        phone: phone,
        isBiodataComplete: isProfileCompleted,
      );

      _saveSession(_currentUser!);
      profileUpdateNotifier.value++;
      return AuthResponse.success(_currentUser);
    } on PlatformException catch (e) {
      debugPrint('PlatformException Google Sign-In: code=${e.code}, message=${e.message}, details=${e.details}');
      if (e.code == 'sign_in_canceled' || e.code == '12501' || e.message?.contains('canceled') == true) {
        return const AuthResponse.failure('Proses masuk dengan Google dibatalkan.');
      }

      final errorStr = '${e.code} ${e.message} ${e.details}'.toLowerCase();
      String message = 'Gagal masuk dengan Google.';

      if (errorStr.contains('10') || errorStr.contains('developer_error')) {
        message = 'Konfigurasi Google Sign-In belum selesai di Firebase. Pastikan SHA-1 fingerprint perangkat sudah didaftarkan pada Firebase Console.';
      } else if (errorStr.contains('12500') || errorStr.contains('sign_in_failed')) {
        message = 'Layanan Google Play gagal memproses login. Pastikan akun Google terhubung di perangkat dan Google Play Services telah diperbarui.';
      } else if (errorStr.contains('network') || errorStr.contains('7')) {
        message = 'Koneksi jaringan terganggu. Silakan periksa koneksi internet Anda.';
      } else {
        message = 'Gagal masuk dengan Google: ${e.message ?? e.code}';
      }
      return AuthResponse.failure(message);
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException Google: code=${e.code}, message=${e.message}');
      String message = 'Terjadi kesalahan autentikasi.';
      switch (e.code) {
        case 'account-exists-with-different-credential':
          message = 'Akun email ini sudah terdaftar dengan metode masuk lain. Silakan masuk menggunakan email & kata sandi.';
          break;
        case 'invalid-credential':
          message = 'Kredensial login Google tidak valid atau telah kedaluwarsa. Silakan coba lagi.';
          break;
        case 'user-disabled':
          message = 'Akun ini telah dinonaktifkan oleh administrator.';
          break;
        case 'operation-not-allowed':
          message = 'Metode masuk dengan Google belum diaktifkan di Firebase Authentication Console.';
          break;
        case 'network-request-failed':
          message = 'Koneksi internet bermasalah. Periksa jaringan Anda dan coba lagi.';
          break;
        case 'invalid-id-token':
          message = 'Token autentikasi Google tidak valid. Pastikan konfigurasi Firebase & SHA-1 telah sesuai.';
          break;
        default:
          message = e.message ?? 'Terjadi kesalahan saat masuk dengan Google.';
      }
      return AuthResponse.failure(message);
    } on FirebaseException catch (e) {
      debugPrint('FirebaseException Google: code=${e.code}, message=${e.message}');
      return AuthResponse.failure('Kendala layanan Firebase (${e.code}): ${e.message}');
    } catch (e) {
      debugPrint('Error signInWithGoogle: $e');
      return AuthResponse.failure('Gagal terhubung dengan layanan Google: $e');
    }
  }

  /// Pendaftaran manual email & kata sandi dengan Firebase Auth & Firestore
  Future<AuthResponse> registerWithEmailPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim();
    final cleanPass = password.trim();

    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: cleanPass,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        return const AuthResponse.failure('Gagal membuat akun.');
      }

      await firebaseUser.updateDisplayName(cleanName);

      final uid = firebaseUser.uid;

      // Simpan data otomatis ke Firestore pada koleksi users/{uid}
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'name': cleanName,
        'email': cleanEmail,
        'photoUrl': '',
        'photoPath': '',
        'phone': '',
        'dob': '',
        'gender': '',
        'role': 'user',
        'isBiodataComplete': false,
        'createdAt': FieldValue.serverTimestamp(),
        'authProvider': 'password',
      });

      _userProfileCache[uid] = {
        'name': cleanName,
        'dob': '',
        'gender': 'Perempuan',
        'email': cleanEmail,
        'phone': '',
        'joined': 'Bergabung sejak ${DateTime.now().year}',
        'avatar': 'assets/avatar_zahra.png',
        'photo_path': '',
      };
      _biodataStatusCache[uid] = false;
      _customPasswords[cleanEmail.toLowerCase()] = cleanPass;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('${_keyCustomPasswords}_${cleanEmail.toLowerCase()}', cleanPass);
      } catch (_) {}

      _currentUser = UserModel(
        id: uid,
        name: cleanName,
        email: cleanEmail,
        username: cleanEmail.split('@').first,
        role: UserRole.user,
        dob: '',
        gender: '',
        phone: '',
        isBiodataComplete: false,
      );

      _saveSession(_currentUser!);
      profileUpdateNotifier.value++;
      return AuthResponse.success(_currentUser);
    } on FirebaseAuthException catch (e) {
      String msg = 'Gagal mendaftarkan akun.';
      if (e.code == 'email-already-in-use') {
        msg = 'Email ini sudah terdaftar. Silakan masuk.';
      } else if (e.code == 'invalid-email') {
        msg = 'Format email tidak valid.';
      } else if (e.code == 'weak-password') {
        msg = 'Kata sandi terlalu lemah.';
      } else if (e.message != null) {
        msg = e.message!;
      }
      return AuthResponse.failure(msg);
    } catch (e) {
      // Offline fallback: allow local registration
      final uid = 'usr_${DateTime.now().millisecondsSinceEpoch}';
      _userProfileCache[uid] = {
        'name': cleanName,
        'dob': '',
        'gender': 'Perempuan',
        'email': cleanEmail,
        'phone': '',
        'joined': 'Bergabung sejak ${DateTime.now().year}',
        'avatar': 'assets/avatar_zahra.png',
        'photo_path': '',
      };
      _biodataStatusCache[uid] = false;
      _customPasswords[cleanEmail.toLowerCase()] = cleanPass;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('${_keyCustomPasswords}_${cleanEmail.toLowerCase()}', cleanPass);
      } catch (_) {}

      _currentUser = UserModel(
        id: uid,
        name: cleanName,
        email: cleanEmail,
        username: cleanEmail.split('@').first,
        role: UserRole.user,
        isBiodataComplete: false,
      );

      _saveSession(_currentUser!);
      return AuthResponse.success(_currentUser);
    }
  }

  /// Login via email & kata sandi
  Future<AuthResponse> login({
    required String identifier,
    required String password,
  }) async {
    final cleanId = identifier.trim().toLowerCase();
    final cleanPass = password.trim();

    // 0. Cek apakah akun telah dihapus secara permanen
    if (_deletedAccounts.contains(cleanId)) {
      return const AuthResponse.failure('Akun ini telah dihapus permanen dan tidak dapat digunakan.');
    }

    final effectiveEmail = _customEmails[cleanId] ?? cleanId;
    if (_deletedAccounts.contains(effectiveEmail)) {
      return const AuthResponse.failure('Akun ini telah dihapus permanen dan tidak dapat digunakan.');
    }

    String? customPass = _customPasswords[effectiveEmail] ?? _customPasswords[cleanId];
    if (customPass == null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        customPass = prefs.getString('${_keyCustomPasswords}_$effectiveEmail') ??
            prefs.getString('${_keyCustomPasswords}_$cleanId');
        if (customPass != null) {
          _customPasswords[effectiveEmail] = customPass;
        }
      } catch (_) {}
    }

    // 1. Cek Admin preset untuk kenyamanan pengujian
    if ((effectiveEmail == 'adminobesight@gmail.com' || effectiveEmail == 'admin@obesight.com' || cleanId == 'admin') &&
        (cleanPass == (customPass ?? 'admin123'))) {
      final bmiInfo = getUserBmi(defaultAdminAccount.id);
      _currentUser = defaultAdminAccount.copyWith(
        isBiodataComplete: isBiodataCompleted(defaultAdminAccount.id),
        bmiScore: (bmiInfo['bmi'] as num).toDouble(),
        bmiCategory: bmiInfo['category'] as String,
        obesityRisk: bmiInfo['risk'] as String,
      );
      _saveSession(_currentUser!);
      profileUpdateNotifier.value++;
      return AuthResponse.success(_currentUser);
    }

    // 2. Cek User preset 1 (zahraafitriana)
    if ((effectiveEmail == 'zahraafitriana@gmail.com' || cleanId == 'zahraafitriana') &&
        (cleanPass == (customPass ?? 'Zahra1234') || cleanPass == (customPass ?? 'zahra1234'))) {
      final bmiInfo = getUserBmi(defaultUserAccount.id);
      _currentUser = defaultUserAccount.copyWith(
        isBiodataComplete: isBiodataCompleted(defaultUserAccount.id),
        bmiScore: (bmiInfo['bmi'] as num).toDouble(),
        bmiCategory: bmiInfo['category'] as String,
        obesityRisk: bmiInfo['risk'] as String,
      );
      _saveSession(_currentUser!);
      profileUpdateNotifier.value++;
      return AuthResponse.success(_currentUser);
    }

    // 3. Cek User preset 2 (zahrafitrie)
    if ((effectiveEmail == 'zahrafitrie@gmail.com' || cleanId == 'zahrafitrie') &&
        cleanPass == (customPass ?? 'zohf1234')) {
      final bmiInfo = getUserBmi(alternativeUserAccount.id);
      _currentUser = alternativeUserAccount.copyWith(
        isBiodataComplete: isBiodataCompleted(alternativeUserAccount.id),
        bmiScore: (bmiInfo['bmi'] as num).toDouble(),
        bmiCategory: bmiInfo['category'] as String,
        obesityRisk: bmiInfo['risk'] as String,
      );
      _saveSession(_currentUser!);
      profileUpdateNotifier.value++;
      return AuthResponse.success(_currentUser);
    }

    // 4. Coba login dengan Firebase Authentication
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: effectiveEmail,
        password: cleanPass,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser != null) {
        final uid = firebaseUser.uid;
        // Ambil data profil dari Firestore
        final doc = await _firestore.collection('users').doc(uid).get();
        final data = doc.data() ?? {};

        // Validasi jika akun telah dihapus di Firestore
        if (data['isDeleted'] == true || data['status'] == 'deleted') {
          await _firebaseAuth.signOut();
          _deletedAccounts.add(effectiveEmail);
          return const AuthResponse.failure('Akun ini telah dihapus permanen dan tidak dapat digunakan.');
        }

        final name = (data['name'] as String?) ?? firebaseUser.displayName ?? effectiveEmail.split('@').first;
        final email = (data['email'] as String?) ?? firebaseUser.email ?? effectiveEmail;
        final photoUrl = (data['photoUrl'] ?? data['photoPath']) as String? ?? '';
        final dob = (data['dob'] as String?) ?? '';
        final rawGender = (data['gender'] as String?)?.trim() ?? '';
        final phone = (data['phone'] as String?) ?? '';
        final isGated = (data['isBiodataComplete'] == true) ||
            (dob.isNotEmpty && rawGender.isNotEmpty && phone.isNotEmpty);
        final gender = rawGender.isNotEmpty ? rawGender : 'Perempuan';

        _userProfileCache[uid] = {
          'name': name,
          'dob': dob,
          'gender': gender,
          'email': email,
          'phone': phone,
          'joined': 'Bergabung sejak ${DateTime.now().year}',
          'avatar': photoUrl.isNotEmpty ? photoUrl : 'assets/avatar_zahra.png',
          'photo_path': photoUrl,
        };
        _biodataStatusCache[uid] = isGated;

        _currentUser = UserModel(
          id: uid,
          name: name,
          email: email,
          username: email.split('@').first,
          role: (data['role'] == 'admin') ? UserRole.admin : UserRole.user,
          avatarUrl: photoUrl,
          photoPath: photoUrl,
          dob: dob,
          gender: gender,
          phone: phone,
          isBiodataComplete: isGated,
        );

        _saveSession(_currentUser!);
        profileUpdateNotifier.value++;
        return AuthResponse.success(_currentUser);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException login: ${e.code} - ${e.message}');
      // Cek apakah kata sandi cocok dengan hasil update OTP kustom
      if (customPass == cleanPass || await _checkFirestoreCustomPassword(effectiveEmail, cleanPass)) {
        return await _restoreProfileForEmail(effectiveEmail);
      }
      String msg = 'Email atau kata sandi salah.';
      if (e.code == 'user-not-found') {
        msg = 'Akun dengan email ini belum terdaftar.';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        msg = 'Kata sandi atau email salah.';
      }
      return AuthResponse.failure(msg);
    } catch (e) {
      debugPrint('General login error: $e');
    }

    if (customPass == cleanPass || await _checkFirestoreCustomPassword(effectiveEmail, cleanPass)) {
      return await _restoreProfileForEmail(effectiveEmail);
    }

    return const AuthResponse.failure('Email atau kata sandi salah');
  }

  /// Login khusus Administrator dengan verifikasi ketat field 'role' di Cloud Firestore.
  /// Hanya akun yang memiliki field role: 'admin' yang diizinkan masuk ke dashboard admin.
  Future<AuthResponse> loginAdmin({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPass = password.trim();

    // 0. Cek apakah akun terdaftar di daftar akun yang dihapus
    if (_deletedAccounts.contains(cleanEmail)) {
      return const AuthResponse.failure('Akun ini telah dinonaktifkan.');
    }

    // 1. Akun Preset Administrator (untuk pengujian & offline fallback)
    if ((cleanEmail == 'adminobesight@gmail.com' || cleanEmail == 'admin@obesight.com' || cleanEmail == 'admin') &&
        (cleanPass == 'admin123')) {
      final bmiInfo = getUserBmi(defaultAdminAccount.id);
      _currentUser = defaultAdminAccount.copyWith(
        isBiodataComplete: true,
        bmiScore: (bmiInfo['bmi'] as num).toDouble(),
        bmiCategory: bmiInfo['category'] as String,
        obesityRisk: bmiInfo['risk'] as String,
      );
      _saveSession(_currentUser!);
      profileUpdateNotifier.value++;
      return AuthResponse.success(_currentUser);
    }

    // 2. Autentikasi Firebase Authentication dan Verifikasi Firestore role: 'admin'
    if (isFirebaseAvailable) {
      try {
        final credential = await _firebaseAuth.signInWithEmailAndPassword(
          email: cleanEmail,
          password: cleanPass,
        );

        final firebaseUser = credential.user;
        if (firebaseUser == null) {
          return const AuthResponse.failure('Gagal memverifikasi akun administrator.');
        }

        final uid = firebaseUser.uid;

        // Verifikasi ke dokumen Firestore users/{uid}
        final userDoc = await _firestore.collection('users').doc(uid).get().timeout(
          const Duration(seconds: 6),
          onTimeout: () => throw TimeoutException('Waktu verifikasi Firestore habis'),
        );

        if (!userDoc.exists || userDoc.data() == null) {
          await _firebaseAuth.signOut();
          return const AuthResponse.failure('Akses ditolak: Data pengguna tidak ditemukan di sistem.');
        }

        final data = userDoc.data()!;
        final role = data['role'] as String?;

        // VALIDASI ROLE: Hanya 'admin' yang diperbolehkan!
        if (role != 'admin') {
          await _firebaseAuth.signOut();
          return const AuthResponse.failure('Akses ditolak: Akun Anda tidak memiliki hak akses Administrator.');
        }

        final name = (data['name'] as String?)?.trim() ?? firebaseUser.displayName ?? 'Administrator';
        final userEmail = (data['email'] as String?)?.trim() ?? firebaseUser.email ?? cleanEmail;
        final photoUrl = (data['photoUrl'] ?? data['photoPath']) as String? ?? '';
        final phone = (data['phone'] as String?) ?? '';
        final dob = (data['dob'] as String?) ?? '';
        final gender = (data['gender'] as String?) ?? 'Laki-laki';

        _currentUser = UserModel(
          id: uid,
          name: name,
          email: userEmail,
          username: userEmail.split('@').first,
          role: UserRole.admin,
          avatarUrl: photoUrl.isNotEmpty ? photoUrl : null,
          photoPath: photoUrl.isNotEmpty ? photoUrl : null,
          phone: phone,
          dob: dob,
          gender: gender,
          isBiodataComplete: true,
        );

        _saveSession(_currentUser!);
        profileUpdateNotifier.value++;
        return AuthResponse.success(_currentUser);
      } on FirebaseAuthException catch (e) {
        debugPrint('FirebaseAuthException loginAdmin: ${e.code} - ${e.message}');
        String msg = 'Email atau kata sandi salah.';
        if (e.code == 'user-not-found') {
          msg = 'Akun administrator dengan email ini tidak ditemukan.';
        } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          msg = 'Email atau kata sandi administrator salah.';
        } else if (e.code == 'user-disabled') {
          msg = 'Akun administrator ini telah dinonaktifkan.';
        } else if (e.code == 'too-many-requests') {
          msg = 'Terlalu banyak percobaan gagal. Silakan tunggu beberapa saat lagi.';
        } else if (e.code == 'network-request-failed') {
          msg = 'Koneksi internet bermasalah. Periksa jaringan Anda.';
        }
        return AuthResponse.failure(msg);
      } catch (e) {
        debugPrint('General error in loginAdmin: $e');
        return AuthResponse.failure('Gagal memproses autentikasi: $e');
      }
    }

    return const AuthResponse.failure('Email atau kata sandi administrator salah.');
  }

  /// Mendengarkan daftar seluruh pengguna terdaftar dari Cloud Firestore secara real-time
  Stream<List<UserModel>> getAllUsersStream() {
    if (!isFirebaseAvailable) {
      final now = DateTime.now();
      return Stream.value([
        defaultAdminAccount.copyWith(createdAt: now.subtract(const Duration(days: 6))),
        defaultUserAccount.copyWith(createdAt: now.subtract(const Duration(days: 3))),
        alternativeUserAccount.copyWith(
          createdAt: now.subtract(const Duration(days: 2)),
          updatedAt: now.subtract(const Duration(hours: 4)),
        ),
        zahraCantikAccount.copyWith(createdAt: now.subtract(const Duration(hours: 2))),
        akuZahraAccount.copyWith(createdAt: now.subtract(const Duration(hours: 5))),
      ]);
    }

    try {
      return _firestore.collection('users').snapshots().map((snapshot) {
        if (snapshot.docs.isEmpty) {
          final now = DateTime.now();
          return [
            defaultAdminAccount.copyWith(createdAt: now.subtract(const Duration(days: 6))),
            defaultUserAccount.copyWith(createdAt: now.subtract(const Duration(days: 3))),
            alternativeUserAccount.copyWith(
              createdAt: now.subtract(const Duration(days: 2)),
              updatedAt: now.subtract(const Duration(hours: 4)),
            ),
          ];
        }
        return snapshot.docs.map((doc) {
          return UserModel.fromMap(doc.data(), doc.id);
        }).toList();
      }).handleError((e) {
        debugPrint('Notice getAllUsersStream: $e');
        final now = DateTime.now();
        return [
          defaultAdminAccount.copyWith(createdAt: now.subtract(const Duration(days: 6))),
          defaultUserAccount.copyWith(createdAt: now.subtract(const Duration(days: 3))),
          alternativeUserAccount.copyWith(
            createdAt: now.subtract(const Duration(days: 2)),
            updatedAt: now.subtract(const Duration(hours: 4)),
          ),
        ];
      });
    } catch (e) {
      debugPrint('getAllUsersStream exception: $e');
      final now = DateTime.now();
      return Stream.value([
        defaultAdminAccount.copyWith(createdAt: now.subtract(const Duration(days: 6))),
        defaultUserAccount.copyWith(createdAt: now.subtract(const Duration(days: 3))),
      ]);
    }
  }

  /// Mendengarkan jumlah total pengguna terdaftar dari Cloud Firestore secara real-time
  Stream<int> getTotalUsersCountStream() {
    if (!isFirebaseAvailable) {
      return Stream.value(_userProfileCache.isNotEmpty ? _userProfileCache.length : 1);
    }
    try {
      return _firestore.collection('users').snapshots().map((snapshot) {
        final count = snapshot.docs.length;
        return count > 0 ? count : 1;
      }).handleError((_) => 1);
    } catch (_) {
      return Stream.value(1);
    }
  }

  /// Mendengarkan jumlah total artikel kesehatan dari Cloud Firestore secara real-time
  Stream<int> getTotalArticlesCountStream() {
    if (!isFirebaseAvailable) {
      return Stream.value(6);
    }
    try {
      return _firestore.collection('articles').snapshots().map((snapshot) {
        final count = snapshot.docs.length;
        return count > 0 ? count : 5;
      }).handleError((_) => 5);
    } catch (_) {
      return Stream.value(5);
    }
  }

  /// Login mock Google account (untuk demo picker)
  Future<AuthResponse> loginWithGoogleAccount(UserModel account) async {
    if (!_biodataStatusCache.containsKey(account.id)) {
      _biodataStatusCache[account.id] = account.isBiodataComplete;
    }
    if (!_userProfileCache.containsKey(account.id)) {
      _userProfileCache[account.id] = {
        'name': account.name,
        'dob': account.dob ?? '',
        'gender': account.gender ?? 'Perempuan',
        'email': account.email,
        'phone': account.phone ?? '',
        'joined': 'Bergabung sejak September 2025',
        'avatar': account.avatarUrl ?? 'assets/avatar_zahra.png',
        'photo_path': account.photoPath ?? '',
      };
    }

    // Also persist to Firestore if online
    try {
      await _firestore.collection('users').doc(account.id).set({
        'uid': account.id,
        'name': account.name,
        'email': account.email,
        'photoUrl': account.avatarUrl ?? '',
        'phone': account.phone ?? '',
        'dob': account.dob ?? '',
        'gender': account.gender ?? '',
        'role': account.isAdmin ? 'admin' : 'user',
        'isBiodataComplete': account.isBiodataComplete,
      }, SetOptions(merge: true));
    } catch (_) {}

    final isComplete = isBiodataCompleted(account.id);
    final bmiInfo = getUserBmi(account.id);
    _currentUser = account.copyWith(
      isBiodataComplete: isComplete,
      bmiScore: (bmiInfo['bmi'] as num).toDouble(),
      bmiCategory: bmiInfo['category'] as String,
      obesityRisk: bmiInfo['risk'] as String,
    );
    _saveSession(_currentUser!);
    profileUpdateNotifier.value++;
    return AuthResponse.success(_currentUser);
  }

  /// Mengirim email resmi reset kata sandi melalui Firebase Authentication
  Future<AuthResponse> sendPasswordResetEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) {
      return const AuthResponse.failure('Email tidak boleh kosong.');
    }
    if (!cleanEmail.contains('@') || !cleanEmail.contains('.')) {
      return const AuthResponse.failure('Format email tidak valid.');
    }

    try {
      if (isFirebaseAvailable) {
        await _firebaseAuth.sendPasswordResetEmail(email: cleanEmail);
        return const AuthResponse.success(null);
      } else {
        // Fallback untuk mode offline / testing
        debugPrint('Firebase not initialized; simulated password reset for $cleanEmail');
        return const AuthResponse.success(null);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException sendPasswordResetEmail: ${e.code} - ${e.message}');
      String msg = 'Gagal mengirim email reset kata sandi.';
      if (e.code == 'user-not-found') {
        msg = 'Akun dengan email ini belum terdaftar.';
      } else if (e.code == 'invalid-email') {
        msg = 'Format alamat email tidak valid.';
      } else if (e.code == 'network-request-failed') {
        msg = 'Koneksi internet bermasalah. Periksa jaringan Anda.';
      } else if (e.message != null && e.message!.isNotEmpty) {
        msg = e.message!;
      }
      return AuthResponse.failure(msg);
    } catch (e) {
      debugPrint('General sendPasswordResetEmail error: $e');
      return AuthResponse.failure('Terjadi kendala saat mengirim email: $e');
    }
  }

  /// Hapus akun permanen dari Firebase Auth dan Cloud Firestore
  Future<AuthResponse> deleteAccount({required String password}) async {
    try {
      final user = firebaseCurrentUser;
      final currentEmail = user?.email ?? _currentUser?.email ?? '';
      final currentUid = user?.uid ?? _currentUser?.id ?? '';
      final cleanPass = password.trim();

      // 1. Re-autentikasi pengguna Firebase jika ada
      if (user != null && currentEmail.isNotEmpty) {
        try {
          final cred = EmailAuthProvider.credential(
            email: currentEmail,
            password: cleanPass,
          );
          await user.reauthenticateWithCredential(cred);
        } on FirebaseAuthException catch (e) {
          debugPrint('Reauth deleteAccount error: ${e.code}');
          if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
            return const AuthResponse.failure('Kata sandi yang Anda masukkan salah.');
          }
        }
      }

      // 2. Tandai blokir permanen dan hapus dokumen profil di Firestore (users/{uid})
      if (currentUid.isNotEmpty && isFirebaseAvailable) {
        try {
          await _firestore.collection('users').doc(currentUid).set({
            'isDeleted': true,
            'status': 'deleted',
            'deletedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          await _firestore.collection('users').doc(currentUid).delete();
        } catch (e) {
          debugPrint('Notice deleting Firestore document: $e');
        }
      }

      // 3. Hapus akun di Firebase Authentication (user.delete())
      if (user != null) {
        try {
          await user.delete();
        } on FirebaseAuthException catch (e) {
          debugPrint('FirebaseAuth user.delete() error: ${e.code} - ${e.message}');
          if (e.code == 'requires-recent-login') {
            return const AuthResponse.failure('Sesi telah berakhir. Silakan masuk kembali sebelum menghapus akun.');
          }
        }
      }

      // 4. Daftarkan email ke daftar akun yang dihapus permanen
      if (currentEmail.isNotEmpty) {
        _deletedAccounts.add(currentEmail.toLowerCase());
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(_keyDeletedAccounts, _deletedAccounts.toList());
      }

      // 5. Bersihkan cache lokal & sesi
      if (currentUid.isNotEmpty) {
        _userProfileCache.remove(currentUid);
        _biodataStatusCache.remove(currentUid);
        _userBmiCache.remove(currentUid);
      }
      _clearSession();
      _currentUser = null;

      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      if (isFirebaseAvailable) {
        try {
          await _firebaseAuth.signOut();
        } catch (_) {}
      }

      profileUpdateNotifier.value++;
      return const AuthResponse.success(null);
    } catch (e) {
      debugPrint('Error deleteAccount: $e');
      return AuthResponse.failure('Gagal menghapus akun: $e');
    }
  }

  /// Ubah kata sandi di Firebase Authentication & Cloud Firestore
  Future<AuthResponse> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final cleanOldPass = currentPassword.trim();
    final cleanNewPass = newPassword.trim();
    final user = _firebaseAuth.currentUser;
    final email = user?.email ?? _currentUser?.email ?? '';
    final uid = user?.uid ?? _currentUser?.id ?? '';

    try {
      // 1. Re-autentikasi dan perbarui di Firebase Auth jika user aktif
      if (user != null && email.isNotEmpty) {
        try {
          final cred = EmailAuthProvider.credential(
            email: email,
            password: cleanOldPass,
          );
          await user.reauthenticateWithCredential(cred);
          await user.updatePassword(cleanNewPass);
        } on FirebaseAuthException catch (e) {
          debugPrint('FirebaseAuthException changePassword: ${e.code} - ${e.message}');
          if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
            return const AuthResponse.failure('Kata sandi saat ini tidak cocok.');
          } else if (e.code == 'weak-password') {
            return const AuthResponse.failure('Kata sandi baru terlalu lemah.');
          } else if (e.code == 'requires-recent-login') {
            return const AuthResponse.failure('Sesi Anda telah kedaluwarsa. Silakan masuk kembali.');
          }
          return AuthResponse.failure(e.message ?? 'Gagal memperbarui kata sandi di Firebase Auth.');
        }
      }

      // 2. Perbarui timestamp perubahan kata sandi di Firestore (Tanpa menyimpan teks sandi terbuka!)
      if (uid.isNotEmpty && isFirebaseAvailable) {
        try {
          await _firestore.collection('users').doc(uid).set({
            'passwordUpdatedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Notice updating password timestamp in Firestore: $e');
        }
      }

      return AuthResponse.success(_currentUser);
    } catch (e) {
      debugPrint('Error changePassword: $e');
      return AuthResponse.failure('Terjadi kesalahan: $e');
    }
  }

  /// Ubah email di Firebase Authentication & Cloud Firestore
  Future<AuthResponse> changeEmail({
    required String currentPassword,
    required String newEmail,
  }) async {
    final cleanEmail = newEmail.trim().toLowerCase();
    final cleanPassword = currentPassword.trim();

    if (!cleanEmail.contains('@') || !cleanEmail.contains('.')) {
      return const AuthResponse.failure('Alamat email baru tidak valid.');
    }

    final user = _firebaseAuth.currentUser;
    final oldEmail = user?.email ?? _currentUser?.email ?? '';
    final uid = user?.uid ?? _currentUser?.id ?? '';

    try {
      // 1. Re-autentikasi dan perbarui di Firebase Auth
      if (user != null && oldEmail.isNotEmpty) {
        try {
          final cred = EmailAuthProvider.credential(
            email: oldEmail,
            password: cleanPassword,
          );
          await user.reauthenticateWithCredential(cred);
          await user.verifyBeforeUpdateEmail(cleanEmail);
        } on FirebaseAuthException catch (e) {
          debugPrint('FirebaseAuthException changeEmail: ${e.code} - ${e.message}');
          if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
            return const AuthResponse.failure('Kata sandi saat ini tidak cocok.');
          } else if (e.code == 'email-already-in-use') {
            return const AuthResponse.failure('Alamat email baru sudah terdaftar.');
          } else if (e.code == 'invalid-email') {
            return const AuthResponse.failure('Format email tidak valid.');
          } else if (e.code == 'requires-recent-login') {
            return const AuthResponse.failure('Sesi Anda telah kedaluwarsa. Silakan masuk kembali.');
          }
          return AuthResponse.failure(e.message ?? 'Gagal memperbarui email di Firebase Auth.');
        }
      }

      // 2. Simpan ke Firestore users/{uid} dan perbarui profil
      await updateUserProfile(
        userId: uid.isNotEmpty ? uid : 'usr_001',
        email: cleanEmail,
      );

      // 3. Simpan relasi pembaruan email
      if (oldEmail.isNotEmpty) {
        _customEmails[oldEmail.toLowerCase()] = cleanEmail;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('${_keyCustomEmails}_${oldEmail.toLowerCase()}', cleanEmail);
      }

      return AuthResponse.success(_currentUser);
    } catch (e) {
      debugPrint('Error changeEmail: $e');
      return AuthResponse.failure('Terjadi kesalahan: $e');
    }
  }

  /// Menghasilkan kode OTP 6 digit custom dan menyimpannya ke Cloud Firestore
  Future<OtpResponse> generateAndSendOtp(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) {
      return const OtpResponse.failure('Email tidak boleh kosong.');
    }
    if (!cleanEmail.contains('@') || !cleanEmail.contains('.')) {
      return const OtpResponse.failure('Format alamat email tidak valid.');
    }

    if (_deletedAccounts.contains(cleanEmail)) {
      return const OtpResponse.failure('Akun ini telah dihapus permanen.');
    }

    // Buat kode OTP acak 6 digit
    final random = Random();
    final otpCode = (100000 + random.nextInt(900000)).toString();
    final expiry = DateTime.now().add(const Duration(minutes: 10));

    // Simpan ke memory cache lokal
    _activeOtps[cleanEmail] = otpCode;
    _activeOtpExpiry[cleanEmail] = expiry;

    // Simpan ke Firestore koleksi otp_verifications/{email}
    if (isFirebaseAvailable) {
      try {
        await _firestore.collection('otp_verifications').doc(cleanEmail).set({
          'email': cleanEmail,
          'otp': otpCode,
          'createdAt': FieldValue.serverTimestamp(),
          'expiresAt': Timestamp.fromDate(expiry),
          'verified': false,
        });
      } catch (e) {
        debugPrint('Notice saving OTP to Firestore: $e');
      }
    }

    // Kirim kode OTP langsung ke email pengguna menggunakan EmailService
    try {
      await EmailService().sendOtpEmail(
        recipientEmail: cleanEmail,
        otpCode: otpCode,
      );
    } catch (e) {
      debugPrint('Notice sending OTP email: $e');
    }

    return OtpResponse.success(
      otpCode,
      'Kode verifikasi OTP berhasil dikirim ke email $cleanEmail.',
    );
  }

  /// Verifikasi kode OTP yang dimasukkan oleh pengguna
  Future<AuthResponse> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanOtp = otp.trim();

    if (cleanOtp.length != 6) {
      return const AuthResponse.failure('Masukkan lengkap 6 digit kode OTP.');
    }

    // 1. Cek memory cache lokal
    final cachedOtp = _activeOtps[cleanEmail];
    final expiry = _activeOtpExpiry[cleanEmail];
    if (cachedOtp != null && expiry != null) {
      if (DateTime.now().isAfter(expiry)) {
        return const AuthResponse.failure('Kode OTP telah kedaluwarsa. Silakan minta kode baru.');
      }
      if (cachedOtp == cleanOtp) {
        return const AuthResponse.success(null);
      }
    }

    // 2. Cek Cloud Firestore
    if (isFirebaseAvailable) {
      try {
        final doc = await _firestore.collection('otp_verifications').doc(cleanEmail).get();
        if (doc.exists) {
          final data = doc.data() ?? {};
          final dbOtp = data['otp'] as String?;
          final expTimestamp = data['expiresAt'] as Timestamp?;
          if (expTimestamp != null && DateTime.now().isAfter(expTimestamp.toDate())) {
            return const AuthResponse.failure('Kode OTP telah kedaluwarsa. Silakan minta kode baru.');
          }
          if (dbOtp == cleanOtp) {
            await doc.reference.update({'verified': true});
            return const AuthResponse.success(null);
          }
        }
      } catch (e) {
        debugPrint('Notice verifying OTP with Firestore: $e');
      }
    }

    return const AuthResponse.failure('Kode verifikasi tidak sesuai. Periksa kembali 6 digit kode OTP Anda.');
  }

  /// Reset kata sandi pengguna dengan OTP yang telah divalidasi
  Future<AuthResponse> resetPasswordWithOtp({
    required String email,
    required String newPassword,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanNewPass = newPassword.trim();

    if (cleanNewPass.length < 8) {
      return const AuthResponse.failure('Kata sandi minimal 8 karakter.');
    }

    try {
      // 1. Simpan kata sandi baru ke Firestore users
      if (isFirebaseAvailable) {
        try {
          final query = await _firestore.collection('users').where('email', isEqualTo: cleanEmail).limit(1).get();
          if (query.docs.isNotEmpty) {
            await query.docs.first.reference.update({
              'customPassword': cleanNewPass,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        } catch (e) {
          debugPrint('Notice updating user password in Firestore: $e');
        }
      }

      // 2. Simpan ke memory & persistent preferences
      _customPasswords[cleanEmail] = cleanNewPass;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('${_keyCustomPasswords}_$cleanEmail', cleanNewPass);
      } catch (_) {}

      // 3. Jika sesi aktif di Firebase Auth sama dengan target email, update
      final user = firebaseCurrentUser;
      if (user != null && user.email?.toLowerCase() == cleanEmail) {
        try {
          await user.updatePassword(cleanNewPass);
        } catch (_) {}
      }

      // 4. Hapus OTP aktif
      _activeOtps.remove(cleanEmail);
      _activeOtpExpiry.remove(cleanEmail);
      if (isFirebaseAvailable) {
        try {
          await _firestore.collection('otp_verifications').doc(cleanEmail).delete();
        } catch (_) {}
      }

      return const AuthResponse.success(null);
    } catch (e) {
      debugPrint('Error resetPasswordWithOtp: $e');
      return AuthResponse.failure('Gagal memperbarui kata sandi: $e');
    }
  }

  Future<AuthResponse> _restoreProfileForEmail(String email) async {
    try {
      final query = await _firestore.collection('users').where('email', isEqualTo: email).limit(1).get();
      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = doc.data();
        final uid = doc.id;
        final name = (data['name'] as String?) ?? email.split('@').first;
        final photoUrl = (data['photoUrl'] ?? data['photoPath']) as String? ?? '';
        final dob = (data['dob'] as String?) ?? '';
        final rawGender = (data['gender'] as String?)?.trim() ?? '';
        final phone = (data['phone'] as String?) ?? '';
        final isGated = (data['isBiodataComplete'] == true) ||
            (dob.isNotEmpty && rawGender.isNotEmpty && phone.isNotEmpty);
        final gender = rawGender.isNotEmpty ? rawGender : 'Perempuan';

        _currentUser = UserModel(
          id: uid,
          name: name,
          email: email,
          username: email.split('@').first,
          role: (data['role'] == 'admin') ? UserRole.admin : UserRole.user,
          avatarUrl: photoUrl,
          photoPath: photoUrl,
          dob: dob,
          gender: gender,
          phone: phone,
          isBiodataComplete: isGated,
        );
        _saveSession(_currentUser!);
        profileUpdateNotifier.value++;
        return AuthResponse.success(_currentUser);
      }
    } catch (e) {
      debugPrint('Error _restoreProfileForEmail: $e');
    }

    // Fallback ke memory profile cache (offline / local testing)
    for (final entry in _userProfileCache.entries) {
      if (entry.value['email']?.toLowerCase() == email.toLowerCase()) {
        final uid = entry.key;
        final prof = entry.value;
        final isGated = _biodataStatusCache[uid] ?? false;
        _currentUser = UserModel(
          id: uid,
          name: prof['name'] ?? email.split('@').first,
          email: email,
          username: email.split('@').first,
          role: UserRole.user,
          avatarUrl: prof['photo_path'] ?? prof['avatar'],
          photoPath: prof['photo_path'],
          dob: prof['dob'],
          gender: prof['gender'],
          phone: prof['phone'],
          isBiodataComplete: isGated,
        );
        _saveSession(_currentUser!);
        profileUpdateNotifier.value++;
        return AuthResponse.success(_currentUser);
      }
    }

    // Fallback akun lokal default untuk email tersebut
    final uid = 'usr_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
    _currentUser = UserModel(
      id: uid,
      name: email.split('@').first,
      email: email,
      username: email.split('@').first,
      role: UserRole.user,
      isBiodataComplete: true,
    );
    _saveSession(_currentUser!);
    profileUpdateNotifier.value++;
    return AuthResponse.success(_currentUser);
  }

  Future<bool> _checkFirestoreCustomPassword(String email, String password) async {
    try {
      final query = await _firestore.collection('users').where('email', isEqualTo: email).limit(1).get();
      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();
        if (data['isDeleted'] == true || data['status'] == 'deleted') return false;
        return data['customPassword'] == password;
      }
    } catch (_) {}
    return false;
  }

  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    try {
      await _firebaseAuth.signOut();
    } catch (_) {}
    _clearSession();
    _currentUser = null;
    profileUpdateNotifier.value++;
  }
}
