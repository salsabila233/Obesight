import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../auth/login_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  final UserModel user;

  const AdminHomeScreen({
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Image.asset('assets/logo.png', width: 30, height: 30),
            const SizedBox(width: 8),
            Text(
              'ObeSight Admin',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white70),
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
            // Admin Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFDC2626)),
                        ),
                        child: Text(
                          'PANEL ADMINISTRATOR',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFCA5A5),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const Icon(Icons.shield_outlined, color: Color(0xFFFCA5A5), size: 20),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user.name,
                    style: GoogleFonts.poppins(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.title ?? 'Administrator Sistem ObeSight',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Metrics Grid
            Text(
              'Ringkasan Data & Skrining',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Total Pasien',
                    value: '1.482',
                    trend: '+12% bln ini',
                    icon: Icons.people_alt_outlined,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Risiko Tinggi',
                    value: '134',
                    trend: 'Perlu atensi',
                    icon: Icons.warning_amber_rounded,
                    color: const Color(0xFFE11D48),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Konsultasi Aktif',
                    value: '28',
                    trend: '5 menunggu',
                    icon: Icons.chat_bubble_outline_rounded,
                    color: const Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Akurasi Model',
                    value: '94.8%',
                    trend: 'Model v2.4',
                    icon: Icons.auto_graph_rounded,
                    color: const Color(0xFF7C3AED),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Management Tools
            Text(
              'Menu Pengelolaan Sistem',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),

            _buildAdminActionTile(
              icon: Icons.manage_accounts_outlined,
              title: 'Kelola Data Pengguna & Hak Akses',
              subtitle: 'Verifikasi akun dan status keanggotaan',
            ),
            const SizedBox(height: 10),
            _buildAdminActionTile(
              icon: Icons.biotech_outlined,
              title: 'Parameter Algoritma Risiko Obesitas',
              subtitle: 'Pengaturan cut-off BMI dan biomarker',
            ),
            const SizedBox(height: 10),
            _buildAdminActionTile(
              icon: Icons.file_download_outlined,
              title: 'Ekspor Laporan Epidemiologi',
              subtitle: 'Unduh rekap statistik format Excel/PDF',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String trend,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            trend,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF334155)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }
}
