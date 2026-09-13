import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/animated_illustration.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/google_account_picker_sheet.dart';
import '../home/admin_home_screen.dart';
import '../home/user_home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final _identifierFocus = FocusNode();
  final _passwordFocus = FocusNode();

  final _authService = AuthService();

  bool _isLoading = false;
  String? _authErrorMessage;

  @override
  void initState() {
    super.initState();
    // Default dummy account prefilled for testing convenience if needed,
    // or can be empty. Let's keep it empty initially per State 1 requirement:
    // "STATE 1 — LOGIN AWAL: Saat halaman dibuka: Email kosong, Password kosong, Keyboard tidak muncul"
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _identifierFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Clear any previous error
    setState(() {
      _authErrorMessage = null;
    });

    // Unfocus keyboards
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final response = await _authService.login(
      identifier: _identifierController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (response.isSuccess && response.user != null) {
      _navigateToDashboard(response.user!);
    } else {
      setState(() {
        _authErrorMessage = response.errorMessage ?? 'Email atau kata sandi salah';
      });
    }
  }

  void _clearAuthError() {
    if (_authErrorMessage != null) {
      setState(() {
        _authErrorMessage = null;
      });
    }
  }

  void _navigateToDashboard(UserModel user) {
    Widget destination;
    if (user.isAdmin) {
      destination = AdminHomeScreen(user: user);
    } else {
      destination = UserHomeScreen(user: user);
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    // Open Google Account Picker Bottom Sheet
    final selectedAccount = await GoogleAccountPickerSheet.show(context);
    if (selectedAccount != null) {
      setState(() {
        _isLoading = true;
      });

      final response = await _authService.loginWithGoogleAccount(selectedAccount);
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (response.isSuccess && response.user != null) {
        _navigateToDashboard(response.user!);
      }
    }
  }

  void _handleForgotPassword() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.lock_reset_rounded, color: AppColors.primaryGreen, size: 24),
            const SizedBox(width: 8),
            Text(
              'Lupa Kata Sandi',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.darkGreen,
              ),
            ),
          ],
        ),
        content: Text(
          'Tautan pemulihan kata sandi telah disiapkan. Masukkan email Anda untuk menerima instruksi reset kata sandi.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: const Color(0xFF4A5568),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              'Mengerti',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 100;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              physics: const ClampingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),

                        // Top Row with App Logo & Quick Role Testing Badge
                        Center(
                          child: Column(
                            children: [
                              // Circular Health Logo
                              Image.asset(
                                'assets/logo.png',
                                width: 68,
                                height: 68,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 6),

                              // App Name "ObeSight"
                              Text(
                                'ObeSight',
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.brandTitleGreen,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Title: "Selamat Datang Kembali di ObeSight!" (Placed above illustration)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Selamat Datang Kembali\ndi ObeSight!',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkGreen,
                              height: 1.25,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Animated Woman Illustration (Always visible, directly below title)
                        Center(
                          child: AnimatedIllustration(
                            maxHeight: isKeyboardOpen ? 95 : 180,
                            isCompact: isKeyboardOpen,
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Input: Nama Pengguna dan Email
                        CustomTextField(
                          label: 'Nama Pengguna dan Email',
                          hintText: 'Masukkan nama pengguna dan email',
                          controller: _identifierController,
                          focusNode: _identifierFocus,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nama pengguna atau email wajib diisi';
                            }
                            return null;
                          },
                          onChanged: (_) => _clearAuthError(),
                        ),

                        const SizedBox(height: 16),

                        // Input: Kata Sandi
                        CustomTextField(
                          label: 'Kata sandi',
                          hintText: 'Masukkan kata sandi',
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          isPassword: true,
                          textInputAction: TextInputAction.done,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Kata sandi wajib diisi';
                            }
                            if (value.length < 4) {
                              return 'Kata sandi minimal 4 karakter';
                            }
                            return null;
                          },
                          onChanged: (_) => _clearAuthError(),
                        ),

                        const SizedBox(height: 8),

                        // Link: "Lupa kata sandi?" (Right Aligned)
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: _handleForgotPassword,
                            child: Text(
                              'Lupa kata sandi?',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.linkBlue,
                              ),
                            ),
                          ),
                        ),

                        // Error Banner if login credentials are wrong (only appears on wrong credentials)
                        if (_authErrorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                                const SizedBox(width: 8),
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
                        ],

                        SizedBox(height: _authErrorMessage != null ? 18 : 24),

                        // Button: "Masuk"
                        Center(
                          child: SizedBox(
                            width: 250,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
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
                                  : Text(
                                      'Masuk',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Separator: ─── atau ───
                        Row(
                          children: [
                            const Expanded(
                              child: Divider(
                                color: AppColors.dividerColor,
                                thickness: 1.0,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: Text(
                                'atau',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.normal,
                                  color: AppColors.dividerText,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Divider(
                                color: AppColors.dividerColor,
                                thickness: 1.0,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Button: "Lanjutkan dengan Google"
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _handleGoogleSignIn,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1F2937),
                              side: const BorderSide(color: AppColors.inputBorder, width: 1.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SvgPicture.asset(
                                  'assets/google_icon.svg',
                                  width: 20,
                                  height: 20,
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    'Lanjutkan dengan Google',
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1F2937),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Bottom Link: "Belum punya akun?   Daftar"
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Center(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const RegisterScreen(),
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Belum punya akun?   ',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: const Color(0xFF4B5563),
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  Text(
                                    'Daftar',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: AppColors.primaryGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
        ),
      ),
    );
  }
}
