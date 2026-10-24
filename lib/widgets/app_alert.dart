import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AlertType {
  success,
  error,
  warning,
  info,
}

/// Komponen bersama untuk menampilkan notifikasi/alert di bagian atas layar (top banner)
/// dengan latar belakang putih (atau slate di dark mode), teks jelas, dan aksen warna sesuai tipe.
class AppAlert {
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    show(context, message: message, type: AlertType.success, duration: duration);
  }

  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    show(context, message: message, type: AlertType.error, duration: duration);
  }

  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    show(context, message: message, type: AlertType.warning, duration: duration);
  }

  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    show(context, message: message, type: AlertType.info, duration: duration);
  }

  static void show(
    BuildContext context, {
    required String message,
    AlertType type = AlertType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final mediaQuery = MediaQuery.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = mediaQuery.size.height;
    final topPadding = mediaQuery.padding.top;

    // Posisi tepat di bagian atas layar di bawah status bar
    final double safeTop = topPadding > 0 ? topPadding + 6.0 : 8.0;
    const double bannerHeight = 44.0;
    final double bottomMargin = (screenHeight - safeTop - bannerHeight).clamp(10.0, screenHeight - 30.0);

    Color accentColor;
    IconData icon;
    switch (type) {
      case AlertType.success:
        accentColor = isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D6A4F);
        icon = Icons.check_circle_rounded;
        break;
      case AlertType.error:
        accentColor = isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
        icon = Icons.error_rounded;
        break;
      case AlertType.warning:
        accentColor = isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
        icon = Icons.warning_amber_rounded;
        break;
      case AlertType.info:
        accentColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
        icon = Icons.info_rounded;
        break;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.zero,
        dismissDirection: DismissDirection.up,
        margin: EdgeInsets.only(
          bottom: bottomMargin,
          left: 16,
          right: 16,
        ),
        duration: duration,
        content: GestureDetector(
          onTap: () => messenger.hideCurrentSnackBar(),
          behavior: HitTestBehavior.opaque,
          child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
