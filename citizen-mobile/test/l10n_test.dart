import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:patag_citizen/app/locale.dart';
import 'package:patag_citizen/app/theme.dart';
import 'package:patag_citizen/core/api.dart';
import 'package:patag_citizen/core/errors.dart';
import 'package:patag_citizen/features/report_wizard.dart';
import 'package:patag_citizen/features/screens.dart';
import 'package:patag_citizen/l10n/l10n.dart';
import 'package:patag_citizen/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> arb(String name) =>
    jsonDecode(File('lib/l10n/$name').readAsStringSync())
        as Map<String, dynamic>;

/// Placeholder names used in an ICU message, e.g. {count} or {count, plural…}.
Set<String> placeholders(String message) => RegExp(r'\{(\w+)[,}]')
    .allMatches(message)
    .map((match) => match.group(1)!)
    .where((name) => int.tryParse(name) == null)
    .toSet();

Future<void> pumpFrames(WidgetTester tester, [int count = 8]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    SharedPreferences.setMockInitialValues({'onboarded': true});
    store.client = MockClient((_) async => http.Response('{"ok":true}', 200));
    store.token = null;
    store.user = null;
    localeController.locale = LocaleController.english;
  });
  tearDown(() {
    binding.platformDispatcher.clearAccessibilityFeaturesTestValue();
    localeController.locale = LocaleController.english;
  });

  group('ARB files', () {
    final en = arb('app_en.arb'), fil = arb('app_fil.arb');
    Iterable<String> keys(Map<String, dynamic> file) =>
        file.keys.where((key) => !key.startsWith('@'));

    test('have the same keys', () {
      expect(keys(fil).toSet().difference(keys(en).toSet()), isEmpty,
          reason: 'keys only in app_fil.arb');
      expect(keys(en).toSet().difference(keys(fil).toSet()), isEmpty,
          reason: 'keys only in app_en.arb');
    });

    test('use the same placeholders', () {
      for (final key in keys(en)) {
        final declared =
            ((en['@$key'] as Map?)?['placeholders'] as Map?)?.keys.toSet() ??
                <String>{};
        expect(placeholders(en[key]), declared, reason: 'en $key');
        expect(placeholders(fil[key]), declared, reason: 'fil $key');
      }
    });

    test('keep the Taglish brand lines identical', () {
      for (final key in [
        'brandTagline',
        'brandHomeQuestion',
        'brandSuccessHeading',
        'brandReportTitle',
        'brandWelcomeHeadline',
        'brandSignInHeading',
        'brandOnboardingTitle',
        'brandAboutHeading',
      ]) {
        expect(fil[key], en[key], reason: key);
      }
      expect(en['homeCallToAction'], startsWith('I-tag mo na.'));
      expect(fil['homeCallToAction'], startsWith('I-tag mo na.'));
    });
  });

  test('statuses and severities stay English API values with display labels',
      () {
    final fil = lookupAppLocalizations(LocaleController.tagalog);
    expect(apiValueLabel(englishL10n, 'Under Review'), 'Under Review');
    expect(apiValueLabel(fil, 'Under Review'), 'Sinusuri');
    expect(apiValueLabel(fil, 'High'), 'Mataas');
    expect(apiValueLabel(fil, 'Something new'), 'Something new');
  });

  test('known server errors are translated; others show the server text', () {
    final fil = lookupAppLocalizations(LocaleController.tagalog);
    PatagException server(String text) =>
        PatagException(PatagErrorKind.server, serverMessage: text);
    expect(describeError(fil, server('Session expired. Sign in again.')),
        fil.errSessionExpired);
    expect(
        describeError(
            fil, server('Email or password is incorrect for this portal.')),
        fil.errWrongPassword);
    expect(
        describeError(
            fil, server('Too many attempts. Wait a minute and try again.')),
        fil.errTooManyAttempts);
    expect(describeError(fil, server('Choose a PNG, JPEG or WebP image.')),
        fil.errPhotoType);
    expect(describeError(fil, server('Invalid image or file exceeds 8 MB.')),
        fil.errPhotoTooLarge);
    expect(describeError(fil, const PatagException(PatagErrorKind.timeout)),
        fil.errTimeout);
    expect(describeError(fil, server('A brand new problem.')),
        'A brand new problem.');
    // English text is unchanged for existing callers.
    expect(PatagStore.clean(const PatagException(PatagErrorKind.unreachable)),
        startsWith('Cannot reach PATAG.'));
  });

  testWidgets('the app starts in English and ignores the device language',
      (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('fil')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await localeController.load();
    await tester.pumpWidget(const PatagApp());
    await pumpFrames(tester);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Create an account'), findsOneWidget);
    expect(Localizations.localeOf(tester.element(find.text('Sign in'))),
        const Locale('en'));
  });

  testWidgets(
      'switching to Tagalog on sign-in updates the screen and is remembered',
      (tester) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await localeController.load();
    await tester.pumpWidget(const PatagApp());
    await pumpFrames(tester);
    navigatorKey.currentState!.pushNamed('/login');
    await pumpFrames(tester);
    expect(find.text('Tuloy po. Welcome back.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);

    await tester.tap(find.byTooltip('Language / Wika'));
    await pumpFrames(tester);
    await tester
        .tap(find.widgetWithText(CheckedPopupMenuItem<Locale>, 'Tagalog'));
    await pumpFrames(tester);

    // Updated at once, no restart; the brand line stays the same.
    expect(find.widgetWithText(FilledButton, 'Mag-sign in'), findsOneWidget);
    expect(find.text('Tuloy po. Welcome back.'), findsOneWidget);
    expect(find.text('Gumawa ng account'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('patag-language'), 'fil');

    // A fresh start keeps Tagalog.
    final restarted = LocaleController();
    await restarted.load();
    expect(restarted.locale, LocaleController.tagalog);
    await tester.pumpWidget(const SizedBox());
    localeController.locale = LocaleController.english;
    await localeController.load();
    await tester.pumpWidget(const PatagApp());
    await pumpFrames(tester);
    expect(find.text('Mag-sign in'), findsOneWidget);
    expect(find.text('Sign in'), findsNothing);
  });

  testWidgets('the Settings language choice applies immediately',
      (tester) async {
    await tester.pumpWidget(ListenableBuilder(
        listenable: localeController,
        builder: (context, _) => MaterialApp(
            theme: patagTheme(),
            locale: localeController.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const SettingsScreen())));
    await tester.pumpAndSettle();
    expect(find.text('Language / Wika'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('language-setting')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tagalog').last);
    await tester.pumpAndSettle();

    expect(find.text('Language / Wika'), findsOneWidget);
    expect(find.text('Itsura'), findsOneWidget);
    expect(find.text('Piliin ang wika ng app.'), findsOneWidget);
    expect(localeController.locale, LocaleController.tagalog);
    expect((await SharedPreferences.getInstance()).getString('patag-language'),
        'fil');
    expect(tester.takeException(), isNull);
  });

  final screens = <String, Widget Function()>{
    'home': () => const CitizenHome(),
    'report wizard': () => const ReportWizard(),
    'settings': () => const SettingsScreen(),
    'sign-in': () => const AuthScreen('login'),
    'registration': () => const AuthScreen('register'),
  };
  for (final locale in [LocaleController.english, LocaleController.tagalog]) {
    for (final entry in screens.entries) {
      testWidgets(
          '${entry.key} fits 360 px in ${locale.languageCode} with large text',
          (tester) async {
        tester.view.physicalSize = const Size(360, 780);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(MaterialApp(
            theme: patagTheme(),
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.3)),
                child: child!),
            home: entry.value()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final l = lookupAppLocalizations(locale);
        final expected = switch (entry.key) {
          'home' => l.reportAPothole,
          'report wizard' => l.takePhoto,
          'settings' => l.appearance,
          'sign-in' => l.forgotPassword,
          _ => l.signupStepAbout,
        };
        expect(find.textContaining(expected), findsWidgets);
      });
    }
  }
}
