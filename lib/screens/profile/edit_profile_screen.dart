import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
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
  final _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _dobController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late String _selectedGender;

  // State pengelolaan foto profil
  File? _selectedImageFile;
  bool _isPhotoRemoved = false;

  // Nilai awal untuk mendeteksi perubahan
  late String _initialName;
  late String _initialDob;
  late String _initialEmail;
  late String _initialPhone;
  late String _initialGender;
  late String _initialPhotoPath;
  late bool _initialIsRemoved;

  @override
  void initState() {
    super.initState();
    _initialName = widget.initialProfile['name'] ?? widget.user.name;
    _initialDob = widget.initialProfile['dob'] ?? '12 Juli 2003';
    _initialEmail = widget.initialProfile['email'] ?? widget.user.email;
    _initialPhone = widget.initialProfile['phone'] ?? '089334212098';
    _initialGender = widget.initialProfile['gender'] ?? 'Perempuan';
    _initialPhotoPath = widget.initialProfile['photo_path'] ?? '';
    _initialIsRemoved = widget.initialProfile['avatar'] == 'removed';

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

  /// Mengecek apakah ada perubahan data pada formulir atau foto
  bool get _hasChanges {
    final isNameChanged = _nameController.text.trim() != _initialName;
    final isDobChanged = _dobController.text.trim() != _initialDob;
    final isEmailChanged = _emailController.text.trim() != _initialEmail;
    final isPhoneChanged = _phoneController.text.trim() != _initialPhone;
    final isGenderChanged = _selectedGender != _initialGender;
    final isPhotoChanged = _selectedImageFile != null || (_isPhotoRemoved != _initialIsRemoved);

    return isNameChanged ||
        isDobChanged ||
        isEmailChanged ||
        isPhoneChanged ||
        isGenderChanged ||
        isPhotoChanged;
  }

  /// Menangani aksi kembali: jika ada perubahan, tampilkan konfirmasi
  void _handleBack() {
    if (_hasChanges) {
      _showCancelConfirmDialog();
    } else {
      Navigator.of(context).pop(false);
    }
  }

  /// Pop-up konfirmasi di tengah layar saat menekan tombol kembali
  void _showCancelConfirmDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.help_outline_rounded,
                color: Color(0xFFD97706),
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Konfirmasi Perubahan',
              style: GoogleFonts.poppins(
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: Text(
          'Batalkan perubahan pada profil Anda?',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF475569),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        actions: [
          Row(
            children: [
              // Tombol "Batal": Kembali ke halaman profil saya tanpa menyimpan perubahan
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(dialogCtx); // Tutup dialog
                    Navigator.of(context).pop(false); // Kembali tanpa menyimpan
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Batal',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Tombol "Simpan": Memperbarui data, lalu kembali ke halaman profil dengan data terbaru
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogCtx); // Tutup dialog
                    _saveProfileAndPop(); // Simpan dan kembali
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF36785A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Simpan',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Mengambil foto menggunakan image_picker (Kamera atau Galeri)
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _selectedImageFile = File(picked.path);
          _isPhotoRemoved = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih gambar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Menghapus foto profil
  void _removePhoto() {
    setState(() {
      _selectedImageFile = null;
      _isPhotoRemoved = true;
    });
  }

  /// Menampilkan bottom sheet dengan 3 opsi: Kamera, Galeri, Hapus Foto
  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetCtx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
            const SizedBox(height: 12),

            // 1. Ambil Foto (Kamera)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(9),
                decoration: const BoxDecoration(
                  color: Color(0xFFE2F1E8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF36785A), size: 20),
              ),
              title: Text('Ambil Foto', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: Text('Gunakan kamera perangkat untuk mengambil foto baru', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B))),
              onTap: () {
                Navigator.pop(bottomSheetCtx);
                _pickImage(ImageSource.camera);
              },
            ),

            // 2. Pilih dari Galeri
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(9),
                decoration: const BoxDecoration(
                  color: Color(0xFFE0F2FE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library_rounded, color: Color(0xFF0284C7), size: 20),
              ),
              title: Text('Pilih dari Galeri', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: Text('Pilih foto dari penyimpanan galeri perangkat', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B))),
              onTap: () {
                Navigator.pop(bottomSheetCtx);
                _pickImage(ImageSource.gallery);
              },
            ),

            // 3. Hapus Foto Profil
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(9),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 20),
              ),
              title: Text('Hapus Foto Profil', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFFDC2626))),
              subtitle: Text('Gunakan avatar bawaan ObeSight', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF94A3B8))),
              onTap: () {
                Navigator.pop(bottomSheetCtx);
                _removePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Menyimpan perubahan dan kembali ke Halaman Profil Saya
  void _saveProfileAndPop() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    String? photoPathToSave;
    String? avatarToSave;

    if (_isPhotoRemoved) {
      avatarToSave = 'removed';
      photoPathToSave = '';
    } else if (_selectedImageFile != null) {
      avatarToSave = 'custom';
      photoPathToSave = _selectedImageFile!.path;
    } else {
      photoPathToSave = _initialPhotoPath;
      avatarToSave = widget.initialProfile['avatar'];
    }

    _authService.updateUserProfile(
      userId: widget.user.id,
      name: _nameController.text.trim(),
      dob: _dobController.text.trim(),
      gender: _selectedGender,
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      avatar: avatarToSave,
      photoPath: photoPathToSave,
    );

    // Pop kembali ke Halaman Profil dengan nilai true (memicu reload data & snackbar hijau)
    Navigator.of(context).pop(true);
  }

  /// Membangun widget avatar berdasarkan state (file kamera/galeri, default, atau removed)
  Widget _buildAvatarWidget() {
    // 1. Gambar baru dipilih dari ImagePicker (Kamera / Galeri)
    if (_selectedImageFile != null && _selectedImageFile!.existsSync()) {
      return Image.file(_selectedImageFile!, fit: BoxFit.cover);
    }

    // 2. Foto profil dihapus
    if (_isPhotoRemoved) {
      return Container(
        color: const Color(0xFFE2F1E8),
        child: const Icon(Icons.person, color: Color(0xFF36785A), size: 48),
      );
    }

    // 3. Foto dari path lokal sebelumnya yang pernah disimpan
    if (_initialPhotoPath.isNotEmpty && File(_initialPhotoPath).existsSync()) {
      return Image.file(File(_initialPhotoPath), fit: BoxFit.cover);
    }

    // 4. Avatar default atau asset
    if (_initialIsRemoved) {
      return Container(
        color: const Color(0xFFE2F1E8),
        child: const Icon(Icons.person, color: Color(0xFF36785A), size: 48),
      );
    }

    return Image.asset(
      widget.initialProfile['avatar'] ?? 'assets/avatar_zahra.png',
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
                  // Avatar dengan Tombol Kamera & Aksi Tap
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _showPhotoOptions,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 96,
                                height: 96,
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

                  // Formulir Isian Profil
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

                        // Dropdown Jenis Kelamin
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

                  // Tombol Simpan Utama
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveProfileAndPop,
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
