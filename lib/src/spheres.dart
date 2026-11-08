import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'core.dart';

// ---------------------------------------------------------------------------
// Wire Sphere
// ---------------------------------------------------------------------------

class _WireLine {
  const _WireLine(this.points, [this.height]);
  final List<Vec3> points;

  /// Normalized height (0 = bottom, 1 = top) for latitude rings.
  final double? height;
}

const double _wireR = 64;
const int _wireLat = 10;

final List<_WireLine> _wireLines = () {
  final lines = <_WireLine>[];
  for (var i = 1; i < _wireLat; i++) {
    final phi = -math.pi / 2 + math.pi * i / _wireLat;
    lines.add(
      _WireLine([
        for (var k = 0; k <= 72; k++)
          (
            _wireR * math.cos(phi) * math.cos(k / 72 * 2 * math.pi),
            -_wireR * math.sin(phi),
            _wireR * math.cos(phi) * math.sin(k / 72 * 2 * math.pi),
          ),
      ], i / _wireLat),
    );
  }
  for (var j = 0; j < 12; j++) {
    final th = j / 12 * 2 * math.pi;
    lines.add(
      _WireLine([
        for (var k = 0; k <= 48; k++)
          (
            _wireR * math.cos(-math.pi / 2 + math.pi * k / 48) * math.cos(th),
            -_wireR * math.sin(-math.pi / 2 + math.pi * k / 48),
            _wireR * math.cos(-math.pi / 2 + math.pi * k / 48) * math.sin(th),
          ),
      ]),
    );
  }
  return lines;
}();

/// A rotating wireframe globe. Latitude rings light up bottom-to-top with
/// progress; in indeterminate mode a glowing band scans up and down.
class WireSphereLoader extends MonoLoader {
  /// Creates a wire sphere loader.
  const WireSphereLoader({
    super.key,
    super.progress,
    super.color,
    super.size,
    super.speed,
    super.thickness,
    super.showLabel,
    super.labelStyle,
    super.smoothProgress,
    super.semanticsLabel,
  });

  @override
  void paintFrame(Canvas canvas, MonoFrame f) {
    final t = f.time, p = f.progress;
    final ry = t * .5, rx = -.38, level = .5 + .42 * math.sin(t * 1.8);
    canvas.drawCircle(kCenter, _wireR, f.stroke(1, .3));
    for (final line in _wireLines) {
      final h = line.height;
      final a = h == null
          ? 0.0
          : p == null
          ? clamp01(1 - (h - level).abs() * 5)
          : clamp01((p - h) * _wireLat + 1);
      drawSplit(
        canvas,
        [for (final q in line.points) project(q, ry, rx)],
        f.stroke(1 + a, .2 + .8 * a),
        f.stroke(.8, .06 + .14 * a),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Dot Globe
// ---------------------------------------------------------------------------

const double _dotR = 66;
const int _dotN = 240;

/// Fibonacci sphere, index 0 at the bottom.
final List<Vec3> _dotPoints = () {
  final ga = math.pi * (3 - math.sqrt(5));
  return [
    for (var i = 0; i < _dotN; i++)
      () {
        final y = 1 - 2 * (i + .5) / _dotN, r = math.sqrt(1 - y * y);
        return (
          _dotR * r * math.cos(ga * i),
          _dotR * y,
          _dotR * r * math.sin(ga * i),
        );
      }(),
  ];
}();

/// A spinning sphere of 240 dots that fills from the bottom with progress;
/// in indeterminate mode waves of light travel across it.
class DotGlobeLoader extends MonoLoader {
  /// Creates a dot globe loader.
  const DotGlobeLoader({
    super.key,
    super.progress,
    super.color,
    super.size,
    super.speed,
    super.thickness,
    super.showLabel,
    super.labelStyle,
    super.smoothProgress,
    super.semanticsLabel,
  });

  @override
  void paintFrame(Canvas canvas, MonoFrame f) {
    final t = f.time, p = f.progress;
    final paint = Paint();
    for (var i = 0; i < _dotN; i++) {
      final q = _dotPoints[i];
      final v = project(q, t * .45, -.3);
      final d = (v.$3 / _dotR + 1) / 2;
      final lit = p == null
          ? clamp01(math.sin(q.$2 * .06 - t * 3) * 1.6 - .4)
          : clamp01(p * _dotN - i);
      paint.color = f.ink((.07 + .93 * lit) * (.2 + .8 * d));
      canvas.drawCircle(
        Offset(100 + v.$1, 100 + v.$2),
        (.7 + 1.7 * d * (.55 + .45 * lit)) * f.thickness,
        paint,
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Liquid Orb
// ---------------------------------------------------------------------------

/// A circle filling with a rippling liquid. The percent label inverts where
/// the liquid passes behind it.
class LiquidOrbLoader extends MonoLoader {
  /// Creates a liquid orb loader.
  const LiquidOrbLoader({
    super.key,
    super.progress,
    super.color,
    super.size,
    super.speed,
    super.thickness,
    super.showLabel,
    super.labelStyle,
    super.smoothProgress,
    super.semanticsLabel,
  });

  static Path _wave(double level, double amp, double phase, double k) {
    final path = Path()..moveTo(30, level);
    for (var x = 30.0; x <= 170; x += 4) {
      path.lineTo(x, level + math.sin(x * k + phase) * amp);
    }
    return path
      ..lineTo(170, 175)
      ..lineTo(30, 175)
      ..close();
  }

  @override
  void paintFrame(Canvas canvas, MonoFrame f) {
    const r = 66.0;
    final t = f.time, p = f.progress;
    final fill = p ?? .5 + .14 * math.sin(t * 1.4);
    final level = 168 - 136 * fill;

    canvas
      ..drawCircle(kCenter, r + 7, f.stroke(1, .35))
      ..save()
      ..clipPath(Path()..addOval(Rect.fromCircle(center: kCenter, radius: r)))
      ..drawPath(_wave(level - 3, 5, -t * 2.4 + 1, .042), f.fill(.18))
      ..saveLayer(const Rect.fromLTWH(0, 0, 200, 200), Paint())
      ..drawPath(_wave(level, 4, t * 3, .05), f.fill());
    if (p != null && f.showLabel) {
      // XOR punches the label out of the liquid and paints it elsewhere.
      paintLabel(
        canvas,
        f,
        '${(p * 100).round()}%',
        fontSize: 26,
        fontWeight: FontWeight.w500,
        blendMode: BlendMode.xor,
      );
    }
    canvas
      ..restore()
      ..restore();
  }
}
