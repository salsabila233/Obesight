import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth/auth_wrapper.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/auth/verify_otp_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'services/sleep_tracking_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform-specific options
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('Firebase successfully initialized for project: ${DefaultFirebaseOptions.currentPlatform.projectId}');
    }
  } catch (e) {
    debugPrint('Firebase initializeApp notice: $e');
  }

  // Set system UI overlay style to match the light theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // Lock to portrait mode for phone stability
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize sleep tracking service observer for auto/manual detection
  SleepTrackingService.instance.initialize();

  runApp(const ObeSightApp());
}

class ObeSightApp extends StatelessWidget {
  const ObeSightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeModeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'ObeSight',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/auth-gate': (context) => const AuthWrapper(),
            '/login': (context) => const LoginScreen(),
            '/welcome': (context) => const WelcomeScreen(),
            '/register': (context) => const RegisterScreen(),
            '/forgot-password': (context) => const ForgotPasswordScreen(),
            '/verify-otp': (context) => const VerifyOtpScreen(),
            '/reset-password': (context) => const ResetPasswordScreen(),
          },
        );
      },
    );
  }
}
