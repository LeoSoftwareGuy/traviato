import 'dart:ui';

/// A language the app knows (#220). As a UI choice, [system] follows the
/// phone and the others pin the app to a locale — but only [en] and [ru]
/// are UI languages: Estonian users read the app in English (#245), so
/// [et] exists for dictation only.
enum AppLanguage {
  system(null),
  en('en'),
  ru('ru'),
  et('et');

  const AppLanguage(this.code);

  /// The locale code, or `null` for [system]. This is what's stored in
  /// `shared_preferences` and in `profiles.language`.
  final String? code;

  /// The pinned UI languages, in the order the language sheet lists them.
  static const uiLanguages = [en, ru];

  /// The languages a note can be dictated in, in the order the Speak in…
  /// sheet lists them.
  static const dictationLanguages = [en, ru, et];

  /// Whether the app's UI can be shown in this language.
  bool get isUiLanguage => uiLanguages.contains(this);

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

  /// Parses a stored UI choice: like [fromCode], but a language the UI
  /// isn't translated into (an `et` saved before #245) means [system].
  static AppLanguage uiFromCode(String? code) {
    final language = fromCode(code);
    return language.isUiLanguage ? language : system;
  }
}

/// The UI language a choice resolves to: a pinned UI choice is itself;
/// [AppLanguage.system] (or a language the UI lacks) takes the first device locale the UI supports and
/// falls back to English — so an Estonian phone reads the app in English.
AppLanguage resolveAppLanguage(AppLanguage choice, List<Locale> deviceLocales) {
  if (choice.isUiLanguage) return choice;
  for (final locale in deviceLocales) {
    final match = AppLanguage.fromCode(locale.languageCode);
    if (match.isUiLanguage) return match;
  }
  return AppLanguage.en;
}
