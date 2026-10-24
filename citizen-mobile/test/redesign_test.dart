import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patag_citizen/app/theme.dart';
import 'package:patag_citizen/features/screens.dart';
import 'package:patag_citizen/shared/widgets/ui.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
  });
  tearDown(() {
    binding.platformDispatcher.clearAccessibilityFeaturesTestValue();
  });
  for (final width in [320.0, 390.0, 768.0]) {
    testWidgets(
        'home report action and navigation fit $width with enlarged text',
        (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
          theme: patagTheme(),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!),
          home: const CitizenHome()));
      await tester.pumpAndSettle();
      expect(find.text('Report a pothole'), findsOneWidget);
      expect(find.byType(PatagNavigation), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('wizard indicates each active step without changing its labels',
      (tester) async {
    for (var step = 0; step < 4; step++) {
      await tester.pumpWidget(MaterialApp(
          theme: patagTheme(), home: Scaffold(body: WizardSteps(step))));
      for (final label in ['Photo', 'Location', 'Details', 'Review']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    }
  });
}
