import 'package:shared_preferences/shared_preferences.dart';

/// Device-local storage for the You → Settings "Reduce flashing" switch
/// (#363). Off until the user turns it on.
class ReduceFlashingPrefs {
  const ReduceFlashingPrefs();

  static const key = 'reduce_flashing';

  Future<bool> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key) ?? false;
    } catch (_) {
      // Unreadable prefs must never block startup.
      return false;
    }
  }

  Future<void> write({required bool enabled}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, enabled);
  }
}
