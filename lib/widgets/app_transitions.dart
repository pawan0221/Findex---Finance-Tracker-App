import 'package:flutter/material.dart';

// Smooth slide transition
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final SlideDirection direction;

  SlidePageRoute({required this.page, this.direction = SlideDirection.right})
      : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (_, animation, secondaryAnimation, child) {
            final begin = direction == SlideDirection.right
                ? const Offset(1.0, 0.0)
                : direction == SlideDirection.up
                    ? const Offset(0.0, 1.0)
                    : const Offset(-1.0, 0.0);
            final tween = Tween(begin: begin, end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOutCubic));
            final offsetAnimation = animation.drive(tween);
            return SlideTransition(
              position: offsetAnimation,
              child: FadeTransition(opacity: animation, child: child),
            );
          },
        );
}

// Fade + scale transition
class FadeScaleRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadeScaleRoute({required this.page})
      : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: const Duration(milliseconds: 350),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1.0)
                    .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              ),
            );
          },
        );
}

enum SlideDirection { left, right, up }

// Animated counter widget
class AnimatedCounter extends StatefulWidget {
  final double value;
  final String prefix;
  final TextStyle? style;
  const AnimatedCounter({super.key, required this.value, this.prefix = '₹', this.style});

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  double _oldValue = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _anim = Tween<double>(begin: 0, end: widget.value)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _oldValue = old.value;
      _anim = Tween<double>(begin: _oldValue, end: widget.value)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => Text(
      '${widget.prefix}${_fmt(_anim.value)}',
      style: widget.style,
    ),
  );

  static String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000)   return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// Bouncy FAB
class BouncyFab extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final Color color;
  const BouncyFab({super.key, required this.onPressed, required this.icon, required this.color});

  @override
  State<BouncyFab> createState() => _BouncyFabState();
}

class _BouncyFabState extends State<BouncyFab> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween<double>(begin: 1.0, end: 0.85)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => _ctrl.forward(),
    onTapUp: (_) { _ctrl.reverse(); widget.onPressed(); },
    onTapCancel: () => _ctrl.reverse(),
    child: ScaleTransition(
      scale: _scale,
      child: Container(
        width: 60, height: 60,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: widget.color.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Icon(widget.icon, color: Colors.white, size: 28),
      ),
    ),
  );
}

// Shimmer card
class ShimmerCard extends StatefulWidget {
  final Widget child;
  const ShimmerCard({super.key, required this.child});

  @override
  State<ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<ShimmerCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _anim = Tween<double>(begin: -2, end: 2).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, child) => ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment(_anim.value - 1, 0),
        end: Alignment(_anim.value, 0),
        colors: [Colors.transparent, Colors.white.withOpacity(0.05), Colors.transparent],
      ).createShader(bounds),
      blendMode: BlendMode.srcATop,
      child: child,
    ),
    child: widget.child,
  );
}