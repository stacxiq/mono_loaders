import 'package:flutter/widgets.dart';

import 'core.dart';
import 'rings.dart';
import 'shapes.dart';
import 'spheres.dart';

/// Every loader in the package, handy for pickers and settings screens.
enum MonoLoaderType {
  /// [WireSphereLoader]
  wireSphere('Wire Sphere'),

  /// [DotGlobeLoader]
  dotGlobe('Dot Globe'),

  /// [LiquidOrbLoader]
  liquidOrb('Liquid Orb'),

  /// [ArcRingLoader]
  arcRing('Arc Ring'),

  /// [TickDialLoader]
  tickDial('Tick Dial'),

  /// [OrbitAtomLoader]
  orbitAtom('Orbit Atom'),

  /// [ShapeMorphLoader]
  shapeMorph('Shape Morph'),

  /// [WireCubeLoader]
  wireCube('Wire Cube'),

  /// [HelixLoader]
  helix('Helix'),

  /// [InfinityTraceLoader]
  infinityTrace('Infinity Trace'),

  /// [DotMatrixLoader]
  dotMatrix('Dot Matrix'),

  /// [SquareTunnelLoader]
  squareTunnel('Square Tunnel');

  const MonoLoaderType(this.label);

  /// Human readable name.
  final String label;

  /// Builds the loader widget for this type.
  MonoLoader build({
    Key? key,
    double? progress,
    Color? color,
    double size = 64,
    double speed = 1,
    double thickness = 1,
    bool showLabel = true,
    TextStyle? labelStyle,
    bool smoothProgress = true,
    String? semanticsLabel,
  }) {
    return switch (this) {
      wireSphere => WireSphereLoader(
        key: key,
        progress: progress,
        color: color,
        size: size,
        speed: speed,
        thickness: thickness,
        showLabel: showLabel,
        labelStyle: labelStyle,
        smoothProgress: smoothProgress,
        semanticsLabel: semanticsLabel,
      ),
      dotGlobe => DotGlobeLoader(
        key: key,
        progress: progress,
        color: color,
        size: size,
        speed: speed,
        thickness: thickness,
        showLabel: showLabel,
        labelStyle: labelStyle,
        smoothProgress: smoothProgress,
        semanticsLabel: semanticsLabel,
      ),
      liquidOrb => LiquidOrbLoader(
        key: key,
        progress: progress,
        color: color,
        size: size,
        speed: speed,
        thickness: thickness,
        showLabel: showLabel,
        labelStyle: labelStyle,
        smoothProgress: smoothProgress,
        semanticsLabel: semanticsLabel,
      ),
      arcRing => ArcRingLoader(
        key: key,
        progress: progress,
        color: color,
        size: size,
        speed: speed,
        thickness: thickness,
        showLabel: showLabel,
        labelStyle: labelStyle,
        smoothProgress: smoothProgress,
        semanticsLabel: semanticsLabel,
      ),
      tickDial => TickDialLoader(
        key: key,
        progress: progress,
        color: color,
        size: size,
        speed: speed,
        thickness: thickness,
        showLabel: showLabel,
        labelStyle: labelStyle,
        smoothProgress: smoothProgress,
        semanticsLabel: semanticsLabel,
      ),
      orbitAtom => OrbitAtomLoader(
        key: key,
        progress: progress,
        color: color,
        size: size,
        speed: speed,
        thickness: thickness,
        showLabel: showLabel,
        labelStyle: labelStyle,
        smoothProgress: smoothProgress,
        semanticsLabel: semanticsLabel,
      ),
      shapeMorph => ShapeMorphLoader(
        key: key,
        progress: progress,
        color: color,
        size: size,
        speed: speed,
        thickness: thickness,
        showLabel: showLabel,
        labelStyle: labelStyle,
        smoothProgress: smoothProgress,
        semanticsLabel: semanticsLabel,
      ),
      wireCube => WireCubeLoader(
        key: key,
        progress: progress,
        color: color,
        size: size,
        speed: speed,
        thickness: thickness,
        showLabel: showLabel,
        labelStyle: labelStyle,
        smoothProgress: smoothProgress,
        semanticsLabel: semanticsLabel,
      ),
      helix => HelixLoader(
        key: key,
        progress: progress,
        color: color,
        size: size,
        speed: speed,
        thickness: thickness,
        showLabel: showLabel,
        labelStyle: labelStyle,
        smoothProgress: smoothProgress,
        semanticsLabel: semanticsLabel,
      ),
      infinityTrace => InfinityTraceLoader(
        key: key,
        progress: progress,
        color: color,
        size: size,
        speed: speed,
        thickness: thickness,
        showLabel: showLabel,
        labelStyle: labelStyle,
        smoothProgress: smoothProgress,
        semanticsLabel: semanticsLabel,
      ),
      dotMatrix => DotMatrixLoader(
        key: key,
        progress: progress,
        color: color,
        size: size,
        speed: speed,
        thickness: thickness,
        showLabel: showLabel,
        labelStyle: labelStyle,
        smoothProgress: smoothProgress,
        semanticsLabel: semanticsLabel,
      ),
      squareTunnel => SquareTunnelLoader(
        key: key,
        progress: progress,
        color: color,
        size: size,
        speed: speed,
        thickness: thickness,
        showLabel: showLabel,
        labelStyle: labelStyle,
        smoothProgress: smoothProgress,
        semanticsLabel: semanticsLabel,
      ),
    };
  }
}
