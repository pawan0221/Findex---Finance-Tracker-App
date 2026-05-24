import 'dart:math';
import 'package:flutter/material.dart';

/// Drop-in animated Findex AI hexagon logo widget.
/// Usage:
///   FindexAILogo(size: 56)   ← for the FAB
///   FindexAILogo(size: 120)  ← for a splash / about screen
class FindexAILogo extends StatefulWidget {
  final double size;
  const FindexAILogo({super.key, this.size = 56});

  @override
  State<FindexAILogo> createState() => _FindexAILogoState();
}

class _FindexAILogoState extends State<FindexAILogo>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _blinkCtrl;
  late AnimationController _chartCtrl;
  late AnimationController _badgeCtrl;

  late Animation<double> _pulse1;
  late Animation<double> _pulse2;
  late Animation<double> _pulse3;
  late Animation<double> _blink;
  late Animation<double> _chart;
  late Animation<double> _badge;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    _chartCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..forward();

    _badgeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _pulse1 = Tween(begin: 0.15, end: 0.35).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _pulse2 = Tween(begin: 0.08, end: 0.22).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _pulse3 = Tween(begin: 0.04, end: 0.12).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _blink = TweenSequence([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 90),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 5),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 5),
    ]).animate(_blinkCtrl);

    _chart = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _chartCtrl, curve: Curves.easeOut));

    _badge = Tween(begin: 1.0, end: 1.08).animate(
        CurvedAnimation(parent: _badgeCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _blinkCtrl.dispose();
    _chartCtrl.dispose();
    _badgeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(
          [_pulseCtrl, _blinkCtrl, _chartCtrl, _badgeCtrl]),
      builder: (_, __) => CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _FindexAIPainter(
          pulse1: _pulse1.value,
          pulse2: _pulse2.value,
          pulse3: _pulse3.value,
          blink: _blink.value,
          chartProgress: _chart.value,
          badgeScale: _badge.value,
        ),
      ),
    );
  }
}

class _FindexAIPainter extends CustomPainter {
  final double pulse1, pulse2, pulse3, blink, chartProgress, badgeScale;

  static const _purple = Color(0xFF6C63FF);
  static const _cyan   = Color(0xFF00E5FF);
  static const _bg     = Color(0xFF1A1A2E);

  _FindexAIPainter({
    required this.pulse1,
    required this.pulse2,
    required this.pulse3,
    required this.blink,
    required this.chartProgress,
    required this.badgeScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2;

    // ── Hex path helper ──
    Path hexPath(double centerX, double centerY, double radius) {
      final path = Path();
      for (int i = 0; i < 6; i++) {
        final angle = (pi / 180) * (60 * i - 90);
        final x = centerX + radius * cos(angle);
        final y = centerY + radius * sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      return path;
    }

    // ── 1. Pulsing glow rings ──
    final glowPaint = Paint()..style = PaintingStyle.fill;
    for (final (radius, opacity) in [
      (r * 1.55, pulse3),
      (r * 1.38, pulse2),
      (r * 1.18, pulse1),
    ]) {
      glowPaint.color = _purple.withOpacity(opacity);
      canvas.drawCircle(Offset(cx, cy), radius, glowPaint);
    }

    // ── 2. Hex glow border ──
    final hexGlowPaint = Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = r * 0.08
      ..color       = _purple.withOpacity(0.5);
    canvas.drawPath(hexPath(cx, cy, r * 1.02), hexGlowPaint);

    // ── 3. Hex body ──
    final bgPaint = Paint()..color = _bg;
    canvas.drawPath(hexPath(cx, cy, r * 0.95), bgPaint);

    // ── 4. Hex inner border ──
    final borderPaint = Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = r * 0.035
      ..color       = _purple;
    canvas.drawPath(hexPath(cx, cy, r * 0.95), borderPaint);

    // ── 5. Chart line ──
    final chartPoints = [
      Offset(cx - r * 0.65, cy + r * 0.30),
      Offset(cx - r * 0.45, cy + r * 0.12),
      Offset(cx - r * 0.28, cy + r * 0.22),
      Offset(cx - r * 0.12, cy - r * 0.08),
      Offset(cx + r * 0.02, cy + r * 0.02),
      Offset(cx + r * 0.20, cy - r * 0.22),
      Offset(cx + r * 0.36, cy - r * 0.10),
      Offset(cx + r * 0.62, cy - r * 0.30),
    ];

    // Clip to hex
    canvas.save();
    canvas.clipPath(hexPath(cx, cy, r * 0.93));

    // Chart fill
    final fillPath = Path();
    fillPath.moveTo(chartPoints.first.dx, chartPoints.first.dy);
    for (final pt in chartPoints.skip(1)) {
      fillPath.lineTo(pt.dx, pt.dy);
    }
    fillPath.lineTo(chartPoints.last.dx, cy + r * 0.45);
    fillPath.lineTo(chartPoints.first.dx, cy + r * 0.45);
    fillPath.close();
    canvas.drawPath(
      fillPath,
      Paint()..color = _cyan.withOpacity(0.07),
    );

    // Animated chart stroke
    final totalPoints = chartPoints.length;
    final visibleCount = (totalPoints * chartProgress).clamp(1, totalPoints.toDouble()).toInt();
    if (visibleCount >= 2) {
      final chartPaint = Paint()
        ..color       = _cyan
        ..strokeWidth = r * 0.04
        ..strokeCap   = StrokeCap.round
        ..strokeJoin  = StrokeJoin.round
        ..style       = PaintingStyle.stroke;
      final chartPath = Path();
      chartPath.moveTo(chartPoints[0].dx, chartPoints[0].dy);
      for (int i = 1; i < visibleCount; i++) {
        chartPath.lineTo(chartPoints[i].dx, chartPoints[i].dy);
      }
      canvas.drawPath(chartPath, chartPaint);
    }
    canvas.restore();

    // ── 6. Adviser face ──
    final faceR = r * 0.38;
    final faceY = cy - r * 0.08;

    // face bg
    canvas.drawCircle(
      Offset(cx, faceY), faceR,
      Paint()..color = _purple.withOpacity(0.18),
    );
    canvas.drawCircle(
      Offset(cx, faceY), faceR,
      Paint()
        ..color       = _purple
        ..style       = PaintingStyle.stroke
        ..strokeWidth = r * 0.025,
    );

    // antenna
    canvas.drawLine(
      Offset(cx, faceY - faceR),
      Offset(cx, faceY - faceR - r * 0.14),
      Paint()
        ..color       = _purple
        ..strokeWidth = r * 0.03
        ..strokeCap   = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(cx, faceY - faceR - r * 0.18),
      r * 0.06,
      Paint()..color = _purple,
    );
    canvas.drawCircle(
      Offset(cx, faceY - faceR - r * 0.18),
      r * 0.035,
      Paint()..color = _cyan,
    );

    // eyes
    final eyePaint = Paint()..color = _cyan.withOpacity(blink);
    canvas.drawCircle(Offset(cx - r * 0.12, faceY - r * 0.04), r * 0.055, eyePaint);
    canvas.drawCircle(Offset(cx + r * 0.12, faceY - r * 0.04), r * 0.055, eyePaint);

    // smile
    final smilePath = Path();
    smilePath.moveTo(cx - r * 0.12, faceY + r * 0.10);
    smilePath.quadraticBezierTo(cx, faceY + r * 0.20, cx + r * 0.12, faceY + r * 0.10);
    canvas.drawPath(
      smilePath,
      Paint()
        ..color       = _cyan
        ..style       = PaintingStyle.stroke
        ..strokeWidth = r * 0.035
        ..strokeCap   = StrokeCap.round,
    );

    // ── 7. Rupee badge ──
    final badgeY = cy + r * 0.62;
    canvas.save();
    canvas.translate(cx, badgeY);
    canvas.scale(badgeScale, badgeScale);
    canvas.translate(-cx, -badgeY);

    canvas.drawCircle(Offset(cx, badgeY), r * 0.22, Paint()..color = _purple);
    final tp = TextPainter(
      text: TextSpan(
        text: '₹',
        style: TextStyle(
          color: Colors.white,
          fontSize: r * 0.28,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, badgeY - tp.height / 2));
    canvas.restore();

    // ── 8. Hex corner dots ──
    final dotPaint = Paint()..color = _purple;
    for (int i = 0; i < 6; i++) {
      final angle = (pi / 180) * (60 * i - 90);
      final dx = cx + r * 0.95 * cos(angle);
      final dy = cy + r * 0.95 * sin(angle);
      canvas.drawCircle(Offset(dx, dy), r * 0.05, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_FindexAIPainter old) => true;
}