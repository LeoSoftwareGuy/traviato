import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traviato/features/settings/data/app_language_prefs.dart';
import 'package:traviato/features/settings/domain/app_language.dart';

void main() {
  const prefs = AppLanguagePrefs();

  test('nothing stored reads as System default', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await prefs.read(), AppLanguage.system);
  });

  test('every UI choice survives a write/read round trip', () async {
    for (final language in [AppLanguage.system, ...AppLanguage.uiLanguages]) {
      SharedPreferences.setMockInitialValues({});
      await prefs.write(language);
      expect(await prefs.read(), language);
    }
  });

  test(
    'an Estonian choice saved before #245 reads as System default',
    () async {
      SharedPreferences.setMockInitialValues({'app_language': 'et'});
      expect(await prefs.read(), AppLanguage.system);
    },
  );

  test('stores under the app_language key', () async {
    SharedPreferences.setMockInitialValues({});
    await prefs.write(AppLanguage.ru);
    final raw = await SharedPreferences.getInstance();
    expect(raw.getString('app_language'), 'ru');
  });
}
