import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../home/admin_home_screen.dart';
import '../home/user_home_screen.dart';
import '../skrining/skrining_landing_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  final UserModel user;
  final bool isGatedFlow; // Jika true, diarahkan langsung ke skrining setelah simpan
  final bool redirectToHomeAfterSave; // Jika true, langsung arahkan ke beranda setelah simpan

  const CompleteProfileScreen({
    super.key,
    required this.user,
    this.isGatedFlow = true,
    this.redirectToHomeAfterSave = false,
  });

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _dobController;
  late TextEditingController _phoneController;

  String? _selectedGender;
  bool _isLoading = false;

  final List<String> _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    final profile = _authService.getUserProfile(widget.user.id);

    final initialName = profile['name']?.isNotEmpty == true ? profile['name']! : widget.user.name;
    final initialEmail = profile['email']?.isNotEmpty == true ? profile['email']! : widget.user.email;
    final initialDob = profile['dob'] ?? widget.user.dob ?? '';
    final initialGender = profile['gender'] ?? widget.user.gender;
    final initialPhone = profile['phone'] ?? widget.user.phone ?? '';

    _nameController = TextEditingController(text: initialName);
    _emailController = TextEditingController(text: initialEmail);
    _dobController = TextEditingController(text: initialDob);
    _phoneController = TextEditingController(text: initialPhone);

    if (initialGender != null && (initialGender == 'Perempuan' || initialGender == 'Laki-laki')) {
      _selectedGender = initialGender;
    } else {
      _selectedGender = 'Perempuan';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = DateTime(2003, 7, 12);
    final firstDate = DateTime(1920);
    final lastDate = now;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: isDark
              ? ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: AppColors.primaryGreen,
                    onPrimary: Colors.white,
                    surface: Color(0xFF1E293B),
                    onSurface: Colors.white,
                  ),
                  dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF1E293B)),
                )
              : ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: AppColors.primaryGreen,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Color(0xFF0F172A),
                  ),
                ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted = '${picked.day} ${_months[picked.month - 1]} ${picked.year}';
      setState(() {
        _dobController.text = formatted;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_dobController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih Tanggal Lahir terlebih dahulu'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    if (_selectedGender == null || _selectedGender!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih Jenis Kelamin terlebih dahulu'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final name = _nameController.text.trim();
    final dob = _dobController.text.trim();
    final gender = _selectedGender!;
    final phone = _phoneController.text.trim();

    // 1. Simpan ke AuthService & Firestore users/{uid}
    _authService.updateUserProfile(
      userId: widget.user.id,
      name: name,
      dob: dob,
      gender: gender,
      phone: phone,
    );

    await Future.delayed(const Duration(milliseconds: 350));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    final updatedUser = widget.user.copyWith(
      name: name,
      dob: dob,
      gender: gender,
      phone: phone,
      isBiodataComplete: true,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'Profil berhasil dilengkapi!',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (widget.isGatedFlow) {
      // Redirect langsung ke Skrining Landing Screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SkriningLandingScreen(user: updatedUser),
        ),
      );
    } else if (widget.redirectToHomeAfterSave || !Navigator.of(context).canPop()) {
      // Redirect langsung ke Beranda sesuai akun yang sedang aktif
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => updatedUser.isAdmin
              ? AdminHomeScreen(user: updatedUser)
              : UserHomeScreen(user: updatedUser),
        ),
        (route) => false,
      );
    } else {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: const Color(0xFF489874),
      appBar: AppBar(
        backgroundColor: const Color(0xFF489874),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => widget.user.isAdmin
                      ? AdminHomeScreen(user: widget.user)
                      : UserHomeScreen(user: widget.user),
                ),
                (route) => false,
              );
            }
          },
        ),
        title: Text(
          'Lengkapi Profil',
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Banner tentang Gating Skrining
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE8F5EE),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF36785A).withValues(alpha: isDark ? 0.4 : 0.25),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF36785A).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_user_rounded,
                          color: Color(0xFF36785A),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Persyaratan Skrining Obesitas',
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF1E4534),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Mohon lengkapi Tanggal Lahir, Jenis Kelamin, dan Nomor Telepon agar sistem kami dapat menghitung risiko obesitas secara akurat.',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF2D5A45),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Form Container Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Field 1: Nama Lengkap
                      Text(
                        'Nama Lengkap',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        style: GoogleFonts.poppins(fontSize: 13.5, color: textDark),
                        decoration: InputDecoration(
                          hintText: 'Masukkan nama lengkap',
                          prefixIcon: Icon(Icons.person_outline_rounded, color: textMuted, size: 20),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama lengkap tidak boleh kosong';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      // Field 2: Email (Informasi Akun)
                      Text(
                        'Alamat Email',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        readOnly: true,
                        style: GoogleFonts.poppins(fontSize: 13.5, color: textMuted),
                        decoration: InputDecoration(
                          hintText: 'Email terdaftar',
                          prefixIcon: Icon(Icons.email_outlined, color: textMuted, size: 20),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFFF1F5F9),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Field 3: Tanggal Lahir (Wajib Gating)
                      Row(
                        children: [
                          Text(
                            'Tanggal Lahir',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('*', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _pickDate(context),
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: _dobController,
                            style: GoogleFonts.poppins(fontSize: 13.5, color: textDark),
                            decoration: InputDecoration(
                              hintText: 'Contoh: 12 Juli 2003',
                              prefixIcon: Icon(Icons.calendar_today_rounded, color: textMuted, size: 20),
                              suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF36785A)),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Tanggal lahir wajib diisi';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Field 4: Jenis Kelamin (Wajib Gating)
                      Row(
                        children: [
                          Text(
                            'Jenis Kelamin',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('*', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildGenderOption(
                              label: 'Laki-laki',
                              symbol: '♂',
                              symbolColor: const Color(0xFF00BBA7),
                              isSelected: _selectedGender == 'Laki-laki',
                              onTap: () => setState(() => _selectedGender = 'Laki-laki'),
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildGenderOption(
                              label: 'Perempuan',
                              symbol: '♀',
                              symbolColor: const Color(0xFFD946EF),
                              isSelected: _selectedGender == 'Perempuan',
                              onTap: () => setState(() => _selectedGender = 'Perempuan'),
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Field 5: Nomor Telepon (Wajib Gating)
                      Row(
                        children: [
                          Text(
                            'Nomor Telepon',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('*', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: GoogleFonts.poppins(fontSize: 13.5, color: textDark),
                        decoration: InputDecoration(
                          hintText: 'Contoh: 081234567890',
                          prefixIcon: Icon(Icons.phone_outlined, color: textMuted, size: 20),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nomor telepon wajib diisi';
                          }
                          if (value.trim().length < 9) {
                            return 'Nomor telepon minimal 9 digit';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Tombol Simpan & Lanjutkan
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF36785A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.isGatedFlow
                                    ? 'Simpan & Lanjutkan ke Skrining'
                                    : (widget.redirectToHomeAfterSave
                                        ? 'Simpan & Masuk ke Beranda'
                                        : 'Simpan Perubahan'),
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderOption({
    required String label,
    required String symbol,
    required Color symbolColor,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final activeBg = isDark ? const Color(0xFF1E3A2F) : const Color(0xFFF0FAF5);
    final inactiveBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final activeBorder = isDark ? const Color(0xFF58AF86) : const Color(0xFF489874);
    final inactiveBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final activeText = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF2E6B4F);
    final inactiveText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeBorder : inactiveBorder,
            width: isSelected ? 1.6 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              symbol,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: symbolColor,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? activeText : inactiveText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
