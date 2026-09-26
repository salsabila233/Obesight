import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import 'change_password_screen.dart';
import 'change_email_screen.dart';
import 'dark_mode_screen.dart';
import 'clinical_info_screen.dart';
import 'help_center_screen.dart';
import 'about_app_screen.dart';
import 'delete_account_screen.dart';

class SettingsScreen extends StatefulWidget {
  final UserModel user;

  const SettingsScreen({super.key, required this.user});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _isDarkMode;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _isDarkMode = AppTheme.isDark;
  }

  void _showLogoutConfirmDialog({bool isDark = false}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF3F1D1D) : const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              'Keluar Akun',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun ObeSight?',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _authService.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: Text('Ya, Keluar', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _isDarkMode = AppTheme.isDark;

    return Scaffold(
      backgroundColor: const Color(0xFF489874),
      appBar: AppBar(
        backgroundColor: const Color(0xFF489874),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Pengaturan',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF4F8F6),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seksi 1: Keamanan
              _buildSectionHeader('Keamanan'),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFEAEFEA),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSettingItem(
                      icon: Icons.lock_outline_rounded,
                      iconBg: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE8F3EE),
                      iconColor: const Color(0xFF36785A),
                      title: 'Ubah Kata Sandi',
                      subtitle: 'Perbarui kata sandi akun Anda',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                        );
                      },
                    ),
                    Divider(
                      height: 1,
                      indent: 60,
                      endIndent: 16,
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                    ),
                    _buildSettingItem(
                      icon: Icons.mail_outline_rounded,
                      iconBg: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE8F3EE),
                      iconColor: const Color(0xFF36785A),
                      title: 'Ubah Email',
                      subtitle: 'Ganti alamat email terdaftar',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ChangeEmailScreen(user: widget.user)),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Seksi 2: Tampilan
              _buildSectionHeader('Tampilan'),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFEAEFEA),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DarkModeScreen(
                          initialDarkMode: AppTheme.isDark,
                          onThemeChanged: (val) {
                            setState(() {
                              _isDarkMode = val;
                            });
                          },
                        ),
                      ),
                    );
                    if (mounted) setState(() {});
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2E2A50) : const Color(0xFFEDE9FE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.dark_mode_outlined, size: 20, color: Color(0xFF818CF8)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mode Gelap',
                                style: GoogleFonts.poppins(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                AppTheme.currentThemeMode == ThemeMode.dark
                                    ? 'Aktif (gelap ke seluruh halaman)'
                                    : (AppTheme.currentThemeMode == ThemeMode.system
                                        ? 'Mengikuti Sistem perangkat'
                                        : 'Nonaktif (terang)'),
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isDarkMode,
                          activeThumbColor: const Color(0xFF4F9B77),
                          onChanged: (val) {
                            AppTheme.toggleDarkMode(val);
                            setState(() {
                              _isDarkMode = val;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(val ? 'Mode Gelap diterapkan ke seluruh halaman' : 'Mode Terang diterapkan ke seluruh halaman'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Seksi 3: Informasi dan Akun
              _buildSectionHeader('Informasi dan Akun'),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFEAEFEA),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSettingItem(
                      icon: Icons.menu_book_outlined,
                      iconBg: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE0F2FE),
                      iconColor: const Color(0xFF0284C7),
                      title: 'Informasi dan Sumber',
                      subtitle: 'Pedoman klinis, rumus & referensi',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ClinicalInfoScreen()),
                        );
                      },
                    ),
                    Divider(
                      height: 1,
                      indent: 60,
                      endIndent: 16,
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                    ),
                    _buildSettingItem(
                      icon: Icons.help_outline_rounded,
                      iconBg: isDark ? const Color(0xFF133E2B) : const Color(0xFFD1FAE5),
                      iconColor: const Color(0xFF10B981),
                      title: 'Pusat Bantuan',
                      subtitle: 'FAQ, WhatsApp, & kontak bantuan',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
                        );
                      },
                    ),
                    Divider(
                      height: 1,
                      indent: 60,
                      endIndent: 16,
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                    ),
                    _buildSettingItem(
                      icon: Icons.info_outline_rounded,
                      iconBg: isDark ? const Color(0xFF113D38) : const Color(0xFFCCFBF1),
                      iconColor: const Color(0xFF0D9488),
                      title: 'Tentang Aplikasi',
                      subtitle: 'Versi, visi & fitur ObeSight',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AboutAppScreen()),
                        );
                      },
                    ),
                    Divider(
                      height: 1,
                      indent: 60,
                      endIndent: 16,
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                    ),
                    _buildSettingItem(
                      icon: Icons.delete_outline_rounded,
                      iconBg: isDark ? const Color(0xFF3F1D1D) : const Color(0xFFFEE2E2),
                      iconColor: const Color(0xFFDC2626),
                      title: 'Hapus Akun',
                      subtitle: 'Hapus akun dan riwayat permanen',
                      titleColor: const Color(0xFFDC2626),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => DeleteAccountScreen(user: widget.user)),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Seksi 4: Tombol Keluar
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showLogoutConfirmDialog(isDark: isDark),
                  icon: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFDC2626)),
                  label: Text(
                    'Keluar dari Akun',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5),
                    ),
                    backgroundColor: isDark ? const Color(0xFF2A1717) : const Color(0xFFFEF2F2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: iconColor),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: titleColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 11.5,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
    );
  }
}
