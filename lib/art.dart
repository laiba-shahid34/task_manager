import 'dart:math' as math;

import 'package:flutter/material.dart';

// ------------------------------------------------------------------
//  Gently floating child (butterflies, sparkles ...)
// ------------------------------------------------------------------
class Floating extends StatefulWidget {
  final Widget child;
  final double distance;
  final Duration duration;
  const Floating({
    super.key,
    required this.child,
    this.distance = 7,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<Floating> createState() => _FloatingState();
}

class _FloatingState extends State<Floating>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration)
        ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -widget.distance * Curves.easeInOut.transform(_c.value)),
        child: child,
      ),
    );
  }
}

// ------------------------------------------------------------------
//  The purple cat
// ------------------------------------------------------------------
class CatWidget extends StatefulWidget {
  final double size;
  final bool awake;
  const CatWidget({super.key, this.size = 120, this.awake = false});

  @override
  State<CatWidget> createState() => _CatWidgetState();
}

class _CatWidgetState extends State<CatWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Transform.translate(
        offset: Offset(0, math.sin(_c.value * 2 * math.pi) * 2),
        child: CustomPaint(
          size: Size.square(widget.size),
          painter: CatPainter(_c.value, awake: widget.awake),
        ),
      ),
    );
  }
}

class CatPainter extends CustomPainter {
  final double t;
  final bool awake;
  CatPainter(this.t, {this.awake = false});

  @override
  void paint(Canvas c, Size size) {
    final k = math.min(size.width, size.height) / 200.0;
    c.save();
    c.translate((size.width - 200 * k) / 2, (size.height - 200 * k) / 2);
    c.scale(k);

    final wag = math.sin(t * 2 * math.pi) * 12;
    const furColor = Color(0xFFB190F6);
    const deepColor = Color(0xFF9468E6);
    final fur = Paint()..color = furColor;
    final deep = Paint()..color = deepColor;
    final belly = Paint()..color = const Color(0xFFF0E6FF);
    final pink = Paint()..color = const Color(0xFFFFA8CB);
    final ink = Paint()
      ..color = const Color(0xFF3A2766)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.6
      ..strokeCap = StrokeCap.round;
    final thin = Paint()
      ..color = const Color(0xFF3A2766)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    // tail
    final tail = Path()
      ..moveTo(150, 170)
      ..cubicTo(200, 175, 205 + wag, 120, 178 + wag, 96);
    c.drawPath(
      tail,
      Paint()
        ..color = furColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round,
    );
    c.drawCircle(Offset(178 + wag, 96), 9, deep);

    // body, belly, paws
    c.drawOval(Rect.fromCenter(center: const Offset(100, 152), width: 118, height: 94), fur);
    c.drawOval(Rect.fromCenter(center: const Offset(100, 160), width: 66, height: 62), belly);
    c.drawOval(Rect.fromCenter(center: const Offset(76, 191), width: 34, height: 20), fur);
    c.drawOval(Rect.fromCenter(center: const Offset(124, 191), width: 34, height: 20), fur);

    // ears
    c.drawPath(
        Path()
          ..moveTo(48, 70)
          ..lineTo(54, 18)
          ..lineTo(92, 46)
          ..close(),
        fur);
    c.drawPath(
        Path()
          ..moveTo(152, 70)
          ..lineTo(146, 18)
          ..lineTo(108, 46)
          ..close(),
        fur);
    c.drawPath(
        Path()
          ..moveTo(58, 60)
          ..lineTo(61, 32)
          ..lineTo(82, 48)
          ..close(),
        pink);
    c.drawPath(
        Path()
          ..moveTo(142, 60)
          ..lineTo(139, 32)
          ..lineTo(118, 48)
          ..close(),
        pink);

    // head
    c.drawOval(Rect.fromCenter(center: const Offset(100, 88), width: 118, height: 98), fur);

    // forehead stripes
    final stripe = Paint()
      ..color = deepColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (final dx in const [-12.0, 0.0, 12.0]) {
      c.drawLine(Offset(100 + dx, 42), Offset(100 + dx * 0.8, 54), stripe);
    }

    // cheeks
    final blush = Paint()..color = const Color(0x77FF8FB8);
    c.drawCircle(const Offset(64, 100), 9, blush);
    c.drawCircle(const Offset(136, 100), 9, blush);

    // eyes
    if (awake) {
      final eye = Paint()..color = const Color(0xFF3A2766);
      final shine = Paint()..color = Colors.white;
      for (final x in const [78.0, 122.0]) {
        c.drawOval(Rect.fromCenter(center: Offset(x, 90), width: 15, height: 19), eye);
        c.drawCircle(Offset(x + 2.5, 85), 3.2, shine);
      }
    } else {
      c.drawArc(Rect.fromCenter(center: const Offset(78, 92), width: 22, height: 16), math.pi, math.pi, false, ink);
      c.drawArc(Rect.fromCenter(center: const Offset(122, 92), width: 22, height: 16), math.pi, math.pi, false, ink);
    }

    // nose + smile
    c.drawPath(
        Path()
          ..moveTo(95, 101)
          ..lineTo(105, 101)
          ..lineTo(100, 107)
          ..close(),
        Paint()..color = const Color(0xFFFF7FB0));
    c.drawArc(Rect.fromLTWH(90, 105, 10, 8), 0, math.pi, false, thin);
    c.drawArc(Rect.fromLTWH(100, 105, 10, 8), 0, math.pi, false, thin);

    // whiskers
    final whisk = Paint()
      ..color = const Color(0x883A2766)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    c.drawLine(const Offset(60, 100), const Offset(34, 94), whisk);
    c.drawLine(const Offset(60, 106), const Offset(34, 109), whisk);
    c.drawLine(const Offset(140, 100), const Offset(166, 94), whisk);
    c.drawLine(const Offset(140, 106), const Offset(166, 109), whisk);

    // bow
    final bow = Paint()..color = const Color(0xFFFFC2DE);
    c.drawPath(
        Path()
          ..moveTo(138, 36)
          ..lineTo(120, 25)
          ..lineTo(120, 47)
          ..close(),
        bow);
    c.drawPath(
        Path()
          ..moveTo(138, 36)
          ..lineTo(156, 25)
          ..lineTo(156, 47)
          ..close(),
        bow);
    c.drawCircle(const Offset(138, 36), 5.5, Paint()..color = const Color(0xFFFF7FB0));

    c.restore();
  }

  @override
  bool shouldRepaint(covariant CatPainter old) => old.t != t || old.awake != awake;
}

// ------------------------------------------------------------------
//  Night sky with moon, twinkling stars and a castle (splash screen)
// ------------------------------------------------------------------
class NightSky extends StatefulWidget {
  const NightSky({super.key});

  @override
  State<NightSky> createState() => _NightSkyState();
}

class _Star {
  final double x, y, r, phase;
  const _Star(this.x, this.y, this.r, this.phase);
}

class _NightSkyState extends State<NightSky>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))
        ..repeat();
  late final List<_Star> _stars = () {
    final rnd = math.Random(3);
    return List<_Star>.generate(
      80,
      (_) => _Star(rnd.nextDouble(), rnd.nextDouble() * 0.7,
          0.6 + rnd.nextDouble() * 1.8, rnd.nextDouble()),
    );
  }();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => SizedBox.expand(
        child: CustomPaint(painter: _SkyPainter(_c.value, _stars)),
      ),
    );
  }
}

class _SkyPainter extends CustomPainter {
  final double t;
  final List<_Star> stars;
  _SkyPainter(this.t, this.stars);

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final h = s.height;

    // sky
    c.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF140B33),
            Color(0xFF3B1F7A),
            Color(0xFF8B49C9),
            Color(0xFFE59ADB),
          ],
          stops: [0, 0.45, 0.78, 1],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // stars
    for (final st in stars) {
      final a = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(2 * math.pi * (t + st.phase)));
      c.drawCircle(
        Offset(st.x * w, st.y * h),
        st.r,
        Paint()..color = Colors.white.withValues(alpha: a),
      );
    }

    // moon
    final mc = Offset(w * 0.28, h * 0.17);
    final r = w * 0.11;
    c.drawCircle(
      mc,
      r * 2.2,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x66FFE9A8), Color(0x00FFE9A8)],
        ).createShader(Rect.fromCircle(center: mc, radius: r * 2.2)),
    );
    final moon = Path()..addOval(Rect.fromCircle(center: mc, radius: r));
    final cut = Path()
      ..addOval(Rect.fromCircle(center: mc.translate(r * 0.5, -r * 0.2), radius: r * 0.88));
    c.drawPath(
      Path.combine(PathOperation.difference, moon, cut),
      Paint()..color = const Color(0xFFFFE9A8),
    );

    // soft clouds
    final cloud = Paint()..color = const Color(0x33FFFFFF);
    for (final o in const [
      Offset(0.15, 0.62),
      Offset(0.45, 0.58),
      Offset(0.8, 0.64),
      Offset(0.62, 0.7),
    ]) {
      final cx = o.dx * w;
      final cy = o.dy * h;
      c.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: w * 0.42, height: h * 0.05), cloud);
      c.drawOval(Rect.fromCenter(center: Offset(cx + w * 0.08, cy - h * 0.012), width: w * 0.26, height: h * 0.05), cloud);
    }

    // castle
    final y0 = h * 0.78;
    final sil = Paint()..color = const Color(0xFF2A1759);
    final win = Paint()..color = const Color(0xFFFFE08A);
    void tower(double cx, double tw, double th) {
      c.drawRect(Rect.fromLTWH(cx - tw / 2, y0 - th, tw, th), sil);
      c.drawPath(
        Path()
          ..moveTo(cx - tw / 2 - 3, y0 - th)
          ..lineTo(cx, y0 - th - tw * 1.4)
          ..lineTo(cx + tw / 2 + 3, y0 - th)
          ..close(),
        sil,
      );
      c.drawRect(Rect.fromLTWH(cx - 2, y0 - th * 0.62, 4, 8), win);
    }

    final u = w / 400;
    tower(w * 0.72, 26 * u, 120 * u);
    tower(w * 0.62, 18 * u, 80 * u);
    tower(w * 0.82, 18 * u, 70 * u);
    tower(w * 0.68, 14 * u, 52 * u);
    tower(w * 0.77, 14 * u, 48 * u);
    c.drawRect(Rect.fromLTWH(w * 0.6, y0 - 28 * u, w * 0.24, 28 * u), sil);

    // foreground hill
    final hill = Path()
      ..moveTo(0, h * 0.84)
      ..quadraticBezierTo(w * 0.3, h * 0.77, w * 0.6, h * 0.83)
      ..quadraticBezierTo(w * 0.85, h * 0.87, w, h * 0.82)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    c.drawPath(
      hill,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3A1F73), Color(0xFF1B0F3F)],
        ).createShader(Rect.fromLTWH(0, h * 0.75, w, h * 0.25)),
    );
  }

  @override
  bool shouldRepaint(covariant _SkyPainter old) => old.t != t;
}
