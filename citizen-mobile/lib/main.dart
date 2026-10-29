import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/theme.dart';
import 'core/api.dart';
import 'features/screens.dart';
import 'features/report_map.dart';
import 'features/report_wizard.dart';
import 'shared/widgets/ui.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  store.showUnread = preferences.getBool('notifications') ?? true;
  await themeController.load();
  runApp(const PatagApp());
}

class PatagApp extends StatelessWidget {
  const PatagApp({super.key});
  @override
  Widget build(BuildContext context) {
    // An expired session (401) returns to sign-in from wherever the user is.
    store.onSessionExpired ??= () => navigatorKey.currentState
        ?.pushNamedAndRemoveUntil('/login', (_) => false);
    return AnimatedBuilder(
      animation: Listenable.merge([store, themeController]),
      builder: (context, _) => MaterialApp(
          title: 'PATAG',
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: patagTheme(),
          darkTheme: patagTheme(brightness: Brightness.dark),
          themeMode: themeController.mode,
          themeAnimationDuration: PatagTokens.motion,
          initialRoute: '/',
          onGenerateRoute: (settings) {
            final route = settings.name ?? '/';
            final parts = route.split('/');
            // A builder, not a widget: every store change must build a fresh screen
            // (returning the same instance makes Flutter skip the rebuild).
            late Widget Function() screen;
            final protected = route == '/home' ||
                route.startsWith('/report/') ||
                route.startsWith('/reports') ||
                route.startsWith('/profile') ||
                route == '/notifications' ||
                route == '/settings';
            if (protected && store.token == null) {
              screen = () => AuthScreen('login');
            } else if (route == '/') {
              screen = () => Splash();
            } else if (route == '/onboarding') {
              screen = () => Onboarding();
            } else if (route == '/welcome') {
              screen = () => Welcome();
            } else if (['/login', '/register', '/forgot-password']
                .contains(route)) {
              screen = () => AuthScreen(parts.last);
            } else if (route == '/home') {
              screen = () => CitizenHome();
            } else if (route == '/report/new') {
              screen = () => ReportWizard(
                  initialPin: settings.arguments as LatLng? ??
                      store.takePendingReportPin());
            } else if (route.startsWith('/report/success/')) {
              screen = () => ReportSuccess(parts.last);
            } else if (route == '/reports') {
              screen = () => MyReports();
            } else if (route.startsWith('/reports/') &&
                parts.last == 'feedback') {
              screen = () => FeedbackScreen(parts[2]);
            } else if (route.startsWith('/reports/')) {
              screen = () => ReportDetails(parts.last);
            } else if (route == '/map') {
              screen = () => PublicMap();
            } else if (route.startsWith('/map/reports/')) {
              screen = () => ReportDetails(parts.last, public: true);
            } else if (route == '/notifications') {
              screen = () => NotificationsScreen();
            } else if (route == '/profile') {
              screen = () => ProfileScreen();
            } else if (route == '/profile/edit') {
              screen = () => EditProfile();
            } else if (route == '/settings') {
              screen = () => SettingsScreen();
            } else if (route == '/help' || route == '/about') {
              screen = () => InfoScreen(about: route == '/about');
            } else {
              screen = () => Screen(
                  title: 'PATAG',
                  body: EmptyState(
                      'Page not found', 'Use the navigation to continue.'));
            }
            return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => ListenableBuilder(
                    listenable: store, builder: (_, __) => screen()));
          }));
  }
}
