import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedIllustration extends StatefulWidget {
  final double maxHeight;
  final bool isCompact;

  const AnimatedIllustration({
    super.key,
    this.maxHeight = 260,
    this.isCompact = false,
  });

  @override
  State<AnimatedIllustration> createState() => _AnimatedIllustrationState();
}

class _AnimatedIllustrationState extends State<AnimatedIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatingAnimation;
  late Animation<double> _breathingAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _floatingAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
      ),
    );

    _breathingAnimation = Tween<double>(begin: 0.985, end: 1.015).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = widget.isCompact ? widget.maxHeight * 0.55 : widget.maxHeight;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatingAnimation.value),
          child: Transform.scale(
            scale: _breathingAnimation.value,
            child: SizedBox(
              height: effectiveHeight,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Woman holding phone with health icons (clean, no container box behind)
                  Image.asset(
                    'assets/illustration_woman_original.png',
                    height: effectiveHeight,
                    fit: BoxFit.contain,
                  ),

                  // Floating Twinkling Sparkle 1 (Top Left)
                  Positioned(
                    top: 16 + math.sin(_controller.value * 2 * math.pi) * 3,
                    left: 28,
                    child: Opacity(
                      opacity: (0.5 + 0.5 * math.cos(_controller.value * 2 * math.pi)).clamp(0.2, 1.0),
                      child: const _SparkleIcon(size: 14, color: Color(0xFF4F9B77)),
                    ),
                  ),

                  // Floating Twinkling Sparkle 2 (Top Right)
                  Positioned(
                    top: 24 - math.sin(_controller.value * 2 * math.pi) * 4,
                    right: 32,
                    child: Opacity(
                      opacity: (0.4 + 0.6 * math.sin(_controller.value * 2 * math.pi)).clamp(0.2, 1.0),
                      child: const _SparkleIcon(size: 16, color: Color(0xFF4F9B77)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SparkleIcon extends StatelessWidget {
  final double size;
  final Color color;

  const _SparkleIcon({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SparklePainter(color: color),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final Color color;

  _SparklePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final halfW = size.width / 2;
    final halfH = size.height / 2;

    path.moveTo(halfW, 0);
    path.quadraticBezierTo(halfW, halfH, size.width, halfH);
    path.quadraticBezierTo(halfW, halfH, halfW, size.height);
    path.quadraticBezierTo(halfW, halfH, 0, halfH);
    path.quadraticBezierTo(halfW, halfH, halfW, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
