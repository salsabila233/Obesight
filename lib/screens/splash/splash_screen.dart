import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../auth/welcome_screen.dart';

/// Halaman Splash Screen Dua Tahap:
/// 1. Tahap 1: Latar belakang hijau tua (AppColors.darkGreen) dengan logo di tengah.
/// 2. Tahap 2: Latar belakang bertransisi mulus menjadi putih bersih (Colors.white),
///    lalu teks merek "ObeSight" muncul di sebelah kanan logo dengan fade-in halus.
/// 3. Navigasi: Bertransisi halus ke WelcomeScreen (halaman Login).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Controller animasi pulse/scale logo
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  // Controller animasi kemunculan teks "ObeSight"
  late final AnimationController _textController;
  late final Animation<double> _textFadeAnimation;

  // Controller animasi floating halus (antigravity naik-turun)
  late final AnimationController _floatingController;
  late final Animation<double> _floatingAnimation;

  // State tampilan & tahapan
  Color _backgroundColor = AppColors.darkGreen;
  bool _showText = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    // 1. Controller Skala Logo
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeOutBack,
      ),
    );

    // 2. Controller Fade Teks Brand
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeIn,
      ),
    );

    // 3. Controller Efek Melayang Halus
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _floatingAnimation = Tween<double>(begin: -4.0, end: 4.0).animate(
      CurvedAnimation(
        parent: _floatingController,
        curve: Curves.easeInOutSine,
      ),
    );

    _startSplashSequence();
  }

  Future<void> _startSplashSequence() async {
    // Jalankan animasi skala awal logo di layar hijau tua
    _scaleController.forward();

    // Tampilkan fase hijau tua selama 1.2 detik
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    // Transisi latar belakang menjadi putih bersih
    setState(() {
      _backgroundColor = Colors.white;
    });

    // Jeda sejenak untuk transisi warna
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    // Munculkan teks merek "ObeSight" di samping logo
    setState(() {
      _showText = true;
    });
    await _textController.forward();
    if (!mounted) return;

    // Tampilkan brand identity lengkap di latar putih selama 1.5 detik
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    // Masuk ke halaman Welcome / Login
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const WelcomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _textController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        color: _backgroundColor,
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Logo ObeSight dengan animasi Scale & Floating
                AnimatedBuilder(
                  animation: _floatingController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _floatingAnimation.value),
                      child: child,
                    );
                  },
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: SizedBox(
                      width: 76,
                      height: 76,
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                // 2. Teks "ObeSight" berwarna hijau saat latar menjadi putih
                if (_showText) ...[
                  const SizedBox(width: 14),
                  FadeTransition(
                    opacity: _textFadeAnimation,
                    child: Text(
                      'ObeSight',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandTitleGreen,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
