import 'dart:async';
import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:patag_citizen/app/theme.dart';
import 'package:patag_citizen/core/api.dart';
import 'package:patag_citizen/features/address_autofill.dart';
import 'package:patag_citizen/features/report_wizard.dart';
import 'package:shared_preferences/shared_preferences.dart';

const guinhawa = {
  'road': 'MacArthur Highway',
  'barangay': 'Guinhawa',
  'city': 'Malolos',
  'province': 'Bulacan',
  'source': 'mapbox',
};
const empty = {
  'road': '',
  'barangay': '',
  'city': '',
  'province': '',
  'source': 'none',
};

void main() {
  late List<http.Request> requests;
  late Map<String, String> answer;
  var fail = false;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    requests = [];
    answer = guinhawa;
    fail = false;
    store.token = 'citizen-token';
    store.client = MockClient((request) async {
      requests.add(request);
      if (fail) throw http.ClientException('Connection refused');
      return http.Response(jsonEncode(answer), 200);
    });
  });
  tearDown(() => store.token = null);

  late TextEditingController road, barangay, city, province;
  AddressAutofill make() {
    road = TextEditingController();
    barangay = TextEditingController();
    city = TextEditingController(text: 'Malolos');
    province = TextEditingController(text: 'Bulacan');
    return AddressAutofill(
      road: road,
      barangay: barangay,
      city: city,
      province: province,
      lookup: (lat, lng) => store.reverseGeocode(lat, lng, 'en'),
    );
  }

  test('fills empty fields and the untouched defaults', () {
    fakeAsync((async) {
      answer = {...guinhawa, 'city': 'City of Malolos'};
      final autofill = make();
      autofill.pinMoved(14.8527, 120.8160);
      expect(autofill.state, AutofillState.finding);
      async.elapse(const Duration(milliseconds: 700));

      expect(road.text, 'MacArthur Highway');
      expect(barangay.text, 'Guinhawa');
      expect(city.text, 'City of Malolos');
      expect(province.text, 'Bulacan');
      expect(autofill.state, AutofillState.filled);
      expect(autofill.autoFilled,
          containsAll(['road', 'barangay', 'city', 'province']));

      final request = requests.single;
      expect(request.url.path, endsWith('/api/geocode/reverse'));
      expect(request.url.queryParameters,
          {'lat': '14.852700', 'lng': '120.816000', 'lang': 'en'});
      expect(request.headers['Authorization'], 'Bearer citizen-token');
      autofill.dispose();
    });
  });

  test('never overwrites text the citizen typed', () {
    fakeAsync((async) {
      final autofill = make();
      road.text = 'Paseo del Congreso';
      city.text = 'Calumpit';
      autofill.pinMoved(14.85, 120.81);
      async.elapse(const Duration(milliseconds: 700));

      expect(road.text, 'Paseo del Congreso');
      expect(city.text, 'Calumpit');
      expect(barangay.text, 'Guinhawa');
      expect(autofill.userOwned, containsAll(['road', 'city']));
      expect(autofill.autoFilled, isNot(contains('road')));
      autofill.dispose();
    });
  });

  test('a second pin updates only the fields that were auto-filled', () {
    fakeAsync((async) {
      final autofill = make();
      autofill.pinMoved(14.85, 120.81);
      async.elapse(const Duration(milliseconds: 700));
      expect(barangay.text, 'Guinhawa');

      barangay.text = 'Sumapang Matanda'; // the citizen corrects it
      answer = {
        ...guinhawa,
        'road': 'Paseo del Congreso',
        'barangay': 'San Vicente',
      };
      autofill.pinMoved(14.84, 120.80);
      async.elapse(const Duration(milliseconds: 700));

      expect(road.text, 'Paseo del Congreso');
      expect(barangay.text, 'Sumapang Matanda');
      expect(requests, hasLength(2));
      autofill.dispose();
    });
  });

  test('a failed or empty lookup leaves the fields unchanged', () {
    fakeAsync((async) {
      final autofill = make();
      road.text = 'Typed road';
      fail = true;
      autofill.pinMoved(14.85, 120.81);
      async.elapse(const Duration(milliseconds: 700));
      expect(road.text, 'Typed road');
      expect(barangay.text, '');
      expect(city.text, 'Malolos');
      expect(autofill.state, AutofillState.notFound);

      fail = false;
      answer = empty;
      autofill.pinMoved(14.86, 120.82);
      async.elapse(const Duration(milliseconds: 700));
      expect(road.text, 'Typed road');
      expect(barangay.text, '');
      expect(province.text, 'Bulacan');
      expect(autofill.state, AutofillState.notFound);
      autofill.dispose();
    });
  });

  test('rapid pin moves send one request, for the last pin', () {
    fakeAsync((async) {
      final autofill = make();
      for (var i = 0; i < 5; i++) {
        autofill.pinMoved(14.80 + i / 100, 120.80);
        async.elapse(const Duration(milliseconds: 200));
      }
      expect(requests, isEmpty);
      async.elapse(const Duration(milliseconds: 600));
      expect(requests, hasLength(1));
      expect(requests.single.url.queryParameters['lat'], '14.840000');
      expect(road.text, 'MacArthur Highway');
      autofill.dispose();
    });
  });

  test('a late answer for an older pin is ignored', () {
    fakeAsync((async) {
      final pending = <Completer<Map<String, String>>>[];
      road = TextEditingController();
      barangay = TextEditingController();
      city = TextEditingController();
      province = TextEditingController();
      final autofill = AddressAutofill(
        road: road,
        barangay: barangay,
        city: city,
        province: province,
        lookup: (lat, lng) {
          final completer = Completer<Map<String, String>>();
          pending.add(completer);
          return completer.future;
        },
      );
      autofill.pinMoved(1, 1);
      async.elapse(const Duration(milliseconds: 700));
      autofill.pinMoved(2, 2);
      async.elapse(const Duration(milliseconds: 700));
      expect(pending, hasLength(2));

      pending[1].complete({'road': 'New road'});
      async.flushMicrotasks();
      pending[0].complete({'road': 'Old road'});
      async.flushMicrotasks();
      expect(road.text, 'New road');
      autofill.dispose();
    });
  });

  testWidgets('the report form saves auto-filled values in the draft',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        theme: patagTheme(),
        home: const ReportWizard(initialPin: LatLng(14.8527, 120.8160))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();

    final prefs = await SharedPreferences.getInstance();
    final draft = jsonDecode(prefs.getString('patag-draft')!);
    expect(draft['location']['road'], 'MacArthur Highway');
    expect(draft['location']['barangay'], 'Guinhawa');
    expect(draft['location']['coordinates']['lat'], 14.8527);
    expect(draft['autofilled'], contains('road'));
    expect(requests, hasLength(1));
    // Let the "location set from the map" message time out.
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('the location step shows the note and keeps fields editable',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'patag-draft': jsonEncode({
        'title': '',
        'description': '',
        'hazards': '',
        'severity': 'Medium',
        'photos': [
          {'id': 'p1', 'url': '/demo.png', 'name': 'demo', 'demo': true}
        ],
        'location': {
          'road': '',
          'barangay': '',
          'city': 'Malolos',
          'province': 'Bulacan',
          'landmark': '',
          'coordinates': {'lat': null, 'lng': null},
        },
      }),
    });
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
        theme: patagTheme(),
        home: const ReportWizard(initialPin: LatLng(14.8527, 120.8160))));
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pump();
    expect(find.text('Finding address…'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();

    expect(find.text('Filled from the map — please check it.'), findsOneWidget);
    expect(find.text('MacArthur Highway'), findsOneWidget);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'MacArthur Highway'), 'My road');
    await tester.pump();
    expect(find.text('My road'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });
}
