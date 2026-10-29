import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:patag_citizen/core/api.dart';
import 'package:patag_citizen/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store.client = MockClient((_) async => http.Response('{"ok":true}', 200));
    store.token = 'test-token';
    store.user = {
      'id': 'u',
      'name': 'Old Name',
      'email': 'a@b.test',
      'role': 'citizen'
    };
  });
  tearDown(() {
    store.token = null;
    store.user = null;
  });

  testWidgets('an open screen updates when the store changes (real app routes)',
      (tester) async {
    await tester.pumpWidget(const PatagApp());
    // Let the splash screen hand over to onboarding first.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    navigatorKey.currentState!.pushNamed('/profile');
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.textContaining('Old Name'), findsWidgets);

    store.user = {
      'id': 'u',
      'name': 'New Name',
      'email': 'a@b.test',
      'role': 'citizen'
    };
    store.notifyListeners();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('New Name'), findsWidgets);
    expect(find.textContaining('Old Name'), findsNothing);
  });

  testWidgets('an expired session returns to sign-in', (tester) async {
    store.client = MockClient((request) async => request.url.path
            .endsWith('/health')
        ? http.Response('{"ok":true}', 200)
        : http.Response('{"error":"Session expired. Sign in again."}', 401));
    await tester.pumpWidget(const PatagApp());
    // Let the splash screen hand over to onboarding first.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    navigatorKey.currentState!.pushNamed('/profile');
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    store.pendingReportPin = null;
    await expectLater(store.refresh(), throwsException);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(store.token, isNull);
    expect(find.text('Sign in'), findsWidgets);
  });
}
