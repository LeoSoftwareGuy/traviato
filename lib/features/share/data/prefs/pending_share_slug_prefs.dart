import 'package:shared_preferences/shared_preferences.dart';

/// Device-local storage for the deferred deep link (#310): the slug of the
/// shared memory someone arrived from, kept across sign-up / log-in until
/// its preview has been shown signed in.
class PendingShareSlugPrefs {
  const PendingShareSlugPrefs();

  static const key = 'pending_share_slug';

  /// Set once the Android install referrer has been read (first launch).
  static const referrerCheckedKey = 'share_install_referrer_checked';

  /// Set once the iOS "Opening a shared memory?" card has been offered.
  static const pasteOfferedKey = 'share_paste_offered';

  Future<String?> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (_) {
      // Unreadable prefs must never block startup.
      return null;
    }
  }

  Future<void> write(String? slug) async {
    final prefs = await SharedPreferences.getInstance();
    if (slug == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, slug);
    }
  }

  /// Returns whether [flagKey] was already set, and sets it.
  Future<bool> testAndSet(String flagKey) async {
    final prefs = await SharedPreferences.getInstance();
    final wasSet = prefs.getBool(flagKey) ?? false;
    if (!wasSet) await prefs.setBool(flagKey, true);
    return wasSet;
  }
}
