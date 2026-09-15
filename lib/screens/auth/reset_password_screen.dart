import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isPasswordObscured = true;
  bool _isConfirmObscured = true;
  bool _isLoading = false;
  String? _errorMessage;

  // Criteria
  bool _hasMinLength = false;
  bool _hasUpperAndLower = false;
  bool _hasNumber = false;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_validateCriteria);
  }

  void _validateCriteria() {
    final pwd = _newPasswordController.text;
    setState(() {
      _hasMinLength = pwd.length >= 8;
      _hasUpperAndLower = RegExp(r'[a-z]').hasMatch(pwd) && RegExp(r'[A-Z]').hasMatch(pwd);
      _hasNumber = RegExp(r'\d').hasMatch(pwd);
    });
  }

  @override
  void dispose() {
    _newPasswordController.removeListener(_validateCriteria);
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Widget _buildRuleItem({required bool isValid, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isValid ? const Color(0xFF16A34A) : Colors.transparent,
              border: Border.all(
                color: isValid ? const Color(0xFF16A34A) : const Color(0xFF9CA3AF),
                width: 1.5,
              ),
            ),
            child: isValid
                ? const Icon(
                    Icons.check,
                    size: 11,
                    color: Colors.white,
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isValid ? FontWeight.w500 : FontWeight.w400,
                color: isValid ? const Color(0xFF166534) : const Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSavePassword() async {
    setState(() {
      _errorMessage = null;
    });

    final isAllCriteriaMet = _hasMinLength && _hasUpperAndLower && _hasNumber;
    if (!isAllCriteriaMet) {
      setState(() {
        _errorMessage = 'Kata sandi belum memenuhi seluruh kriteria yang ditentukan.';
      });
      return;
    }

    final newPwd = _newPasswordController.text;
    final confirmPwd = _confirmPasswordController.text;

    if (newPwd != confirmPwd) {
      setState(() {
        _errorMessage = 'Konfirmasi kata sandi tidak cocok.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate backend update
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Kata sandi berhasil diperbarui! Silakan masuk dengan kata sandi baru Anda.',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        backgroundColor: const Color(0xFF4F9B77),
      ),
    );

    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
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
                          'Buat Kata Sandi Baru',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF234C37),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Masukkan kata sandi baru untuk akun Anda.',
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

                  // Field: Kata Sandi Baru
                  Text(
                    'Kata Sandi Baru',
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF4A5568),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: _isPasswordObscured,
                    style: GoogleFonts.poppins(fontSize: 13.5, color: const Color(0xFF1F2937)),
                    decoration: InputDecoration(
                      hintText: 'Masukkan kata sandi baru',
                      hintStyle: GoogleFonts.poppins(
                        color: const Color(0xFF9CA3AF),
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        color: Color(0xFF6B7280),
                        size: 20,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordObscured
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF6B7280),
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordObscured = !_isPasswordObscured;
                          });
                        },
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
                  ),

                  const SizedBox(height: 16),

                  // Field: Konfirmasi Kata Sandi
                  Text(
                    'Konfirmasi Kata Sandi',
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF4A5568),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _isConfirmObscured,
                    style: GoogleFonts.poppins(fontSize: 13.5, color: const Color(0xFF1F2937)),
                    decoration: InputDecoration(
                      hintText: 'Konfirmasi kata sandi',
                      hintStyle: GoogleFonts.poppins(
                        color: const Color(0xFF9CA3AF),
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        color: Color(0xFF6B7280),
                        size: 20,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmObscured
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF6B7280),
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _isConfirmObscured = !_isConfirmObscured;
                          });
                        },
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
                  ),

                  const SizedBox(height: 14),

                  // Password Criteria Checklist
                  Text(
                    'Kata sandi harus memenuhi:',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF4A5568),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildRuleItem(
                    isValid: _hasMinLength,
                    text: 'Minimal 8 karakter',
                  ),
                  _buildRuleItem(
                    isValid: _hasUpperAndLower,
                    text: 'Mengandung huruf besar dan kecil',
                  ),
                  _buildRuleItem(
                    isValid: _hasNumber,
                    text: 'Mengandung angka',
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

                  // Button: Simpan Kata Sandi
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSavePassword,
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
                              'Simpan Kata Sandi',
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
                        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
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
            ),
          ),
        ),
      ),
    );
  }
}
