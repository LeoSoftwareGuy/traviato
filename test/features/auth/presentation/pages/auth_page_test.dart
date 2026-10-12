import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/core/theme/app_colors.dart';
import 'package:traviato/core/theme/app_theme.dart';
import 'package:traviato/features/auth/domain/entities/signup_result.dart';
import 'package:traviato/features/auth/domain/entities/user_entity.dart';
import 'package:traviato/features/auth/presentation/pages/auth_page.dart';
import 'package:traviato/features/auth/presentation/providers/auth_providers.dart';
import 'package:traviato/features/auth/presentation/widgets/confirm_email_card.dart';

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

  group('failed submit (#155)', () {
    Future<void> fillSignup(WidgetTester tester) async {
      await tester.enterText(find.byType(TextFormField).at(0), 'Ada Wong');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'ada@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(2), 'secret1');
      await tester.enterText(find.byType(TextFormField).at(3), 'secret1');
    }

    testWidgets(
      'a rate-limited signup shows a friendly snackbar, with no unhandled '
      'exception and no stuck spinner',
      (tester) async {
        final repo = FakeAuthRepository()
          ..signupResult = Left(RateLimitedFailure(retryAfterSeconds: 43));
        addTearDown(repo.dispose);
        await tester.pumpWidget(_wrap(repo, AuthMode.signup));

        await fillSignup(tester);
        await tester.tap(find.text('Create my account'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // A test fails on any error that escapes to the zone, so reaching
        // this line already proves nothing was left unhandled.
        expect(tester.takeException(), isNull);
        expect(
          find.text('Too many attempts. Please wait 43 seconds and try again.'),
          findsOneWidget,
        );
        expect(find.byType(CircularProgressIndicator), findsNothing);

        // The button is live again — once the message has cleared, the user
        // can retry.
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Create my account'));
        await tester.pump();
        expect(repo.signupCalls, hasLength(2));
      },
    );

    testWidgets('a failed login also stays handled and shows its message', (
      tester,
    ) async {
      final repo = FakeAuthRepository()
        ..loginResult = const Left(
          AuthenticationFailure(message: 'Invalid login credentials'),
        );
      addTearDown(repo.dispose);
      await tester.pumpWidget(_wrap(repo, AuthMode.login));

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'ada@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'secret1');
      await tester.tap(find.text('Log in').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
      expect(find.text('Invalid login credentials'), findsOneWidget);
    });
  });

  group('signup awaiting email confirmation (#162)', () {
    const cardKey = Key('confirm-email-card');

    FakeAuthRepository pendingRepo() =>
        FakeAuthRepository()
          ..signupResult = const Right(
            SignupResult(
              user: UserEntity(id: 'u1', email: 'ada@example.com'),
              needsEmailConfirmation: true,
            ),
          );

    Future<void> signUp(WidgetTester tester) async {
      await tester.enterText(find.byType(TextFormField).at(0), 'Ada Wong');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'ada@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(2), 'secret1');
      await tester.enterText(find.byType(TextFormField).at(3), 'secret1');
      await tester.tap(find.text('Create my account'));
      await tester.pump();
      await tester.pump();
    }

    testWidgets('replaces the form with the confirmation card — not an '
        'error snackbar', (tester) async {
      final repo = pendingRepo();
      addTearDown(repo.dispose);
      await tester.pumpWidget(_wrap(repo, AuthMode.signup));

      await signUp(tester);

      expect(find.byKey(cardKey), findsOneWidget);
      expect(find.text('Check your inbox'), findsOneWidget);
      expect(
        find.textContaining('ada@example.com', findRichText: true),
        findsOneWidget,
      );
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('Create my account'), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('a signup that returned a session shows no card', (
      tester,
    ) async {
      final repo = FakeAuthRepository();
      addTearDown(repo.dispose);
      await tester.pumpWidget(_wrap(repo, AuthMode.signup));

      await signUp(tester);

      expect(find.byKey(cardKey), findsNothing);
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('"Back to log in" switches to log-in with the email '
        'prefilled and the password cleared', (tester) async {
      final repo = pendingRepo();
      addTearDown(repo.dispose);
      await tester.pumpWidget(_wrap(repo, AuthMode.signup));
      await signUp(tester);

      await tester.tap(find.text('Back to log in'));
      await tester.pump();

      expect(find.byKey(cardKey), findsNothing);
      expect(find.text('NAME'), findsNothing);
      final fields = tester
          .widgetList<TextFormField>(find.byType(TextFormField))
          .toList();
      expect(fields, hasLength(2));
      expect(fields[0].controller!.text, 'ada@example.com');
      expect(fields[1].controller!.text, isEmpty);
    });

    testWidgets('"Use a different email" returns to the signup form with '
        'its fields kept', (tester) async {
      final repo = pendingRepo();
      addTearDown(repo.dispose);
      await tester.pumpWidget(_wrap(repo, AuthMode.signup));
      await signUp(tester);

      await tester.tap(find.text('Use a different email'));
      await tester.pump();

      expect(find.byKey(cardKey), findsNothing);
      expect(find.text('NAME'), findsOneWidget);
      final email = tester.widget<TextFormField>(
        find.byType(TextFormField).at(1),
      );
      expect(email.controller!.text, 'ada@example.com');
    });

    testWidgets('resend is held back by a cooldown, then resends and '
        'restarts it', (tester) async {
      final repo = pendingRepo();
      addTearDown(repo.dispose);
      await tester.pumpWidget(_wrap(repo, AuthMode.signup));
      await signUp(tester);

      final seconds = ConfirmEmailCard.resendCooldown.inSeconds;
      expect(find.text('Resend in ${seconds}s'), findsOneWidget);
      await tester.tap(find.text('Resend in ${seconds}s'));
      await tester.pump();
      expect(repo.resendCalls, isEmpty);

      await tester.pump(const Duration(seconds: 18));
      expect(find.text('Resend in ${seconds - 18}s'), findsOneWidget);

      await tester.pump(ConfirmEmailCard.resendCooldown);
      await tester.tap(find.text('Resend email'));
      await tester.pump();
      await tester.pump();

      expect(repo.resendCalls, ['ada@example.com']);
      expect(find.text('Sent again ✓'), findsOneWidget);
      expect(find.text('Resend in ${seconds}s'), findsOneWidget);
    });

    testWidgets('a failed resend shows the rate-limit message and leaves '
        'the card up', (tester) async {
      final repo = pendingRepo()
        ..resendResult = Left(RateLimitedFailure(isEmailQuota: true));
      addTearDown(repo.dispose);
      await tester.pumpWidget(_wrap(repo, AuthMode.signup));
      await signUp(tester);

      await tester.pump(ConfirmEmailCard.resendCooldown);
      await tester.tap(find.text('Resend email'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
      expect(
        find.text(
          "We've sent too many emails for now. Please try again in a "
          'little while.',
        ),
        findsOneWidget,
      );
      expect(find.text('Sent again ✓'), findsNothing);
      expect(find.byKey(cardKey), findsOneWidget);
    });
  });
}
