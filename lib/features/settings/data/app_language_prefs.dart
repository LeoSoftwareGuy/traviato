import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_language.dart';

/// Device-local storage for the UI-language choice (#220), so the app opens
/// in the right language before anyone signs in.
class AppLanguagePrefs {
  const AppLanguagePrefs();

  static const key = 'app_language';
  static const _systemValue = 'system';

  Future<AppLanguage> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return AppLanguage.uiFromCode(prefs.getString(key));
    } catch (_) {
      // Unreadable prefs must never block startup; follow the phone.
      return AppLanguage.system;
    }
  }

  Future<void> write(AppLanguage language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, language.code ?? _systemValue);
  }
}
