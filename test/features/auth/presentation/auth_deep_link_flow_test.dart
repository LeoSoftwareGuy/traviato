import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/auth/domain/entities/user_entity.dart';
import 'package:traviato/features/auth/presentation/providers/auth_providers.dart';
import 'package:traviato/features/trip/presentation/providers/trip_providers.dart';
import 'package:traviato/main.dart';

import '../../trip/fakes/fake_trip_repository.dart';
import '../fakes/fake_auth_repository.dart';

// Email confirmation deep link (#157). supabase_flutter turns the link into
// auth-stream events before the app sees it, so each case is driven through
// the fake repository's streams: a successful link is a signed-in user, a
// failed one is an AuthLinkFailure.

const _user = UserEntity(id: 'u1', email: 'ada@example.com', username: 'ada');

Future<FakeAuthRepository> _pumpApp(WidgetTester tester) async {
  final repo = FakeAuthRepository();
  addTearDown(repo.dispose);
  final tripRepo = FakeTripRepository()..tripsResult = const Right([]);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        tripRepositoryProvider.overrideWithValue(tripRepo),
      ],
      child: const TraviatoApp(),
    ),
  );
  await tester.pump();
  return repo;
}

// Not pumpAndSettle on guest screens: their looping animations never settle.
Future<void> _pumpRouteChange(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('cold start: the link already produced a session, so the app '
      'goes straight from splash to Home', (tester) async {
    final repo = await _pumpApp(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    repo.emit(_user);
    await tester.pumpAndSettle();

    expect(find.text('Hello, ada'), findsOneWidget);
  });

  testWidgets('warm start: a user waiting on the auth screen lands on Home '
      'when the link signs them in', (tester) async {
    final repo = await _pumpApp(tester);
    repo.emit(null);
    await _pumpRouteChange(tester);
    await tester.tap(find.text('Log in').first);
    await _pumpRouteChange(tester);
    expect(find.text('Hello, ada'), findsNothing);

    repo.emit(_user);
    await tester.pumpAndSettle();

    expect(find.text('Hello, ada'), findsOneWidget);
  });

  testWidgets('expired or used link: friendly message with a Log in action, '
      'no crash, user stays signed out', (tester) async {
    final repo = await _pumpApp(tester);
    repo.emit(null);
    await _pumpRouteChange(tester);

    repo.emitLinkFailure();
    await _pumpRouteChange(tester);

    expect(find.text(const AuthLinkFailure().message), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.widgetWithText(SnackBarAction, 'Log in'));
    await _pumpRouteChange(tester);
    expect(find.text('Hello, ada'), findsNothing);
    // The auth screen, in log-in mode (no NAME field).
    expect(find.text('EMAIL'), findsOneWidget);
    expect(find.text('NAME'), findsNothing);
  });

  testWidgets('a stale link while signed in explains itself without signing '
      'the user out', (tester) async {
    final repo = await _pumpApp(tester);
    repo.emit(_user);
    await tester.pumpAndSettle();

    repo.emitLinkFailure();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(const AuthLinkFailure().message), findsOneWidget);
    expect(find.widgetWithText(SnackBarAction, 'Log in'), findsNothing);
    expect(find.text('Hello, ada'), findsOneWidget);
  });
}
