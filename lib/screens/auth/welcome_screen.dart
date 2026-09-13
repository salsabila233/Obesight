import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/animated_illustration.dart';
import '../../widgets/google_account_picker_sheet.dart';
import '../home/admin_home_screen.dart';
import '../home/user_home_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Logo & App Name
              Image.asset(
                'assets/logo.png',
                width: 68,
                height: 68,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 6),
              Text(
                'ObeSight',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandTitleGreen,
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
                  color: const Color(0xFF2D3748),
                ),
              ),

              const SizedBox(height: 18),

              // Animated Woman Illustration (Bobbing & Breathing)
              const AnimatedIllustration(
                maxHeight: 310,
              ),

              const SizedBox(height: 24),

              // "Daftar" Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const RegisterScreen(),
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
                    'Daftar',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // "Sudah punya akun? Masuk"
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(fontSize: 14),
                    children: [
                      const TextSpan(
                        text: 'Sudah punya akun?  ',
                        style: TextStyle(
                          color: Color(0xFF4B5563),
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      TextSpan(
                        text: 'Masuk',
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
                  onPressed: () async {
                    final selected = await GoogleAccountPickerSheet.show(context);
                    if (selected != null && context.mounted) {
                      await AuthService().loginWithGoogleAccount(selected);
                      if (context.mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => selected.isAdmin
                                ? AdminHomeScreen(user: selected)
                                : UserHomeScreen(user: selected),
                          ),
                        );
                      }
                    }
                  },
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
                    children: [
                      SvgPicture.asset(
                        'assets/google_icon.svg',
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Lanjutkan dengan Google',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
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
