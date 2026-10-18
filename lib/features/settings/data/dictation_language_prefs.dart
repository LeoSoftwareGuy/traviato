import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_language.dart';

/// Device-local storage for the last-used dictation language (#218).
/// `null` until the user picks one.
class DictationLanguagePrefs {
  const DictationLanguagePrefs();

  static const key = 'dictation_language';

  Future<AppLanguage?> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final language = AppLanguage.fromCode(prefs.getString(key));
      return language == AppLanguage.system ? null : language;
    } catch (_) {
      return null;
    }
  }

  Future<void> write(AppLanguage language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, language.code!);
  }
}
