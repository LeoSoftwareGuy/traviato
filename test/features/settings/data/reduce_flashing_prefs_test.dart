import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traviato/features/settings/data/reduce_flashing_prefs.dart';

void main() {
  const prefs = ReduceFlashingPrefs();

  test('is off until the user turns it on', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await prefs.read(), isFalse);
  });

  test('remembers the choice', () async {
    SharedPreferences.setMockInitialValues({});
    await prefs.write(enabled: true);
    expect(await prefs.read(), isTrue);
    await prefs.write(enabled: false);
    expect(await prefs.read(), isFalse);
  });
}
