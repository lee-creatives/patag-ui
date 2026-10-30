import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app language. English by default; the device language is not
/// followed. Saved on this device under [storageKey].
class LocaleController extends ChangeNotifier {
  static const storageKey = 'patag-language';
  static const english = Locale('en'), tagalog = Locale('fil');

  Locale locale = english;

  bool get isTagalog => locale.languageCode == tagalog.languageCode;

  Future<void> load() async {
    String? saved;
    try {
      saved = (await SharedPreferences.getInstance()).getString(storageKey);
    } catch (_) {}
    locale = saved == tagalog.languageCode ? tagalog : english;
    notifyListeners();
  }

  Future<void> setLocale(Locale value) async {
    locale = value.languageCode == tagalog.languageCode ? tagalog : english;
    notifyListeners();
    try {
      await (await SharedPreferences.getInstance())
          .setString(storageKey, locale.languageCode);
    } catch (_) {}
  }
}

final localeController = LocaleController();
