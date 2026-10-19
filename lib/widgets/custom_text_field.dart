import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final FocusNode? focusNode;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onChanged,
    this.focusNode,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? const Color(0xFF94A3B8) : AppColors.inputLabel;
    final textColor = isDark ? const Color(0xFFF1F5F9) : AppColors.inputText;
    final hintColor = isDark ? const Color(0xFF64748B) : AppColors.inputPlaceholder;
    final fillColor = isDark ? const Color(0xFF1E293B) : AppColors.inputBackground;
    final borderColor = isDark ? const Color(0xFF334155) : AppColors.inputBorder;
    final eyeIconColor = isDark ? const Color(0xFF94A3B8) : AppColors.eyeIcon;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label Text
        Text(
          widget.label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 8),

        // Text Form Field
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          obscureText: widget.isPassword ? _obscureText : false,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          validator: widget.validator,
          onChanged: widget.onChanged,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.normal,
              color: hintColor,
            ),
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: borderColor,
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.inputBorderFocused,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 1.0,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 1.5,
              ),
            ),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: _obscureText
                        ? _buildClosedEyeIcon(eyeIconColor)
                        : Icon(
                            Icons.visibility_outlined,
                            size: 22,
                            color: eyeIconColor,
                          ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                    splashRadius: 20,
                    tooltip: _obscureText ? 'Lihat kata sandi' : 'Sembunyikan kata sandi',
                  )
                : null,
          ),
        ),
      ],
    );
  }

  /// Custom eye icon with lashes matching the closed eye design in the screenshot
  Widget _buildClosedEyeIcon(Color iconColor) {
    return CustomPaint(
      size: const Size(24, 24),
      painter: _ClosedEyeWithLashesPainter(color: iconColor),
    );
  }
}

/// Custom painter for the exact closed eye with lashes seen in the Figma screenshots
class _ClosedEyeWithLashesPainter extends CustomPainter {
  final Color color;

  _ClosedEyeWithLashesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);

    // Main closed eye arch (curving downward slightly)
    final path = Path();
    path.moveTo(center.dx - 8, center.dy);
    path.quadraticBezierTo(center.dx, center.dy + 4.5, center.dx + 8, center.dy);
    canvas.drawPath(path, paint);

    // Three downward eyelashes
    // Left lash
    canvas.drawLine(
      Offset(center.dx - 5, center.dy + 2.5),
      Offset(center.dx - 7, center.dy + 6.5),
      paint,
    );
    // Center lash
    canvas.drawLine(
      Offset(center.dx, center.dy + 4.5),
      Offset(center.dx, center.dy + 8.5),
      paint,
    );
    // Right lash
    canvas.drawLine(
      Offset(center.dx + 5, center.dy + 2.5),
      Offset(center.dx + 7, center.dy + 6.5),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
