import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../profile/edit_profile_screen.dart';
import 'skrining_wizard_screen.dart';

class SkriningLandingScreen extends StatefulWidget {
  final UserModel? user;

  const SkriningLandingScreen({
    super.key,
    this.user,
  });

  @override
  State<SkriningLandingScreen> createState() => _SkriningLandingScreenState();
}

class _SkriningLandingScreenState extends State<SkriningLandingScreen> {
  late bool _isBiodataComplete;

  @override
  void initState() {
    super.initState();
    _checkBiodataStatus();
  }

  void _checkBiodataStatus() {
    final userId = widget.user?.id ?? AuthService().currentUser?.id ?? 'usr_001';
    setState(() {
      _isBiodataComplete = AuthService().isBiodataCompleted(userId);
    });
  }

  void _navigateToWizard() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SkriningWizardScreen(user: widget.user),
      ),
    ).then((_) => _checkBiodataStatus());
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF4A8B6C); // Medical soft green
    const textDark = Color(0xFF1E293B);
    const textMuted = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: textMuted,
                        size: 28,
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),

            // Optional Warning Banner if Profile is Incomplete (Matching reference Page 24)
            if (!_isBiodataComplete)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: InkWell(
                  onTap: () {
                    final userToEdit = widget.user ?? AuthService().currentUser ?? AuthService.defaultUserAccount;
                    final initialProfile = AuthService().getUserProfile(userToEdit.id);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EditProfileScreen(
                          user: userToEdit,
                          initialProfile: initialProfile,
                        ),
                      ),
                    ).then((_) => _checkBiodataStatus());
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFE53E3E),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'Lengkapi profil terlebih dahulu!',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    // Brand Header
                    Text(
                      'ObeSight',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: primaryGreen,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kenali Risiko, Jaga Masa Depanmu',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: textMuted,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Character Illustration
                    Image.asset(
                      'assets/illustration_woman.png',
                      height: 240,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 220,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.accessibility_new_rounded,
                          size: 100,
                          color: primaryGreen,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Headings matching UI reference
                    Text(
                      'Kenali dirimu,',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                    Text(
                      'Kendalikan',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: primaryGreen,
                      ),
                    ),
                    Text(
                      'risiko obesitas',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: primaryGreen,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Short description paragraph
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Text(
                        'Skrining ini membantu kamu mengetahui risiko obesitas berdasarkan pola hidup dan kebiasaan sehari-hari.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                          color: textMuted,
                          height: 1.45,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // "Mulai Skrining ->" Button
                    ElevatedButton(
                      onPressed: _navigateToWizard,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Mulai Skrining',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
