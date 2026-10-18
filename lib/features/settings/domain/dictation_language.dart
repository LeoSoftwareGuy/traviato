import 'dart:ui';

import 'app_language.dart';

/// The recogniser locale id for [language] among [supportedIds] ("ru_RU",
/// "en-GB", …), preferring the device's own region for that language —
/// so an en_GB phone dictates British English. `null` when the recogniser
/// doesn't support the language at all (#218).
String? recognizerLocaleFor(
  AppLanguage language,
  List<String> supportedIds,
  List<Locale> deviceLocales,
) {
  final code = language.code;
  if (code == null) return null;
  final matches = [
    for (final id in supportedIds)
      if (_languagePart(id) == code) id,
  ];
  if (matches.isEmpty) return null;
  for (final device in deviceLocales) {
    if (device.languageCode != code || device.countryCode == null) continue;
    for (final id in matches) {
      if (_regionPart(id) == device.countryCode!.toUpperCase()) return id;
    }
  }
  return matches.first;
}

/// The dictation language to use when the user hasn't picked one yet
/// (spec 2): the UI language if speech supports it, otherwise the first of
/// the device's preferred languages that it does, otherwise English. With
/// [supportedIds] unknown (no speech permission yet) the UI language wins.
AppLanguage defaultDictationLanguage({
  required AppLanguage uiLanguage,
  required List<String>? supportedIds,
  required List<Locale> deviceLocales,
}) {
  if (supportedIds == null) return uiLanguage;
  bool supported(AppLanguage l) =>
      recognizerLocaleFor(l, supportedIds, deviceLocales) != null;
  if (supported(uiLanguage)) return uiLanguage;
  for (final device in deviceLocales) {
    final candidate = AppLanguage.fromCode(device.languageCode);
    if (candidate != AppLanguage.system && supported(candidate)) {
      return candidate;
    }
  }
  return AppLanguage.en;
}

String _languagePart(String id) => id.split(RegExp('[-_]')).first.toLowerCase();

String? _regionPart(String id) {
  final parts = id.split(RegExp('[-_]'));
  return parts.length > 1 ? parts[1].toUpperCase() : null;
}
