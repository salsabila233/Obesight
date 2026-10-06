import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/animated_illustration.dart';
import '../../widgets/antigravity_floating.dart';
import '../home/admin_home_screen.dart';
import '../home/user_home_screen.dart';
import '../profile/complete_profile_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isGoogleLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Logo & App Name with smooth antigravity floating motion
              AntigravityFloating(
                distance: 7.0,
                duration: const Duration(milliseconds: 2400),
                child: Image.asset(
                  'assets/logo.png',
                  width: 68,
                  height: 68,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'ObeSight',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF58AF86) : AppColors.brandTitleGreen,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 12),

              // Subtitle: "Mulai kenali risiko obesitas sejak sekarang"
              Text(
                'Mulai kenali risiko obesitas sejak sekarang',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF2D3748),
                ),
              ),

              const SizedBox(height: 18),

              // Animated Woman Illustration (Bobbing & Breathing with illustration_woman_original.png)
              const AnimatedIllustration(
                maxHeight: 310,
              ),

              const SizedBox(height: 24),

              // Button 1 (Background Hijau): "Masuk"
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Masuk',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Teks Link: "Belum punya akun? Daftar"
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const RegisterScreen(),
                    ),
                  );
                },
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(fontSize: 14),
                    children: [
                      TextSpan(
                        text: 'Belum punya akun?  ',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF4B5563),
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      TextSpan(
                        text: 'Daftar',
                        style: GoogleFonts.poppins(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // "Lanjutkan dengan Google" Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _isGoogleLoading
                      ? null
                      : () async {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          setState(() {
                            _isGoogleLoading = true;
                          });

                          final response = await AuthService().signInWithGoogle();
                          if (!mounted) return;

                          setState(() {
                            _isGoogleLoading = false;
                          });

                          final nav = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);

                          if (response.isSuccess && response.user != null) {
                            final signedUser = response.user!;
                            if (!signedUser.hasCompletedRequiredProfile && !signedUser.isAdmin && signedUser.id != 'usr_001') {
                              nav.pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => CompleteProfileScreen(
                                    user: signedUser,
                                    isGatedFlow: false,
                                    redirectToHomeAfterSave: true,
                                  ),
                                ),
                              );
                            } else {
                              nav.pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => signedUser.isAdmin
                                      ? AdminHomeScreen(user: signedUser)
                                      : UserHomeScreen(user: signedUser),
                                ),
                              );
                            }
                            return;
                          }

                          if (response.errorMessage != null &&
                              !response.errorMessage!.contains('dibatalkan')) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(response.errorMessage!),
                                backgroundColor: const Color(0xFFDC2626),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    foregroundColor: isDark ? Colors.white : const Color(0xFF1F2937),
                    side: BorderSide(
                      color: isDark ? const Color(0xFF334155) : AppColors.inputBorder,
                      width: 1.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isGoogleLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              'assets/google_icon.svg',
                              width: 20,
                              height: 20,
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                'Lanjutkan dengan Google',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
