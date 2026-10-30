import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patag_maintenance/core/api.dart';
import 'package:patag_maintenance/core/models.dart';
import 'package:patag_maintenance/features/screens.dart';

import 'test_app.dart';

void main() {
  setUp(() {
    store.token = 'test-token';
    store.user = const User(
      id: 'user-1',
      name: 'Road Crew Alpha',
      email: 'crew@malolos.gov.ph',
      role: 'maintenance',
      teamId: 'team-1',
      active: true,
    );
    store.team = const Team(
      id: 'team-1',
      name: 'Road Crew Alpha',
      members: ['user-1'],
      active: true,
    );
    store.reports = [
      PotholeReport({
        'id': 'PTG-2026-0104',
        'title': 'Pothole on Paseo del Congreso',
        'status': 'Assigned',
        'severity': 'High',
        'location': {
          'road': 'Paseo del Congreso',
          'barangay': 'Catmon',
          'city': 'Malolos',
          'province': 'Bulacan',
          'coordinates': {'lat': 14.852, 'lng': 120.814},
        },
        'photos': [],
        'assignment': {
          'teamId': 'team-1',
          'priority': 'High',
          'note': 'Deploy hot mix asphalt patch.',
          'targetDate': '2026-10-30',
          'at': '2026-10-24T08:00:00Z',
        },
      }),
      PotholeReport({
        'id': 'PTG-2026-0106',
        'title': 'Deep crater on MacArthur Highway',
        'status': 'In Progress',
        'severity': 'High',
        'location': {
          'road': 'MacArthur Highway',
          'barangay': 'Guinhawa',
          'city': 'Malolos',
          'province': 'Bulacan',
          'coordinates': {'lat': 14.856, 'lng': 120.817},
        },
        'photos': [],
        'assignment': {
          'teamId': 'team-1',
          'priority': 'High',
          'note': 'Compaction underway.',
          'targetDate': '2026-10-28',
          'at': '2026-10-24T08:00:00Z',
        },
      }),
    ];
  });

  testWidgets('Dashboard renders team name, metrics, and active work orders',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      testApp(const DashboardTab()),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Road Crew Alpha'), findsWidgets);
    expect(find.text('Active Work Orders'), findsOneWidget);
    expect(find.text('MacArthur Highway'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Paseo del Congreso'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Paseo del Congreso'), findsOneWidget);
  });

  testWidgets('AssignmentsTab renders search and list of tasks',
      (tester) async {
    await tester.pumpWidget(
      testApp(const AssignmentsTab()),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('My Assignments'), findsOneWidget);
    expect(find.text('Paseo del Congreso'), findsOneWidget);
  });

  testWidgets('TaskDetailsScreen renders work order info and action buttons',
      (tester) async {
    await tester.pumpWidget(
      testApp(const TaskDetailsScreen('PTG-2026-0104')),
    );
    await tester.pumpAndSettle();

    expect(find.text('PTG-2026-0104'), findsOneWidget);
    expect(find.text('Paseo del Congreso'), findsOneWidget);
    expect(find.text('TASK PROGRESS'), findsOneWidget);
    expect(find.text('Add Before Photo'), findsOneWidget);
    expect(find.text('Add After Photo'), findsNothing);
    expect(find.text('Start Inspection / Repair'), findsOneWidget);
  });

  testWidgets(
      'TaskDetailsScreen for In Progress task shows Add After Photo and submit',
      (tester) async {
    await tester.pumpWidget(
      testApp(const TaskDetailsScreen('PTG-2026-0106')),
    );
    await tester.pumpAndSettle();

    expect(find.text('PTG-2026-0106'), findsOneWidget);
    expect(find.text('MacArthur Highway'), findsOneWidget);
    expect(find.text('Add After Photo'), findsOneWidget);
    expect(find.text('Add Before Photo'), findsNothing);
    expect(find.text('Document & Submit Completion'), findsOneWidget);
  });

  testWidgets('TaskDetailsScreen waits for LGU verification after completion',
      (tester) async {
    final i = store.reports.indexWhere((r) => r.id == 'PTG-2026-0106');
    store.reports[i] = PotholeReport({
      ...store.reports[i].json,
      'completion': {
        'state': 'Awaiting Verification',
        'note': 'Patched.',
        'photos': [],
        'at': '2026-10-27T01:00:00.000Z',
      },
    });
    await tester.pumpWidget(
      testApp(const TaskDetailsScreen('PTG-2026-0106')),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Waiting for the LGU'), findsOneWidget);
    expect(find.textContaining('Awaiting LGU Verification'), findsOneWidget);
    expect(find.text('Add After Photo'), findsNothing);
    expect(find.text('Document & Submit Completion'), findsNothing);
  });

  testWidgets('SubmissionSuccessScreen displays celebration and return CTA',
      (tester) async {
    await tester.pumpWidget(
      testApp(const SubmissionSuccessScreen('PTG-2026-0106')),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Work submitted.\nOne step closer to patag.'),
        findsOneWidget);
    expect(find.text('Return to Overview'), findsOneWidget);
  });
}
