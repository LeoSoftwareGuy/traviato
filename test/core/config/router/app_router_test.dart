import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/features/auth/domain/entities/user_entity.dart';
import 'package:traviato/features/auth/presentation/providers/auth_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traviato/features/profile/presentation/providers/profile_providers.dart';
import 'package:traviato/features/share/presentation/pages/shared_memory_preview_page.dart';
import 'package:traviato/features/share/presentation/providers/share_providers.dart';
import 'package:traviato/features/trip/presentation/providers/trip_providers.dart';
import 'package:traviato/main.dart';

import '../../../features/auth/fakes/fake_auth_repository.dart';
import '../../../features/profile/fakes/fake_profile_repository.dart';
import '../../../features/share/fakes/fake_share_repository.dart';
import '../../../features/trip/fakes/fake_trip_repository.dart';

void main() {
  testWidgets(
    'redirects splash -> guest landing -> home as auth state changes',
    (tester) async {
      final repo = FakeAuthRepository();
      addTearDown(repo.dispose);
      final tripRepo = FakeTripRepository()..tripsResult = const Right([]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(repo),
            tripRepositoryProvider.overrideWithValue(tripRepo),
            // Home greets with profiles.username (#266).
            profileRepositoryProvider.overrideWithValue(
              FakeProfileRepository(),
            ),
          ],
          child: const TraviatoApp(),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      repo.emit(null);
      // Not pumpAndSettle: the guest landing screen has looping animations
      // (star specks, floating polaroids, the CTA's pulse glow) that never
      // settle. A couple of bounded pumps is enough for the route
      // transition to finish.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Start capturing your moments'), findsOneWidget);

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

  testWidgets(
    'a pending shared-memory link wins over Home after sign-in (#310)',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final repo = FakeAuthRepository();
      addTearDown(repo.dispose);
      final shareRepo = FakeShareRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(repo),
            tripRepositoryProvider.overrideWithValue(
              FakeTripRepository()..tripsResult = const Right([]),
            ),
            profileRepositoryProvider.overrideWithValue(
              FakeProfileRepository(),
            ),
            shareRepositoryProvider.overrideWithValue(shareRepo),
            initialPendingShareSlugProvider.overrideWithValue('k7Qm2xPa9c'),
          ],
          child: const TraviatoApp(),
        ),
      );
      await tester.pump();

      repo.emit(
        const UserEntity(id: 'u1', email: 'ada@example.com', username: 'ada'),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SharedMemoryPreviewPage), findsOneWidget);
      expect(find.text('One long road'), findsOneWidget);
    },
  );
}
