import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_alert.dart';

class AdminProfileScreen extends StatefulWidget {
  final UserModel user;
  final ValueChanged<UserModel>? onProfileUpdated;

  const AdminProfileScreen({
    super.key,
    required this.user,
    this.onProfileUpdated,
  });

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final _authService = AuthService();
  late UserModel _currentUser;
  late String _currentName;
  late String _currentPhone;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _resolveInitialValues();
    _loadLatestProfile();
  }

  /// Tentukan nilai awal profil jika data di Firestore belum ada
  void _resolveInitialValues() {
    final rawName = _currentUser.name.trim();
    if (rawName.isNotEmpty &&
        rawName != 'Administrator' &&
        rawName != 'Dr. Hendra Wijaya, Sp.GK' &&
        rawName != 'Pengguna ObeSight') {
      _currentName = rawName;
    } else {
      _currentName = 'Admin ObeSight';
    }

    final rawPhone = (_currentUser.phone ?? '').trim();
    if (rawPhone.isNotEmpty && rawPhone != '081198765432') {
      _currentPhone = rawPhone;
    } else {
      _currentPhone = '089334213110';
    }
  }

  /// Muat data profil terbaru dari Firestore users/{uid} secara asinkron
  Future<void> _loadLatestProfile() async {
    try {
      final updated = await _authService.fetchUserProfile(_currentUser.id);
      if (updated != null && mounted) {
        setState(() {
          _currentUser = updated;
          final updatedName = updated.name.trim();
          if (updatedName.isNotEmpty &&
              updatedName != 'Administrator' &&
              updatedName != 'Dr. Hendra Wijaya, Sp.GK' &&
              updatedName != 'Pengguna ObeSight') {
            _currentName = updatedName;
          }
          final updatedPhone = (updated.phone ?? '').trim();
          if (updatedPhone.isNotEmpty && updatedPhone != '081198765432') {
            _currentPhone = updatedPhone;
          }
        });
      }
    } catch (_) {}
  }

  String get _email {
    final email = _currentUser.email.trim();
    if (email.isNotEmpty) return email;
    try {
      final fbEmail = FirebaseAuth.instance.currentUser?.email;
      if (fbEmail != null && fbEmail.isNotEmpty) return fbEmail;
    } catch (_) {}
    return 'adminobesight@gmail.com';
  }

  String get _accountCreatedDate {
    DateTime? date = _currentUser.createdAt;
    if (date == null) {
      try {
        final fbUser = FirebaseAuth.instance.currentUser;
        date = fbUser?.metadata.creationTime;
      } catch (_) {}
    }
    date ??= DateTime(2026, 8, 1);

    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    final dayStr = date.day.toString().padLeft(2, '0');
    final monthStr = months[date.month - 1];
    final yearStr = date.year.toString();

    return '$dayStr $monthStr $yearStr';
  }

  /// Modal Bottom Sheet sederhana untuk memperbarui Nama Lengkap & Telepon
  void _openEditProfileSheet(BuildContext context, bool isDark) {
    final nameController = TextEditingController(text: _currentName);
    final phoneController = TextEditingController(text: _currentPhone);
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ubah Informasi Profil',
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            size: 20,
                          ),
                          onPressed: () => Navigator.of(sheetContext).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Perbarui nama lengkap dan nomor kontak administrator.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Input Nama Lengkap
                    Text(
                      'Nama Lengkap',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: nameController,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Masukkan nama lengkap',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 13,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(
                          Icons.person_outline_rounded,
                          size: 20,
                          color: Color(0xFF438466),
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF438466),
                            width: 1.5,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama lengkap tidak boleh kosong';
                        }
                        if (value.trim().length < 3) {
                          return 'Nama minimal 3 karakter';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Input Nomor Telepon
                    Text(
                      'Nomor Telepon',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Contoh: 089334213110',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 13,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(
                          Icons.phone_outlined,
                          size: 20,
                          color: Color(0xFF438466),
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF438466),
                            width: 1.5,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nomor telepon tidak boleh kosong';
                        }
                        final clean = value.trim();
                        if (clean.length < 9 || clean.length > 15) {
                          return 'Nomor telepon harus antara 9–15 digit';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    // Catatan Keamanan
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 16,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Email, Peran, dan Tanggal Akun bersifat tetap dan tidak dapat diubah.',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Tombol Aksi
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSaving ? null : () => Navigator.of(sheetContext).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(
                                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Batal',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (!(formKey.currentState?.validate() ?? false)) {
                                      return;
                                    }

                                    setSheetState(() => isSaving = true);
                                    final newName = nameController.text.trim();
                                    final newPhone = phoneController.text.trim();

                                    try {
                                      await _authService.updateUserProfile(
                                        userId: _currentUser.id,
                                        name: newName,
                                        phone: newPhone,
                                      );

                                      final updatedUser = _currentUser.copyWith(
                                        name: newName,
                                        phone: newPhone,
                                      );

                                      if (mounted) {
                                        setState(() {
                                          _currentName = newName;
                                          _currentPhone = newPhone;
                                          _currentUser = updatedUser;
                                        });
                                        widget.onProfileUpdated?.call(updatedUser);
                                      }

                                      if (sheetContext.mounted) {
                                        Navigator.of(sheetContext).pop();
                                      }

                                      if (context.mounted) {
                                        AppAlert.showSuccess(
                                          context,
                                          'Profil administrator berhasil diperbarui.',
                                        );
                                      }
                                    } catch (e) {
                                      setSheetState(() => isSaving = false);
                                      if (context.mounted) {
                                        AppAlert.showError(
                                          context,
                                          'Gagal memperbarui profil: $e',
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF438466),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Simpan Perubahan',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final textLabel = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B);
    final textValue = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: const Color(0xFF438466), // Warna Header Hijau Melengkung
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header Bar: Tombol Back & Judul "Profil Saya"
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 16, 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 48), // Seimbangkan offset tombol back
                        child: Text(
                          'Profil Saya',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Konten Bawah dengan Sudut Atas Membulat
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F3),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 110),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. KARTU PROFIL UTAMA
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: cardBorder),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Avatar Bulat Hijau dengan Siluet Putih
                              Container(
                                width: 72,
                                height: 72,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF438466),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  color: Colors.white,
                                  size: 46,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _currentName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _email,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Badge Hijau "Administrator"
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF132F23) : const Color(0xFFE8F5EE),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.verified_rounded,
                                            size: 13,
                                            color: Color(0xFF2E7D5B),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Administrator',
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: isDark
                                                  ? const Color(0xFF6EE7B7)
                                                  : const Color(0xFF2E7D5B),
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
                        ),

                        const SizedBox(height: 18),

                        // 2. KARTU INFORMASI PRIBADI
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: cardBorder),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header Judul Kartu
                              Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF132F23) : const Color(0xFFE8F5EE),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(0xFF2E7D5B)
                                            : const Color(0xFF388E6B),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.person_rounded,
                                      size: 16,
                                      color: Color(0xFF2E7D5B),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Informasi Pribadi',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Baris 1: Nama Lengkap (Editable)
                              _buildInfoRow(
                                iconBg: const Color(0xFFEDEDED),
                                iconWidget: const Icon(
                                  Icons.person_rounded,
                                  size: 16,
                                  color: Color(0xFF71717A),
                                ),
                                label: 'Nama Lengkap',
                                value: _currentName,
                                isEditable: true,
                                onEditTap: () => _openEditProfileSheet(context, isDark),
                                textLabel: textLabel,
                                textValue: textValue,
                                isDark: isDark,
                              ),

                              _buildDivider(isDark),

                              // Baris 2: Email (Read-Only)
                              _buildInfoRow(
                                iconBg: const Color(0xFFEEF2FF),
                                iconWidget: const Icon(
                                  Icons.mail_outline_rounded,
                                  size: 16,
                                  color: Color(0xFFEA580C),
                                ),
                                label: 'Email',
                                value: _email,
                                isEditable: false,
                                textLabel: textLabel,
                                textValue: textValue,
                                isDark: isDark,
                              ),

                              _buildDivider(isDark),

                              // Baris 3: Telepon (Editable)
                              _buildInfoRow(
                                iconBg: const Color(0xFFF3E8FF),
                                iconWidget: const Icon(
                                  Icons.phone_in_talk_rounded,
                                  size: 16,
                                  color: Color(0xFF16A34A),
                                ),
                                label: 'Telepon',
                                value: _currentPhone,
                                isEditable: true,
                                onEditTap: () => _openEditProfileSheet(context, isDark),
                                textLabel: textLabel,
                                textValue: textValue,
                                isDark: isDark,
                              ),

                              _buildDivider(isDark),

                              // Baris 4: Peran (Read-Only)
                              _buildInfoRow(
                                iconBg: const Color(0xFFFEF3C7),
                                iconWidget: const Icon(
                                  Icons.shield_rounded,
                                  size: 16,
                                  color: Color(0xFFF59E0B),
                                ),
                                label: 'Peran',
                                value: 'Administrator',
                                isEditable: false,
                                textLabel: textLabel,
                                textValue: textValue,
                                isDark: isDark,
                              ),

                              _buildDivider(isDark),

                              // Baris 5: Akun Dibuat (Read-Only)
                              _buildInfoRow(
                                iconBg: const Color(0xFFE0F2FE),
                                iconWidget: const Icon(
                                  Icons.calendar_month_rounded,
                                  size: 16,
                                  color: Color(0xFF0284C7),
                                ),
                                label: 'Akun Dibuat',
                                value: _accountCreatedDate,
                                isEditable: false,
                                textLabel: textLabel,
                                textValue: textValue,
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // 3. KARTU HIJAU MUDA "AKUN ADMINISTRATOR"
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF132F23).withValues(alpha: 0.6)
                                : const Color(0xFFE9F5EF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? const Color(0xFF1F4A37) : const Color(0xFFD1EAD8),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF438466),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.info_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Akun Administrator',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Akun ini memiliki akses khusus untuk mengelola dan memantau aplikasi ObeSight.',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11.5,
                                        color: textSecondary,
                                        height: 1.4,
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
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // 4. BOTTOM NAVIGATION BAR (Pil Hijau Desain Baru Tanpa Label)
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF438466),
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF246B4D).withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavIcon(
                icon: Icons.home_rounded,
                tooltip: 'Beranda',
                onTap: () => Navigator.of(context).pop(0),
              ),
              _buildBottomNavIcon(
                icon: Icons.people_alt_rounded,
                tooltip: 'Pengguna',
                onTap: () => Navigator.of(context).pop(1),
              ),
              _buildBottomNavIcon(
                icon: Icons.article_rounded,
                tooltip: 'Artikel',
                onTap: () => Navigator.of(context).pop(2),
              ),
              _buildBottomNavIcon(
                icon: Icons.bar_chart_rounded,
                tooltip: 'Laporan',
                onTap: () => Navigator.of(context).pop(3),
              ),
              _buildBottomNavIcon(
                icon: Icons.settings_rounded,
                tooltip: 'Pengaturan',
                onTap: () => Navigator.of(context).pop(4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 22,
      thickness: 0.8,
      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
    );
  }

  Widget _buildInfoRow({
    required Color iconBg,
    required Widget iconWidget,
    required String label,
    required String value,
    required bool isEditable,
    VoidCallback? onEditTap,
    required Color textLabel,
    required Color textValue,
    required bool isDark,
  }) {
    return InkWell(
      onTap: isEditable ? onEditTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDark ? iconBg.withValues(alpha: 0.2) : iconBg,
                shape: BoxShape.circle,
              ),
              child: Center(child: iconWidget),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textLabel,
              ),
            ),
            const Spacer(),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textValue,
                ),
              ),
            ),
            if (isEditable) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.edit_outlined,
                size: 14,
                color: Color(0xFF438466),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavIcon({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return IconButton(
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 40),
      icon: Icon(
        icon,
        color: Colors.white,
        size: 24,
      ),
      onPressed: onTap,
    );
  }
}
