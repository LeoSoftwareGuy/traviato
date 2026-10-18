import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traviato/core/l10n/context_l10n.dart';
import 'package:traviato/core/theme/app_typography.dart';
import 'package:traviato/features/auth/presentation/providers/auth_providers.dart';
import 'package:traviato/features/settings/domain/app_language.dart';
import 'package:traviato/features/settings/presentation/controllers/app_language_controller.dart';
import 'package:traviato/features/settings/presentation/widgets/locale_fade.dart';
import 'package:traviato/features/wrap_up/presentation/film/wrap_up_film_tokens.dart';

import '../../features/auth/fakes/fake_auth_repository.dart';

/// Every serif role in AppTypography.
List<TextStyle> _serifRoles() => [
  AppTypography.heroHeadline,
  AppTypography.screenTitle,
  AppTypography.bigNumber,
  AppTypography.pullQuote,
  AppTypography.displaySerif,
  AppTypography.headlineSerif,
  AppTypography.noteBody,
  AppTypography.noteTitle,
  AppTypography.noteDockAa,
  AppTypography.titlePageTitle,
  AppTypography.titlePageMeta,
  WrapUpFilmText.serif(size: 40, color: const Color(0xFFFFFFFF)),
];

void main() {
  // No network in tests; same as app_theme_test.
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  tearDown(() => AppTypography.useLocale(const Locale('en')));

  testWidgets('Russian uses Literata for every serif role (#239)', (_) async {
    AppTypography.useLocale(const Locale('ru'));
    for (final style in _serifRoles()) {
      expect(style.fontFamily, AppTypography.literata);
      expect(
        style.fontVariations,
        contains(FontVariation.weight(style.fontWeight!.value.toDouble())),
      );
    }
    expect(AppTypography.pullQuote.fontStyle, FontStyle.italic);
  });

  for (final code in ['en', 'et']) {
    testWidgets('$code keeps Fraunces with a Literata fallback for Cyrillic', (
      _,
    ) async {
      AppTypography.useLocale(Locale(code));
      for (final style in _serifRoles()) {
        expect(style.fontFamily, contains('Fraunces'));
        expect(style.fontFamilyFallback, [AppTypography.literata]);
      }
    });
  }

  testWidgets('sans and mono styles are untouched', (_) async {
    AppTypography.useLocale(const Locale('ru'));
    expect(AppTypography.bodyEmphasis.fontFamily, contains('Roboto'));
    expect(AppTypography.mono.fontFamily, contains('JetBrains'));
  });

  test('the Literata font files and licence are bundled', () {
    for (final path in [
      'assets/fonts/Literata[opsz,wght].ttf',
      'assets/fonts/Literata-Italic[opsz,wght].ttf',
      'assets/fonts/Literata-OFL.txt',
    ]) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('family: Literata'));
  });

  testWidgets('switching to Russian re-renders serif text, even in widgets '
      'that do not depend on Localizations', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final auth = FakeAuthRepository();
    addTearDown(auth.dispose);
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(auth)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, _) {
            final locale = ref.watch(appLocaleProvider);
            AppTypography.useLocale(locale);
            return MaterialApp(
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) =>
                  LocaleFade(locale: locale, child: child!),
              home: const Scaffold(body: _StaticTitle()),
            );
          },
        ),
      ),
    );
    TextStyle? title() =>
        tester.widget<Text>(find.byKey(const Key('static-title'))).style;
    expect(title()?.fontFamily, contains('Fraunces'));

    await container
        .read(appLanguageControllerProvider.notifier)
        .select(AppLanguage.ru);
    await tester.pumpAndSettle();
    expect(title()?.fontFamily, AppTypography.literata);

    await container
        .read(appLanguageControllerProvider.notifier)
        .select(AppLanguage.et);
    await tester.pumpAndSettle();
    expect(title()?.fontFamily, contains('Fraunces'));
  });
}

/// Reads a serif style but no InheritedWidget — only the forced rebuild in
/// [LocaleFade] can update it.
class _StaticTitle extends StatelessWidget {
  const _StaticTitle();

  @override
  Widget build(BuildContext context) => Text(
    'Каждое воспоминание',
    key: const Key('static-title'),
    style: AppTypography.screenTitle,
  );
}
