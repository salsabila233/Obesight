import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  final Map<String, String> initialProfile;

  const EditProfileScreen({
    super.key,
    required this.user,
    required this.initialProfile,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  late TextEditingController _nameController;
  late TextEditingController _dobController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late String _selectedGender;

  // Photo state
  String _avatarState = 'default'; // 'default', 'custom_camera', 'custom_gallery', 'removed'

  // Initial values to detect changes
  late String _initialName;
  late String _initialDob;
  late String _initialEmail;
  late String _initialPhone;
  late String _initialGender;

  @override
  void initState() {
    super.initState();
    _initialName = widget.initialProfile['name'] ?? widget.user.name;
    _initialDob = widget.initialProfile['dob'] ?? '12 Juli 2003';
    _initialEmail = widget.initialProfile['email'] ?? widget.user.email;
    _initialPhone = widget.initialProfile['phone'] ?? '089334212098';
    _initialGender = widget.initialProfile['gender'] ?? 'Perempuan';

    _nameController = TextEditingController(text: _initialName);
    _dobController = TextEditingController(text: _initialDob);
    _emailController = TextEditingController(text: _initialEmail);
    _phoneController = TextEditingController(text: _initialPhone);
    _selectedGender = _initialGender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool get _hasChanges {
    return _nameController.text.trim() != _initialName ||
        _dobController.text.trim() != _initialDob ||
        _emailController.text.trim() != _initialEmail ||
        _phoneController.text.trim() != _initialPhone ||
        _selectedGender != _initialGender ||
        _avatarState != 'default';
  }

  void _handleBack() {
    if (_hasChanges) {
      _showCancelConfirmDialog();
    } else {
      Navigator.of(context).pop(false);
    }
  }

  void _showCancelConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              'Batalkan Perubahan?',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
            ),
          ],
        ),
        content: Text(
          'Perubahan yang Anda buat belum disimpan. Yakin ingin membatalkan dan kembali ke profil?',
          style: GoogleFonts.poppins(fontSize: 12.5, color: const Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Lanjut Edit',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFF36785A)),
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
              Navigator.pop(ctx); // Close dialog
              Navigator.of(context).pop(false); // Pop screen
            },
            child: Text(
              'Batalkan',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Foto Profil',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 14),

            // Ambil Foto (Kamera)
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFE2F1E8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF36785A), size: 20),
              ),
              title: Text('Ambil Foto (Kamera)', style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w600)),
              subtitle: Text('Gunakan kamera ponsel untuk foto baru', style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFF64748B))),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _avatarState = 'custom_camera');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Foto berhasil diambil dari Kamera!'),
                    backgroundColor: Color(0xFF36785A),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),

            // Unggah Gambar (Galeri)
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFE0F2FE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library_rounded, color: Color(0xFF0284C7), size: 20),
              ),
              title: Text('Pilih dari Galeri', style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w600)),
              subtitle: Text('Pilih foto dari penyimpanan perangkat', style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFF64748B))),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _avatarState = 'custom_gallery');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Foto berhasil dipilih dari Galeri!'),
                    backgroundColor: Color(0xFF36785A),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),

            // Hapus Foto
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 20),
              ),
              title: Text('Hapus Foto Profil', style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w600, color: const Color(0xFFDC2626))),
              subtitle: Text('Gunakan avatar bawaan ObeSight', style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFF94A3B8))),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _avatarState = 'removed');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Foto profil dihapus. Menggunakan avatar bawaan.'),
                    backgroundColor: Color(0xFF0F172A),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _saveProfile() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    _authService.updateUserProfile(
      userId: widget.user.id,
      name: _nameController.text.trim(),
      dob: _dobController.text.trim(),
      gender: _selectedGender,
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    // Show Alert Dialog Success as requested
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Color(0xFF16A34A), size: 36),
            ),
            const SizedBox(height: 12),
            Text(
              'Berhasil Disimpan! 🎉',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: Text(
          'Profil Anda telah berhasil diperbarui dan disinkronkan ke akun ObeSight.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF475569)),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx); // Close dialog
                Navigator.of(context).pop(true); // Pop screen back to profile
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF36785A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
              child: Text(
                'Selesai',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarWidget() {
    if (_avatarState == 'removed') {
      return Container(
        color: const Color(0xFFE2F1E8),
        child: const Icon(Icons.person, color: Color(0xFF36785A), size: 48),
      );
    }
    return Image.asset(
      'assets/avatar_zahra.png',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: const Color(0xFFE2F1E8),
        child: const Icon(Icons.person, color: Color(0xFF36785A), size: 48),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showCancelConfirmDialog();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF489874),
        appBar: AppBar(
          backgroundColor: const Color(0xFF489874),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: _handleBack,
          ),
          title: Text(
            'Edit Profil',
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
          decoration: const BoxDecoration(
            color: Color(0xFFF4F8F6),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Avatar with Camera Badge & Tap action
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _showPhotoOptions,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 92,
                                height: 92,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF36785A), width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF36785A).withValues(alpha: 0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: _buildAvatarWidget(),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF36785A),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _showPhotoOptions,
                          child: Text(
                            'Ubah Foto Profil',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF36785A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Form Container Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFEAEFEA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField(
                          label: 'Nama Lengkap',
                          controller: _nameController,
                          icon: Icons.person_outline_rounded,
                          validator: (val) => val == null || val.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          label: 'Tanggal Lahir',
                          controller: _dobController,
                          icon: Icons.calendar_today_outlined,
                          hint: 'Contoh: 12 Juli 2003',
                        ),
                        const SizedBox(height: 16),

                        // Jenis Kelamin Dropdown
                        Text(
                          'Jenis Kelamin',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedGender,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.wc_outlined, size: 20, color: Color(0xFF64748B)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF36785A), width: 1.5),
                            ),
                          ),
                          style: GoogleFonts.poppins(fontSize: 13.5, color: const Color(0xFF0F172A)),
                          items: const [
                            DropdownMenuItem(value: 'Perempuan', child: Text('Perempuan')),
                            DropdownMenuItem(value: 'Laki-laki', child: Text('Laki-laki')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedGender = val;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          label: 'Email',
                          controller: _emailController,
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: (val) => val == null || !val.contains('@') ? 'Masukkan email yang valid' : null,
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          label: 'Nomor Telepon',
                          controller: _phoneController,
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Button Simpan
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF36785A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Simpan Perubahan',
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.poppins(fontSize: 13.5, color: const Color(0xFF0F172A)),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFF64748B)),
            hintText: hint,
            hintStyle: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF94A3B8)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF36785A), width: 1.5),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
