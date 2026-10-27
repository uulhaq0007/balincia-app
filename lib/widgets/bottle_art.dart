// Flutter port of the web store's BottleArt.tsx: every product's bottle is
// painted from its two-colour palette in one of eight shapes, inside the same
// 400×500 viewBox, with the same gradients, glass highlights, caps and label.

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/product.dart';

class BottleArt extends StatelessWidget {
  const BottleArt({
    super.key,
    required this.dark,
    required this.light,
    this.shape = BottleShape.classic,
    this.name = '',
    this.bare = false,
    this.alignment = Alignment.center,
  });

  BottleArt.product(Product p, {super.key, this.bare = false, bool showName = true, this.alignment = Alignment.center})
    : dark = p.dark,
      light = p.light,
      shape = p.shape,
      name = showName ? p.name : '';

  final Color dark;
  final Color light;
  final BottleShape shape;

  /// Printed in italics on the label (truncated after 16 characters).
  final String name;

  /// Skip the tinted backdrop, for composing on a coloured surface.
  final bool bare;

  /// Where the 4:5 bottle box sits when the canvas has another aspect ratio.
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: name.isEmpty ? 'Perfume bottle' : '$name bottle',
      image: true,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: BottlePainter(dark: dark, light: light, shape: shape, name: name, bare: bare, alignment: alignment),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class BottlePainter extends CustomPainter {
  BottlePainter({
    required this.dark,
    required this.light,
    required this.shape,
    required this.name,
    required this.bare,
    this.alignment = Alignment.center,
  }) : super(repaint: PaintingBinding.instance.systemFonts);

  final Color dark;
  final Color light;
  final BottleShape shape;
  final String name;
  final bool bare;
  final Alignment alignment;

  static const _view = Size(400, 500);
  static const _white = Color(0xffffffff);
  static const _black = Color(0xff000000);

  static final TextStyle _brandStyle = GoogleFonts.manrope(fontWeight: FontWeight.w700);
  static final TextStyle _nameStyle = GoogleFonts.fraunces(fontStyle: FontStyle.italic, fontWeight: FontWeight.w400);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final s = math.min(size.width / _view.width, size.height / _view.height);
    final box = alignment.inscribe(_view * s, Offset.zero & size);

    if (!bare) _backdrop(canvas, size, box, s);

    canvas.save();
    canvas.translate(box.left, box.top);
    canvas.scale(s);
    switch (shape) {
      case BottleShape.round:
        _round(canvas);
      case BottleShape.tall:
        _tall(canvas);
      case BottleShape.attar:
        _attar(canvas);
      case BottleShape.box:
        _box(canvas);
      case BottleShape.diffuser:
        _diffuser(canvas);
      case BottleShape.candle:
        _candle(canvas);
      case BottleShape.mist:
        _mist(canvas);
      case BottleShape.classic:
        _classic(canvas);
    }
    canvas.restore();
  }

  // ── Backdrop: warm paper, palette wash, a hairline ring and a soft halo ──

  void _backdrop(Canvas canvas, Size size, Rect box, double s) {
    final full = Offset.zero & size;
    canvas.drawRect(full, Paint()..color = const Color(0xfff4eee5));
    canvas.drawRect(
      full,
      Paint()
        ..shader = ui.Gradient.linear(full.topCenter, full.bottomCenter, [
          light.withValues(alpha: 0.16),
          light.withValues(alpha: 0.5),
        ]),
    );
    final center = box.topLeft + const Offset(200, 270) * s;
    canvas.drawCircle(
      center,
      190 * s,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, s)
        ..color = dark.withValues(alpha: 0.08),
    );
    canvas.drawCircle(
      center,
      150 * s,
      Paint()
        ..shader = ui.Gradient.radial(center, 150 * s, [_white.withValues(alpha: 0.75), _white.withValues(alpha: 0)]),
    );
  }

  // ── Gradients (objectBoundingBox semantics, like the SVG defs) ──

  /// A linear gradient from the box's top-left to ([x2], [y2]) in box units.
  Shader _bbox(Rect r, double x2, double y2, List<Color> colors, List<double> stops) {
    final m = Float64List.fromList([
      r.width, 0, 0, 0, //
      0, r.height, 0, 0,
      0, 0, 1, 0,
      r.left, r.top, 0, 1,
    ]);
    return ui.Gradient.linear(Offset.zero, Offset(x2, y2), colors, stops, TileMode.clamp, m);
  }

  Shader _liquid(Rect r) => _bbox(r, 0, 1, [light.withValues(alpha: 0.95), light, dark], const [0, 0.55, 1]);

  Shader _glass(Rect r) => _bbox(
    r,
    1,
    0,
    [
      _white.withValues(alpha: 0.32),
      _white.withValues(alpha: 0.04),
      _black.withValues(alpha: 0.04),
      _black.withValues(alpha: 0.22),
    ],
    const [0, 0.18, 0.75, 1],
  );

  Shader _cap(Rect r) => _bbox(
    r,
    1,
    0,
    [dark, dark.withValues(alpha: 0.85), light.withValues(alpha: 0.9), dark, dark],
    const [0, 0.35, 0.5, 0.62, 1],
  );

  Shader _gold(Rect r) => _bbox(
    r,
    1,
    1,
    const [Color(0xff8a6332), Color(0xffecd09a), Color(0xffa87d45), Color(0xffd8b67c)],
    const [0, 0.45, 0.7, 1],
  );

  Shader _crystal(Rect r) => _bbox(
    r,
    1,
    1,
    [_white.withValues(alpha: 0.9), light.withValues(alpha: 0.6), dark.withValues(alpha: 0.7)],
    const [0, 0.5, 1],
  );

  Shader _boxFill(Rect r) => _bbox(r, 1, 1, [dark, dark.withValues(alpha: 0.8)], const [0, 1]);

  Shader _flame(Rect r) =>
      _bbox(r, 0, 1, const [Color(0xfffff3c4), Color(0xfff6a943), Color(0xffc8561c)], const [0, 0.6, 1]);

  // ── Drawing primitives ──

  static RRect _rr(double x, double y, double w, double h, double rx) =>
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(math.min(rx, math.min(w, h) / 2)));

  void _fill(Canvas c, RRect r, {Color? color, Shader Function(Rect)? shader, double opacity = 1}) {
    final p = Paint()..isAntiAlias = true;
    if (shader != null) {
      p.shader = shader(r.outerRect);
      if (opacity < 1) p.color = _black.withValues(alpha: opacity);
    } else {
      p.color = color!.withValues(alpha: color.a * opacity);
    }
    c.drawRRect(r, p);
  }

  void _stroke(Canvas c, RRect r, Color color, double opacity, [double width = 1]) {
    c.drawRRect(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = color.withValues(alpha: opacity),
    );
  }

  void _shadow(Canvas c, double cx, double cy, double rx, double ry) {
    c.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2),
      Paint()
        ..color = dark.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
  }

  /// Highlight strip / neck: a flat fill at an opacity.
  void _flat(Canvas c, double x, double y, double w, double h, double rx, Color color, double opacity) =>
      _fill(c, _rr(x, y, w, h, rx), color: color, opacity: opacity);

  Path _poly(List<double> pts) {
    final p = Path()..moveTo(pts[0], pts[1]);
    for (var i = 2; i < pts.length; i += 2) {
      p.lineTo(pts[i], pts[i + 1]);
    }
    return p..close();
  }

  // ── The cream label: BALINCIA, a rule and the scent name in italics ──

  void _label(Canvas c, double x, double y, double w, double h) {
    _fill(c, _rr(x, y, w, h, 3), color: const Color(0xfff7f2ea), opacity: 0.94);
    _stroke(c, _rr(x + 5, y + 5, w - 10, h - 10, 2), dark, 0.35, 0.8);

    _text(
      c,
      'BALINCIA',
      _brandStyle.copyWith(fontSize: math.max(6.5, w * 0.065), letterSpacing: math.max(2, w * 0.03), color: dark),
      x + w / 2,
      y + h * 0.36,
    );

    c.drawLine(
      Offset(x + w * 0.3, y + h * 0.48),
      Offset(x + w * 0.7, y + h * 0.48),
      Paint()
        ..strokeWidth = 0.7
        ..color = dark.withValues(alpha: 0.4),
    );

    final label = name.length > 16 ? '${name.substring(0, 15)}…' : name;
    if (label.isNotEmpty) {
      final size = math.max(8.0, math.min(14.0, (w * 1.5) / math.max(label.length, 6)));
      _text(
        c,
        label,
        _nameStyle.copyWith(fontSize: size, color: dark),
        x + w / 2,
        y + h * 0.72,
        maxWidth: w - 12,
      );
    }
  }

  /// Draws [text] centred on [cx] with its alphabetic baseline at [baseline] (SVG semantics).
  void _text(Canvas c, String text, TextStyle style, double cx, double baseline, {double? maxWidth}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth ?? double.infinity);
    final ascent = tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    // SVG letter-spacing trails the last glyph too; centre on the visible glyphs.
    final trailing = style.letterSpacing ?? 0;
    tp.paint(c, Offset(cx - (tp.width - trailing) / 2, baseline - ascent));
    tp.dispose();
  }

  // ── The eight shapes ──

  void _classic(Canvas c) {
    _shadow(c, 200, 448, 112, 12);
    _flat(c, 180, 168, 40, 26, 0, dark, 0.75);
    _fill(c, _rr(152, 92, 96, 82, 6), shader: _cap);
    _flat(c, 160, 100, 10, 66, 5, _white, 0.22);
    final body = _rr(108, 190, 184, 252, 22);
    _fill(c, body, shader: _liquid);
    _fill(c, body, shader: _glass);
    _stroke(c, _rr(117, 199, 166, 234, 16), _white, 0.22);
    _flat(c, 124, 208, 14, 214, 7, _white, 0.3);
    _label(c, 146, 286, 108, 74);
  }

  void _round(Canvas c) {
    _shadow(c, 200, 446, 105, 12);
    _flat(c, 182, 168, 36, 30, 0, dark, 0.75);
    _fill(c, _rr(158, 102, 84, 72, 10), shader: _cap);
    _flat(c, 166, 110, 10, 56, 5, _white, 0.22);
    final ball = Rect.fromCircle(center: const Offset(200, 318), radius: 124);
    c.drawOval(ball, Paint()..shader = _liquid(ball));
    c.drawOval(ball, Paint()..shader = _glass(ball));
    c.drawCircle(
      const Offset(200, 318),
      116,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _white.withValues(alpha: 0.22),
    );
    c.drawPath(
      Path()
        ..moveTo(108, 280)
        ..quadraticBezierTo(118, 230, 160, 208),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..color = _white.withValues(alpha: 0.45),
    );
    _label(c, 150, 300, 100, 62);
  }

  void _tall(Canvas c) {
    _shadow(c, 200, 448, 80, 10);
    _flat(c, 186, 140, 28, 16, 0, dark, 0.75);
    _fill(c, _rr(164, 52, 72, 92, 4), shader: _cap);
    _flat(c, 172, 60, 8, 76, 4, _white, 0.22);
    final body = _rr(142, 154, 116, 290, 12);
    _fill(c, body, shader: _liquid);
    _fill(c, body, shader: _glass);
    _stroke(c, _rr(150, 162, 100, 274, 8), _white, 0.2);
    _flat(c, 154, 172, 12, 250, 6, _white, 0.3);
    _label(c, 160, 300, 80, 84);
  }

  void _attar(Canvas c) {
    _shadow(c, 200, 448, 78, 10);
    // Faceted crystal stopper.
    final crystal = _poly([200, 70, 236, 150, 214, 252, 186, 252, 164, 150]);
    c.drawPath(crystal, Paint()..shader = _crystal(crystal.getBounds()));
    c.drawPath(
      crystal,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = _white.withValues(alpha: 0.6),
    );
    final facets = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _white.withValues(alpha: 0.45);
    c.drawLine(const Offset(200, 70), const Offset(214, 252), facets);
    c.drawLine(const Offset(200, 70), const Offset(186, 252), facets);
    c.drawLine(const Offset(164, 150), const Offset(236, 150), facets);
    // Gold collar.
    _fill(c, _rr(180, 248, 40, 30, 3), shader: _gold);
    // Octagonal body.
    final body = _poly([150, 290, 176, 272, 224, 272, 250, 290, 258, 420, 238, 444, 162, 444, 142, 420]);
    final bounds = body.getBounds();
    c.drawPath(body, Paint()..shader = _liquid(bounds));
    c.drawPath(body, Paint()..shader = _glass(bounds));
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..color = _white.withValues(alpha: 0.35);
    c.drawPath(body, edge);
    c.drawLine(const Offset(150, 290), const Offset(142, 420), edge);
    c.drawLine(const Offset(250, 290), const Offset(258, 420), edge);
    _flat(c, 156, 300, 9, 110, 4, _white, 0.3);
    _label(c, 168, 330, 64, 60);
  }

  void _box(Canvas c) {
    _shadow(c, 200, 448, 140, 12);
    _fill(c, _rr(82, 236, 236, 206, 6), shader: _boxFill);
    final lid = _rr(72, 204, 256, 50, 6);
    _fill(c, lid, color: dark);
    _fill(c, lid, shader: _glass);
    // Ribbon and bow.
    _fill(c, _rr(186, 204, 28, 238, 0), shader: _gold);
    final left = Path()
      ..moveTo(200, 206)
      ..cubicTo(160, 150, 118, 170, 142, 198)
      ..cubicTo(152, 210, 180, 208, 200, 206)
      ..close();
    final right = Path()
      ..moveTo(200, 206)
      ..cubicTo(240, 150, 282, 170, 258, 198)
      ..cubicTo(248, 210, 220, 208, 200, 206)
      ..close();
    c.drawPath(left, Paint()..shader = _gold(left.getBounds()));
    c.drawPath(right, Paint()..shader = _gold(right.getBounds()));
    final knot = Rect.fromCircle(center: const Offset(200, 205), radius: 11);
    c.drawOval(knot, Paint()..shader = _gold(knot));
    c.drawOval(
      knot,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = dark.withValues(alpha: 0.25),
    );
    _label(c, 232, 300, 74, 64);
  }

  void _diffuser(Canvas c) {
    _shadow(c, 200, 448, 92, 11);
    final reed = Paint()
      ..color = const Color(0xff4a3626)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    const tips = [
      (112.0, 64.0),
      (150.0, 46.0),
      (196.0, 38.0),
      (242.0, 46.0),
      (284.0, 66.0),
      (128.0, 96.0),
      (268.0, 96.0),
    ];
    for (final (x, y) in tips) {
      c.drawLine(const Offset(200, 292), Offset(x, y), reed);
    }
    _fill(c, _rr(174, 268, 52, 30, 4), shader: _cap);
    final body = _rr(132, 292, 136, 152, 24);
    _fill(c, body, shader: _liquid);
    _fill(c, body, shader: _glass);
    _stroke(c, body, _white, 0.3);
    _flat(c, 144, 306, 10, 120, 5, _white, 0.3);
    _label(c, 160, 336, 80, 64);
  }

  void _candle(Canvas c) {
    _shadow(c, 200, 448, 112, 12);
    c.drawCircle(
      const Offset(200, 190),
      70,
      Paint()
        ..shader = ui.Gradient.radial(const Offset(200, 190), 70, [
          const Color(0xffffd8a0).withValues(alpha: 0.8),
          const Color(0xffffd8a0).withValues(alpha: 0),
        ]),
    );
    final flame = Path()
      ..moveTo(200, 150)
      ..cubicTo(214, 172, 216, 196, 200, 212)
      ..cubicTo(184, 196, 186, 172, 200, 150)
      ..close();
    c.drawPath(flame, Paint()..shader = _flame(flame.getBounds()));
    c.drawLine(
      const Offset(200, 212),
      const Offset(200, 236),
      Paint()
        ..color = const Color(0xff2a1c12)
        ..strokeWidth = 3,
    );
    final jar = _rr(108, 232, 184, 212, 18);
    _fill(c, jar, color: dark);
    _fill(c, jar, shader: _glass);
    c.drawOval(
      Rect.fromCenter(center: const Offset(200, 240), width: 172, height: 24),
      Paint()..color = const Color(0xfff3e9d9),
    );
    _flat(c, 120, 252, 10, 170, 5, _white, 0.18);
    _label(c, 146, 312, 108, 70);
  }

  void _mist(Canvas c) {
    _shadow(c, 200, 448, 80, 10);
    _fill(c, _rr(182, 112, 36, 58, 6), shader: _cap);
    _fill(c, _rr(214, 124, 26, 12, 3), shader: _cap);
    _flat(c, 172, 160, 56, 22, 6, dark, 0.8);
    final body = _rr(148, 176, 104, 268, 34);
    _fill(c, body, shader: _liquid);
    _fill(c, body, shader: _glass);
    _stroke(c, body, _white, 0.3);
    _flat(c, 160, 196, 11, 226, 5.5, _white, 0.3);
    _label(c, 162, 290, 76, 80);
  }

  @override
  bool shouldRepaint(BottlePainter old) =>
      old.dark != dark ||
      old.light != light ||
      old.shape != shape ||
      old.name != name ||
      old.bare != bare ||
      old.alignment != alignment;
}
