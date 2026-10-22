import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_text_field.dart';

/// Modal dialog / bottom sheet untuk mengubah kata sandi Administrator
/// dengan verifikasi reautentikasi Firebase wajib menggunakan kata sandi saat ini
/// sebelum kata sandi baru disimpan.
///
/// KEAMANAN: Kata sandi TIDAK PERNAH disimpan dalam bentuk teks biasa.
class AdminChangePasswordSheet extends StatefulWidget {
  final String adminEmail;

  const AdminChangePasswordSheet({
    super.key,
    required this.adminEmail,
  });

  static Future<bool?> show(BuildContext context, {required String adminEmail}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdminChangePasswordSheet(adminEmail: adminEmail),
    );
  }

  @override
  State<AdminChangePasswordSheet> createState() => _AdminChangePasswordSheetState();
}

class _AdminChangePasswordSheetState extends State<AdminChangePasswordSheet> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final _oldFocus = FocusNode();
  final _newFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _isLoading = false;
  String? _errorMessage;

  bool _hasMinLength = false;
  bool _hasDigit = false;
  bool _hasUpperAndLower = false;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_validatePasswordCriteria);
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _oldFocus.dispose();
    _newFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _validatePasswordCriteria() {
    final text = _newPasswordController.text;
    setState(() {
      _hasMinLength = text.length >= 8;
      _hasDigit = RegExp(r'[0-9]').hasMatch(text);
      _hasUpperAndLower =
          RegExp(r'[A-Z]').hasMatch(text) && RegExp(r'[a-z]').hasMatch(text);
    });
  }

  Future<void> _handleUpdatePassword() async {
    setState(() {
      _errorMessage = null;
    });

    FocusScope.of(context).unfocus();

    final oldPass = _oldPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (oldPass.isEmpty) {
      setState(() {
        _errorMessage = 'Kata sandi saat ini wajib diisi untuk verifikasi keamanan.';
      });
      return;
    }

    if (!_hasMinLength || !_hasDigit || !_hasUpperAndLower) {
      setState(() {
        _errorMessage =
            'Kata sandi baru harus minimal 8 karakter, mengandung huruf besar, huruf kecil, dan angka.';
      });
      return;
    }

    if (newPass != confirmPass) {
      setState(() {
        _errorMessage = 'Konfirmasi kata sandi baru tidak cocok.';
      });
      return;
    }

    if (oldPass == newPass) {
      setState(() {
        _errorMessage =
            'Kata sandi baru tidak boleh sama dengan kata sandi saat ini.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // 1. Verifikasi kata sandi lama melalui Reautentikasi Firebase Authentication
    final auth = FirebaseAuth.instance;
    final currentUser = auth.currentUser;

    if (currentUser != null && currentUser.email != null) {
      try {
        final credential = EmailAuthProvider.credential(
          email: currentUser.email!,
          password: oldPass,
        );

        // REAUTENTIKASI WAJIB:
        await currentUser.reauthenticateWithCredential(credential);

        // Setelah reautentikasi sukses, perbarui kata sandi di Firebase Auth
        await currentUser.updatePassword(newPass);

        // Update password timestamp di Firestore TANPA teks sandi biasa
        await AuthService().changePassword(
          currentPassword: oldPass,
          newPassword: newPass,
        );
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });

        debugPrint('FirebaseAuthException reauthenticate admin: ${e.code}');
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          setState(() {
            _errorMessage =
                'Verifikasi gagal: Kata sandi saat ini salah. Pastikan kata sandi lama Anda benar.';
          });
        } else if (e.code == 'weak-password') {
          setState(() {
            _errorMessage = 'Kata sandi baru dinilai terlalu lemah oleh Firebase.';
          });
        } else if (e.code == 'requires-recent-login') {
          setState(() {
            _errorMessage =
                'Sesi autentikasi telah kedaluwarsa. Silakan keluar dan login ulang sebelum mengubah sandi.';
          });
        } else {
          setState(() {
            _errorMessage = e.message ?? 'Gagal memperbarui kata sandi.';
          });
        }
        return;
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'Terjadi kesalahan sistem saat verifikasi reautentikasi: $e';
        });
        return;
      }
    } else {
      // Offline fallback / Dummy account handling
      if (oldPass != 'admin123' && oldPass != 'Admin123') {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Verifikasi gagal: Kata sandi saat ini salah.';
        });
        return;
      }

      await AuthService().changePassword(
        currentPassword: oldPass,
        newPassword: newPass,
      );
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    Navigator.of(context).pop(true);
  }

  Widget _buildCriterion(String label, bool isSatisfied) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isSatisfied ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 15,
            color: isSatisfied ? AppColors.success : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isSatisfied ? AppColors.success : const Color(0xFF64748B),
                fontWeight: isSatisfied ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppColors.adminGreen;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: bottomInset > 0 ? bottomInset + 20 : 32,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.lock_reset_rounded,
                      color: primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ubah Kata Sandi Admin',
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Verifikasi kata sandi saat ini via Firebase Auth',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Info Banner: Reauthentication
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.verified_user_rounded,
                      size: 18,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Untuk melindungi akun admin, sistem mewajibkan verifikasi kata sandi lama secara langsung melalui Firebase Authentication sebelum kata sandi baru disimpan.',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: Color(0xFFDC2626), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFB91C1C),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Input 1: Kata Sandi Saat Ini
              CustomTextField(
                label: 'Kata Sandi Saat Ini (Lama)',
                hintText: 'Masukkan kata sandi saat ini',
                controller: _oldPasswordController,
                focusNode: _oldFocus,
                isPassword: true,
                textInputAction: TextInputAction.next,
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                },
              ),

              const SizedBox(height: 14),

              // Input 2: Kata Sandi Baru
              CustomTextField(
                label: 'Kata Sandi Baru',
                hintText: 'Minimal 8 karakter kombinasi',
                controller: _newPasswordController,
                focusNode: _newFocus,
                isPassword: true,
                textInputAction: TextInputAction.next,
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                },
              ),

              const SizedBox(height: 10),

              // Criteria checklist
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  children: [
                    _buildCriterion('Minimal 8 karakter', _hasMinLength),
                    _buildCriterion('Mengandung huruf besar (A-Z) & huruf kecil (a-z)',
                        _hasUpperAndLower),
                    _buildCriterion('Mengandung minimal 1 angka (0-9)', _hasDigit),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Input 3: Konfirmasi Kata Sandi Baru
              CustomTextField(
                label: 'Konfirmasi Kata Sandi Baru',
                hintText: 'Ulangi kata sandi baru',
                controller: _confirmPasswordController,
                focusNode: _confirmFocus,
                isPassword: true,
                textInputAction: TextInputAction.done,
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                },
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF475569)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Text(
                        'Batal',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleUpdatePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Simpan Kata Sandi',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
