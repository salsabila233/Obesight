import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../auth/login_screen.dart';

class UserHomeScreen extends StatelessWidget {
  final UserModel user;

  const UserHomeScreen({
    super.key,
    required this.user,
  });

  void _handleLogout(BuildContext context) {
    AuthService().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Image.asset('assets/logo.png', width: 32, height: 32),
            const SizedBox(width: 8),
            Text(
              'ObeSight',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.brandTitleGreen,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF64748B)),
            tooltip: 'Keluar',
            onPressed: () => _handleLogout(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Greeting Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F9B77), Color(0xFF2E6B4F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'BERANDA PENGGUNA',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Halo, ${user.name}!',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mari kenali & pantau kesehatan tubuh Anda hari ini.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0] : 'U',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // BMI Health Status Card
            Text(
              'Indikator Kesehatan Anda',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.darkGreen,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Indeks Massa Tubuh (BMI)',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '21.4 kg/m²',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F4EA),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Berat Ideal',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF137333),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Progress indicator bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: const LinearProgressIndicator(
                      value: 0.45,
                      minHeight: 8,
                      backgroundColor: Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Features Grid
            Text(
              'Layanan & Fitur ObeSight',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.darkGreen,
              ),
            ),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
              children: [
                _buildFeatureCard(
                  icon: Icons.monitor_heart_outlined,
                  title: 'Deteksi Risiko',
                  subtitle: 'Skrining cerdas',
                  color: const Color(0xFF0284C7),
                ),
                _buildFeatureCard(
                  icon: Icons.restaurant_outlined,
                  title: 'Panduan Gizi',
                  subtitle: 'Kalori & nutrisi',
                  color: const Color(0xFF16A34A),
                ),
                _buildFeatureCard(
                  icon: Icons.directions_run_outlined,
                  title: 'Target Olahraga',
                  subtitle: 'Aktivitas fisik harian',
                  color: const Color(0xFFEA580C),
                ),
                _buildFeatureCard(
                  icon: Icons.medical_services_outlined,
                  title: 'Konsultasi Ahli',
                  subtitle: 'Chat dokter & gizi',
                  color: const Color(0xFF9333EA),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
