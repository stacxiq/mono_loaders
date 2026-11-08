import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// A snapshot of everything a loader needs to paint one frame.
///
/// All painting happens on a virtual 200 x 200 canvas centered at (100, 100);
/// the base widget scales it to the requested [MonoLoader.size].
@immutable
class MonoFrame {
  /// Creates a frame snapshot.
  const MonoFrame({
    required this.time,
    required this.progress,
    required this.color,
    required this.thickness,
    required this.labelStyle,
    required this.showLabel,
  });

  /// Animation clock in seconds, already multiplied by [MonoLoader.speed].
  final double time;

  /// Current (smoothed) progress in `0..1`, or `null` when indeterminate.
  final double? progress;

  /// The single ink color used for every element.
  final Color color;

  /// Multiplier applied to every stroke width.
  final double thickness;

  /// Base style for the percent label.
  final TextStyle labelStyle;

  /// Whether the loader should paint its percent label (if it has one).
  final bool showLabel;

  /// Whether the loader is in indeterminate mode.
  bool get indeterminate => progress == null;

  /// [color] with its alpha multiplied by [opacity].
  Color ink(double opacity) =>
      color.withValues(alpha: color.a * opacity.clamp(0.0, 1.0));

  /// A round-capped stroke paint.
  Paint stroke(double width, [double opacity = 1]) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width * thickness
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = ink(opacity);

  /// A fill paint.
  Paint fill([double opacity = 1]) => Paint()..color = ink(opacity);
}

/// Base class for every loader in this package.
///
/// * Pass a [progress] between `0.0` and `1.0` for a determinate indicator.
/// * Leave [progress] `null` for an indeterminate (looping) indicator.
abstract class MonoLoader extends StatefulWidget {
  /// Shared constructor for all loaders.
  const MonoLoader({
    super.key,
    this.progress,
    this.color,
    this.size = 64,
    this.speed = 1,
    this.thickness = 1,
    this.showLabel = true,
    this.labelStyle,
    this.smoothProgress = true,
    this.semanticsLabel,
  }) : assert(size > 0),
       assert(speed >= 0),
       assert(thickness > 0);

  /// Progress in `0.0..1.0` (values outside are clamped). `null` = indeterminate.
  final double? progress;

  /// Ink color. Defaults to the ambient [DefaultTextStyle] color, then
  /// [IconTheme] color, so it follows light / dark themes automatically.
  final Color? color;

  /// Width and height of the loader in logical pixels.
  final double size;

  /// Animation speed multiplier. `0` freezes the motion.
  final double speed;

  /// Multiplier for every stroke width.
  final double thickness;

  /// Whether loaders that support it paint a percent label.
  final bool showLabel;

  /// Style overrides for the percent label (font family, weight, ...).
  final TextStyle? labelStyle;

  /// Animate smoothly towards new [progress] values instead of jumping.
  final bool smoothProgress;

  /// Accessibility label, e.g. "Uploading photo".
  final String? semanticsLabel;

  /// Paints a single frame onto a 200 x 200 virtual canvas.
  @protected
  void paintFrame(Canvas canvas, MonoFrame frame);

  @override
  State<MonoLoader> createState() => _MonoLoaderState();
}

class _MonoLoaderState extends State<MonoLoader>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _repaint = _Repaint();
  Duration _last = Duration.zero;
  double _time = 0;
  double? _shown;
  Color _color = const Color(0xFF000000);
  TextStyle _labelStyle = const TextStyle();

  double? get _target => widget.progress?.clamp(0.0, 1.0).toDouble();

  @override
  void initState() {
    super.initState();
    _shown = _target;
    _ticker = createTicker(_tick)..start();
  }

  void _tick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    _time += dt * widget.speed;
    final target = _target;
    if (target == null || _shown == null || !widget.smoothProgress) {
      _shown = target;
    } else {
      _shown = _shown! + (target - _shown!) * (1 - math.exp(-dt * 12));
      if ((target - _shown!).abs() < 0.0005) _shown = target;
    }
    _repaint.notify();
  }

  MonoFrame get frame => MonoFrame(
    time: _time,
    progress: _shown,
    color: _color,
    thickness: widget.thickness,
    labelStyle: _labelStyle,
    showLabel: widget.showLabel,
  );

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ambient = DefaultTextStyle.of(context).style;
    _color =
        widget.color ??
        ambient.color ??
        IconTheme.of(context).color ??
        const Color(0xFF000000);
    _labelStyle = ambient.merge(widget.labelStyle);
    final target = _target;
    return Semantics(
      label: widget.semanticsLabel,
      value: target == null ? null : '${(target * 100).round()}%',
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: widget.size,
          child: CustomPaint(painter: _MonoPainter(this)),
        ),
      ),
    );
  }
}

class _Repaint extends ChangeNotifier {
  void notify() => notifyListeners();
}

class _MonoPainter extends CustomPainter {
  _MonoPainter(this.state) : super(repaint: state._repaint);

  final _MonoLoaderState state;

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height) / 200;
    canvas
      ..save()
      ..translate((size.width - 200 * s) / 2, (size.height - 200 * s) / 2)
      ..scale(s);
    state.widget.paintFrame(canvas, state.frame);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MonoPainter old) => old.state != state;
}

// ---------------------------------------------------------------------------
// Shared helpers (package-private).
// ---------------------------------------------------------------------------

/// Center of the virtual canvas.
const Offset kCenter = Offset(100, 100);

/// A 3D point.
typedef Vec3 = (double, double, double);

double clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

double lerpD(double a, double b, double t) => a + (b - a) * t;

double easeInOutCubic(double x) =>
    x < .5 ? 4 * x * x * x : 1 - math.pow(-2 * x + 2, 3) / 2;

/// Rotates [p] around the Y axis by [ry], then around the X axis by [rx].
/// The returned z is positive towards the viewer.
Vec3 project(Vec3 p, double ry, double rx) {
  var c = math.cos(ry), s = math.sin(ry);
  final x1 = p.$1 * c + p.$3 * s, z1 = -p.$1 * s + p.$3 * c;
  c = math.cos(rx);
  s = math.sin(rx);
  return (x1, p.$2 * c - z1 * s, p.$2 * s + z1 * c);
}

/// Draws a projected polyline, splitting it into front-facing and
/// back-facing parts so the back can be painted fainter.
void drawSplit(Canvas canvas, List<Vec3> pts, Paint front, Paint back) {
  final f = Path(), b = Path();
  var inF = false, inB = false;
  for (var i = 0; i < pts.length - 1; i++) {
    final a = pts[i], n = pts[i + 1];
    if (a.$3 + n.$3 >= 0) {
      if (!inF) f.moveTo(100 + a.$1, 100 + a.$2);
      f.lineTo(100 + n.$1, 100 + n.$2);
      inF = true;
      inB = false;
    } else {
      if (!inB) b.moveTo(100 + a.$1, 100 + a.$2);
      b.lineTo(100 + n.$1, 100 + n.$2);
      inB = true;
      inF = false;
    }
  }
  canvas
    ..drawPath(b, back)
    ..drawPath(f, front);
}

/// Returns the part of a single-contour [path] that starts at fraction
/// [start] and spans fraction [length] of its total length, wrapping around.
Path trimPath(Path path, double start, double length) {
  final out = Path();
  final it = path.computeMetrics().iterator;
  if (!it.moveNext()) return out;
  final m = it.current, total = m.length;
  final len = clamp01(length) * total;
  if (len <= 0) return out;
  final s = ((start % 1) + 1) % 1 * total, e = s + len;
  if (e <= total) {
    out.addPath(m.extractPath(s, e), Offset.zero);
  } else {
    out
      ..addPath(m.extractPath(s, total), Offset.zero)
      ..addPath(m.extractPath(0, e - total), Offset.zero);
  }
  return out;
}

/// Builds a closed path from polar samples `r(theta)`.
Path polarPath(
  double Function(double theta) radius, {
  int samples = 120,
  double rotation = 0,
  Offset center = kCenter,
}) {
  final p = Path();
  for (var k = 0; k <= samples; k++) {
    final th = k / samples * 2 * math.pi;
    final r = radius(th), a = th - math.pi / 2 + rotation;
    final pt = center + Offset(r * math.cos(a), r * math.sin(a));
    k == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
  }
  return p..close();
}

/// Paints a centered text label.
void paintLabel(
  Canvas canvas,
  MonoFrame f,
  String text, {
  required double fontSize,
  FontWeight fontWeight = FontWeight.w400,
  Offset center = kCenter,
  BlendMode? blendMode,
}) {
  final base = f.labelStyle;
  final paint = Paint()..color = f.ink(1);
  if (blendMode != null) paint.blendMode = blendMode;
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: base.fontFamily,
        fontFamilyFallback: base.fontFamilyFallback,
        package: null,
        fontSize: fontSize,
        fontWeight: base.fontWeight ?? fontWeight,
        letterSpacing: base.letterSpacing ?? -0.5,
        height: 1,
        fontFeatures: const [ui.FontFeature.tabularFigures()],
        foreground: paint,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  tp.dispose();
}
