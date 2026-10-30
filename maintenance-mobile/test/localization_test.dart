import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:patag_maintenance/app/locale.dart';
import 'package:patag_maintenance/core/api.dart';
import 'package:patag_maintenance/core/models.dart';
import 'package:patag_maintenance/features/screens.dart';
import 'package:patag_maintenance/l10n/l10n.dart';
import 'package:patag_maintenance/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_app.dart';

final en = lookupAppLocalizations(const Locale('en'));
final fil = lookupAppLocalizations(const Locale('fil'));

Map<String, dynamic> readArb(String name) =>
    jsonDecode(File('lib/l10n/$name').readAsStringSync())
        as Map<String, dynamic>;

/// Placeholder names used in an ARB message, including inside plurals.
Set<String> placeholdersOf(String message) => RegExp(r'\{(\w+)(?=[,}])')
    .allMatches(message)
    .map((m) => m.group(1)!)
    .toSet();

Map<String, dynamic> report(String id, String status,
        {Map<String, dynamic>? completion}) =>
    {
      'id': id,
      'title': 'Pothole $id',
      'status': status,
      'severity': 'High',
      'teamId': 'team-1',
      'location': {
        'road': 'Paseo del Congreso',
        'barangay': 'Catmon',
        'city': 'Malolos',
        'province': 'Bulacan',
        'coordinates': {'lat': 14.852, 'lng': 120.814},
      },
      'photos': [],
      'updates': [],
      'history': [],
      'completion': completion,
      'assignment': {
        'teamId': 'team-1',
        'priority': 'High',
        'note': 'Deploy hot mix asphalt patch.',
        'targetDate': '2026-10-30',
        'at': '2026-10-24T08:00:00Z',
      },
    };

void seedStore() {
  store.token = 'test-token';
  store.user = const User(
    id: 'user-1',
    name: 'Mika Santos',
    email: 'crew@example.test',
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
    PotholeReport(report('PTG-1', 'Assigned')),
    PotholeReport(report('PTG-2', 'In Progress')),
    PotholeReport(report('PTG-3', 'In Progress', completion: {
      'state': 'Additional Work Requested',
      'note': 'Patched.',
      'photos': [],
      'at': '2026-10-27T01:00:00.000Z',
    })),
    PotholeReport(report('PTG-4', 'Resolved')),
  ];
  store.notifications = [
    Notice.fromJson({
      'id': 'n1',
      'reportId': 'PTG-1',
      'title': 'PTG-1 assigned to Road Crew Alpha',
      'at': '2026-10-29T01:00:00Z',
      'read': false,
    }),
  ];
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await localeController.load();
    // No real server: the sign-in screen's health check gets a mocked answer.
    store.client = MockClient((_) async => http.Response('{"ok":true}', 200));
  });
  tearDown(() {
    store.token = null;
    store.user = null;
    store.team = null;
    store.reports = [];
    store.notifications = [];
    store.timer?.cancel();
  });

  group('ARB files', () {
    final enArb = readArb('app_en.arb');
    final filArb = readArb('app_fil.arb');
    Iterable<String> keys(Map<String, dynamic> arb) =>
        arb.keys.where((k) => !k.startsWith('@'));

    test('every key exists in both languages', () {
      expect(keys(filArb).toSet().difference(keys(enArb).toSet()), isEmpty,
          reason: 'keys only in app_fil.arb');
      expect(keys(enArb).toSet().difference(keys(filArb).toSet()), isEmpty,
          reason: 'keys only in app_en.arb');
    });

    test('placeholders match between languages', () {
      for (final key in keys(enArb)) {
        final enMessage = enArb[key] as String;
        final filMessage = filArb[key] as String;
        expect(placeholdersOf(filMessage), placeholdersOf(enMessage),
            reason: key);
        final declared =
            ((enArb['@$key'] as Map?)?['placeholders'] as Map?)?.keys.toSet() ??
                <String>{};
        expect(placeholdersOf(enMessage), declared, reason: '@$key');
      }
    });

    test('brand Taglish lines are identical in both languages', () {
      expect(fil.brandEveryPothole, en.brandEveryPothole);
      expect(fil.brandFastRepair, en.brandFastRepair);
      expect(fil.brandWorkOrdersReady, en.brandWorkOrdersReady);
      expect(fil.languageSettingTitle, 'Wika / Language');
      expect(en.languageSettingTitle, 'Wika / Language');
    });
  });

  group('translation helpers', () {
    test('API status and severity values get display text only', () {
      expect(statusLabel(fil, 'In Progress'), fil.statusInProgress);
      expect(statusLabel(en, 'In Progress'), 'In Progress');
      expect(statusLabel(fil, 'Awaiting Verification'),
          fil.statusAwaitingVerification);
      expect(statusLabel(fil, 'Something New'), 'Something New');
      expect(severityLabel(fil, 'High'), fil.severityHigh);
      expect(severityLabel(fil, 'low'), fil.severityLow);
    });

    test('known backend errors are translated, unknown ones pass through', () {
      const known = PatagException(PatagErrorKind.server,
          serverMessage: 'Email or password is incorrect for this portal.');
      expect(errorText(fil, known), fil.errorBadCredentials);
      expect(errorText(en, known), known.serverMessage);
      expect(errorText(fil, Exception('Session expired. Sign in again.')),
          fil.errorSessionExpired);
      expect(translateServerMessage(fil, 'Invalid image or file exceeds 8 MB.'),
          fil.errorPhotoTooLarge);
      expect(translateServerMessage(fil, 'A brand new server message.'),
          'A brand new server message.');
      // Local errors keep English for logs and translate on screen.
      const timeout = PatagException(PatagErrorKind.timeout);
      expect(PatagMaintenanceStore.clean(timeout), en.errorTimeout);
      expect(errorText(fil, timeout), fil.errorTimeout);
      expect(
          errorText(
              fil,
              const PatagException(PatagErrorKind.serverUnavailable,
                  statusCode: 502)),
          contains('502'));
    });
  });

  group('language setting', () {
    test('defaults to Tagalog and reloads a saved choice', () async {
      expect(localeController.locale, LocaleController.tagalog);
      SharedPreferences.setMockInitialValues({'maintenance-language': 'en'});
      await localeController.load();
      expect(localeController.locale, LocaleController.english);
    });

    testWidgets('the app starts in Tagalog even on an English phone',
        (tester) async {
      tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const PatagMaintenanceApp());
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text(fil.loginWelcome), findsOneWidget);
      expect(find.text(en.loginWelcome), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'switching to English on the sign-in screen updates text at once and is saved',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const PatagMaintenanceApp());
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text(fil.loginHeroTitle), findsOneWidget);

      await tester.tap(find.text('English'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Safer roads start here.'), findsOneWidget);
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text(fil.loginHeroTitle), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('maintenance-language'), 'en');

      await tester.tap(find.text('Tagalog'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(fil.loginWelcome), findsOneWidget);
      expect(prefs.getString('maintenance-language'), 'fil');
      expect(tester.takeException(), isNull);
    });

    testWidgets('the Wika / Language setting in Profile switches the app',
        (tester) async {
      seedStore();
      tester.view.physicalSize = const Size(360, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(testApp(const ProfileTab(), locale: null));
      await tester.pump();
      expect(find.text('Wika / Language'), findsOneWidget);
      expect(find.text(fil.profileTitle), findsOneWidget);

      await tester.tap(find.text('English'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Profile & Settings'), findsOneWidget);
      expect(find.text('Wika / Language'), findsOneWidget);
      expect(localeController.locale, LocaleController.english);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('maintenance-language'), 'en');
    });
  });

  group('key screens fit a 360 px phone', () {
    for (final locale in LocaleController.supported) {
      final screens = <String, Widget Function()>{
        'login': () => const MaintenanceLogin(),
        'welcome': () => const MaintenanceWelcome(),
        'dashboard': () => const DashboardTab(),
        'assignments': () => const AssignmentsTab(),
        'in progress': () => const InProgressTab(),
        'assigned task details': () => const TaskDetailsScreen('PTG-1'),
        'in-progress task details': () => const TaskDetailsScreen('PTG-2'),
        'returned task details': () => const TaskDetailsScreen('PTG-3'),
        'resolved task details': () => const TaskDetailsScreen('PTG-4'),
        'repair documentation': () => const RepairDocumentationScreen('PTG-2'),
        'submission success': () => const SubmissionSuccessScreen('PTG-2'),
        'notifications': () => const NotificationsScreen(),
        'profile': () => const ProfileTab(),
      };
      for (final entry in screens.entries) {
        testWidgets('${entry.key} in ${locale.languageCode}', (tester) async {
          seedStore();
          tester.view.physicalSize = const Size(360, 2400);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(testApp(entry.value(), locale: locale));
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('task details show Tagalog text and a localized date',
        (tester) async {
      seedStore();
      tester.view.physicalSize = const Size(360, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(testApp(const TaskDetailsScreen('PTG-1'),
          locale: const Locale('fil')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(fil.progressTitle), findsOneWidget);
      expect(find.text(fil.startRepair), findsOneWidget);
      expect(find.text(fil.statusAssigned), findsOneWidget);
      expect(find.text(fil.severityHigh.toUpperCase()), findsOneWidget);
      expect(find.textContaining('2026'), findsOneWidget);
      expect(find.textContaining('2026-10-30'), findsNothing);
    });
  });
}
