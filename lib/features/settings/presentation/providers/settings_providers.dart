import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/app_language_prefs.dart';
import '../../data/dictation_language_prefs.dart';
import '../../data/reduce_flashing_prefs.dart';
import '../../domain/app_language.dart';

part 'settings_providers.g.dart';

@Riverpod(keepAlive: true)
AppLanguagePrefs appLanguagePrefs(Ref ref) => const AppLanguagePrefs();

/// The stored choice, read in `main()` before `runApp` and overridden there,
/// so the first frame is already in the right language (#236).
@Riverpod(keepAlive: true)
AppLanguage initialAppLanguage(Ref ref) => AppLanguage.system;

@Riverpod(keepAlive: true)
DictationLanguagePrefs dictationLanguagePrefs(Ref ref) =>
    const DictationLanguagePrefs();

/// The stored dictation language (or `null`), read in `main()` like
/// [initialAppLanguage] (#218).
@Riverpod(keepAlive: true)
AppLanguage? initialDictationLanguage(Ref ref) => null;

@Riverpod(keepAlive: true)
ReduceFlashingPrefs reduceFlashingPrefs(Ref ref) => const ReduceFlashingPrefs();

/// The stored "Reduce flashing" choice, read in `main()` like
/// [initialAppLanguage], so a film never plays its first flash before the
/// setting has loaded (#363).
@Riverpod(keepAlive: true)
bool initialReduceFlashing(Ref ref) => false;
