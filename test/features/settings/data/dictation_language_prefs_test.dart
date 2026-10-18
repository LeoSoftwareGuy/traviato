import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traviato/features/settings/data/dictation_language_prefs.dart';
import 'package:traviato/features/settings/domain/app_language.dart';

void main() {
  const prefs = DictationLanguagePrefs();

  test('nothing chosen reads as null', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await prefs.read(), isNull);
  });

  test('round-trips under the dictation_language key', () async {
    SharedPreferences.setMockInitialValues({});
    await prefs.write(AppLanguage.ru);
    expect(await prefs.read(), AppLanguage.ru);
    final raw = await SharedPreferences.getInstance();
    expect(raw.getString('dictation_language'), 'ru');
  });
}
