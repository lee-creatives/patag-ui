import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patag_citizen/app/theme.dart';
import 'package:patag_citizen/shared/widgets/ui.dart';

void main() {
  testWidgets(
      'mascot stays visible across theme changes without changing layout',
      (tester) async {
    for (final brightness in [
      Brightness.light,
      Brightness.dark,
      Brightness.light
    ]) {
      await tester.pumpWidget(MaterialApp(
          theme: patagTheme(brightness: brightness),
          home: Scaffold(body: mascot(width: 100))));
      await tester.pumpAndSettle();
      final image = tester.widget<Image>(find.descendant(
          of: find.byType(DancingMascot), matching: find.byType(Image)));
      expect(image.color, brightness == Brightness.dark ? Colors.white : ink);
      expect(image.colorBlendMode, BlendMode.srcIn);
      expect(image.width, 100);
      expect(image.excludeFromSemantics, isTrue);
      expect(tester.takeException(), isNull);
    }
  });
}
