import 'package:flutter_test/flutter_test.dart';
import 'package:mono_loaders_example/main.dart';

void main() {
  testWidgets('gallery renders', (tester) async {
    await tester.pumpWidget(const GalleryApp());
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Mono Loaders'), findsOneWidget);
    expect(find.text('Wire Sphere'), findsOneWidget);
  });
}
