import 'package:patag_citizen/shared/widgets/ui.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:patag_citizen/app/theme.dart';
import 'package:patag_citizen/features/screens.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
  });
  tearDown(() {
    binding.platformDispatcher.clearAccessibilityFeaturesTestValue();
  });
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('Montserrat')
      ..addFont(rootBundle.load('assets/fonts/Montserrat.ttf'));
    await loader.load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  test('theme preference survives a new controller and supports system default',
      () async {
    SharedPreferences.setMockInitialValues({});
    final first = ThemeController();
    await first.load();
    expect(first.mode, ThemeMode.system);
    await first.setMode(ThemeMode.dark);
    final restarted = ThemeController();
    await restarted.load();
    expect(restarted.mode, ThemeMode.dark);
    await restarted.setMode(ThemeMode.light);
    await first.load();
    expect(first.mode, ThemeMode.light);
  });
  for (final brightness in Brightness.values) {
    for (final width in [320.0, 375.0, 390.0, 430.0, 768.0]) {
      testWidgets(
          'Montserrat home ${brightness.name} $width with enlarged text',
          (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final key = GlobalKey();
        await tester.pumpWidget(MaterialApp(
            theme: patagTheme(brightness: brightness),
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.3)),
                child: child!),
            home: RepaintBoundary(key: key, child: const CitizenHome())));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Report a pothole'), findsOneWidget);
        if (width == 390) {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            final file = File(
                '../docs/visual-system/native-home-${brightness.name}.png');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      });
    }
  }
  testWidgets('theme toggle updates current screen immediately',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await themeController.setMode(ThemeMode.light);
    await tester.pumpWidget(ListenableBuilder(
        listenable: themeController,
        builder: (context, _) => MaterialApp(
            theme: patagTheme(),
            darkTheme: patagTheme(brightness: Brightness.dark),
            themeMode: themeController.mode,
            home: const CitizenHome())));
    await tester.tap(find.byTooltip('Switch to dark mode'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Switch to light mode'), findsOneWidget);
    expect(themeController.mode, ThemeMode.dark);
    expect(tester.takeException(), isNull);
  });
  testWidgets('mascot dances and stops for reduced motion', (tester) async {
    binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: false);
    await tester
        .pumpWidget(MaterialApp(home: Scaffold(body: mascot(dance: true))));
    final artwork = find
        .descendant(
            of: find.byType(DancingMascot), matching: find.byType(Image))
        .last;
    final initial = tester.getTopLeft(artwork);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.getTopLeft(artwork), isNot(initial));
    binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    await tester.pumpAndSettle();
    final stationary = tester.getTopLeft(artwork);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.getTopLeft(artwork), stationary);
    expect(tester.takeException(), isNull);
  });
}
