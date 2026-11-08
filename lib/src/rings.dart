import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'core.dart';

// ---------------------------------------------------------------------------
// Arc Ring
// ---------------------------------------------------------------------------

/// A classic ring with a rounded arc and a large, light percent label.
class ArcRingLoader extends MonoLoader {
  /// Creates an arc ring loader.
  const ArcRingLoader({
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
    final rect = Rect.fromCircle(center: kCenter, radius: 64);
    final t = f.time, p = f.progress;
    canvas.drawCircle(kCenter, 64, f.stroke(8, .1)..strokeCap = StrokeCap.butt);
    if (p == null) {
      final sweep =
          (8 + 60 * (.5 + .5 * math.sin(t * 2.2))) / 100 * 2 * math.pi;
      final start = ((t * 280) % 360 - 90) * math.pi / 180;
      canvas.drawArc(rect, start, sweep, false, f.stroke(8));
    } else {
      if (p > .005) {
        canvas.drawArc(rect, -math.pi / 2, p * 2 * math.pi, false, f.stroke(8));
      }
      if (f.showLabel) {
        paintLabel(
          canvas,
          f,
          '${(p * 100).round()}',
          fontSize: 34,
          fontWeight: FontWeight.w300,
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Tick Dial
// ---------------------------------------------------------------------------

/// Sixty watch-style ticks that light up with progress; a comet sweeps
/// around the dial when indeterminate.
class TickDialLoader extends MonoLoader {
  /// Creates a tick dial loader.
  const TickDialLoader({
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
    const n = 60;
    final t = f.time, p = f.progress, head = (t * 40) % n;
    for (var i = 0; i < n; i++) {
      final a = i / n * 2 * math.pi - math.pi / 2;
      final dir = Offset(math.cos(a), math.sin(a));
      final lit = p == null
          ? math.max(0.0, 1 - (((head - i) % n + n) % n) / 22)
          : clamp01(p * n - i);
      canvas.drawLine(
        kCenter + dir * 56,
        kCenter + dir * 72,
        f.stroke(2.4, .12 + .88 * lit),
      );
    }
    if (p != null && f.showLabel) {
      paintLabel(
        canvas,
        f,
        '${(p * 100).round()}'.padLeft(2, '0'),
        fontSize: 24,
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Orbit Atom
// ---------------------------------------------------------------------------

Path _ellipse(double rx, double ry) {
  final path = Path()..moveTo(rx, 0);
  for (var k = 1; k <= 96; k++) {
    final a = k / 96 * 2 * math.pi;
    path.lineTo(rx * math.cos(a), ry * math.sin(a));
  }
  return path..close();
}

final Path _orbitPath = _ellipse(74, 24);

/// Three tilted orbits with travelling electrons. Each orbit draws itself
/// with progress while the nucleus grows.
class OrbitAtomLoader extends MonoLoader {
  /// Creates an orbit atom loader.
  const OrbitAtomLoader({
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
    for (var i = 0; i < 3; i++) {
      canvas
        ..save()
        ..translate(100, 100)
        ..rotate(i * math.pi / 3)
        ..drawPath(_orbitPath, f.stroke(1, .14));
      if (p == null) {
        canvas.drawPath(_orbitPath, f.stroke(1.6, .4));
      } else {
        canvas.drawPath(trimPath(_orbitPath, 0, p), f.stroke(1.6));
      }
      final a = t * (1.6 + i * .35) + i * 2.1;
      canvas
        ..drawCircle(
          Offset(74 * math.cos(a), 24 * math.sin(a)),
          2.6 + 2 * (math.sin(a) + 1) / 2,
          f.fill(),
        )
        ..restore();
    }
    canvas.drawCircle(
      kCenter,
      p == null ? 6 + 1.5 * math.sin(t * 4) : 4 + 6 * p,
      f.fill(),
    );
  }
}

// ---------------------------------------------------------------------------
// Infinity Trace
// ---------------------------------------------------------------------------

final Path _lemniscate = () {
  final path = Path();
  for (var k = 0; k <= 240; k++) {
    final s = k / 240 * 2 * math.pi;
    final den = 1 + math.pow(math.sin(s), 2);
    final x = 100 + 74 * math.cos(s) / den;
    final y = 100 + 74 * math.sin(s) * math.cos(s) / den;
    k == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
  }
  return path;
}();

/// A figure-eight track: progress draws the curve, indeterminate mode sends
/// a comet with a fading tail around it.
class InfinityTraceLoader extends MonoLoader {
  /// Creates an infinity trace loader.
  const InfinityTraceLoader({
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
    final p = f.progress;
    canvas.drawPath(_lemniscate, f.stroke(6, .1));
    if (p == null) {
      final s = (f.time * .32) % 1;
      canvas
        ..drawPath(trimPath(_lemniscate, s - .18, .34), f.stroke(6, .3))
        ..drawPath(trimPath(_lemniscate, s, .16), f.stroke(6));
    } else if (p > .005) {
      canvas.drawPath(trimPath(_lemniscate, 0, p), f.stroke(6));
    }
  }
}
