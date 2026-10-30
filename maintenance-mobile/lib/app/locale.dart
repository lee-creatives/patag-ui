import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app language: Tagalog (`fil`) by default, or English. The phone's own
/// language is deliberately ignored; only the crew's choice counts.
class LocaleController extends ChangeNotifier {
  static const storageKey = 'maintenance-language';
  static const tagalog = Locale('fil');
  static const english = Locale('en');
  static const supported = [tagalog, english];

  Locale locale = tagalog;

  bool get isEnglish => locale.languageCode == english.languageCode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(storageKey);
    locale = saved == english.languageCode ? english : tagalog;
    notifyListeners();
  }

  Future<void> setLocale(Locale value) async {
    final next = value.languageCode == english.languageCode ? english : tagalog;
    if (next != locale) {
      locale = next;
      notifyListeners();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, next.languageCode);
  }
}

final localeController = LocaleController();
