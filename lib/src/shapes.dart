import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'core.dart';

// ---------------------------------------------------------------------------
// Shape Morph
// ---------------------------------------------------------------------------

const List<int> _morphSeq = [3, 4, 6, 0]; // 0 = circle

double _polyRadius(int n, double th) {
  if (n == 0) return .88;
  final seg = 2 * math.pi / n;
  final a = ((th % seg) + seg) % seg - seg / 2;
  return math.cos(math.pi / n) / math.cos(a);
}

/// Triangle → square → hexagon → circle. Progress traces the outline;
/// indeterminate mode chases a dash around it.
class ShapeMorphLoader extends MonoLoader {
  /// Creates a shape morph loader.
  const ShapeMorphLoader({
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
    final s = t / 1.5, i = s.floor() % _morphSeq.length, frac = s - s.floor();
    final e = frac < .55 ? 0.0 : easeInOutCubic((frac - .55) / .45);
    final n0 = _morphSeq[i], n1 = _morphSeq[(i + 1) % _morphSeq.length];
    double radius(double th, double scale) =>
        70 * scale * lerpD(_polyRadius(n0, th), _polyRadius(n1, th), e);

    final outer = polarPath((th) => radius(th, 1), rotation: t * .35);
    final inner = polarPath((th) => radius(th, .45), rotation: -t * .6);
    canvas
      ..drawPath(outer, f.stroke(3, .13))
      ..drawPath(inner, f.stroke(1.2, .35));
    if (p == null) {
      canvas.drawPath(trimPath(outer, (t * .4) % 1, .24), f.stroke(3));
    } else if (p > .005) {
      canvas.drawPath(trimPath(outer, 0, p), f.stroke(3));
    }
  }
}

// ---------------------------------------------------------------------------
// Wire Cube
// ---------------------------------------------------------------------------

const double _cubeS = 44;
const List<Vec3> _cubeV = [
  (-1, -1, -1), (1, -1, -1), (1, -1, 1), (-1, -1, 1), //
  (-1, 1, -1), (1, 1, -1), (1, 1, 1), (-1, 1, 1),
];

/// Bottom square, verticals, then top square: the order edges light up.
const List<(int, int)> _cubeE = [
  (4, 5), (5, 6), (6, 7), (7, 4), //
  (4, 0), (5, 1), (6, 2), (7, 3),
  (0, 1), (1, 2), (2, 3), (3, 0),
];

/// A spinning wireframe cube whose 12 edges are drawn one by one with
/// progress, with a smaller counter-rotating cube inside.
class WireCubeLoader extends MonoLoader {
  /// Creates a wire cube loader.
  const WireCubeLoader({
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
    Offset o(Vec3 v) => Offset(100 + v.$1, 100 + v.$2);
    double depth(double z) => clamp01(z / (1.8 * _cubeS) * .5 + .5);

    final outer = [
      for (final v in _cubeV)
        project(
          (v.$1 * _cubeS, v.$2 * _cubeS, v.$3 * _cubeS),
          t * .6,
          -.5 + .15 * math.sin(t * .7),
        ),
    ];
    final inner = [
      for (final v in _cubeV)
        project(
          (v.$1 * _cubeS * .38, v.$2 * _cubeS * .38, v.$3 * _cubeS * .38),
          -t * .9,
          .6,
        ),
    ];
    final innerPaint = f.stroke(1, .28);
    for (var i = 0; i < _cubeE.length; i++) {
      final (ia, ib) = _cubeE[i];
      final a = outer[ia], b = outer[ib];
      final dep = depth((a.$3 + b.$3) / 2);
      canvas
        ..drawLine(o(inner[ia]), o(inner[ib]), innerPaint)
        ..drawLine(o(a), o(b), f.stroke(1.2, .08 + .2 * dep));

      final double frac, op;
      if (p == null) {
        frac = 1;
        op = (.25 + .75 * dep) * math.max(0.0, math.sin(t * 3.5 - i * .55));
      } else {
        frac = clamp01(p * _cubeE.length - i);
        op = .45 + .55 * dep;
      }
      if (frac > 0 && op > 0) {
        canvas.drawLine(
          o(a),
          Offset.lerp(o(a), o(b), frac)!,
          f.stroke(2.2, op),
        );
      }
    }
    for (final v in outer) {
      canvas.drawCircle(o(v), 2.2 * f.thickness, f.fill(.2 + .8 * depth(v.$3)));
    }
  }
}

// ---------------------------------------------------------------------------
// Helix
// ---------------------------------------------------------------------------

/// A rotating double helix of dots that fills top-to-bottom with progress.
class HelixLoader extends MonoLoader {
  /// Creates a helix loader.
  const HelixLoader({
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
    const n = 15;
    final t = f.time, p = f.progress;
    for (var i = 0; i < n; i++) {
      final y = 37 + i * (126 / (n - 1));
      final ang = t * 2.2 + i * .42, c = math.cos(ang), z = math.sin(ang);
      final lit = p == null
          ? .55 + .45 * math.sin(t * 3 - i * .5)
          : clamp01(p * n - i);
      double op(double z) => (.1 + .9 * lit) * (.3 + .7 * (z + 1) / 2);
      final a = Offset(100 + 40 * c, y), b = Offset(100 - 40 * c, y);
      canvas
        ..drawLine(
          a,
          b,
          f.stroke(1, .06 + .2 * lit)..strokeCap = StrokeCap.butt,
        )
        ..drawCircle(a, (2 + 2.4 * (z + 1) / 2) * f.thickness, f.fill(op(z)))
        ..drawCircle(b, (2 + 2.4 * (-z + 1) / 2) * f.thickness, f.fill(op(-z)));
    }
  }
}

// ---------------------------------------------------------------------------
// Dot Matrix
// ---------------------------------------------------------------------------

/// Cells of a 5x5 grid in clockwise spiral order (outside → in).
final List<(int, int)> _spiral = () {
  final out = <(int, int)>[];
  var top = 0, bot = 4, l = 0, r = 4;
  while (top <= bot && l <= r) {
    for (var c = l; c <= r; c++) {
      out.add((top, c));
    }
    top++;
    for (var row = top; row <= bot; row++) {
      out.add((row, r));
    }
    r--;
    if (top <= bot) {
      for (var c = r; c >= l; c--) {
        out.add((bot, c));
      }
      bot--;
    }
    if (l <= r) {
      for (var row = bot; row >= top; row--) {
        out.add((row, l));
      }
      l++;
    }
  }
  return out;
}();

/// A 5x5 grid of rounded cells: fills in a spiral with progress, ripples from
/// the center when indeterminate.
class DotMatrixLoader extends MonoLoader {
  /// Creates a dot matrix loader.
  const DotMatrixLoader({
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
    const size = 20.0, gap = 27.0, origin = 100 - gap * 2;
    final t = f.time, p = f.progress;
    for (var k = 0; k < _spiral.length; k++) {
      final (row, col) = _spiral[k];
      double a;
      if (p == null) {
        final dist = math.sqrt(math.pow(row - 2, 2) + math.pow(col - 2, 2));
        a = math.max(0.0, math.sin(t * 4 - dist * 1.3));
        a *= a;
      } else {
        a = clamp01(p * _spiral.length - k);
      }
      final s = .65 + .35 * a;
      final rect = Rect.fromCenter(
        center: Offset(origin + col * gap, origin + row * gap),
        width: size * s,
        height: size * s,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(5 * s)),
        f.fill(.08 + .92 * a),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Square Tunnel
// ---------------------------------------------------------------------------

/// Seven nested rounded squares twisting in a wave; they light up from the
/// outside in with progress.
class SquareTunnelLoader extends MonoLoader {
  /// Creates a square tunnel loader.
  const SquareTunnelLoader({
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
    const n = 7;
    final t = f.time, p = f.progress;
    for (var i = 0; i < n; i++) {
      final z = 128.0 - i * 17;
      final a = p == null ? 1 - i / n * .75 : clamp01(p * n - i);
      canvas
        ..save()
        ..translate(100, 100)
        ..rotate(math.sin(t * 1.6 - i * .38) * math.pi / 4)
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: z, height: z),
            Radius.circular(z * .14),
          ),
          f.stroke(1.6, .12 + .88 * a),
        )
        ..restore();
    }
  }
}
