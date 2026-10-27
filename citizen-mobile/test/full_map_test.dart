import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:patag_citizen/app/theme.dart';
import 'package:patag_citizen/core/api.dart';
import 'package:patag_citizen/features/report_map.dart';

const malolos = LatLng(14.8527, 120.8160);

Widget app(Widget home, {Map<String, WidgetBuilder> routes = const {}}) =>
    MaterialApp(theme: patagTheme(), home: home, routes: routes);

void main() {
  setUp(() {
    store.token = null;
    store.pendingReportPin = null;
  });

  testWidgets('every map has a full-screen button that opens the map edge to edge', (tester) async {
    await tester.pumpWidget(app(const Scaffold(body: RoadMap(height: 240))));
    await tester.tap(find.byTooltip('Full screen map'));
    await tester.pumpAndSettle();

    expect(find.byType(FullMapScreen), findsOneWidget);
    expect(find.text('Report a pothole here'), findsOneWidget);
    // The full-screen map does not offer another full-screen button.
    expect(find.byTooltip('Full screen map'), findsNothing);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(FullMapScreen), findsNothing);
  });

  testWidgets('picking full screen hands the chosen location back to the form', (tester) async {
    LatLng? chosen;
    await tester.pumpWidget(app(Scaffold(
        body: RoadMap(pin: malolos, onPin: (p) => chosen = p, height: 240))));
    await tester.tap(find.byTooltip('Full screen map'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Tap the map to place the pothole pin'), findsOneWidget);
    expect(find.text('Report a pothole here'), findsNothing);
    await tester.tap(find.text('Use this location'));
    await tester.pumpAndSettle();

    expect(find.byType(FullMapScreen), findsNothing);
    expect(chosen, malolos);
  });

  testWidgets('full-screen map fills a phone screen and every control is tappable', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(const FullMapScreen(initialPin: malolos)));
    await tester.pumpAndSettle();

    final map = tester.getSize(find.byType(RoadMap));
    expect(map, const Size(390, 844));
    for (final finder in [
      find.byIcon(Icons.close),
      find.text('Report a pothole here'),
      find.text('My GPS'),
      find.byTooltip('Zoom in'),
    ]) {
      expect(finder.hitTestable(), findsOneWidget, reason: '$finder');
    }
    final panel = tester.getRect(find.text('Report a pothole here'));
    expect(panel.bottom, lessThanOrEqualTo(844));
  });

  testWidgets('"Use this location" is disabled until a pin is placed', (tester) async {
    await tester.pumpWidget(app(const FullMapScreen(picking: true)));
    final button = tester.widget<ButtonStyleButton>(find.ancestor(
        of: find.text('Use this location'), matching: find.bySubtype<ButtonStyleButton>()));
    expect(button.onPressed, isNull);
  });

  testWidgets('reporting from the map opens the report form with the pin when signed in', (tester) async {
    store.token = 'signed-in';
    Object? args;
    await tester.pumpWidget(app(const FullMapScreen(initialPin: malolos), routes: {
      '/report/new': (context) {
        args = ModalRoute.of(context)!.settings.arguments;
        return const Scaffold(body: Text('Report form'));
      },
    }));
    await tester.tap(find.text('Report a pothole here'));
    await tester.pumpAndSettle();

    expect(find.text('Report form'), findsOneWidget);
    expect(args, malolos);
    expect(store.pendingReportPin, isNull);
  });

  testWidgets('reporting from the map while signed out keeps the pin for after sign-in', (tester) async {
    await tester.pumpWidget(app(const FullMapScreen(initialPin: malolos), routes: {
      '/login': (_) => const Scaffold(body: Text('Sign in')),
    }));
    await tester.tap(find.text('Report a pothole here'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
    expect(store.pendingReportPin, malolos);
    expect(store.takePendingReportPin(), malolos);
    expect(store.pendingReportPin, isNull);
  });
}
