import 'package:flutter/material.dart';
import 'package:patag_maintenance/app/locale.dart';
import 'package:patag_maintenance/app/theme.dart';
import 'package:patag_maintenance/l10n/app_localizations.dart';

/// A localized MaterialApp for widget tests. Existing tests use English
/// explicitly (the app default is Tagalog); pass `locale: null` to follow
/// [localeController] like the real app does.
Widget testApp(
  Widget home, {
  Locale? locale = const Locale('en'),
  Map<String, WidgetBuilder> routes = const {},
}) =>
    ListenableBuilder(
      listenable: localeController,
      builder: (_, __) => MaterialApp(
        theme: patagMaintenanceTheme(),
        locale: locale ?? localeController.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        routes: routes,
        home: home,
      ),
    );
