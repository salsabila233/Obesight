import 'package:flutter/material.dart';

/// Widget animasi halus untuk efek melayang (antigravity) naik-turun
/// menggunakan [AnimationController] dan [Curves.easeInOutSine].
class AntigravityFloating extends StatefulWidget {
  final Widget child;
  final double distance;
  final Duration duration;

  const AntigravityFloating({
    super.key,
    required this.child,
    this.distance = 7.0,
    this.duration = const Duration(milliseconds: 2400),
  });

  @override
  State<AntigravityFloating> createState() => _AntigravityFloatingState();
}

class _AntigravityFloatingState extends State<AntigravityFloating>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: -widget.distance,
      end: widget.distance,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
