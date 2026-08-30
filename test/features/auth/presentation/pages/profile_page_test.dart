import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/auth/presentation/pages/profile_page.dart';
import 'package:traviato/features/auth/presentation/providers/auth_providers.dart';

import '../../fakes/fake_auth_repository.dart';

void main() {
  Future<FakeAuthRepository> pumpProfilePage(WidgetTester tester) async {
    final repo = FakeAuthRepository();
    addTearDown(repo.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: ProfilePage()),
      ),
    );
    return repo;
  }

  testWidgets('renders a Log out button', (tester) async {
    await pumpProfilePage(tester);
    expect(find.widgetWithText(OutlinedButton, 'Log out'), findsOneWidget);
  });

  testWidgets('tapping Log out calls repository.logout()', (tester) async {
    final repo = await pumpProfilePage(tester);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Log out'));
    await tester.pumpAndSettle();
    expect(repo.logoutCalled, isTrue);
  });

  testWidgets('shows a spinner while the logout mutation is pending', (
    tester,
  ) async {
    final repo = await pumpProfilePage(tester);
    repo.delay = const Duration(milliseconds: 200);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Log out'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Log out'), findsNothing);

    await tester.pumpAndSettle();
  });

  testWidgets('shows an error snackbar when logout fails', (tester) async {
    final repo = await pumpProfilePage(tester);
    repo.logoutResult = const Left(UnknownFailure(message: 'boom'));

    await tester.tap(find.widgetWithText(OutlinedButton, 'Log out'));
    await tester.pumpAndSettle();

    expect(find.text('boom'), findsOneWidget);
  });
}
