import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:patag_citizen/core/api.dart';
import 'package:patag_citizen/shared/widgets/ui.dart';

void main() {
  var serverUp = false;
  setUp(() {
    serverUp = false;
    store.client = MockClient((request) async {
      expect(request.url.path, endsWith('/api/health'));
      if (!serverUp) throw http.ClientException('Connection refused');
      return http.Response('{"ok":true,"mode":"supabase"}', 200);
    });
  });

  Widget screen() =>
      const MaterialApp(home: Scaffold(body: ServerStatusBanner()));

  testWidgets('explains an unreachable server and recovers on Retry',
      (tester) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    expect(find.textContaining("Can't reach the PATAG server"), findsOneWidget);
    // Debug builds also show which URL the app is using.
    expect(find.textContaining('/api'), findsOneWidget);

    serverUp = true;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.textContaining("Can't reach the PATAG server"), findsNothing);
    expect(store.serverProblem, isNull);
  });

  testWidgets('shows nothing when the server answers', (tester) async {
    serverUp = true;
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    expect(find.byType(Text), findsNothing);
  });
}
