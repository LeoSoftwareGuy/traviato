import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/theme/app_theme.dart';
import 'package:traviato/features/auth/presentation/pages/register_page.dart';
import 'package:traviato/features/auth/presentation/providers/auth_providers.dart';

import '../../fakes/fake_auth_repository.dart';

Widget _wrap(FakeAuthRepository repo) => ProviderScope(
  overrides: [authRepositoryProvider.overrideWithValue(repo)],
  child: MaterialApp(theme: AppTheme.dark, home: const RegisterPage()),
);

void main() {
  testWidgets('shows validation errors and does not submit when empty', (
    tester,
  ) async {
    final repo = FakeAuthRepository();
    addTearDown(repo.dispose);
    await tester.pumpWidget(_wrap(repo));

    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pump();

    expect(find.text('Enter your name.'), findsOneWidget);
    expect(find.text('Enter your email.'), findsOneWidget);
    expect(find.text('Enter a password.'), findsOneWidget);
    expect(repo.signupCalls, isEmpty);
  });

  testWidgets('flags a mismatched confirm-password field', (tester) async {
    final repo = FakeAuthRepository();
    addTearDown(repo.dispose);
    await tester.pumpWidget(_wrap(repo));

    await tester.enterText(find.byType(TextFormField).at(0), 'Ada Wong');
    await tester.enterText(find.byType(TextFormField).at(1), 'ada@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'secret1');
    await tester.enterText(find.byType(TextFormField).at(3), 'different1');
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pump();

    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(repo.signupCalls, isEmpty);
  });

  testWidgets(
    'shows a loading indicator while the signup mutation is pending',
    (
      tester,
    ) async {
      final repo = FakeAuthRepository()
        ..delay = const Duration(milliseconds: 50);
      addTearDown(repo.dispose);
      await tester.pumpWidget(_wrap(repo));

      await tester.enterText(find.byType(TextFormField).at(0), 'Ada Wong');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'ada@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(2), 'secret1');
      await tester.enterText(find.byType(TextFormField).at(3), 'secret1');
      await tester.ensureVisible(find.text('Create account'));
      await tester.tap(find.text('Create account'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(repo.signupCalls, ['ada@example.com']);

      await tester.pump(const Duration(milliseconds: 60));
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );
}
