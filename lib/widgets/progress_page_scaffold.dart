import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable Scaffold for screens in the Progress feature.
/// Provides a sticky green header and a rounded curved sheet body (radius 28)
/// matching the design language demonstrated in clinical_info_screen.
class ProgressPageScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final VoidCallback? onBack;
  final Color? sheetColor;
  final EdgeInsetsGeometry? contentPadding;

  const ProgressPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.onBack,
    this.sheetColor,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerColor = isDark ? const Color(0xFF1E293B) : const Color(0xFF489874);
    final bodyBgColor = isDark
        ? const Color(0xFF0F172A)
        : (sheetColor ?? const Color(0xFFF3F6F8));

    return Scaffold(
      backgroundColor: headerColor,
      appBar: AppBar(
        backgroundColor: headerColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: onBack ?? () => Navigator.of(context).pop(),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: actions,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: bodyBgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: contentPadding != null
              ? Padding(
                  padding: contentPadding!,
                  child: body,
                )
              : body,
        ),
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
