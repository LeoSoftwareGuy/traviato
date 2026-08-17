import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/theme/app_theme.dart';
import 'package:traviato/features/auth/presentation/pages/login_page.dart';
import 'package:traviato/features/auth/presentation/providers/auth_providers.dart';

import '../../fakes/fake_auth_repository.dart';

Widget _wrap(FakeAuthRepository repo) => ProviderScope(
  overrides: [authRepositoryProvider.overrideWithValue(repo)],
  child: MaterialApp(theme: AppTheme.dark, home: const LoginPage()),
);

void main() {
  testWidgets('shows validation errors and does not submit when empty', (
    tester,
  ) async {
    final repo = FakeAuthRepository();
    addTearDown(repo.dispose);
    await tester.pumpWidget(_wrap(repo));

    await tester.tap(find.text('Log in'));
    await tester.pump();

    expect(find.text('Enter your email.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
    expect(repo.loginCalls, isEmpty);
  });

  testWidgets('shows a loading indicator while the login mutation is pending', (
    tester,
  ) async {
    final repo = FakeAuthRepository()..delay = const Duration(milliseconds: 50);
    addTearDown(repo.dispose);
    await tester.pumpWidget(_wrap(repo));

    await tester.enterText(find.byType(TextFormField).at(0), 'ada@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret1');
    await tester.tap(find.text('Log in'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(repo.loginCalls, ['ada@example.com']);

    await tester.pump(const Duration(milliseconds: 60));
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
