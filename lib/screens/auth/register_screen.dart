import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../theme/app_colors.dart';
import '../home/user_home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  bool _isTermsAgreed = false;
  String? _termsErrorMessage;

  // Password criteria flags
  bool _hasValidLength = false;
  bool _hasNumber = false;
  bool _hasUpperAndLower = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePasswordCriteria);
  }

  void _validatePasswordCriteria() {
    final pwd = _passwordController.text;
    setState(() {
      _hasValidLength = pwd.length >= 8 && pwd.length <= 16;
      _hasNumber = RegExp(r'\d').hasMatch(pwd);
      _hasUpperAndLower = RegExp(r'[a-z]').hasMatch(pwd) && RegExp(r'[A-Z]').hasMatch(pwd);
    });
  }

  @override
  void dispose() {
    _passwordController.removeListener(_validatePasswordCriteria);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    setState(() {
      _termsErrorMessage = null;
    });

    final isFormValid = _formKey.currentState?.validate() ?? false;
    final isPasswordValid = _hasValidLength && _hasNumber && _hasUpperAndLower;

    if (!isPasswordValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kata sandi belum memenuhi seluruh kriteria yang ditentukan.',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    if (!_isTermsAgreed) {
      setState(() {
        _termsErrorMessage = 'Anda harus menyetujui syarat dan ketentuan untuk mendaftar';
      });
      return;
    }

    if (isFormValid) {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();

      final newUser = UserModel(
        id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: email,
        username: email.split('@').first,
        role: UserRole.user,
      );

      // Direct navigation to user home dashboard
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => UserHomeScreen(user: newUser),
        ),
        (route) => false,
      );
    }
  }

  Widget _buildRuleItem(String text, bool isValid) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          isValid
              ? const Icon(
                  Icons.check_circle,
                  color: Color(0xFF16A34A),
                  size: 15,
                )
              : const Icon(
                  Icons.radio_button_unchecked,
                  color: Color(0xFF9CA3AF),
                  size: 15,
                ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                color: isValid ? const Color(0xFF166534) : const Color(0xFF6B7280),
                fontWeight: isValid ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                        'Buat Akun ObeSight',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF264E3C),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Name Field
                Text(
                  'Nama',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF4A5568),
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Masukkan nama lengkap anda',
                    hintStyle: GoogleFonts.poppins(
                      color: const Color(0xFF9CA3AF),
                      fontSize: 13,
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
                  style: GoogleFonts.poppins(fontSize: 13.5, color: const Color(0xFF1F2937)),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Nama lengkap wajib diisi';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 14),

                // Email Field
                Text(
                  'Email',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF4A5568),
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Masukkan email anda',
                    hintStyle: GoogleFonts.poppins(
                      color: const Color(0xFF9CA3AF),
                      fontSize: 13,
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
                  style: GoogleFonts.poppins(fontSize: 13.5, color: const Color(0xFF1F2937)),
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

                const SizedBox(height: 14),

                // Password Field
                Text(
                  'Kata Sandi',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF4A5568),
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _isPasswordObscured,
                  decoration: InputDecoration(
                    hintText: 'Masukkan kata sandi anda',
                    hintStyle: GoogleFonts.poppins(
                      color: const Color(0xFF9CA3AF),
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: const Color(0xFF6B7280),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordObscured = !_isPasswordObscured;
                        });
                      },
                    ),
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
                  style: GoogleFonts.poppins(fontSize: 13.5, color: const Color(0xFF1F2937)),
                ),

                // Password Rules Checklist
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Column(
                    children: [
                      _buildRuleItem('Minimum 8 karakter (maksimal 16)', _hasValidLength),
                      _buildRuleItem('Terdapat minimum 1 angka', _hasNumber),
                      _buildRuleItem('Terdapat minimum 1 huruf besar dan 1 huruf kecil', _hasUpperAndLower),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Confirm Password Field
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
                  obscureText: _isConfirmPasswordObscured,
                  decoration: InputDecoration(
                    hintText: 'Masukkan konfirmasi kata sandi',
                    hintStyle: GoogleFonts.poppins(
                      color: const Color(0xFF9CA3AF),
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: const Color(0xFF6B7280),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordObscured = !_isConfirmPasswordObscured;
                        });
                      },
                    ),
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
                  style: GoogleFonts.poppins(fontSize: 13.5, color: const Color(0xFF1F2937)),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Konfirmasi kata sandi wajib diisi';
                    }
                    if (val != _passwordController.text) {
                      return 'Konfirmasi kata sandi tidak cocok';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Terms and Conditions Checkbox
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _isTermsAgreed,
                        activeColor: const Color(0xFF16A34A),
                        checkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        side: const BorderSide(color: Color(0xFF9CA3AF), width: 1.8),
                        onChanged: (val) {
                          setState(() {
                            _isTermsAgreed = val ?? false;
                            if (_isTermsAgreed) _termsErrorMessage = null;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isTermsAgreed = !_isTermsAgreed;
                            if (_isTermsAgreed) _termsErrorMessage = null;
                          });
                        },
                        child: Text(
                          'Saya menyetujui syarat dan ketentuan',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF374151),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_termsErrorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _termsErrorMessage!,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Register Button: "Daftar"
                Center(
                  child: SizedBox(
                    width: 240,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F9B77),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        'Daftar',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Already have account row
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.poppins(fontSize: 13),
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
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
