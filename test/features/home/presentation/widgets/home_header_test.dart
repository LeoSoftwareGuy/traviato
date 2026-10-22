import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/theme/app_theme.dart';
import 'package:traviato/features/home/presentation/widgets/home_header.dart';
import 'package:traviato/features/profile/presentation/providers/profile_providers.dart';
import 'package:traviato/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:traviato/l10n/app_localizations.dart';

Future<void> _pump(
  WidgetTester tester, {
  required String? username,
  String? avatarUrl,
  Locale locale = const Locale('en'),
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        // Signing never resolves: the avatar stays on its loading fill, so
        // no test touches the network.
        avatarImageUrlProvider.overrideWith(
          (ref, path) => Completer<String>().future,
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: HomeHeader(
            username: username,
            avatarUrl: avatarUrl,
            stars: 0,
            onAvatarTap: () {},
            onStarsTap: () {},
          ),
        ),
      ),
    ),
  );
}

String _greeting(WidgetTester tester) {
  final widget = tester.widget(find.byKey(const Key('home-greeting')));
  return switch (widget) {
    Text(:final data?) => data,
    Text(:final textSpan?) => textSpan.toPlainText(),
    _ => throw StateError('unexpected greeting widget: $widget'),
  };
}

void main() {
  testWidgets('greets the user by name', (tester) async {
    await _pump(tester, username: 'Leo');

    expect(_greeting(tester), 'Hello, Leo');
  });

  testWidgets(
    'with no name (e.g. Apple sign-in hid it) says just "Hello!", not a '
    'placeholder name',
    (tester) async {
      await _pump(tester, username: null);
      expect(_greeting(tester), 'Hello!');

      await _pump(tester, username: '   ');
      expect(_greeting(tester), 'Hello!');
    },
  );

  testWidgets('no-name greeting in Russian', (tester) async {
    await _pump(tester, username: null, locale: const Locale('ru'));

    expect(_greeting(tester), 'Привет!');
  });

  group('avatar (#283)', () {
    Finder initial(String letter) => find.descendant(
      of: find.byKey(const Key('home-avatar')),
      matching: find.text(letter),
    );

    testWidgets('without a photo, shows the name\'s initial', (tester) async {
      await _pump(tester, username: 'Leo');

      expect(initial('L'), findsOneWidget);
    });

    testWidgets('with a photo, shows it instead of the initial', (
      tester,
    ) async {
      await _pump(tester, username: 'Leo', avatarUrl: 'u1/avatar.jpg');

      final avatar = tester.widget<ProfileAvatar>(
        find.descendant(
          of: find.byKey(const Key('home-avatar')),
          matching: find.byType(ProfileAvatar),
        ),
      );
      expect(avatar.avatarUrl, 'u1/avatar.jpg');
      expect(initial('L'), findsNothing);
    });
  });
}
