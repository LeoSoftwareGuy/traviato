import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../settings/domain/app_language.dart';
import '../../../settings/domain/dictation_language.dart';
import '../../../settings/presentation/controllers/app_language_controller.dart';
import '../../../settings/presentation/controllers/device_locales_controller.dart';
import '../../data/datasources/speech_to_text_dictation_service.dart';
import '../../domain/dictation/dictation_service.dart';

part 'dictation_providers.g.dart';

/// Kept alive: the platform recogniser is initialised once per app run.
@Riverpod(keepAlive: true)
DictationService dictationService(Ref ref) => SpeechToTextDictationService();

/// The recogniser's locale ids, or `null` while unknown (speech permission
/// not granted yet — asking would pop a dialog just for opening a note).
/// Re-read each time a note opens (not keepAlive) and after the mic
/// permission prompt (#218).
@riverpod
Future<List<String>?> dictationSupportedLocales(Ref ref) => ref
    .watch(dictationServiceProvider)
    .supportedLocaleIds(askPermission: false);

/// The dictation language in effect on the note page and whether this
/// device can recognise it.
typedef DictationLanguageStatus = ({
  AppLanguage language,
  String? localeId,
  bool isAvailable,
});

@riverpod
DictationLanguageStatus dictationLanguageStatus(Ref ref) {
  final supported = ref.watch(dictationSupportedLocalesProvider).value;
  final device = ref.watch(deviceLocalesControllerProvider);
  final language =
      ref.watch(dictationLanguageControllerProvider) ??
      defaultDictationLanguage(
        uiLanguage: ref.watch(resolvedAppLanguageProvider),
        supportedIds: supported,
        deviceLocales: device,
      );
  final localeId = supported == null
      ? null
      : recognizerLocaleFor(language, supported, device);
  return (
    language: language,
    localeId: localeId,
    // Unknown support counts as available; the mic tap asks and re-checks.
    isAvailable: supported == null || localeId != null,
  );
}

/// Whether [language] can be recognised here (`true` while unknown).
@riverpod
bool dictationLanguageSupported(Ref ref, AppLanguage language) {
  final supported = ref.watch(dictationSupportedLocalesProvider).value;
  if (supported == null) return true;
  return recognizerLocaleFor(
        language,
        supported,
        ref.watch(deviceLocalesControllerProvider),
      ) !=
      null;
}
