import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  FirebaseAuth get _firebaseAuth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  GoogleSignIn get _googleSignIn => GoogleSignIn();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

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
    email: 'admin@obesight.com',
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
      'email': 'admin@obesight.com',
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

  /// Get current cached profile data
  Map<String, String> getUserProfile(String userId) {
    if (_userProfileCache.containsKey(userId)) {
      return _userProfileCache[userId]!;
    }
    if (_currentUser != null && _currentUser!.id == userId) {
      return {
        'name': _currentUser!.name,
        'dob': _currentUser!.dob ?? '',
        'gender': _currentUser!.gender ?? 'Perempuan',
        'email': _currentUser!.email,
        'phone': _currentUser!.phone ?? '',
        'joined': 'Bergabung sejak Juni 2026',
        'avatar': _currentUser!.avatarUrl ?? 'assets/avatar_zahra.png',
        'photo_path': _currentUser!.photoPath ?? '',
      };
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

  /// Update user profile both locally and automatically to Firestore (users/{uid})
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
      _firestore.collection('users').doc(userId).set(firestoreData, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Notice saving to Firestore user doc: $e');
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

  /// Masuk dengan Google menggunakan package google_sign_in asli
  /// yang langsung terhubung ke Firebase Auth (GoogleAuthProvider).
  Future<AuthResponse> signInWithGoogle() async {
    try {
      if (Platform.environment.containsKey('FLUTTER_TEST')) {
        return const AuthResponse.failure('Test environment');
      }

      // 1. Trigger Google Sign-In prompt
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return const AuthResponse.failure('Proses masuk dengan Google dibatalkan.');
      }

      // 2. Obtain auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Create a new credential for Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase Auth
      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        return const AuthResponse.failure('Gagal mendapatkan profil pengguna dari Google.');
      }

      final uid = firebaseUser.uid;
      final name = firebaseUser.displayName ?? googleUser.displayName ?? 'Pengguna Google';
      final email = firebaseUser.email ?? googleUser.email;
      final photoUrl = firebaseUser.photoURL ?? googleUser.photoUrl ?? '';

      // 5. Simpan / Perbarui data secara otomatis ke Firestore pada koleksi users/{uid}
      final userDocRef = _firestore.collection('users').doc(uid);
      final userDoc = await userDocRef.get();

      bool isProfileCompleted = false;
      String dob = '';
      String gender = 'Perempuan';
      String phone = '';

      if (!userDoc.exists) {
        // Pengguna baru pertama kali login
        await userDocRef.set({
          'uid': uid,
          'name': name,
          'email': email,
          'photoUrl': photoUrl,
          'photoPath': photoUrl,
          'phone': '',
          'dob': '',
          'gender': '',
          'role': 'user',
          'isBiodataComplete': false,
          'createdAt': FieldValue.serverTimestamp(),
          'authProvider': 'google',
        });
      } else {
        // Pengguna lama: ambil data gating yang sudah ada
        final data = userDoc.data() ?? {};
        dob = (data['dob'] as String?)?.trim() ?? '';
        gender = (data['gender'] as String?)?.trim() ?? 'Perempuan';
        phone = (data['phone'] as String?)?.trim() ?? '';
        isProfileCompleted = dob.isNotEmpty && gender.isNotEmpty && phone.isNotEmpty;

        // Pastikan foto dan nama terbaru tersinkronisasi jika diperbarui di akun Google
        await userDocRef.set({
          'name': name,
          'email': email,
          if (photoUrl.isNotEmpty) 'photoUrl': photoUrl,
          'lastLoginAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // 6. Update cache lokal
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
        username: email.split('@').first,
        role: UserRole.user,
        avatarUrl: photoUrl,
        photoPath: photoUrl,
        dob: dob,
        gender: gender,
        phone: phone,
        isBiodataComplete: isProfileCompleted,
      );

      profileUpdateNotifier.value++;
      return AuthResponse.success(_currentUser);
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException Google: ${e.code} - ${e.message}');
      return AuthResponse.failure(e.message ?? 'Terjadi kesalahan saat masuk dengan Google.');
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

      _currentUser = UserModel(
        id: uid,
        name: cleanName,
        email: cleanEmail,
        username: cleanEmail.split('@').first,
        role: UserRole.user,
        isBiodataComplete: false,
      );

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

    // 1. Cek Admin preset untuk kenyamanan pengujian
    if ((cleanId == 'admin@obesight.com' || cleanId == 'admin') &&
        cleanPass == 'admin123') {
      final bmiInfo = getUserBmi(defaultAdminAccount.id);
      _currentUser = defaultAdminAccount.copyWith(
        isBiodataComplete: isBiodataCompleted(defaultAdminAccount.id),
        bmiScore: (bmiInfo['bmi'] as num).toDouble(),
        bmiCategory: bmiInfo['category'] as String,
        obesityRisk: bmiInfo['risk'] as String,
      );
      profileUpdateNotifier.value++;
      return AuthResponse.success(_currentUser);
    }

    // 2. Cek User preset 1 (zahraafitriana)
    if ((cleanId == 'zahraafitriana@gmail.com' || cleanId == 'zahraafitriana') &&
        (cleanPass == 'Zahra1234' || cleanPass == 'zahra1234')) {
      final bmiInfo = getUserBmi(defaultUserAccount.id);
      _currentUser = defaultUserAccount.copyWith(
        isBiodataComplete: isBiodataCompleted(defaultUserAccount.id),
        bmiScore: (bmiInfo['bmi'] as num).toDouble(),
        bmiCategory: bmiInfo['category'] as String,
        obesityRisk: bmiInfo['risk'] as String,
      );
      profileUpdateNotifier.value++;
      return AuthResponse.success(_currentUser);
    }

    // 3. Cek User preset 2 (zahrafitrie)
    if ((cleanId == 'zahrafitrie@gmail.com' || cleanId == 'zahrafitrie') &&
        cleanPass == 'zohf1234') {
      final bmiInfo = getUserBmi(alternativeUserAccount.id);
      _currentUser = alternativeUserAccount.copyWith(
        isBiodataComplete: isBiodataCompleted(alternativeUserAccount.id),
        bmiScore: (bmiInfo['bmi'] as num).toDouble(),
        bmiCategory: bmiInfo['category'] as String,
        obesityRisk: bmiInfo['risk'] as String,
      );
      profileUpdateNotifier.value++;
      return AuthResponse.success(_currentUser);
    }

    // 4. Coba login dengan Firebase Authentication
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: cleanId,
        password: cleanPass,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser != null) {
        final uid = firebaseUser.uid;
        // Ambil data profil dari Firestore
        final doc = await _firestore.collection('users').doc(uid).get();
        final data = doc.data() ?? {};

        final name = (data['name'] as String?) ?? firebaseUser.displayName ?? cleanId.split('@').first;
        final email = (data['email'] as String?) ?? firebaseUser.email ?? cleanId;
        final photoUrl = (data['photoUrl'] ?? data['photoPath']) as String? ?? '';
        final dob = (data['dob'] as String?) ?? '';
        final gender = (data['gender'] as String?) ?? 'Perempuan';
        final phone = (data['phone'] as String?) ?? '';
        final isGated = dob.isNotEmpty && gender.isNotEmpty && phone.isNotEmpty;

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

        profileUpdateNotifier.value++;
        return AuthResponse.success(_currentUser);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException login: ${e.code} - ${e.message}');
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

    return const AuthResponse.failure('Email atau kata sandi salah');
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
    profileUpdateNotifier.value++;
    return AuthResponse.success(_currentUser);
  }

  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    try {
      await _firebaseAuth.signOut();
    } catch (_) {}
    _currentUser = null;
    profileUpdateNotifier.value++;
  }
}
