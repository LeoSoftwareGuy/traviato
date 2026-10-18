import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/controllers/auth_state.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/app_language.dart';
import '../providers/settings_providers.dart';
import 'device_locales_controller.dart';

part 'app_language_controller.g.dart';

/// The user's UI-language choice (#236): on-device first, mirrored to
/// `profiles.language` while signed in.
@Riverpod(keepAlive: true)
class AppLanguageController extends _$AppLanguageController {
  @override
  AppLanguage build() => ref.read(initialAppLanguageProvider);

  /// The user picked [language]: apply it now, remember it on the device
  /// and, when signed in, on the profile. A failed profile write is logged,
  /// not surfaced: the language already applied and the next sign-in sync
  /// writes it up again.
  Future<void> select(AppLanguage language) async {
    state = language;
    await ref.read(appLanguagePrefsProvider).write(language);
    if (ref.read(authControllerProvider).status != AuthStatus.authenticated) {
      return;
    }
    final result = await ref
        .read(profileRepositoryProvider)
        .updateLanguage(language.code);
    result.fold(
      (failure) => debugPrint('Saving language to profile failed: $failure'),
      (_) {},
    );
  }

  /// A value that came *from* the profile: apply and store it on the
  /// device without writing it back.
  Future<void> adopt(AppLanguage language) async {
    if (state == language) return;
    state = language;
    await ref.read(appLanguagePrefsProvider).write(language);
  }
}

/// What the choice resolves to right now — `system` becomes the device's
/// first supported language (or English).
@Riverpod(keepAlive: true)
AppLanguage resolvedAppLanguage(Ref ref) => resolveAppLanguage(
  ref.watch(appLanguageControllerProvider),
  ref.watch(deviceLocalesControllerProvider),
);

/// The locale `MaterialApp` runs in.
@Riverpod(keepAlive: true)
Locale appLocale(Ref ref) =>
    Locale(ref.watch(resolvedAppLanguageProvider).code!);

/// Reconciles the device choice with `profiles.language` on sign-in
/// (#236): a value on the profile wins (it's the user's choice from
/// another device); otherwise this device's choice is written up.
/// Instantiated from `TraviatoApp.build()`, like the other lifecycle
/// controllers.
@Riverpod(keepAlive: true)
class LanguageProfileSyncController extends _$LanguageProfileSyncController {
  @override
  void build() {
    ref.listen<AuthState>(
      authControllerProvider,
      (previous, next) => unawaited(_sync(previous, next)),
      fireImmediately: true,
    );
  }

  Future<void> _sync(AuthState? previous, AuthState next) async {
    if (next.status != AuthStatus.authenticated) return;
    if (previous?.status == next.status &&
        previous?.user?.id == next.user?.id) {
      return;
    }
    try {
      final repo = ref.read(profileRepositoryProvider);
      final profile = await repo.getProfile();
      if (!ref.mounted) return;
      final stored = profile.fold((_) => null, (p) => p.language);
      final languages = ref.read(appLanguageControllerProvider.notifier);
      if (stored != null) {
        await languages.adopt(AppLanguage.fromCode(stored));
        return;
      }
      // A failed read leaves the profile alone (we can't tell it's empty).
      if (profile.isLeft()) return;
      final local = ref.read(appLanguageControllerProvider);
      if (local != AppLanguage.system) await repo.updateLanguage(local.code);
    } catch (e) {
      debugPrint('Language profile sync failed: $e');
    }
  }
}
