import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/app_language_prefs.dart';
import '../../domain/app_language.dart';

part 'settings_providers.g.dart';

@Riverpod(keepAlive: true)
AppLanguagePrefs appLanguagePrefs(Ref ref) => const AppLanguagePrefs();

/// The stored choice, read in `main()` before `runApp` and overridden there,
/// so the first frame is already in the right language (#236).
@Riverpod(keepAlive: true)
AppLanguage initialAppLanguage(Ref ref) => AppLanguage.system;
