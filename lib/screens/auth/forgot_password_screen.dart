import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _identifierController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isEmailSent = false;
  String _sentEmail = '';

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  Future<void> _handleSendResetLink() async {
    setState(() {
      _errorMessage = null;
    });

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final input = _identifierController.text.trim();
    String targetEmail = input;
    if (input.toLowerCase() == 'zahra' || input.toLowerCase() == 'zahraafitriana') {
      targetEmail = 'zahraafitriana@gmail.com';
    } else if (input.toLowerCase() == 'admin') {
      targetEmail = 'admin@obesight.com';
    }

    setState(() {
      _isLoading = true;
    });

    final response = await AuthService().sendPasswordResetEmail(targetEmail);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    if (response.isSuccess) {
      setState(() {
        _isEmailSent = true;
        _sentEmail = targetEmail;
      });
    } else {
      setState(() {
        _errorMessage = response.errorMessage ?? 'Gagal mengirim email reset kata sandi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: _isEmailSent ? _buildSuccessView() : _buildFormView(),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView() {
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
                    color: const Color(0xFF2C6348),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Lupa Kata Sandi?',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF234C37),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Masukkan email akun Anda untuk menerima tautan resmi reset kata sandi dari Firebase.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF4A5568),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Label: Nama Pengguna dan Email
          Text(
            'Email',
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF4A5568),
            ),
          ),
          const SizedBox(height: 6),

          // Input: Email with Mail Prefix Icon
          TextFormField(
            controller: _identifierController,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              color: const Color(0xFF1F2937),
            ),
            decoration: InputDecoration(
              hintText: 'nama@email.com',
              hintStyle: GoogleFonts.poppins(
                color: const Color(0xFF9CA3AF),
                fontSize: 13,
              ),
              prefixIcon: const Icon(
                Icons.mail_outline_rounded,
                color: Color(0xFF6B7280),
                size: 20,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF4F9B77)),
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Nama pengguna atau email wajib diisi';
              }
              return null;
            },
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Button: Kirim Tautan Reset
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSendResetLink,
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
                      'Kirim Tautan Reset',
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
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Kembali ke Login',
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4F9B77),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sent Icon Card
        Center(
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryGreen.withValues(alpha: 0.12),
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              size: 42,
              color: AppColors.primaryGreen,
            ),
          ),
        ),
        const SizedBox(height: 18),

        Center(
          child: Text(
            'Tautan Terkirim!',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF234C37),
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Text(
                'Tautan reset kata sandi resmi telah dikirim ke email:',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _sentEmail,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 12),
              Text(
                'Silakan periksa kotak masuk (Inbox) atau folder Spam pada email Anda, lalu klik tautan tersebut untuk membuat kata sandi baru secara aman.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: const Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Button: Kembali ke Halaman Masuk
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F9B77),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            child: Text(
              'Kembali ke Halaman Masuk',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Button: Kirim Ulang Email
        Center(
          child: TextButton(
            onPressed: () {
              setState(() {
                _isEmailSent = false;
              });
            },
            child: Text(
              'Kirim ulang ke email lain',
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4F9B77),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
