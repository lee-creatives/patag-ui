import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/theme.dart';
import 'core/api.dart';
import 'features/screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final prefs = await SharedPreferences.getInstance();
  store.showUnread = prefs.getBool('maintenance-notifications') ?? true;
  await themeController.load();
  runApp(const PatagMaintenanceApp());
}

class PatagMaintenanceApp extends StatelessWidget {
  const PatagMaintenanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([store, themeController]),
      builder: (context, _) => MaterialApp(
        title: 'PATAG Maintenance',
        debugShowCheckedModeBanner: false,
        theme: patagMaintenanceTheme(),
        darkTheme: patagMaintenanceTheme(brightness: Brightness.dark),
        themeMode: themeController.mode,
        themeAnimationDuration: PatagTokens.motion,
        initialRoute: '/',
        builder: (context, child) {
          final dark = Theme.of(context).brightness == Brightness.dark;
          final size = MediaQuery.of(context).size;
          final isWide = size.width > 500;

          if (!isWide) {
            return child ?? const SizedBox();
          }

          // Portrait mobile device frame for desktop/wide browser preview
          final frameHeight = math.min(890.0, math.max(680.0, size.height - 36.0));
          return Container(
            color: dark ? const Color(0xFF090B0E) : const Color(0xFFE4DFD7),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top device frame badge
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'PATAG Crew Mobile · Portrait Phone View',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: dark ? Colors.white70 : const Color(0xFF4A4E57),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                // Phone container
                Container(
                  width: 412,
                  height: frameHeight,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(44),
                    border: Border.all(
                      color: dark ? const Color(0xFF2B303C) : const Color(0xFFD4CDC4),
                      width: 8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.42),
                        blurRadius: 40,
                        spreadRadius: 2,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Positioned.fill(child: child ?? const SizedBox()),
                      // Dynamic Island / Phone top speaker notch
                      Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          margin: const EdgeInsets.only(top: 8),
                          width: 110,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1E293B),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0F172A),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        onGenerateRoute: (settings) {
          final route = settings.name ?? '/';
          final parts = route.split('/');
          Widget screen;

          final protected = route == '/dashboard' ||
              route.startsWith('/assignments') ||
              route == '/map' ||
              route == '/progress' ||
              route.startsWith('/repairs') ||
              route == '/notifications' ||
              route == '/profile';

          if (protected && store.token == null) {
            screen = const MaintenanceLogin();
          } else if (route == '/') {
            screen = const MaintenanceSplash();
          } else if (route == '/welcome') {
            screen = const MaintenanceWelcome();
          } else if (route == '/login') {
            screen = const MaintenanceLogin();
          } else if (route == '/dashboard') {
            screen = const MainShell(initialTab: 0);
          } else if (route == '/assignments') {
            screen = const MainShell(initialTab: 1);
          } else if (route.startsWith('/assignments/')) {
            screen = TaskDetailsScreen(parts.last);
          } else if (route == '/progress') {
            screen = const MainShell(initialTab: 2);
          } else if (route == '/map') {
            screen = const MainShell(initialTab: 3);
          } else if (route.startsWith('/repairs/') && parts.last == 'document') {
            screen = RepairDocumentationScreen(parts[2]);
          } else if (route.startsWith('/repairs/') && parts.last == 'success') {
            screen = SubmissionSuccessScreen(parts[2]);
          } else if (route == '/notifications') {
            screen = const NotificationsScreen();
          } else if (route == '/profile') {
            screen = const MainShell(initialTab: 4);
          } else {
            screen = const MainShell(initialTab: 0);
          }

          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => screen,
          );
        },
      ),
    );
  }
}
