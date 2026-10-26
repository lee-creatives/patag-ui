import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patag_maintenance/app/theme.dart';
import 'package:patag_maintenance/features/screens.dart';

void main() {
  testWidgets('Maintenance login screen renders and has demo login button',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: patagMaintenanceTheme(),
        home: const MaintenanceLogin(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Crew Workspace Sign In'), findsOneWidget);
    expect(find.text('Continue as Road Crew Alpha'), findsOneWidget);
    expect(find.text('Sign in to Workspace'), findsOneWidget);
  });

  testWidgets('Maintenance splash screen displays title and logo',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: patagMaintenanceTheme(),
        routes: {'/login': (_) => const Scaffold()},
        home: const MaintenanceSplash(),
      ),
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
        MaterialApp(
          theme: patagMaintenanceTheme(),
          home: const MaintenanceLogin(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Crew Workspace Sign In'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
