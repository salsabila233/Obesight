import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/auth/verify_otp_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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

  runApp(const ObeSightApp());
}

class ObeSightApp extends StatelessWidget {
  const ObeSightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ObeSight',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/verify-otp': (context) => const VerifyOtpScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
      },
    );
  }
}
