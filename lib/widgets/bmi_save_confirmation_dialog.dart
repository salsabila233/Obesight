import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BmiSaveConfirmationDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const BmiSaveConfirmationDialog({
    super.key,
    required this.onConfirm,
    this.onCancel,
  });

  static Future<bool?> show(BuildContext context, {required VoidCallback onConfirm, VoidCallback? onCancel}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => BmiSaveConfirmationDialog(
        onConfirm: () {
          Navigator.of(ctx).pop(true);
          onConfirm();
        },
        onCancel: () {
          Navigator.of(ctx).pop(false);
          if (onCancel != null) onCancel();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final dialogBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textTitle = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSubtitle = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final iconBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFE8F5EE);
    final cancelBtnBorder = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    final cancelBtnText = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
        decoration: BoxDecoration(
          color: dialogBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: dialogBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Green confirmation icon badge
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF489874).withValues(alpha: 0.18),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.check_circle_outline_rounded,
                  color: Color(0xFF489874),
                  size: 34,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Confirmation title
            Text(
              'Apakah Anda ingin menyimpan perubahan?',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textTitle,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 8),

            // Short explanation text
            Text(
              'Data tinggi dan berat badan Anda akan diperbarui untuk menghitung status IMT serta profil kesehatan terbaru.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: textSubtitle,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons row
            Row(
              children: [
                // Button Batal (Secondary/Outline)
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cancelBtnText,
                      side: BorderSide(color: cancelBtnBorder, width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      if (onCancel != null) {
                        onCancel!();
                      } else {
                        Navigator.of(context).pop(false);
                      }
                    },
                    child: Text(
                      'Batal',
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: cancelBtnText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Button Simpan (Primary Green OBESIGHT)
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF489874),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: onConfirm,
                    child: Text(
                      'Simpan',
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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
  }
}
