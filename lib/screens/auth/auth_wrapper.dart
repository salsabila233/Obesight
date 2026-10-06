import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../home/admin_home_screen.dart';
import '../home/user_home_screen.dart';
import '../profile/complete_profile_screen.dart';
import 'welcome_screen.dart';

/// AuthWrapper / AuthGate:
/// Komponen penjaga rute awal (Root Gate) yang secara reaktif memantau sesi login pengguna
/// menggunakan [FirebaseAuth.instance.authStateChanges] dan [AuthService.restorePersistentSession].
///
/// Logika Gating & Onboarding:
/// 1. Jika belum login (User == null) -> Arahkan ke [WelcomeScreen].
/// 2. Jika sudah login (User != null):
///    - Cek kelengkapan data diri di Cloud Firestore (`users/{uid}`).
///    - Jika data diri belum lengkap & bukan admin -> Arahkan ke [CompleteProfileScreen].
///    - Jika data diri sudah lengkap (atau admin) -> Arahkan langsung ke [UserHomeScreen] / [AdminHomeScreen].
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _authService = AuthService();
  String? _lastUid;
  Future<UserModel?>? _restoreFuture;

  Future<UserModel?> _getRestoreFuture(String? uid) {
    if (_restoreFuture == null || _lastUid != uid) {
      _lastUid = uid;
      _restoreFuture = _authService.restorePersistentSession();
    }
    return _restoreFuture!;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, authSnapshot) {
        // Jika stream masih menunggu inisialisasi awal Firebase Auth dan belum ada cache user
        if (authSnapshot.connectionState == ConnectionState.waiting &&
            _authService.currentUser == null) {
          return _buildLoadingScreen();
        }

        final firebaseUser = authSnapshot.data;

        // 1. Jika pengguna tidak terautentikasi di Firebase Auth dan tidak ada sesi lokal aktif
        if (firebaseUser == null && _authService.currentUser == null) {
          return const WelcomeScreen();
        }

        // 2. Jika pengguna terautentikasi, periksa data profil lengkap dari Cloud Firestore
        final activeUid = firebaseUser?.uid ?? _authService.currentUser?.id;
        return FutureBuilder<UserModel?>(
          future: _getRestoreFuture(activeUid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting &&
                _authService.currentUser == null) {
              return _buildLoadingScreen();
            }

            final user = profileSnapshot.data ?? _authService.currentUser;

            if (user == null) {
              return const WelcomeScreen();
            }

            // Gating: Jika data diri belum lengkap dan bukan admin
            if (!user.hasCompletedRequiredProfile && !user.isAdmin && user.id != 'usr_001') {
              return CompleteProfileScreen(
                user: user,
                isGatedFlow: false,
                redirectToHomeAfterSave: true,
              );
            }

            // Beranda: Langsung ke dashboard sesuai peran pengguna
            if (user.isAdmin) {
              return AdminHomeScreen(user: user);
            } else {
              return UserHomeScreen(user: user);
            }
          },
        );
      },
    );
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
        ),
      ),
    );
  }
}
