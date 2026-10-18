import 'dart:ui';

/// The user's UI-language choice (#220). [system] follows the phone; the
/// others pin the app to one of the supported locales.
enum AppLanguage {
  system(null),
  en('en'),
  ru('ru'),
  et('et');

  const AppLanguage(this.code);

  /// The locale code, or `null` for [system]. This is what's stored in
  /// `shared_preferences` and in `profiles.language`.
  final String? code;

  /// The pinned languages, in the order the sheet lists them.
  static const pinned = [en, ru, et];

  /// The name each language uses for itself; never translated.
  String get nativeName => switch (this) {
    system => '',
    en => 'English',
    ru => 'Русский',
    et => 'Eesti',
  };

  /// Parses a stored value; anything unknown (or `null`) means [system].
  static AppLanguage fromCode(String? code) => switch (code) {
    'en' => en,
    'ru' => ru,
    'et' => et,
    _ => system,
  };
}

/// The supported language a choice resolves to: a pinned choice is itself;
/// [AppLanguage.system] takes the first device locale the app supports and
/// falls back to English.
AppLanguage resolveAppLanguage(AppLanguage choice, List<Locale> deviceLocales) {
  if (choice != AppLanguage.system) return choice;
  for (final locale in deviceLocales) {
    final match = AppLanguage.fromCode(locale.languageCode);
    if (match != AppLanguage.system) return match;
  }
  return AppLanguage.en;
}
