import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:patag_maintenance/core/api.dart';

const _user = {
  'id': 'maintenance-1',
  'name': 'Mika Santos',
  'email': 'crew@example.test',
  'role': 'maintenance',
  'teamId': 'team-1',
  'active': true,
};

Map<String, dynamic> _report(String status,
        {Map<String, dynamic>? completion}) =>
    {
      'id': 'PTG-2026-0104',
      'title': 'Pothole on Mabini Street',
      'status': status,
      'severity': 'High',
      'teamId': 'team-1',
      'location': {
        'road': 'Mabini Street',
        'barangay': 'Mojon',
        'city': 'Malolos',
        'province': 'Bulacan',
        'coordinates': {'lat': 14.8562, 'lng': 120.8047},
      },
      'photos': [],
      'history': [],
      'updates': [],
      'completion': completion,
    };

/// A fake PATAG API that records every request.
class FakeApi {
  final requests = <http.Request>[];
  String status = 'Assigned';
  Map<String, dynamic>? completion;
  int eventStatus = 200;
  String eventError =
      'This action is not allowed from the current report status.';
  int bootstrapStatus = 200;

  late final client = MockClient((request) async {
    requests.add(request);
    final path = request.url.path.replaceFirst('/api', '');
    if (path == '/auth/login') {
      final body = jsonDecode(request.body) as Map;
      if (body['password'] != 'Correct-Password-123') {
        return _json(
            401, {'error': 'Email or password is incorrect for this portal.'});
      }
      return _json(200, {'token': 'real-token', 'user': _user});
    }
    if (path == '/bootstrap') {
      if (bootstrapStatus != 200) {
        return _json(
            bootstrapStatus, {'error': 'Session expired. Sign in again.'});
      }
      return _json(200, {
        'reports': [_report(status, completion: completion)],
        'notifications': [
          {
            'id': 'n-1',
            'reportId': 'PTG-2026-0104',
            'title': 'PTG-2026-0104 assigned to Road Crew Alpha',
            'at': '2026-10-27T01:00:00.000Z',
            'read': false
          },
        ],
        'teams': [
          {
            'id': 'team-1',
            'name': 'Road Crew Alpha',
            'members': ['Mika Santos'],
            'active': true
          },
        ],
        'user': _user,
      });
    }
    if (path.endsWith('/events')) {
      if (eventStatus != 200) return _json(eventStatus, {'error': eventError});
      final action = (jsonDecode(request.body) as Map)['action'];
      if (action == 'start') status = 'In Progress';
      if (action == 'complete') {
        completion = {
          'state': 'Awaiting Verification',
          'note': 'Done',
          'photos': [],
          'at': ''
        };
      }
      return _json(200, _report(status, completion: completion));
    }
    if (path == '/notifications/read') return _json(200, {'ok': true});
    if (path == '/uploads') {
      return _json(201, {
        'id': 'u-1',
        'url': '/uploads/0b7d6a52-3c1e-4e5f-9a2b-7c8d9e0f1a2b.png',
        'name': 'photo.png',
        'kind': 'before'
      });
    }
    return _json(404, {'error': 'Endpoint not found.'});
  });

  static http.Response _json(int status, Object body) =>
      http.Response(jsonEncode(body), status,
          headers: {'content-type': 'application/json'});

  List<Map<String, dynamic>> bodiesFor(String suffix) => requests
      .where((r) => r.url.path.endsWith(suffix))
      .map((r) => Map<String, dynamic>.from(jsonDecode(r.body) as Map))
      .toList();
}

void main() {
  late FakeApi api;
  late PatagMaintenanceStore store;

  setUp(() {
    api = FakeApi();
    store = PatagMaintenanceStore(client: api.client);
  });
  tearDown(() => store.timer?.cancel());

  test('a wrong password shows the server error and creates no session',
      () async {
    await expectLater(
      store.authenticate('crew@example.test', 'wrong'),
      throwsA(predicate(
          (e) => PatagMaintenanceStore.clean(e!).contains('incorrect'))),
    );
    expect(store.token, isNull);
    expect(store.reports, isEmpty);
    expect(api.bodiesFor('/auth/login').single['role'], 'maintenance');
  });

  test('login loads team-scoped work from the server', () async {
    await store.authenticate('crew@example.test', 'Correct-Password-123');
    expect(store.token, 'real-token');
    expect(store.team?.name, 'Road Crew Alpha');
    expect(store.newAssignments.single.id, 'PTG-2026-0104');
    expect(store.notifications.single.read, isFalse);
  });

  test('event() sends contract action names and bodies', () async {
    await store.authenticate('crew@example.test', 'Correct-Password-123');
    final photo = {
      'id': 'u-1',
      'url': '/uploads/0b7d6a52-3c1e-4e5f-9a2b-7c8d9e0f1a2b.png',
      'name': 'before.png',
      'kind': 'before'
    };

    await store.event('PTG-2026-0104', 'before-photos', payload: {
      'photos': [photo]
    });
    await store.event('PTG-2026-0104', 'start', payload: {'note': 'On site.'});
    expect(store.activeWork.single.id, 'PTG-2026-0104');
    await store.event('PTG-2026-0104', 'complete', payload: {
      'note': 'Patched.',
      'photos': [photo]
    });

    final events = api.bodiesFor('/events');
    expect(
        events.map((e) => e['action']), ['before-photos', 'start', 'complete']);
    expect(events[0]['photos'], [photo]);
    expect(events[2]['note'], 'Patched.');
    expect(
        api.requests
            .where((r) => r.url.path.endsWith('/events'))
            .every((r) => r.headers['Authorization'] == 'Bearer real-token'),
        isTrue);
    // Completion leaves the task In Progress until the LGU verifies it.
    expect(store.getReportById('PTG-2026-0104')!.status, 'In Progress');
    expect(store.submissions.single.completion!.state, 'Awaiting Verification');
  });

  test(
      'a failed event throws the server message and leaves local state unchanged',
      () async {
    await store.authenticate('crew@example.test', 'Correct-Password-123');
    api.eventStatus = 409;
    await expectLater(
      store.event('PTG-2026-0104', 'complete',
          payload: {'note': 'x', 'photos': []}),
      throwsA(
          predicate((e) => PatagMaintenanceStore.clean(e!) == api.eventError)),
    );
    final report = store.getReportById('PTG-2026-0104')!;
    expect(report.status, 'Assigned');
    expect(report.completion, isNull);
  });

  test('a 401 clears the session and reports it', () async {
    await store.authenticate('crew@example.test', 'Correct-Password-123');
    var expired = false;
    store.onSessionExpired = () => expired = true;
    api.bootstrapStatus = 401;
    await expectLater(store.refresh(), throwsException);
    expect(store.token, isNull);
    expect(store.reports, isEmpty);
    expect(expired, isTrue);
  });

  test('server errors surface as networkError instead of fake data', () async {
    await store.authenticate('crew@example.test', 'Correct-Password-123');
    api.bootstrapStatus = 500;
    await expectLater(store.refresh(), throwsException);
    expect(store.networkError, isNotNull);
    expect(store.reports.single.id, 'PTG-2026-0104');
  });

  test('markRead sends the notification id', () async {
    await store.authenticate('crew@example.test', 'Correct-Password-123');
    await store.markRead('n-1');
    await store.markRead('all');
    expect(api.bodiesFor('/notifications/read').map((b) => b['id']),
        ['n-1', 'all']);
  });

  test('uploads reject unsupported types before contacting the server',
      () async {
    await store.authenticate('crew@example.test', 'Correct-Password-123');
    final gif = XFile.fromData(Uint8List.fromList([71, 73, 70, 56]),
        name: 'photo.gif', path: 'photo.gif');
    await expectLater(
        store.upload(gif),
        throwsA(predicate((e) =>
            PatagMaintenanceStore.clean(e!).contains('JPEG, PNG or WebP'))));
    expect(api.requests.where((r) => r.url.path.endsWith('/uploads')), isEmpty);

    final png = XFile.fromData(
        Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]),
        name: 'photo.png',
        path: 'photo.png');
    final uploaded = await store.upload(png, kind: 'before');
    expect(uploaded['url'], startsWith('/uploads/'));
    expect(api.bodiesFor('/uploads').single['data'],
        startsWith('data:image/png;base64,'));
  });

  test('photoUrl resolves API photo paths', () {
    expect(PatagMaintenanceStore.photoUrl('/uploads/a.png'),
        endsWith('/api/uploads/a.png'));
  });
}
