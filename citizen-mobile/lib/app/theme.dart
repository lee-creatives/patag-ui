import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Brand artwork keeps its original navy; interface roles use ColorScheme.
const ink = Color(0xFF182B49), orange = Color(0xFFF26A32);
const paper = Color(0xFFF7F1EB), slate = Color(0xFF626263);
const peach = Color(0xFFFDD3BC), palePeach = Color(0xFFFEE8DD);
const quiet = Color(0xFFF5F5F2), line = Color(0xFFD6DADB);

abstract final class PatagTokens {
  static const double gap = 20, radius = 24, fieldRadius = 16;
  static const Duration motion = Duration(milliseconds: 160);
  static const primaryGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFAA76), Color(0xFFFF7A2F), orange]);
  static const darkGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF333438), Color(0xFF111215)]);
}

class ThemeController extends ChangeNotifier {
  ThemeMode mode = ThemeMode.system;
  Future<void> load() async {
    final saved =
        (await SharedPreferences.getInstance()).getString('patag-theme');
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
    await (await SharedPreferences.getInstance())
        .setString('patag-theme', value.name);
  }

  void toggle(Brightness current) =>
      setMode(current == Brightness.dark ? ThemeMode.light : ThemeMode.dark);
}

final themeController = ThemeController();
ThemeData patagTheme({Brightness brightness = Brightness.light}) {
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
    error: dark ? const Color(0xFFFFAA91) : const Color(0xFF8C3212),
  );
  final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colors,
      fontFamily: 'Montserrat');
  return base.copyWith(
    scaffoldBackgroundColor: dark ? const Color(0xFF101114) : paper,
    textTheme: base.textTheme.copyWith(
      headlineLarge: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 34,
          fontWeight: FontWeight.w600,
          height: 1.15,
          letterSpacing: -1.2,
          color: colors.onSurface),
      headlineMedium: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 28,
          fontWeight: FontWeight.w600,
          height: 1.18,
          letterSpacing: -.8,
          color: colors.onSurface),
      titleLarge: const TextStyle(
          fontFamily: 'Montserrat', fontSize: 20, fontWeight: FontWeight.w600),
      titleMedium: const TextStyle(
          fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 16,
          height: 1.5,
          color: colors.onSurface),
      bodyMedium: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 14,
          height: 1.5,
          color: colors.onSurface),
      bodySmall: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 12,
          height: 1.5,
          color: colors.onSurfaceVariant),
    ),
    appBarTheme: AppBarTheme(
        backgroundColor: colors.surface.withValues(alpha: .94),
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 72),
    inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        labelStyle: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
        hintStyle: TextStyle(color: colors.onSurfaceVariant),
        helperStyle: TextStyle(color: colors.onSurfaceVariant),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colors.outlineVariant)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colors.outlineVariant)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colors.primary, width: 2)),
        contentPadding: const EdgeInsets.all(18)),
    filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            minimumSize: const Size(48, 52),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14,
                fontWeight: FontWeight.w600))),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
            foregroundColor: colors.onSurface,
            minimumSize: const Size(48, 50),
            side: BorderSide(color: colors.outlineVariant),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)))),
    textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
            foregroundColor: colors.onSurface,
            minimumSize: const Size(44, 44),
            textStyle: const TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
                fontSize: 13))),
    iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
            foregroundColor: colors.onSurface,
            minimumSize: const Size(48, 48))),
    cardTheme: CardThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 14),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: colors.outlineVariant))),
    listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        iconColor: colors.onSurface,
        textColor: colors.onSurface,
        minVerticalPadding: 14),
    dividerTheme:
        DividerThemeData(color: colors.outlineVariant, space: 28, thickness: 1),
    chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceContainerHighest,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: TextStyle(color: colors.onSurface, fontSize: 12)),
    dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
    bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)))),
    snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF222328),
        contentTextStyle:
            const TextStyle(fontFamily: 'Montserrat', color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
  );
}
