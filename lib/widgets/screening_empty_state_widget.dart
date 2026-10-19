import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../screens/skrining/skrining_landing_screen.dart';

/// Reusable Empty State Widget saat pengguna belum memiliki riwayat hasil skrining kesehatan.
///
/// Tampilan identik dengan status belum skrining di Rekomendasi Aktivitas Fisik,
/// dengan parameter ikon, teks penjelasan, dan callback yang fleksibel.
class ScreeningEmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String buttonText;
  final UserModel? user;
  final VoidCallback? onScreeningReturned;

  const ScreeningEmptyStateWidget({
    super.key,
    this.icon = Icons.restaurant_menu_rounded,
    this.title = 'Belum Ada Hasil Skrining',
    this.description =
        'Rekomendasi makanan dan minuman dipersonalisasi berdasarkan hasil skrining kesehatan dan kategori IMT Anda.\nSilakan lakukan skrining terlebih dahulu.',
    this.buttonText = 'Mulai Skrining Sekarang',
    this.user,
    this.onScreeningReturned,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final primaryColor = isDark ? const Color(0xFF58AF86) : const Color(0xFF36785A);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SkriningLandingScreen(user: user),
                ),
              ).then((_) {
                onScreeningReturned?.call();
              });
            },
            icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
            label: Text(
              buttonText,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
