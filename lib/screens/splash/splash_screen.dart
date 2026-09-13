import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _ellipseController;
  late Animation<double> _ellipseScale;

  late AnimationController _logoFadeController;
  late Animation<double> _logoOpacity;

  late AnimationController _lockupController;
  late Animation<double> _logoShiftX;
  late Animation<double> _textOpacity;
  late Animation<double> _textShiftX;

  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();

    // 1. Expanding white ellipse animation
    _ellipseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _ellipseScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ellipseController, curve: Curves.easeInOutCubic),
    );

    // 2. Logo fade in on white
    _logoFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoFadeController, curve: Curves.easeIn),
    );

    // 3. Logo shifts left & "ObeSight" text reveals
    _lockupController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _logoShiftX = Tween<double>(begin: 0.0, end: -64.0).animate(
      CurvedAnimation(
        parent: _lockupController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeInOutCubic),
      ),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _lockupController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    _textShiftX = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _lockupController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    // Stage 1: Brief pause on green canvas with center logo
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    // Stage 2: White ellipse expands to fill screen
    _ellipseController.forward();
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    // Stage 3: Logo fades in cleanly on white
    _logoFadeController.forward();
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    // Stage 4 & 5: Logo shifts left & "ObeSight" text appears
    _lockupController.forward();
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;

    // Stage 6: Transition to Login Screen
    _navigateToLogin();
  }

  void _navigateToLogin() {
    if (_isTransitioning || !mounted) return;
    _isTransitioning = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _ellipseController.dispose();
    _logoFadeController.dispose();
    _lockupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final maxDimension = screenSize.longestSide * 2.2;

    return Scaffold(
      backgroundColor: AppColors.splashGreen,
      body: Stack(
        children: [
          // White Expanding Ellipse Canvas
          AnimatedBuilder(
            animation: _ellipseScale,
            builder: (context, child) {
              final currentSize = maxDimension * _ellipseScale.value;
              return Center(
                child: Container(
                  width: currentSize,
                  height: currentSize,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),

          // Initial Logo on Green Canvas (visible before white ellipse expands)
          Center(
            child: AnimatedBuilder(
              animation: _ellipseScale,
              builder: (context, child) {
                return Opacity(
                  opacity: (1.0 - _ellipseScale.value * 2.5).clamp(0.0, 1.0),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Image.asset('assets/logo.png'),
                  ),
                );
              },
            ),
          ),

          // Animated Brand Lockup (Logo + "ObeSight") on White Canvas
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _logoFadeController,
                _lockupController,
              ]),
              builder: (context, child) {
                return Opacity(
                  opacity: _logoOpacity.value,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Moving Logo
                      Transform.translate(
                        offset: Offset(_logoShiftX.value, 0),
                        child: Image.asset(
                          'assets/logo.png',
                          width: 68,
                          height: 68,
                        ),
                      ),

                      // Emerging "ObeSight" Brand Text
                      if (_lockupController.value > 0.01)
                        Transform.translate(
                          offset: Offset(_logoShiftX.value + _textShiftX.value, 0),
                          child: Opacity(
                            opacity: _textOpacity.value,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 12),
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
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Skip button ("Lewati →") at top right
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: TextButton(
                  onPressed: _navigateToLogin,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.05),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Lewati',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF4B5563),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: Color(0xFF4B5563),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
