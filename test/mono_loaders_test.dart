import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mono_loaders/mono_loaders.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  for (final type in MonoLoaderType.values) {
    group(type.label, () {
      testWidgets('indeterminate paints for several frames', (tester) async {
        await tester.pumpWidget(_host(type.build(size: 120)));
        for (var i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(tester.takeException(), isNull);
        expect(find.byWidgetPredicate((w) => w is MonoLoader), findsOneWidget);
      });

      testWidgets('determinate edge values paint', (tester) async {
        for (final p in [-1.0, 0.0, 0.004, 0.37, 1.0, 2.0]) {
          await tester.pumpWidget(
            _host(type.build(progress: p, smoothProgress: false)),
          );
          await tester.pump(const Duration(milliseconds: 16));
          expect(tester.takeException(), isNull);
        }
      });
    });
  }

  testWidgets('exposes progress through semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(const ArcRingLoader(progress: .42, semanticsLabel: 'Uploading')),
    );
    expect(find.bySemanticsLabel('Uploading'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(ArcRingLoader)),
      matchesSemantics(label: 'Uploading', value: '42%'),
    );
    handle.dispose();
  });

  testWidgets('switching between determinate and indeterminate', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const LiquidOrbLoader(progress: .3)));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(_host(const LiquidOrbLoader()));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(_host(const LiquidOrbLoader(progress: .9)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });
}
