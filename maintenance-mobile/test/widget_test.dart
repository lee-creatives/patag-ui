import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patag_maintenance/features/screens.dart';

import 'test_app.dart';

void main() {
  testWidgets('Maintenance login screen renders and has demo login button',
      (tester) async {
    await tester.pumpWidget(
      testApp(const MaintenanceLogin()),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Safer roads start here.'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Log in'), findsNWidgets(2)); // header and button
    expect(find.text('Explore fictional demo data'), findsOneWidget);
  });

  testWidgets('Maintenance splash screen displays title and logo',
      (tester) async {
    await tester.pumpWidget(
      testApp(const MaintenanceSplash(),
          routes: {'/login': (_) => const Scaffold()}),
    );
    expect(find.text('Road Maintenance Operations'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
  });

  for (final width in [320.0, 390.0, 430.0, 768.0]) {
    testWidgets('Login screen remains responsive at width $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        testApp(const MaintenanceLogin()),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Welcome back'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
