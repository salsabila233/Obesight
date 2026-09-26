import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../auth/login_screen.dart';

/// Halaman Splash Screen Multi-Tahap (5 Frame):
/// 1. Splash 1 (Tahap Awal): Background hijau tua, logo berukuran kecil di tengah layar.
/// 2. Splash 2-4 (Tahap Transisi): Background berubah menjadi putih bersih.
///    Logo melakukan animasi pulse/zoom-in lembut berulang kali menggunakan [_scaleController].
/// 3. Splash 5 (Tahap Akhir): Logo berhenti pada skala stabil, lalu teks "ObeSight" muncul
///    di sebelah kanan logo menggunakan [FadeTransition] yang digerakkan oleh [_textController].
/// 4. Navigasi: Berpindah ke halaman utama/Login menggunakan [Navigator.pushReplacement].
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // 1. Controller untuk efek skala / pulse logo
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  // 2. Controller terpisah untuk kemunculan (fade in) teks "ObeSight"
  late final AnimationController _textController;
  late final Animation<double> _textFadeAnimation;

  // State tampilan & tahapan
  Color _backgroundColor = AppColors.darkGreen; // Hijau tua awal (Splash 1)
  bool _showText = false; // Pengontrol kemunculan teks di sebelah kanan logo
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    // Inisialisasi AnimationController 1: Efek Skala (Zoom-In / Pulse) Logo
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Animasi skala: dimulai dari kecil (0.8) hingga membesar (1.2) saat pulse
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeInOut,
      ),
    );

    // Inisialisasi AnimationController 2: Fade-In Teks Brand
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Animasi opasitas: dari 0.0 (transparan) menuju 1.0 (terlihat jelas)
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeIn,
      ),
    );

    // Jalankan urutan animasi multi-tahap
    _startSplashSequence();
  }

  /// Mengatur alur tahapan animasi menggunakan Future.delayed
  Future<void> _startSplashSequence() async {
    // -------------------------------------------------------------
    // Tahap Awal (Splash 1):
    // Layar dimulai dengan background penuh berwarna hijau tua.
    // Logo muncul kecil di tengah.
    // -------------------------------------------------------------
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    // -------------------------------------------------------------
    // Tahap Transisi (Splash 2 - 4):
    // Latar belakang berubah menjadi putih bersih.
    // Logo melakukan animasi zoom-in/pulse (membesar dan mengecil berulang kali).
    // -------------------------------------------------------------
    setState(() {
      _backgroundColor = Colors.white;
    });

    // Menjalankan animasi pulse berulang secara bolak-balik
    _scaleController.repeat(reverse: true);

    // Jeda waktu agar efek pulse terlihat selama beberapa siklus
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    // -------------------------------------------------------------
    // Tahap Akhir (Splash 5):
    // Logo berhenti pada skala stabil tertentu (skala 1.0 = nilai tengah 0.5 tween).
    // Teks "ObeSight" berwarna hijau muncul di kanan logo via FadeTransition.
    // -------------------------------------------------------------
    _scaleController.stop();
    await _scaleController.animateTo(
      0.5, // 0.8 + 0.5 * (1.2 - 0.8) = 1.0 (skala normal)
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    if (!mounted) return;

    // Tampilkan teks dan mulai animasi fade in
    setState(() {
      _showText = true;
    });
    await _textController.forward();
    if (!mounted) return;

    // Jeda waktu agar identitas merek dapat dibaca oleh pengguna
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    // Navigasi ke halaman utama / Login
    _navigateToNextScreen();
  }

  /// Melakukan navigasi aman ke halaman berikutnya
  void _navigateToNextScreen() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    // Pastikan kedua AnimationController dilepas dari memori
    _scaleController.dispose();
    _textController.dispose();
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
                // 1. Logo dengan ScaleTransition
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: _backgroundColor == Colors.white
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                // 2. Teks "ObeSight" berwarna hijau dengan FadeTransition
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
