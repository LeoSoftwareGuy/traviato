import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traviato/core/config/router/route_constants.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/auth/domain/entities/user_entity.dart';
import 'package:traviato/features/auth/presentation/controllers/auth_controller.dart';
import 'package:traviato/features/auth/presentation/controllers/auth_state.dart';
import 'package:traviato/features/share/presentation/controllers/pending_share_slug_controller.dart';
import 'package:traviato/features/share/presentation/pages/shared_memory_preview_page.dart';
import 'package:traviato/features/share/presentation/providers/share_providers.dart';

import '../../../../helpers/localized_app.dart';
import '../../fakes/fake_share_repository.dart';

class _FixedAuth extends AuthController {
  _FixedAuth(this._state);

  final AuthState _state;

  @override
  AuthState build() => _state;
}

const _slug = 'k7Qm2xPa9c';
const _user = UserEntity(id: 'u2', email: 'mia@example.com', username: 'mia');

void main() {
  late FakeShareRepository repo;
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = FakeShareRepository();
  });

  Future<void> pumpPage(WidgetTester tester, {required bool signedIn}) async {
    setScreenSize(tester, width: 390, height: 844);
    final router = GoRouter(
      initialLocation: RoutePaths.sharedMemoryFor(_slug),
      routes: [
        GoRoute(
          path: RoutePaths.sharedMemory,
          builder: (_, state) =>
              SharedMemoryPreviewPage(slug: state.pathParameters['slug']!),
        ),
        GoRoute(
          path: RoutePaths.keptMemory,
          name: RouteNames.keptMemory,
          builder: (_, state) => Text('kept ${state.pathParameters['tripId']}'),
        ),
        GoRoute(
          path: RoutePaths.signup,
          builder: (_, _) => const Text('signup'),
        ),
        GoRoute(path: RoutePaths.login, builder: (_, _) => const Text('login')),
        GoRoute(path: RoutePaths.home, builder: (_, _) => const Text('home')),
        GoRoute(
          path: RoutePaths.guestLanding,
          builder: (_, _) => const Text('guest'),
        ),
      ],
    );
    addTearDown(router.dispose);
    container = ProviderContainer(
      overrides: [
        shareRepositoryProvider.overrideWithValue(repo),
        authControllerProvider.overrideWith(
          () => _FixedAuth(
            signedIn
                ? const AuthState.authenticated(_user)
                : const AuthState.unauthenticated(),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: localizedRouterApp(
          locale: const Locale('en'),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('signed out: the teaser asks for an account (#310)', (
    tester,
  ) async {
    await pumpPage(tester, signedIn: false);

    expect(find.text('One long road'), findsOneWidget);
    expect(find.text('Leo shared this'), findsOneWidget);
    expect(find.text('HIGHLANDS · 12–16 AUG 2026'), findsOneWidget);
    expect(find.text('5 DAYS · 84 PHOTOS · A FILM'), findsOneWidget);
    expect(
      find.byKey(const Key('shared-memory-create-account')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('shared-memory-log-in')), findsOneWidget);
    // Signed out: no ownership lookup, and the link waits for sign-up.
    expect(repo.calls, ['preview $_slug']);
    expect(container.read(pendingShareSlugControllerProvider), _slug);

    await tester.tap(find.byKey(const Key('shared-memory-create-account')));
    await tester.pumpAndSettle();
    expect(find.text('signup'), findsOneWidget);
  });

  testWidgets('no film: the meta line leaves it out', (tester) async {
    repo.previewResult = Right(buildSharedMemoryPreview(hasFilm: false));
    await pumpPage(tester, signedIn: false);
    expect(find.text('5 DAYS · 84 PHOTOS'), findsOneWidget);
  });

  testWidgets('teaser photos past the first two are blurred', (tester) async {
    repo.previewResult = Right(
      buildSharedMemoryPreview(
        photoUrls: [for (var i = 0; i < 6; i++) 'https://x.test/$i.jpg'],
      ),
    );
    await pumpPage(tester, signedIn: false);
    // The strip shows 5; 3 of them blurred.
    expect(find.byKey(const Key('teaser-photo-blurred')), findsNWidgets(3));
  });

  testWidgets('signed in, not the owner: teaser without the account CTA', (
    tester,
  ) async {
    await pumpPage(tester, signedIn: true);

    expect(find.text('One long road'), findsOneWidget);
    expect(find.byKey(const Key('shared-memory-start-own')), findsOneWidget);
    expect(find.byKey(const Key('shared-memory-create-account')), findsNothing);
    expect(repo.calls, ['own $_slug', 'preview $_slug']);
    // Shown signed in: the deferred link is done.
    expect(container.read(pendingShareSlugControllerProvider), isNull);
  });

  testWidgets("the owner goes to their memory's Kept Memory page", (
    tester,
  ) async {
    repo.ownTripIdResult = const Right('t1');
    await pumpPage(tester, signedIn: true);

    expect(find.text('kept t1'), findsOneWidget);
    expect(repo.calls, ['own $_slug']);
  });

  testWidgets('unknown or turned-off link: the unavailable screen', (
    tester,
  ) async {
    repo.previewResult = const Right(null);
    await pumpPage(tester, signedIn: false);

    expect(find.text('LINK UNAVAILABLE'), findsOneWidget);
    expect(
      find.text("This memory isn't shared anymore", findRichText: true),
      findsOneWidget,
    );
    expect(container.read(pendingShareSlugControllerProvider), isNull);

    await tester.tap(find.byKey(const Key('shared-memory-close')));
    await tester.pumpAndSettle();
    expect(find.text('guest'), findsOneWidget);
  });

  testWidgets('a failed lookup offers a retry', (tester) async {
    repo.previewResult = const Left(NetworkFailure());
    await pumpPage(tester, signedIn: false);
    expect(find.text('Retry'), findsOneWidget);
  });
}
