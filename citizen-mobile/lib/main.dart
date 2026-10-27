import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/theme.dart';
import 'core/api.dart';
import 'features/screens.dart';
import 'features/report_map.dart';
import 'features/report_wizard.dart';
import 'shared/widgets/ui.dart';

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
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: Listenable.merge([store, themeController]),
      builder: (context, _) => MaterialApp(
          title: 'PATAG',
          debugShowCheckedModeBanner: false,
          theme: patagTheme(),
          darkTheme: patagTheme(brightness: Brightness.dark),
          themeMode: themeController.mode,
          themeAnimationDuration: PatagTokens.motion,
          initialRoute: '/',
          onGenerateRoute: (settings) {
            final route = settings.name ?? '/';
            final parts = route.split('/');
            Widget screen;
            final protected = route == '/home' ||
                route.startsWith('/report/') ||
                route.startsWith('/reports') ||
                route.startsWith('/profile') ||
                route == '/notifications' ||
                route == '/settings';
            if (protected && store.token == null) {
              screen = const AuthScreen('login');
            } else if (route == '/') {
              screen = const Splash();
            } else if (route == '/onboarding') {
              screen = const Onboarding();
            } else if (route == '/welcome') {
              screen = const Welcome();
            } else if (['/login', '/register', '/forgot-password']
                .contains(route)) {
              screen = AuthScreen(parts.last);
            } else if (route == '/home') {
              screen = const CitizenHome();
            } else if (route == '/report/new') {
              screen = const ReportWizard();
            } else if (route.startsWith('/report/success/')) {
              screen = ReportSuccess(parts.last);
            } else if (route == '/reports') {
              screen = const MyReports();
            } else if (route.startsWith('/reports/') &&
                parts.last == 'feedback') {
              screen = FeedbackScreen(parts[2]);
            } else if (route.startsWith('/reports/')) {
              screen = ReportDetails(parts.last);
            } else if (route == '/map') {
              screen = const PublicMap();
            } else if (route.startsWith('/map/reports/')) {
              screen = ReportDetails(parts.last, public: true);
            } else if (route == '/notifications') {
              screen = const NotificationsScreen();
            } else if (route == '/profile') {
              screen = const ProfileScreen();
            } else if (route == '/profile/edit') {
              screen = const EditProfile();
            } else if (route == '/settings') {
              screen = const SettingsScreen();
            } else if (route == '/help' || route == '/about') {
              screen = InfoScreen(about: route == '/about');
            } else {
              screen = const Screen(
                  title: 'PATAG',
                  body: EmptyState(
                      'Page not found', 'Use the navigation to continue.'));
            }
            return MaterialPageRoute<void>(
                settings: settings, builder: (_) => screen);
          }));
}
