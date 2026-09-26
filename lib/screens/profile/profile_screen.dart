import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  late Map<String, String> _profileData;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  /// Memuat data profil terbaru yang tersinkronisasi dengan akun pengguna
  void _loadProfileData() {
    setState(() {
      _profileData = _authService.getUserProfile(widget.user.id);
    });
  }

  /// Membuka Halaman Edit Profil dan menangani hasil kembalian
  Future<void> _openEditProfile() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          user: widget.user,
          initialProfile: _profileData,
        ),
      ),
    );

    // Jika profil berhasil diperbarui, muat ulang data dan tampilkan Snackbar hijau
    if (updated == true && mounted) {
      _loadProfileData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                'Profil berhasil diperbarui!',
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2D6A4F), // Latar belakang hijau
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Membangun widget avatar foto profil yang responsif terhadap perubahan
  Widget _buildAvatar() {
    final photoPath = _profileData['photo_path'];
    final isRemoved = _profileData['avatar'] == 'removed';

    // 1. Menggunakan file gambar hasil kamera/galeri jika ada
    if (!isRemoved && photoPath != null && photoPath.isNotEmpty && File(photoPath).existsSync()) {
      return Image.file(
        File(photoPath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(),
      );
    }

    // 2. Foto profil dihapus (menggunakan avatar ikon placeholder)
    if (isRemoved) {
      return _buildFallbackAvatar();
    }

    // 3. Menggunakan avatar default aplikasi
    return Image.asset(
      _profileData['avatar'] ?? 'assets/avatar_zahra.png',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(),
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      color: const Color(0xFFE2F1E8),
      child: const Icon(Icons.person, color: Color(0xFF36785A), size: 36),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sinkronisasi nama, email, dan tanggal bergabung dari data akun
    final name = _profileData['name'] ?? widget.user.name;
    final email = _profileData['email'] ?? widget.user.email;
    final dob = _profileData['dob'] ?? '12 Juli 2003';
    final gender = _profileData['gender'] ?? 'Perempuan';
    final phone = _profileData['phone'] ?? '089334212098';
    final joined = _profileData['joined'] ?? 'Bergabung sejak Juni 2026';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF36785A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Profil Saya',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          children: [
            // Card 1: Ringkasan Akun (Summary Card)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Avatar Pengguna
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF36785A), width: 2),
                        ),
                        child: ClipOval(
                          child: _buildAvatar(),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.poppins(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              email,
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Informasi Tanggal Bergabung dalam format Bulan & Tahun
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 11,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    joined,
                                    style: GoogleFonts.poppins(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Divider(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                    height: 1,
                  ),
                  const SizedBox(height: 12),

                  // Tombol Masuk ke Halaman Edit Profil
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openEditProfile,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: Text(
                        'Edit Profil',
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? const Color(0xFF58AF86) : const Color(0xFF36785A),
                        side: BorderSide(
                          color: isDark ? const Color(0xFF58AF86) : const Color(0xFF36785A),
                          width: 1.2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Card 2: Informasi Pribadi Lengkap
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE2F1E8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.badge_outlined, size: 18, color: Color(0xFF36785A)),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Informasi Pribadi',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                    height: 1,
                  ),
                  const SizedBox(height: 12),

                  _buildInfoRow(
                    isDark: isDark,
                    icon: Icons.person_outline_rounded,
                    iconBg: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                    iconColor: const Color(0xFF64748B),
                    label: 'Nama Lengkap',
                    value: name,
                  ),
                  _buildInfoRow(
                    isDark: isDark,
                    icon: Icons.cake_outlined,
                    iconBg: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE0F2FE),
                    iconColor: const Color(0xFF0284C7),
                    label: 'Tanggal Lahir',
                    value: dob,
                  ),
                  _buildInfoRow(
                    isDark: isDark,
                    icon: Icons.wc_outlined,
                    iconBg: isDark ? const Color(0xFF4A1D36) : const Color(0xFFFCE7F3),
                    iconColor: const Color(0xFFDB2777),
                    label: 'Jenis Kelamin',
                    value: gender,
                  ),
                  _buildInfoRow(
                    isDark: isDark,
                    icon: Icons.mail_outline_rounded,
                    iconBg: isDark ? const Color(0xFF4A2A1A) : const Color(0xFFFFEDD5),
                    iconColor: const Color(0xFFEA580C),
                    label: 'Email',
                    value: email,
                  ),
                  _buildInfoRow(
                    isDark: isDark,
                    icon: Icons.phone_outlined,
                    iconBg: isDark ? const Color(0xFF133E2B) : const Color(0xFFDCFCE7),
                    iconColor: const Color(0xFF16A34A),
                    label: 'Telepon',
                    value: phone,
                    isLast: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required bool isDark,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 17, color: iconColor),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
