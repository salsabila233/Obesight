import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

class GoogleAccountPickerSheet extends StatelessWidget {
  final Function(UserModel) onAccountSelected;

  const GoogleAccountPickerSheet({
    super.key,
    required this.onAccountSelected,
  });

  static Future<UserModel?> show(BuildContext context) {
    return showModalBottomSheet<UserModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GoogleAccountPickerSheet(
        onAccountSelected: (account) {
          Navigator.of(context).pop(account);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final accounts = authService.availableGoogleAccounts;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Google Header
          Row(
            children: [
              SvgPicture.asset(
                'assets/google_icon.svg',
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Pilih akun Google',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'untuk melanjutkan masuk ke aplikasi ObeSight',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.normal,
              color: const Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),

          // Account Options
          ...accounts.map((acc) => _buildAccountItem(context, acc)),

          // "Use another account" row
          InkWell(
            onTap: () => _handleCustomAccount(context),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_outlined,
                      size: 20,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Gunakan akun Google lain',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 16),

          // Google Disclaimer
          Text(
            'Untuk melanjutkan, Google akan membagikan nama, alamat email, dan foto profil Anda dengan ObeSight. Lihat Kebijakan Privasi dan Persyaratan Layanan.',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.normal,
              color: const Color(0xFF94A3B8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountItem(BuildContext context, UserModel account) {
    final isUser = account.role == UserRole.user;
    final initials = account.name.isNotEmpty
        ? account.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
        : 'G';

    return InkWell(
      onTap: () => onAccountSelected(account),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 21,
              backgroundColor: isUser ? const Color(0xFF4F9B77) : const Color(0xFF1E3A8A),
              child: Text(
                initials,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Account Name and Email
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          account.name,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Role Tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isUser ? AppColors.userBadgeBg : AppColors.adminBadgeBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          account.roleDisplayName,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isUser ? AppColors.userBadgeText : AppColors.adminBadgeText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    account.email,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCustomAccount(BuildContext context) {
    // Quick dialog to enter another email
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Login Akun Google Lain',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Masukkan email Google Anda:',
              style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF475569)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'nama@gmail.com',
                hintStyle: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF94A3B8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text('Batal', style: GoogleFonts.poppins(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              final email = emailController.text.trim();
              if (email.isNotEmpty && email.contains('@')) {
                final isAdmin = email.toLowerCase().contains('admin');
                final customUser = UserModel(
                  id: 'usr_custom_${DateTime.now().millisecondsSinceEpoch}',
                  name: email.split('@').first,
                  email: email,
                  username: email.split('@').first,
                  role: isAdmin ? UserRole.admin : UserRole.user,
                );
                Navigator.of(dialogCtx).pop();
                onAccountSelected(customUser);
              }
            },
            child: Text('Lanjutkan', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
