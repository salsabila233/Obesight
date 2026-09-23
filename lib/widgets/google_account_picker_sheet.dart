import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class GoogleAccountPickerSheet extends StatelessWidget {
  final Function(UserModel) onAccountSelected;
  final String? suggestedEmail;
  final String? suggestedName;

  const GoogleAccountPickerSheet({
    super.key,
    required this.onAccountSelected,
    this.suggestedEmail,
    this.suggestedName,
  });

  static Future<UserModel?> show(
    BuildContext context, {
    String? suggestedEmail,
    String? suggestedName,
  }) {
    return showModalBottomSheet<UserModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GoogleAccountPickerSheet(
        suggestedEmail: suggestedEmail,
        suggestedName: suggestedName,
        onAccountSelected: (account) {
          Navigator.of(context).pop(account);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final accounts = List<UserModel>.from(authService.availableGoogleAccounts);

    if (suggestedEmail != null && suggestedEmail!.contains('@')) {
      final cleanSuggested = suggestedEmail!.trim().toLowerCase();
      final alreadyExists = accounts.any((a) => a.email.toLowerCase() == cleanSuggested);
      if (!alreadyExists) {
        final namePart = cleanSuggested.split('@').first;
        final derivedName = (suggestedName != null && suggestedName!.trim().isNotEmpty)
            ? suggestedName!.trim()
            : (namePart.isNotEmpty ? '${namePart[0].toUpperCase()}${namePart.substring(1)}' : 'Pengguna');
        accounts.insert(
          0,
          UserModel(
            id: 'usr_suggested_${DateTime.now().millisecondsSinceEpoch}',
            name: derivedName,
            email: cleanSuggested,
            username: namePart,
            role: UserRole.user,
            title: 'Akun Anda',
            isBiodataComplete: false,
          ),
        );
      }
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFEFF6F3),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),

            // Top Brand Lockup
            Image.asset(
              'assets/logo.png',
              width: 64,
              height: 64,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.health_and_safety_rounded,
                size: 54,
                color: Color(0xFF2D5A43),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'ObeSight',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2D5A43),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 16),

            // Main White Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Google G icon
                  SvgPicture.asset(
                    'assets/google_icon.svg',
                    width: 44,
                    height: 44,
                  ),
                  const SizedBox(height: 12),

                  // Title: "Masuk dengan Google"
                  Text(
                    'Masuk dengan Google',
                    style: GoogleFonts.poppins(
                      fontSize: 18.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E3A2B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),

                  // Subtitle
                  Text(
                    'Pilih akun Google yang ingin digunakan\nuntuk melanjutkan ke ObeSight',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.normal,
                      color: const Color(0xFF64748B),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),

                  // Accounts List
                  ...accounts.map((acc) => _buildAccountItem(context, acc)),

                  // "Gunakan akun lain"
                  InkWell(
                    onTap: () => _handleCustomAccount(context),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: const Icon(
                              Icons.person_add_alt_1_outlined,
                              size: 18,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Gunakan akun lain',
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 14),

                  // Terms & Privacy
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                          height: 1.45,
                        ),
                        children: const [
                          TextSpan(text: 'Dengan melanjutkan, Anda menyetujui '),
                          TextSpan(
                            text: 'Kebijakan Privasi',
                            style: TextStyle(
                              color: Color(0xFF235D3A),
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(text: ' dan '),
                          TextSpan(
                            text: 'Persyaratan Layanan',
                            style: TextStyle(
                              color: Color(0xFF235D3A),
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(text: ' ObeSight'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Bottom "Kembali" Pill Button
            SizedBox(
              width: 150,
              height: 42,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF2D5A43),
                  side: const BorderSide(color: Color(0xFF94A3B8), width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Kembali',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D5A43),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountItem(BuildContext context, UserModel account) {
    final emailLower = account.email.toLowerCase();
    final isZahraFitriana = emailLower.contains('zahraafitriana') || emailLower.contains('zahrafitrianaa');
    final isZahraCantik = emailLower.contains('zahraaaaa123') || account.name.toLowerCase().contains('cantik');

    Widget avatarWidget;
    if (isZahraFitriana) {
      avatarWidget = ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Image.asset(
          'assets/avatar_zahra.png',
          width: 38,
          height: 38,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => CircleAvatar(
            radius: 19,
            backgroundColor: const Color(0xFF4F9B77),
            child: Text(
              'Z',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    } else if (isZahraCantik) {
      avatarWidget = CircleAvatar(
        radius: 19,
        backgroundColor: const Color(0xFF64748B),
        child: Text(
          'Z',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      );
    } else {
      avatarWidget = CircleAvatar(
        radius: 19,
        backgroundColor: const Color(0xFF6366F1),
        child: Text(
          account.name.isNotEmpty ? account.name[0].toUpperCase() : 'A',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => onAccountSelected(account),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
        ),
        child: Row(
          children: [
            avatarWidget,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    account.email,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: const Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCustomAccount(BuildContext context) {
    final emailController = TextEditingController(text: suggestedEmail ?? '');
    final nameController = TextEditingController(text: suggestedName ?? '');
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Gunakan Akun Google Lain',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Masukkan email Google aktif Anda:',
              style: GoogleFonts.poppins(fontSize: 12.5, color: const Color(0xFF475569)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.poppins(fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'namaanda@gmail.com',
                hintStyle: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF94A3B8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nameController,
              style: GoogleFonts.poppins(fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'Nama Anda (opsional)',
                hintStyle: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF94A3B8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F9B77),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final email = emailController.text.trim();
              if (email.isNotEmpty && email.contains('@')) {
                final customName = nameController.text.trim();
                final namePart = email.split('@').first;
                final derivedName = customName.isNotEmpty
                    ? customName
                    : (namePart.isNotEmpty ? '${namePart[0].toUpperCase()}${namePart.substring(1)}' : 'Pengguna');
                final customUser = UserModel(
                  id: 'usr_custom_${DateTime.now().millisecondsSinceEpoch}',
                  name: derivedName,
                  email: email,
                  username: namePart,
                  role: UserRole.user,
                  isBiodataComplete: false,
                );
                Navigator.of(dialogCtx).pop();
                onAccountSelected(customUser);
              }
            },
            child: Text(
              'Lanjutkan',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
