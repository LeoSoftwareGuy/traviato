import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traviato/core/l10n/context_l10n.dart';
import 'package:traviato/core/theme/app_theme.dart';
import 'package:traviato/features/auth/domain/entities/user_entity.dart';
import 'package:traviato/features/auth/presentation/providers/auth_providers.dart';
import 'package:traviato/features/profile/presentation/providers/profile_providers.dart';
import 'package:traviato/features/settings/domain/app_language.dart';
import 'package:traviato/features/settings/presentation/controllers/app_language_controller.dart';
import 'package:traviato/features/settings/presentation/providers/settings_providers.dart';
import 'package:traviato/features/settings/presentation/widgets/language_chip.dart';
import 'package:traviato/features/settings/presentation/widgets/language_settings_row.dart';

import '../../auth/fakes/fake_auth_repository.dart';
import '../../profile/fakes/fake_profile_repository.dart';

const _user = UserEntity(id: 'u1', email: 'ada@example.com');

/// A tiny app whose locale follows the controller, like `TraviatoApp`.
Widget _app({
  required Widget home,
  required FakeAuthRepository auth,
  required FakeProfileRepository profile,
  AppLanguage initial = AppLanguage.system,
}) => ProviderScope(
  overrides: [
    authRepositoryProvider.overrideWithValue(auth),
    profileRepositoryProvider.overrideWithValue(profile),
    initialAppLanguageProvider.overrideWithValue(initial),
  ],
  child: Consumer(
    builder: (context, ref, _) {
      ref.watch(languageProfileSyncControllerProvider);
      return MaterialApp(
        theme: AppTheme.dark,
        locale: ref.watch(appLocaleProvider),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: home),
      );
    },
  ),
);

void main() {
  late FakeAuthRepository auth;
  late FakeProfileRepository profile;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    auth = FakeAuthRepository();
    profile = FakeProfileRepository();
  });
  tearDown(() => auth.dispose());

  testWidgets('Settings row shows what System default resolves to (1a)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(home: const LanguageSettingsSection(), auth: auth, profile: profile),
    );

    expect(find.text('SETTINGS'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('System default · English'), findsOneWidget);
  });

  testWidgets('picking Русский applies at once, persists and toasts in '
      'Russian (1b/1c)', (tester) async {
    await tester.pumpWidget(
      _app(home: const LanguageSettingsSection(), auth: auth, profile: profile),
    );

    await tester.tap(find.byKey(const Key('settings-language-row')));
    await tester.pumpAndSettle();
    expect(find.text('Changes apply right away.'), findsOneWidget);
    expect(find.textContaining('Follows your'), findsOneWidget);
    // English has no subtitle in an English UI; the others are named.
    expect(find.text('Russian'), findsOneWidget);
    expect(find.text('Estonian'), findsOneWidget);

    await tester.tap(find.byKey(const Key('language-row-ru')));
    await tester.pump(); // sheet pops
    await tester.pump(const Duration(milliseconds: 300)); // fade + toast
    expect(find.text('Язык: русский'), findsOneWidget);
    expect(find.text('НАСТРОЙКИ'), findsOneWidget);
    expect(find.text('Русский'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    final stored = await SharedPreferences.getInstance();
    expect(stored.getString('app_language'), 'ru');
    expect(profile.languageUpdates, isEmpty, reason: 'signed out');
  });

  testWidgets('in a Russian UI the sheet names languages in Russian', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        home: const LanguageSettingsSection(),
        auth: auth,
        profile: profile,
        initial: AppLanguage.ru,
      ),
    );
    await tester.tap(find.byKey(const Key('settings-language-row')));
    await tester.pumpAndSettle();

    expect(find.text('Как в системе'), findsOneWidget);
    expect(find.text('Английский'), findsOneWidget);
    expect(find.text('Эстонский'), findsOneWidget);
    // Русский has no subtitle in a Russian UI.
    expect(find.text('Русский'), findsWidgets);
  });

  testWidgets('guest chip shows the live code and opens the sheet (1d)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        home: const Center(child: LanguageChip()),
        auth: auth,
        profile: profile,
        initial: AppLanguage.et,
      ),
    );
    expect(find.text('ET'), findsOneWidget);

    await tester.tap(find.byKey(const Key('guest-language-chip')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language-row-en')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('EN'), findsOneWidget);
    expect(find.text('Language: English'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });

  group('profile sync on sign-in', () {
    testWidgets('a language saved on the profile wins over the device', (
      tester,
    ) async {
      profile.profileResult = Right(buildProfile(language: 'et'));
      await tester.pumpWidget(
        _app(
          home: const LanguageSettingsSection(),
          auth: auth,
          profile: profile,
          initial: AppLanguage.ru,
        ),
      );
      auth.emit(_user);
      await tester.pumpAndSettle();

      expect(find.text('SEADED'), findsOneWidget);
      expect(profile.languageUpdates, isEmpty);
      final stored = await SharedPreferences.getInstance();
      expect(stored.getString('app_language'), 'et');
    });

    testWidgets('an empty profile gets this device\'s choice written up', (
      tester,
    ) async {
      profile.profileResult = Right(buildProfile());
      await tester.pumpWidget(
        _app(
          home: const LanguageSettingsSection(),
          auth: auth,
          profile: profile,
          initial: AppLanguage.ru,
        ),
      );
      auth.emit(_user);
      await tester.pumpAndSettle();

      expect(profile.languageUpdates, ['ru']);
      expect(find.text('НАСТРОЙКИ'), findsOneWidget);
    });

    testWidgets('System default on an empty profile writes nothing', (
      tester,
    ) async {
      profile.profileResult = Right(buildProfile());
      await tester.pumpWidget(
        _app(home: const SizedBox(), auth: auth, profile: profile),
      );
      auth.emit(_user);
      await tester.pumpAndSettle();

      expect(profile.languageUpdates, isEmpty);
    });

    testWidgets('a change while signed in is saved to the profile', (
      tester,
    ) async {
      profile.profileResult = Right(buildProfile());
      await tester.pumpWidget(
        _app(
          home: const LanguageSettingsSection(),
          auth: auth,
          profile: profile,
        ),
      );
      auth.emit(_user);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('settings-language-row')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('language-row-system')));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await tester.tap(find.byKey(const Key('settings-language-row')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('language-row-et')));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(profile.languageUpdates, [null, 'et']);
    });
  });
}
