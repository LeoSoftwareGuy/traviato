import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/core/theme/app_theme.dart';
import 'package:traviato/features/auth/presentation/providers/auth_providers.dart';
import 'package:traviato/features/auth/presentation/widgets/social_sign_in_buttons.dart';

import '../../fakes/fake_auth_repository.dart';

Widget _wrap(FakeAuthRepository repo) => ProviderScope(
  overrides: [authRepositoryProvider.overrideWithValue(repo)],
  child: MaterialApp(
    theme: AppTheme.dark,
    home: const Scaffold(body: SocialSignInButtons()),
  ),
);

void main() {
  testWidgets('shows only the Google button on non-iOS platforms', (
    tester,
  ) async {
    final repo = FakeAuthRepository();
    addTearDown(repo.dispose);
    await tester.pumpWidget(_wrap(repo));

    expect(find.byKey(const Key('google-sign-in-button')), findsOneWidget);
    expect(find.byKey(const Key('apple-sign-in-button')), findsNothing);
  });

  testWidgets('shows the Apple button too on iOS', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final repo = FakeAuthRepository();
    addTearDown(repo.dispose);
    await tester.pumpWidget(_wrap(repo));

    expect(find.byKey(const Key('apple-sign-in-button')), findsOneWidget);
    expect(find.byKey(const Key('google-sign-in-button')), findsOneWidget);

    // Reset synchronously before the test body returns — flutter_test's
    // invariant check runs immediately after, ahead of addTearDown.
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets(
    'tapping Google triggers signInWithGoogle and shows a loading '
    'indicator while pending',
    (tester) async {
      final repo = FakeAuthRepository()
        ..delay = const Duration(milliseconds: 50);
      addTearDown(repo.dispose);
      await tester.pumpWidget(_wrap(repo));

      await tester.tap(find.byKey(const Key('google-sign-in-button')));
      await tester.pump();

      expect(repo.signInWithGoogleCallCount, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 60));
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets('a real failure shows an error snackbar', (tester) async {
    final repo = FakeAuthRepository()
      ..signInWithGoogleResult = const Left(
        AuthenticationFailure(message: 'Something went wrong.'),
      );
    addTearDown(repo.dispose);
    await tester.pumpWidget(_wrap(repo));

    await tester.tap(find.byKey(const Key('google-sign-in-button')));
    await tester.pump();

    expect(find.text('Something went wrong.'), findsOneWidget);
  });

  testWidgets('a cancelled sign-in does not show an error snackbar', (
    tester,
  ) async {
    // The repository already resolves cancellation to Right(null) — this
    // guards the UI side of issue #84's "cancelled must not error" rule.
    final repo = FakeAuthRepository()
      ..signInWithGoogleResult = const Right(null);
    addTearDown(repo.dispose);
    await tester.pumpWidget(_wrap(repo));

    await tester.tap(find.byKey(const Key('google-sign-in-button')));
    await tester.pump();
    await tester.pump();

    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('tapping Apple on iOS triggers signInWithApple', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final repo = FakeAuthRepository();
    addTearDown(repo.dispose);
    await tester.pumpWidget(_wrap(repo));

    await tester.tap(find.byKey(const Key('apple-sign-in-button')));
    await tester.pump();

    expect(repo.signInWithAppleCallCount, 1);

    debugDefaultTargetPlatformOverride = null;
  });
}
