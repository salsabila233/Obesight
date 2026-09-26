import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  /// Membuka aplikasi email dengan tujuan adminobesight@gmail.com
  static Future<void> launchEmail(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'adminobesight@gmail.com',
      queryParameters: {
        'subject': 'Pertanyaan & Bantuan Layanan ObeSight',
      },
    );

    try {
      final launched = await launchUrl(
        emailLaunchUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(emailLaunchUri);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tidak dapat membuka aplikasi email. Silakan kirim email ke: adminobesight@gmail.com',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  /// Membuka tautan WhatsApp resmi konsultasi ObeSight
  static Future<void> launchWhatsApp(BuildContext context) async {
    final Uri waUri = Uri.parse(
      'https://wa.me/6285602778748?text=Halo%20Admin%20ObeSight,%20saya%20memerlukan%20bantuan%20terkait%20aplikasi.',
    );

    try {
      final launched = await launchUrl(
        waUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(waUri);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tidak dapat membuka WhatsApp. Silakan hubungi: +62 856-0277-8748',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  /// Membuka situs resmi ObeSight
  static Future<void> launchWebsite(BuildContext context) async {
    final Uri webUri = Uri.parse('https://www.obesight.com');
    try {
      final launched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(webUri);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Situs resmi: www.obesight.com',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF36785A),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: const Color(0xFF489874),
      appBar: AppBar(
        backgroundColor: const Color(0xFF489874),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pusat Bantuan',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 17,
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Hero Card: Mint Background
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE2F1E8),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2C5E47) : const Color(0xFFBBE0CF),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ada yang bisa dibantu?',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF1E4534),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Temukan jawaban untuk pertanyaan umum atau hubungi tim customer service kami.',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF2E6B4F),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.support_agent_rounded,
                        color: Color(0xFF36785A),
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2. Hubungi Kami
              Text(
                'Hubungi Kami Langsung',
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),

              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFEAEFEA),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildContactRow(
                      context,
                      isDark: isDark,
                      icon: Icons.mail_outline_rounded,
                      iconColor: const Color(0xFF0284C7),
                      label: 'Email Layanan Resmi',
                      value: 'adminobesight@gmail.com',
                      onTap: () => launchEmail(context),
                    ),
                    Divider(
                      height: 1,
                      indent: 56,
                      endIndent: 16,
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                    ),
                    _buildContactRow(
                      context,
                      isDark: isDark,
                      icon: Icons.chat_bubble_outline_rounded,
                      iconColor: const Color(0xFF16A34A),
                      label: 'WhatsApp Konsultasi',
                      value: '+62 856-0277-8748',
                      onTap: () => launchWhatsApp(context),
                    ),
                    Divider(
                      height: 1,
                      indent: 56,
                      endIndent: 16,
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                    ),
                    _buildContactRow(
                      context,
                      isDark: isDark,
                      icon: Icons.language_rounded,
                      iconColor: const Color(0xFF6366F1),
                      label: 'Situs Resmi',
                      value: 'www.obesight.com',
                      onTap: () => launchWebsite(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 3. Pertanyaan Umum (FAQ)
              Text(
                'Pertanyaan Umum (FAQ)',
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),

              _buildFaqItem(
                isDark: isDark,
                question: 'Bagaimana cara menghitung IMT secara akurat?',
                answer:
                    'Pastikan Anda mengukur berat badan di pagi hari setelah bangun tidur sebelum makan dan tanpa alas kaki. Masukkan tinggi dan berat badan Anda ke fitur Kalkulator IMT di beranda.',
              ),
              _buildFaqItem(
                isDark: isDark,
                question: 'Apakah hasil skrining menggantikan diagnosis dokter?',
                answer:
                    'Tidak. Skrining di ObeSight adalah panduan gaya hidup awal untuk meningkatkan kesadaran terhadap risiko obesitas. Jika Anda memiliki keluhan medis, konsultasikan dengan dokter spesialis.',
              ),
              _buildFaqItem(
                isDark: isDark,
                question: 'Bagaimana cara mengubah profil atau menghapus data?',
                answer:
                    'Anda dapat masuk ke Pengaturan Akun untuk memperbarui email dan kata sandi, atau mengakses tombol Edit Profil di halaman profil utama.',
              ),
              _buildFaqItem(
                isDark: isDark,
                question: 'Apakah fitur pelacak aktivitas fisik memerlukan GPS?',
                answer:
                    'ObeSight menyediakan timer countdown berbasis panduan ilmiah yang dapat digunakan secara offline tanpa memerlukan koneksi GPS terus menerus.',
              ),

              const SizedBox(height: 20),

              // 4. Banner Apresiasi
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2E2412) : const Color(0xFFFEF9C3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? const Color(0xFF5C451E) : const Color(0xFFFDE047),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Terima Kasih! ✨',
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFFFDE047) : const Color(0xFF854D0E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Dukungan Anda membantu kami terus mengembangkan fitur kesehatan yang lebih bermanfaat untuk masyarakat Indonesia.',
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              color: isDark ? const Color(0xFFFACC15) : const Color(0xFFA16207),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Image.asset(
                      'assets/illustration_woman_original.png',
                      width: 54,
                      height: 54,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.favorite_rounded,
                        color: Color(0xFFEAB308),
                        size: 36,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactRow(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: isDark ? 0.2 : 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem({
    required bool isDark,
    required String question,
    required String answer,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFEAEFEA),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: ThemeData().copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            iconColor: const Color(0xFF36785A),
            collapsedIconColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Text(
            question,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 14),
              child: Text(
                answer,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
