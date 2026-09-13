import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pendaftaran akun berhasil disiapkan! Silakan masuk dengan akun Anda.',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button
                IconButton(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  color: AppColors.darkGreen,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 12),

                // Logo & Brand Name Centered
                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/logo.png',
                        width: 70,
                        height: 70,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ObeSight',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brandTitleGreen,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Title
                Text(
                  'Mulai Perjalanan Sehat\nBersama ObeSight!',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkGreen,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Daftarkan diri Anda untuk pemantauan risiko obesitas yang akurat.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                ),

                const SizedBox(height: 24),

                // Name Field
                CustomTextField(
                  label: 'Nama Lengkap',
                  hintText: 'Masukkan nama lengkap',
                  controller: _nameController,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Nama lengkap wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email Field
                CustomTextField(
                  label: 'Email',
                  hintText: 'Masukkan alamat email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Email wajib diisi';
                    }
                    if (!val.contains('@') || !val.contains('.')) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password Field
                CustomTextField(
                  label: 'Kata sandi',
                  hintText: 'Masukkan kata sandi',
                  controller: _passwordController,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Kata sandi wajib diisi';
                    }
                    if (val.length < 6) {
                      return 'Kata sandi minimal 6 karakter';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 28),

                // Register Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Daftar Sekarang',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
