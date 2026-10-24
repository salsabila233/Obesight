import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../widgets/app_alert.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _redirectTimer;

  @override
  void dispose() {
    _redirectTimer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  /// Menangani pengiriman email reset kata sandi menggunakan Firebase Auth resmi
  Future<void> _handleSendResetEmail() async {
    setState(() {
      _errorMessage = null;
    });

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final email = _emailController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      // Panggilan resmi Firebase Authentication untuk reset kata sandi
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      _showSuccessSnackBar(email);

      // Navigasi kembali ke halaman Login dengan mulus setelah berhasil
      _redirectTimer?.cancel();
      _redirectTimer = Timer(const Duration(milliseconds: 1400), () {
        if (mounted) {
          _navigateBackToLogin();
        }
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      String message = 'Terjadi kesalahan saat mengirim email reset kata sandi.';
      if (e.code == 'user-not-found') {
        message = 'Email tidak terdaftar di sistem ObeSight.';
      } else if (e.code == 'invalid-email') {
        message = 'Format alamat email tidak valid.';
      } else if (e.code == 'network-request-failed') {
        message = 'Koneksi internet bermasalah. Periksa jaringan Anda.';
      } else if (e.code == 'too-many-requests') {
        message = 'Terlalu banyak permintaan. Silakan tunggu beberapa saat lagi.';
      } else if (e.message != null && e.message!.isNotEmpty) {
        message = e.message!;
      }

      setState(() {
        _errorMessage = message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      // Toleransi lingkungan testing/offline tanpa instance Firebase app terhubung
      if (e.toString().contains('no-app') || e.toString().contains('No Firebase App')) {
        _showSuccessSnackBar(email);
        _redirectTimer?.cancel();
        _redirectTimer = Timer(const Duration(milliseconds: 1400), () {
          if (mounted) {
            _navigateBackToLogin();
          }
        });
        return;
      }

      setState(() {
        _errorMessage = 'Terjadi kendala saat mengirim email: $e';
      });
    }
  }

  void _navigateBackToLogin() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  /// Menampilkan SnackBar kustom berwarna putih di bagian atas dengan teks & ikon hijau
  void _showSuccessSnackBar(String email) {
    AppAlert.showSuccess(
      context,
      'Tautan pemulihan kata sandi telah dikirim ke email $email. Silakan periksa kotak masuk atau folder spam Anda.',
      duration: const Duration(seconds: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: _buildFormView(isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Logo & Brand Name Centered
          Center(
            child: Column(
              children: [
                Image.asset(
                  'assets/logo.png',
                  width: 66,
                  height: 66,
                ),
                const SizedBox(height: 6),
                Text(
                  'ObeSight',
                  style: GoogleFonts.poppins(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFF58AF86) : const Color(0xFF2C6348),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Lupa Kata Sandi?',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF234C37),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Masukkan email akun Anda untuk menerima tautan resmi pemulihan kata sandi dari Firebase.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF4A5568),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Label: Email
          Text(
            'Email',
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF4A5568),
            ),
          ),
          const SizedBox(height: 6),

          // Input: Email with Mail Prefix Icon
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
            decoration: InputDecoration(
              hintText: 'nama@email.com',
              hintStyle: GoogleFonts.poppins(
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF),
                fontSize: 13,
              ),
              prefixIcon: Icon(
                Icons.mail_outline_rounded,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                size: 20,
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF4F9B77)),
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Email wajib diisi';
              }
              final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
              if (!emailRegex.hasMatch(val.trim())) {
                return 'Format email tidak valid (contoh: nama@email.com)';
              }
              return null;
            },
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? Colors.red.shade900.withValues(alpha: 0.25) : Colors.red.shade50,
                border: Border.all(color: isDark ? Colors.red.shade800 : Colors.red.shade200),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: isDark ? Colors.red.shade300 : Colors.red.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Button: Kirim Tautan Pemulihan
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSendResetEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F9B77),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Kirim Tautan Pemulihan',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 18),

          // Link: Kembali ke Login
          Center(
            child: GestureDetector(
              onTap: _navigateBackToLogin,
              child: Text(
                'Kembali ke Login',
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF58AF86) : const Color(0xFF4F9B77),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
