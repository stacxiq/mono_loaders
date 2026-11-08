import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mono_loaders/mono_loaders.dart';

void main() => runApp(const GalleryApp());

class GalleryApp extends StatefulWidget {
  const GalleryApp({super.key});

  @override
  State<GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> {
  ThemeMode _mode = ThemeMode.system;

  ThemeData _theme(Brightness b) {
    final dark = b == Brightness.dark;
    final fg = dark ? const Color(0xFFF2F2F0) : const Color(0xFF111111);
    return ThemeData(
      brightness: b,
      scaffoldBackgroundColor: dark
          ? const Color(0xFF0A0A0B)
          : const Color(0xFFF3F3F1),
      cardColor: dark ? const Color(0xFF141415) : Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: fg,
        brightness: b,
        primary: fg,
        onSurface: fg,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mono Loaders',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: _mode,
      home: GalleryPage(
        onToggleTheme: () => setState(() {
          final dark =
              _mode == ThemeMode.dark ||
              (_mode == ThemeMode.system &&
                  MediaQuery.platformBrightnessOf(context) == Brightness.dark);
          _mode = dark ? ThemeMode.light : ThemeMode.dark;
        }),
      ),
    );
  }
}

enum DemoMode { auto, manual, indeterminate }

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key, required this.onToggleTheme});

  final VoidCallback onToggleTheme;

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  DemoMode _mode = DemoMode.auto;
  double _manual = .42, _speed = 1, _auto = 0;
  final _clock = Stopwatch()..start();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Simulates a real download: eases to 100%, holds, restarts.
    _timer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (_mode != DemoMode.auto) return;
      final u = (_clock.elapsedMilliseconds / 1000) % 5.6;
      final x = math.min(u / 4.6, 1.0);
      setState(
        () => _auto = x < .5 ? 4 * x * x * x : 1 - math.pow(-2 * x + 2, 3) / 2,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  double? get _progress => switch (_mode) {
    DemoMode.auto => _auto,
    DemoMode.manual => _manual,
    DemoMode.indeterminate => null,
  };

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: .5);
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Mono Loaders',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          onPressed: widget.onToggleTheme,
                          icon: const Icon(Icons.contrast),
                          tooltip: 'Toggle theme',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SegmentedButton<DemoMode>(
                      segments: const [
                        ButtonSegment(
                          value: DemoMode.auto,
                          label: Text('Auto'),
                        ),
                        ButtonSegment(
                          value: DemoMode.manual,
                          label: Text('Manual'),
                        ),
                        ButtonSegment(
                          value: DemoMode.indeterminate,
                          label: Text('Loop'),
                        ),
                      ],
                      selected: {_mode},
                      showSelectedIcon: false,
                      onSelectionChanged: (s) =>
                          setState(() => _mode = s.first),
                    ),
                    if (_mode == DemoMode.manual)
                      _SliderRow(
                        label: 'Progress',
                        value: _manual,
                        onChanged: (v) => setState(() => _manual = v),
                      ),
                    _SliderRow(
                      label: 'Speed',
                      value: _speed,
                      min: .25,
                      max: 2,
                      onChanged: (v) => setState(() => _speed = v),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 260,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: .82,
                ),
                itemCount: MonoLoaderType.values.length,
                itemBuilder: (context, i) {
                  final type = MonoLoaderType.values[i];
                  final p = _progress;
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: muted.withValues(alpha: .15)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (i + 1).toString().padLeft(2, '0'),
                            style: TextStyle(fontSize: 11, color: muted),
                          ),
                          Expanded(
                            child: Center(
                              child: LayoutBuilder(
                                builder: (context, c) => type.build(
                                  progress: p,
                                  speed: _speed,
                                  size: math.min(c.maxWidth, c.maxHeight) * .9,
                                  semanticsLabel: type.label,
                                ),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  type.label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                p == null ? '∞' : '${(p * 100).round()}%',
                                style: TextStyle(fontSize: 12, color: muted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
  });

  final String label;
  final double value, min, max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(width: 72, child: Text(label)),
      Expanded(
        child: Slider(value: value, min: min, max: max, onChanged: onChanged),
      ),
    ],
  );
}
