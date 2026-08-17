import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/auth/domain/entities/user_entity.dart';
import 'package:traviato/features/auth/presentation/providers/auth_providers.dart';
import 'package:traviato/main.dart';

import '../../../features/auth/fakes/fake_auth_repository.dart';

void main() {
  testWidgets(
    'redirects splash -> guest landing -> home as auth state changes',
    (tester) async {
      final repo = FakeAuthRepository();
      addTearDown(repo.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(repo)],
          child: const TraviatoApp(),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      repo.emit(null);
      await tester.pumpAndSettle();
      expect(find.text('Start capturing your memories'), findsOneWidget);

      const user = UserEntity(
        id: 'u1',
        email: 'ada@example.com',
        username: 'ada',
      );
      repo.emit(user);
      await tester.pumpAndSettle();
      expect(find.text('Hello, ada'), findsOneWidget);
    },
  );
}
