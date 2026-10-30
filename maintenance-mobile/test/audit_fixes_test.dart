import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:patag_maintenance/app/locale.dart';
import 'package:patag_maintenance/core/api.dart';
import 'package:patag_maintenance/core/models.dart';
import 'package:patag_maintenance/features/screens.dart';
import 'package:patag_maintenance/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

PotholeReport task(String id, String status,
        {Map<String, dynamic>? completion,
        List<Map<String, dynamic>> updates = const []}) =>
    PotholeReport({
      'id': id,
      'status': status,
      'teamId': 'team-1',
      'location': {
        'road': 'Road $id',
        'coordinates': {'lat': 14.85, 'lng': 120.81}
      },
      'photos': [],
      'updates': updates,
      'completion': completion,
    });

Map<String, dynamic> photo(String url,
        {String kind = 'after', bool demo = false}) =>
    {'id': url, 'url': url, 'name': 'p', 'kind': kind, 'demo': demo};

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // These checks were written against the English UI (the default is Tagalog).
    await localeController.setLocale(LocaleController.english);
    store.client = MockClient((_) async => http.Response('{"ok":true}', 200));
  });
  tearDown(() {
    store.token = null;
    store.reports = [];
    store.notifications = [];
  });

  test('tasks waiting for LGU verification are not counted as active work', () {
    store.reports = [
      task('A', 'In Progress'),
      task('B', 'In Progress', completion: {
        'state': 'Awaiting Verification',
        'photos': [],
        'at': '2026-10-29T01:00:00Z'
      }),
      task('C', 'In Progress', completion: {
        'state': 'Additional Work Requested',
        'photos': [],
        'at': '2026-10-29T01:00:00Z'
      }),
    ];
    expect(store.activeWork.map((r) => r.id), ['A', 'C']);
    expect(store.submissions.map((r) => r.id), ['B']);
  });

  test('completion form pre-fills only new, real after-photos', () {
    final returned = task('R', 'In Progress', completion: {
      'state': 'Additional Work Requested',
      'at': '2026-10-29T02:00:00.000Z',
      'photos': [photo('/demo-after.svg', demo: true)],
    }, updates: [
      {
        'at': '2026-10-29T01:00:00.000Z',
        'note': 'old',
        'phase': 'Repair',
        'photos': [photo('/uploads/old.png')]
      },
      {
        'at': '2026-10-29T03:00:00.000Z',
        'note': 'new',
        'phase': 'Repair',
        'photos': [
          photo('/uploads/new.png'),
          photo('/uploads/before.png', kind: 'before'),
          photo('/demo-after.svg', demo: true),
        ]
      },
    ]);
    expect(newAfterPhotos(returned).map((p) => p.url), ['/uploads/new.png']);
  });

  test('the unread-indicator setting is saved', () async {
    store.setUnreadPreference(false);
    await Future<void>.delayed(Duration.zero);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('maintenance-notifications'), isFalse);
    store.setUnreadPreference(true);
  });

  test('null photo entries and missing coordinates do not crash parsing', () {
    final r = PotholeReport({
      'id': 'N',
      'status': 'Assigned',
      'location': {'road': 'X', 'coordinates': <String, dynamic>{}},
      'photos': [null, photo('/uploads/a.png')],
    });
    expect(r.photos.length, 1);
    expect(r.coordinates.lat, isA<double>());
  });

  testWidgets('an open screen updates when the store changes (real app routes)',
      (tester) async {
    store.notifications = [
      Notice.fromJson({
        'id': 'n1',
        'reportId': 'PTG-1',
        'title': 'Old notice',
        'at': '2026-10-29T01:00:00Z',
        'read': false
      }),
    ];
    // Phone size: wider windows show the desktop device-frame preview.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const PatagMaintenanceApp());
    // Let the splash screen hand over first.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    // Signed out, the splash goes to login; then sign in and open notifications.
    store.token = 'test-token';
    navigatorKey.currentState!.pushNamed('/notifications');
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Old notice'), findsOneWidget);

    store.notifications = [
      Notice.fromJson({
        'id': 'n2',
        'reportId': 'PTG-2',
        'title': 'New notice',
        'at': '2026-10-29T02:00:00Z',
        'read': false
      }),
    ];
    store.notifyListeners();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('New notice'), findsOneWidget);
    expect(find.text('Old notice'), findsNothing);
    store.timer?.cancel();
  });
}
