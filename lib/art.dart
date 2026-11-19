import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'common.dart';

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


// ------------------------------------------------------------------
//  Themed background: night sky, moon and roses (dark) / rose dawn (light)
// ------------------------------------------------------------------
class ThemedBackdrop extends StatelessWidget {
  final Widget child;
  final bool plain; // kept for compatibility, effects are shown everywhere
  const ThemedBackdrop({super.key, required this.child, this.plain = false});

  @override
  Widget build(BuildContext context) {
    final pal = Pal.of(context);
    return LayoutBuilder(builder: (context, box) {
    final landscape = box.maxWidth > box.maxHeight * 1.05;
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: pal.bgGradient,
              ),
            ),
          ),
        ),
        // grungy brown texture (dark mode)
        if (pal.dark)
          Positioned.fill(
            child: Opacity(
              opacity: 0.5,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/grunge.jpg'),
                    repeat: ImageRepeat.repeat,
                    fit: BoxFit.none,
                  ),
                ),
              ),
            ),
          ),
        // pink moon, stars and roses sky, fading out downwards
        Positioned.fill(
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (r) => LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: landscape
                  ? const [Colors.white, Colors.white]
                  : const [Colors.white, Colors.white, Color(0x55FFFFFF)],
              stops: landscape ? null : const [0.0, 0.55, 1.0],
            ).createShader(r),
            child: Opacity(
              opacity: pal.dark ? 0.95 : 0.65,
              child: Image.asset(
                landscape
                    ? 'assets/images/night_wide.jpg'
                    : 'assets/images/night_roses.jpg',
                fit: BoxFit.cover,
                alignment: landscape ? const Alignment(0, -0.3) : Alignment.topCenter,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        // light mode: a soft rosy veil keeps the text readable, picture stays
        if (!pal.dark)
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x33FFF1F5), Color(0x00FFFFFF), Color(0x66FFF1F5)],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
        // glowing halo around the moon corner
        Positioned(
          top: -60,
          right: -60,
          child: IgnorePointer(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    pal.dark ? const Color(0x44FFE9C7) : const Color(0x77FFC9D9),
                    const Color(0x00FFFFFF),
                  ],
                ),
              ),
            ),
          ),
        ),
        const Positioned.fill(child: SparkleLayer()),
        Positioned.fill(child: child),
        // rose garden border along the bottom edge
        if (!landscape)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 56,
          child: IgnorePointer(
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (r) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00FFFFFF), Colors.white],
              ).createShader(r),
              child: Opacity(
                opacity: pal.dark ? 1.0 : 0.85,
                child: Image.asset(
                  'assets/images/rose_border.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
    });
  }
}

// ------------------------------------------------------------------
//  Cute bear sticker (cropped from the theme pictures)
// ------------------------------------------------------------------
class BearAvatar extends StatelessWidget {
  final double size;
  final String asset;
  final bool round;
  const BearAvatar({
    super.key,
    this.size = 84,
    this.asset = 'assets/images/bear_top.jpg',
    this.round = true,
  });

  @override
  Widget build(BuildContext context) {
    final img = Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Text('🧸', style: TextStyle(fontSize: size * 0.6)),
    );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: round ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: round ? null : BorderRadius.circular(size * 0.22),
        border: Border.all(color: const Color(0xFFE9B872), width: 2),
        boxShadow: const [BoxShadow(color: Color(0x55E9B872), blurRadius: 14)],
      ),
      child: round
          ? ClipOval(child: img)
          : ClipRRect(borderRadius: BorderRadius.circular(size * 0.2), child: img),
    );
  }
}

// ------------------------------------------------------------------
//  Twinkling stars, glitter, drifting petals, a shooting star and a
//  crescent moon. Works in both light and dark mode.
// ------------------------------------------------------------------
class SparkleLayer extends StatefulWidget {
  const SparkleLayer({super.key});

  @override
  State<SparkleLayer> createState() => _SparkleLayerState();
}

class _SparkleLayerState extends State<SparkleLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 10))
        ..repeat();

  // x, y, size, phase
  late final List<List<double>> _stars = () {
    final r = math.Random(11);
    return List.generate(
      46,
      (_) => [r.nextDouble(), r.nextDouble() * 0.9, 3.5 + r.nextDouble() * 6, r.nextDouble()],
    );
  }();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
            size: Size.infinite,
            painter: _SparklePainter(_c.value, _stars, Pal.of(context).dark),
          ),
        ),
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final double t;
  final List<List<double>> stars;
  final bool dark;
  _SparklePainter(this.t, this.stars, this.dark);

  Path _star(Offset p, double r, double inner) => Path()
    ..moveTo(p.dx, p.dy - r)
    ..lineTo(p.dx + r * inner, p.dy - r * inner)
    ..lineTo(p.dx + r, p.dy)
    ..lineTo(p.dx + r * inner, p.dy + r * inner)
    ..lineTo(p.dx, p.dy + r)
    ..lineTo(p.dx - r * inner, p.dy + r * inner)
    ..lineTo(p.dx - r, p.dy)
    ..lineTo(p.dx - r * inner, p.dy - r * inner)
    ..close();

  @override
  void paint(Canvas c, Size s) {
    final gold = dark ? const Color(0xFFFFE9C7) : const Color(0xFFE9A04A);
    final rose = dark ? const Color(0xFFFFB3C7) : const Color(0xFFE0557D);

    // soft floating glow dots (bokeh)
    for (var i = 0; i < 9; i++) {
      final ph = (t * 0.35 + i / 9) % 1.0;
      final x = ((i * 0.23 + 0.07) % 1.0) * s.width + math.sin(ph * 6.28 + i) * 14;
      final y = s.height - ph * (s.height + 60) + 30;
      final rad = 10.0 + (i % 4) * 7;
      c.drawCircle(
        Offset(x, y),
        rad,
        Paint()
          ..color = (i.isEven ? gold : rose).withValues(alpha: dark ? 0.16 : 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    // crescent moon with a glow
    final mc = Offset(s.width - 38, 44);
    c.drawCircle(
      mc,
      26,
      Paint()
        ..color = gold.withValues(alpha: dark ? 0.28 : 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    final moon = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: mc, radius: 15)),
      Path()..addOval(Rect.fromCircle(center: mc.translate(7, -4), radius: 13.5)),
    );
    c.drawPath(moon, Paint()..color = gold.withValues(alpha: 0.95));

    // twinkling stars
    for (var i = 0; i < stars.length; i++) {
      final st = stars[i];
      final a = math.pow(math.sin((t * 1.0 + st[3]) * math.pi * 2), 2).toDouble();
      final p = Offset(st[0] * s.width, st[1] * s.height);
      final r = st[2] * (0.45 + 0.55 * a);
      final col = (i % 3 == 0 ? rose : gold).withValues(alpha: 0.25 + 0.75 * a);
      if (st[2] > 7) {
        c.drawCircle(
          p,
          r * 1.6,
          Paint()
            ..color = col.withValues(alpha: 0.25 * a)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
      }
      c.drawPath(_star(p, r, st[2] > 7 ? 0.18 : 0.3), Paint()..color = col);
    }

    // drifting rose petals
    for (var i = 0; i < 12; i++) {
      final ph = (t * (0.6 + 0.07 * i) + i / 12) % 1.0;
      final x = ((i * 0.137 + 0.05) % 1.0) * s.width + math.sin(ph * 6.28 + i) * 22;
      final y = ph * (s.height + 40) - 20;
      c.save();
      c.translate(x, y);
      c.rotate(ph * 6.28 * 2 + i);
      final petal = (i.isEven
              ? (dark ? const Color(0xFFF08296) : const Color(0xFFE05A7D))
              : (dark ? const Color(0xFFFFD0DA) : const Color(0xFFF3A6BA)))
          .withValues(alpha: 0.78);
      // soft shine around the petal, the petal itself and a bright highlight
      c.drawOval(
        const Rect.fromLTWH(-9, -6, 18, 12),
        Paint()
          ..color = petal.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      c.drawOval(const Rect.fromLTWH(-6, -3.5, 12, 7), Paint()..color = petal);
      c.drawOval(
        const Rect.fromLTWH(-3, -2.4, 4.5, 2.2),
        Paint()..color = Colors.white.withValues(alpha: 0.65),
      );
      c.restore();
    }

    // shooting star
    if (t > 0.30 && t < 0.38) {
      final k = (t - 0.30) / 0.08;
      final head = Offset(s.width * (0.05 + 0.6 * k), 40 + s.height * 0.22 * k);
      final tail = head.translate(-70, -30);
      c.drawLine(
        tail,
        head,
        Paint()
          ..shader = LinearGradient(
            colors: [gold.withValues(alpha: 0), gold.withValues(alpha: 0.95)],
          ).createShader(Rect.fromPoints(tail, head))
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round,
      );
      c.drawCircle(head, 3, Paint()..color = Colors.white);
    }

    // quick lightning flash (a bright bolt and a soft glow over the sky)
    final flash = (t > 0.80 && t < 0.835) || (t > 0.87 && t < 0.895);
    if (flash) {
      c.drawRect(
        Offset.zero & s,
        Paint()..color = Color.fromRGBO(255, 233, 199, dark ? 0.10 : 0.12),
      );
      final o = Offset(s.width * 0.16, 56);
      const k = 1.9;
      final bolt = Path()
        ..moveTo(o.dx + 8 * k, o.dy)
        ..lineTo(o.dx - 4 * k, o.dy + 18 * k)
        ..lineTo(o.dx + 3 * k, o.dy + 18 * k)
        ..lineTo(o.dx - 5 * k, o.dy + 36 * k)
        ..lineTo(o.dx + 12 * k, o.dy + 14 * k)
        ..lineTo(o.dx + 5 * k, o.dy + 14 * k)
        ..close();
      c.drawPath(
        bolt,
        Paint()
          ..color = const Color(0xAAFFD86B)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
      );
      c.drawPath(bolt, Paint()..color = const Color(0xEEFFF2B8));
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter old) => old.t != t;
}
