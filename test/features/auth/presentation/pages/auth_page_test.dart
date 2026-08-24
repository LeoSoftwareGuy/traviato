import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/theme/app_colors.dart';
import 'package:traviato/core/theme/app_theme.dart';
import 'package:traviato/features/auth/presentation/pages/auth_page.dart';
import 'package:traviato/features/auth/presentation/providers/auth_providers.dart';

import '../../fakes/fake_auth_repository.dart';

Widget _wrap(FakeAuthRepository repo, AuthMode mode) => ProviderScope(
  overrides: [authRepositoryProvider.overrideWithValue(repo)],
  child: MaterialApp(
    theme: AppTheme.dark,
    home: AuthPage(initialMode: mode),
  ),
);

void main() {
  testWidgets('the toggle switches mode and the name field appears only '
      'in signup', (tester) async {
    final repo = FakeAuthRepository();
    addTearDown(repo.dispose);
    await tester.pumpWidget(_wrap(repo, AuthMode.login));

    expect(find.text('NAME'), findsNothing);
    expect(find.text('Log in'), findsWidgets);

    await tester.tap(find.text('Create account'));
    await tester.pump();

    expect(find.text('NAME'), findsOneWidget);
    expect(find.text('Create my account'), findsOneWidget);

    await tester.tap(find.text('Log in').last);
    await tester.pump();

    expect(find.text('NAME'), findsNothing);
  });

  testWidgets('focusing a field turns its border/label primary', (
    tester,
  ) async {
    final repo = FakeAuthRepository();
    addTearDown(repo.dispose);
    await tester.pumpWidget(_wrap(repo, AuthMode.login));

    Text emailLabel() => tester.widget<Text>(find.text('EMAIL'));
    expect(emailLabel().style?.color, AppColors.textTertiary);

    await tester.tap(find.byType(TextFormField).first);
    await tester.pump();

    expect(emailLabel().style?.color, AppColors.primary);
  });

  testWidgets('password strength meter only shows in signup mode', (
    tester,
  ) async {
    final repo = FakeAuthRepository();
    addTearDown(repo.dispose);
    await tester.pumpWidget(_wrap(repo, AuthMode.login));

    await tester.enterText(find.byType(TextFormField).at(1), 'secret1');
    await tester.pump();
    expect(find.text('Good'), findsNothing);

    await tester.tap(find.text('Create account'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).at(2), 'secret1');
    await tester.pump();
    expect(find.text('Good'), findsOneWidget);
  });

  group('login mode', () {
    testWidgets('shows validation errors and does not submit when empty', (
      tester,
    ) async {
      final repo = FakeAuthRepository();
      addTearDown(repo.dispose);
      await tester.pumpWidget(_wrap(repo, AuthMode.login));

      await tester.tap(find.text('Log in').last);
      await tester.pump();

      expect(find.text('Enter your email.'), findsOneWidget);
      expect(find.text('Enter your password.'), findsOneWidget);
      expect(repo.loginCalls, isEmpty);
    });

    testWidgets(
      'shows a loading indicator while the login mutation is pending',
      (tester) async {
        final repo = FakeAuthRepository()
          ..delay = const Duration(milliseconds: 50);
        addTearDown(repo.dispose);
        await tester.pumpWidget(_wrap(repo, AuthMode.login));

        await tester.enterText(
          find.byType(TextFormField).at(0),
          'ada@example.com',
        );
        await tester.enterText(find.byType(TextFormField).at(1), 'secret1');
        await tester.tap(find.text('Log in').last);
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(repo.loginCalls, ['ada@example.com']);

        await tester.pump(const Duration(milliseconds: 60));
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );
  });

  group('signup mode', () {
    testWidgets('shows validation errors and does not submit when empty', (
      tester,
    ) async {
      final repo = FakeAuthRepository();
      addTearDown(repo.dispose);
      await tester.pumpWidget(_wrap(repo, AuthMode.signup));

      await tester.tap(find.text('Create my account'));
      await tester.pump();

      expect(find.text('Enter your name.'), findsOneWidget);
      expect(find.text('Enter your email.'), findsOneWidget);
      expect(find.text('Enter a password.'), findsOneWidget);
      expect(repo.signupCalls, isEmpty);
    });

    testWidgets('flags a mismatched confirm-password field', (tester) async {
      final repo = FakeAuthRepository();
      addTearDown(repo.dispose);
      await tester.pumpWidget(_wrap(repo, AuthMode.signup));

      await tester.enterText(find.byType(TextFormField).at(0), 'Ada Wong');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'ada@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(2), 'secret1');
      await tester.enterText(find.byType(TextFormField).at(3), 'different1');
      await tester.tap(find.text('Create my account'));
      await tester.pump();

      expect(find.text('Passwords do not match.'), findsOneWidget);
      expect(repo.signupCalls, isEmpty);
    });

    testWidgets(
      'shows a loading indicator while the signup mutation is pending',
      (tester) async {
        final repo = FakeAuthRepository()
          ..delay = const Duration(milliseconds: 50);
        addTearDown(repo.dispose);
        await tester.pumpWidget(_wrap(repo, AuthMode.signup));

        await tester.enterText(find.byType(TextFormField).at(0), 'Ada Wong');
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'ada@example.com',
        );
        await tester.enterText(find.byType(TextFormField).at(2), 'secret1');
        await tester.enterText(find.byType(TextFormField).at(3), 'secret1');
        await tester.tap(find.text('Create my account'));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(repo.signupCalls, ['ada@example.com']);

        await tester.pump(const Duration(milliseconds: 60));
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );
  });
}
