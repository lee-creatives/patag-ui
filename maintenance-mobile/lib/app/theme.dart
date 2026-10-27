import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const ink = Color(0xFF182B49), orange = Color(0xFFF26A32);
const paper = Color(0xFFF7F1EB), slate = Color(0xFF626263);
const peach = Color(0xFFFDD3BC), palePeach = Color(0xFFFEE8DD);
const quiet = Color(0xFFF5F5F2), line = Color(0xFFD6DADB);
const crewAmber = Color(0xFFE58A1F), crewGreen = Color(0xFF247B50);
const crewRed = Color(0xFFB6471C);

abstract final class PatagTokens {
  static const double gap = 20, radius = 24, fieldRadius = 16;
  static const Duration motion = Duration(milliseconds: 160);
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFAA76), Color(0xFFFF7A2F), orange],
  );
  static const darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF333438), Color(0xFF111215)],
  );
  static const crewGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1F3559), Color(0xFF142035)],
  );
}

class ThemeController extends ChangeNotifier {
  ThemeMode mode = ThemeMode.system;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('patag-maintenance-theme');
    mode = saved == 'dark'
        ? ThemeMode.dark
        : saved == 'light'
            ? ThemeMode.light
            : ThemeMode.system;
    notifyListeners();
  }

  Future<void> setMode(ThemeMode value) async {
    mode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('patag-maintenance-theme', value.name);
  }

  void toggle(Brightness current) =>
      setMode(current == Brightness.dark ? ThemeMode.light : ThemeMode.dark);
}

final themeController = ThemeController();

ThemeData patagMaintenanceTheme({Brightness brightness = Brightness.light}) {
  final dark = brightness == Brightness.dark;
  final colors =
      ColorScheme.fromSeed(seedColor: orange, brightness: brightness).copyWith(
    primary: dark ? const Color(0xFFFFAA76) : ink,
    onPrimary: dark ? const Color(0xFF20180F) : Colors.white,
    secondary: orange,
    surface: dark ? const Color(0xFF1B1C20) : Colors.white,
    onSurface: dark ? const Color(0xFFF8F8F8) : const Color(0xFF171717),
    onSurfaceVariant: dark ? const Color(0xFFB5B5BE) : slate,
    surfaceContainerHighest:
        dark ? const Color(0xFF26272C) : const Color(0xFFF0EBE5),
    outlineVariant: dark ? const Color(0xFF35363B) : const Color(0xFFE5DFD8),
    error: dark ? const Color(0xFFFFAA91) : crewRed,
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colors,
    fontFamily: 'Montserrat',
  );
  return base.copyWith(
    scaffoldBackgroundColor: dark ? const Color(0xFF101114) : paper,
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? const Color(0xFF101114) : paper,
      foregroundColor: colors.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      toolbarHeight: 68,
    ),
    textTheme: base.textTheme.copyWith(
      headlineLarge: TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -1.0,
        color: colors.onSurface,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 26,
        fontWeight: FontWeight.w600,
        height: 1.18,
        letterSpacing: -.7,
        color: colors.onSurface,
      ),
      titleLarge: const TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: const TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 15,
        height: 1.5,
        color: colors.onSurface,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 14,
        height: 1.5,
        color: colors.onSurface,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 12,
        height: 1.4,
        color: colors.onSurfaceVariant,
      ),
    ),
    cardTheme: CardThemeData(
      color: colors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PatagTokens.radius),
        side: BorderSide(color: colors.outlineVariant),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF22242A) : quiet,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(PatagTokens.fieldRadius),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(PatagTokens.fieldRadius),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(PatagTokens.fieldRadius),
        borderSide: const BorderSide(color: orange, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PatagTokens.fieldRadius),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.onSurface,
        minimumSize: const Size(48, 42),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        side: BorderSide(color: colors.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PatagTokens.fieldRadius),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w500,
          fontSize: 13.5,
        ),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: colors.surface,
      selectedColor: orange,
      side: BorderSide(color: colors.outlineVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      labelStyle: TextStyle(
        color: colors.onSurface,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    ),
  );
}
