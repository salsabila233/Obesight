import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/antigravity_floating.dart';
import '../../widgets/custom_text_field.dart';
import '../home/admin_home_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  final _authService = AuthService();

  bool _isLoading = false;
  String? _authErrorMessage;

  // Rate Limiting / Lockout State
  int _failedAttempts = 0;
  static const int _maxFailedAttempts = 5;
  static const int _lockoutDurationSeconds = 60;
  static const String _keyLockoutUntil = 'admin_lockout_until';
  static const String _keyFailedAttempts = 'admin_failed_attempts';

  int _remainingLockoutSeconds = 0;
  Timer? _lockoutTimer;

  bool get _isLockedOut => _remainingLockoutSeconds > 0;

  @override
  void initState() {
    super.initState();
    _checkLockoutStatus();
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _checkLockoutStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lockoutUntilMs = prefs.getInt(_keyLockoutUntil) ?? 0;
      _failedAttempts = prefs.getInt(_keyFailedAttempts) ?? 0;

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      if (lockoutUntilMs > nowMs) {
        final remaining = ((lockoutUntilMs - nowMs) / 1000).ceil();
        _startLockoutCountdown(remaining);
      } else if (lockoutUntilMs > 0) {
        // Lockout expired
        await prefs.remove(_keyLockoutUntil);
        await prefs.setInt(_keyFailedAttempts, 0);
        _failedAttempts = 0;
      }
    } catch (e) {
      debugPrint('Notice checking lockout status: $e');
    }
  }

  void _startLockoutCountdown(int seconds) {
    _lockoutTimer?.cancel();
    setState(() {
      _remainingLockoutSeconds = seconds;
      _authErrorMessage =
          'Terlalu banyak percobaan gagal. Akses dikunci sementara. Coba lagi dalam $_remainingLockoutSeconds detik.';
    });

    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_remainingLockoutSeconds > 1) {
          _remainingLockoutSeconds--;
          _authErrorMessage =
              'Terlalu banyak percobaan gagal. Akses dikunci sementara. Coba lagi dalam $_remainingLockoutSeconds detik.';
        } else {
          _remainingLockoutSeconds = 0;
          _authErrorMessage = null;
          timer.cancel();
        }
      });

      if (_remainingLockoutSeconds == 0) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_keyLockoutUntil);
        await prefs.setInt(_keyFailedAttempts, 0);
        _failedAttempts = 0;
      }
    });
  }

  Future<void> _handleFailedAttempt() async {
    _failedAttempts++;
    final remainingTries = _maxFailedAttempts - _failedAttempts;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyFailedAttempts, _failedAttempts);

      if (_failedAttempts >= _maxFailedAttempts) {
        final lockoutUntilMs =
            DateTime.now().millisecondsSinceEpoch + (_lockoutDurationSeconds * 1000);
        await prefs.setInt(_keyLockoutUntil, lockoutUntilMs);
        _startLockoutCountdown(_lockoutDurationSeconds);
        return;
      }
    } catch (_) {}

    if (remainingTries > 0) {
      setState(() {
        _authErrorMessage =
            '${_authErrorMessage ?? "Email atau kata sandi salah."} Sisa percobaan: $remainingTries kali.';
      });
    }
  }

  Future<void> _handleSuccessfulLogin(UserModel adminUser) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyLockoutUntil);
      await prefs.remove(_keyFailedAttempts);
    } catch (_) {}

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AdminHomeScreen(user: adminUser),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  Future<void> _handleAdminLogin() async {
    if (_isLockedOut) return;

    setState(() {
      _authErrorMessage = null;
    });

    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final response = await _authService.loginAdmin(
      email: email,
      password: password,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (response.isSuccess && response.user != null) {
      final user = response.user!;
      if (user.isAdmin) {
        await _handleSuccessfulLogin(user);
      } else {
        setState(() {
          _authErrorMessage =
              'Akses ditolak: Akun Anda tidak memiliki hak akses Administrator.';
        });
        await _handleFailedAttempt();
      }
    } else {
      setState(() {
        _authErrorMessage =
            response.errorMessage ?? 'Email atau kata sandi administrator salah.';
      });
      await _handleFailedAttempt();
    }
  }

  void _clearAuthError() {
    if (_authErrorMessage != null && !_isLockedOut) {
      setState(() {
        _authErrorMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppColors.adminGreen;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
            size: 20,
          ),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/login');
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          physics: const ClampingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top App Logo with Floating Animation
                Center(
                  child: Column(
                    children: [
                      AntigravityFloating(
                        distance: 5.0,
                        duration: const Duration(milliseconds: 2400),
                        child: Image.asset(
                          'assets/logo.png',
                          width: 68,
                          height: 68,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ObeSight',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Administrator Portal Badge
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.admin_panel_settings_rounded,
                          size: 16,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'PORTAL ADMINISTRATOR',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Title & Subtitle
                Text(
                  'Masuk Admin',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Masukkan kredensial administrator terverifikasi untuk mengelola sistem ObeSight.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 24),

                // Lockout Warning Banner (if locked out)
                if (_isLockedOut) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF87171)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lock_clock_rounded,
                          color: Color(0xFFDC2626),
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Akses Dikunci Sementara',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF991B1B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Terjadi $_maxFailedAttempts kali percobaan login gagal berturut-turut. Demi keamanan sistem, silakan tunggu $_remainingLockoutSeconds detik sebelum mencoba kembali.',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFFB91C1C),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Error Banner (if any auth error)
                if (_authErrorMessage != null && !_isLockedOut) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _authErrorMessage!,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Input Field: Email
                CustomTextField(
                  label: 'Email Administrator',
                  hintText: 'adminobesight@gmail.com',
                  controller: _emailController,
                  focusNode: _emailFocus,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email administrator wajib diisi';
                    }
                    final emailRegex =
                        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                    if (!emailRegex.hasMatch(value.trim()) && value.trim() != 'admin') {
                      return 'Format email tidak valid (contoh: adminobesight@gmail.com)';
                    }
                    return null;
                  },
                  onChanged: (_) => _clearAuthError(),
                ),

                const SizedBox(height: 18),

                // Input Field: Kata Sandi
                CustomTextField(
                  label: 'Kata Sandi',
                  hintText: 'Masukkan kata sandi',
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Kata sandi wajib diisi';
                    }
                    if (value.length < 6 && value.trim() != 'admin123') {
                      return 'Kata sandi minimal 6 karakter';
                    }
                    return null;
                  },
                  onChanged: (_) => _clearAuthError(),
                ),

                const SizedBox(height: 28),

                // Button: Masuk sebagai Admin
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (_isLoading || _isLockedOut) ? null : _handleAdminLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      disabledBackgroundColor: primaryColor.withValues(alpha: 0.4),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.login_rounded, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                _isLockedOut
                                    ? 'Terkunci ($_remainingLockoutSeconds s)'
                                    : 'Masuk sebagai Admin',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // Info Box: Security Note
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.security_rounded,
                        size: 18,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Akses dashboard admin hanya diberikan kepada akun dengan role "admin" di database Cloud Firestore.',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Back to User Login
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacementNamed('/login');
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_back_rounded,
                            size: 16,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF4B5563),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Bukan Administrator? ',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF4B5563),
                            ),
                          ),
                          Text(
                            'Masuk Pengguna',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
