/// App-wide product constants.
library;

abstract class AppConstants {
  /// The user-facing product name (#191). `traviato` is only the codename —
  /// it stays in package names, bundle ids and code identifiers.
  static const appName = 'Storyni';

  /// Custom URL scheme the app is registered for on iOS (`CFBundleURLTypes`)
  /// and Android (intent filter) — #157. Reverse-DNS on the product name; it
  /// need not match the bundle id. Keep the platform files in sync.
  static const authRedirectScheme = 'com.leo.storyni';

  /// Where Supabase's confirmation email sends the user back to. Must also
  /// be allow-listed under Auth → URL Configuration → Redirect URLs (hosted)
  /// and `additional_redirect_urls` in `supabase/config.toml` (local).
  static const authRedirectUrl = '$authRedirectScheme://login-callback';
}
