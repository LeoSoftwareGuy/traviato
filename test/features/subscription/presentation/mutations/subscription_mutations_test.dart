import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/core/errors/presentation_failure_exception.dart';
import 'package:traviato/core/events/global_event.dart';
import 'package:traviato/core/events/global_event_bus.dart';
import 'package:traviato/features/subscription/domain/entities/entitlement_entity.dart';
import 'package:traviato/features/subscription/presentation/mutations/subscription_mutations.dart';
import 'package:traviato/features/subscription/presentation/providers/subscription_providers.dart';

import '../../fakes/fake_subscription_repository.dart';

// Mutation.run needs a WidgetRef, so the run* helpers are exercised through a
// minimal widget harness rather than a bare ProviderContainer (mirrors
// trip_mutations_test.dart).
class _PurchaseHarness extends ConsumerWidget {
  const _PurchaseHarness({required this.offeringIdentifier});

  final String offeringIdentifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      home: Scaffold(
        body: ElevatedButton(
          onPressed: () async {
            try {
              await runPurchase(
                ref: ref,
                offeringIdentifier: offeringIdentifier,
              );
            } catch (_) {
              // Surfaced via the mutation's MutationError state instead.
            }
          },
          child: const Text('Purchase'),
        ),
      ),
    );
  }
}

class _RestoreHarness extends ConsumerWidget {
  const _RestoreHarness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      home: Scaffold(
        body: ElevatedButton(
          onPressed: () async {
            try {
              await runRestore(ref: ref);
            } catch (_) {
              // Surfaced via the mutation's MutationError state instead.
            }
          },
          child: const Text('Restore'),
        ),
      ),
    );
  }
}

Future<ProviderContainer> _pumpHarness(
  WidgetTester tester,
  FakeSubscriptionRepository repo, {
  GlobalEventBus? bus,
  required Widget Function() harness,
}) async {
  late final ProviderContainer container;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        subscriptionRepositoryProvider.overrideWithValue(repo),
        if (bus != null) globalEventBusProvider.overrideWithValue(bus),
      ],
      child: Builder(
        builder: (context) {
          container = ProviderScope.containerOf(context);
          return harness();
        },
      ),
    ),
  );
  return container;
}

void main() {
  testWidgets(
    'purchase success fires EntitlementUpdatedDispatched with the new tier',
    (tester) async {
      final proEntitlement = buildProEntitlement();
      final repo = FakeSubscriptionRepository()
        ..purchaseResult = Right(proEntitlement);
      final bus = GlobalEventBus();
      addTearDown(bus.dispose);
      final events = <GlobalEvent>[];
      final sub = bus.stream.listen(events.add);
      addTearDown(sub.cancel);

      await _pumpHarness(
        tester,
        repo,
        bus: bus,
        harness: () =>
            const _PurchaseHarness(offeringIdentifier: r'$rc_annual'),
      );
      await tester.tap(find.text('Purchase'));
      await tester.pumpAndSettle();

      expect(repo.purchaseCallCount, 1);
      expect(repo.lastPurchasedOfferingIdentifier, r'$rc_annual');
      expect(events, hasLength(1));
      final dispatched = events.single as EntitlementUpdatedDispatched;
      expect(dispatched.entitlement, proEntitlement);
    },
  );

  testWidgets(
    'a cancelled purchase (Right(null)) fires no event and is not an error',
    (tester) async {
      final repo = FakeSubscriptionRepository()
        ..purchaseResult = const Right(null);
      final bus = GlobalEventBus();
      addTearDown(bus.dispose);
      final events = <GlobalEvent>[];
      final sub = bus.stream.listen(events.add);
      addTearDown(sub.cancel);

      final container = await _pumpHarness(
        tester,
        repo,
        bus: bus,
        harness: () =>
            const _PurchaseHarness(offeringIdentifier: r'$rc_annual'),
      );
      container.listen(purchaseMutation, (_, _) {});
      await tester.tap(find.text('Purchase'));
      await tester.pumpAndSettle();

      expect(repo.purchaseCallCount, 1);
      expect(events, isEmpty);
      expect(
        container.read(purchaseMutation),
        isA<MutationSuccess<EntitlementEntity?>>(),
      );
    },
  );

  testWidgets('a purchase failure surfaces as MutationError', (tester) async {
    final repo = FakeSubscriptionRepository()
      ..purchaseResult = const Left(NetworkFailure());

    final container = await _pumpHarness(
      tester,
      repo,
      harness: () => const _PurchaseHarness(offeringIdentifier: r'$rc_annual'),
    );
    container.listen(purchaseMutation, (_, _) {});
    await tester.tap(find.text('Purchase'));
    await tester.pumpAndSettle();

    final state = container.read(purchaseMutation);
    expect(state, isA<MutationError<EntitlementEntity?>>());
    final error = (state as MutationError<EntitlementEntity?>).error;
    expect(error, isA<PresentationFailureException>());
    expect(
      (error as PresentationFailureException).failure,
      isA<NetworkFailure>(),
    );
  });

  testWidgets(
    'restore success fires EntitlementUpdatedDispatched even for a free result',
    (tester) async {
      final repo = FakeSubscriptionRepository()
        ..restoreResult = const Right(EntitlementEntity.free);
      final bus = GlobalEventBus();
      addTearDown(bus.dispose);
      final events = <GlobalEvent>[];
      final sub = bus.stream.listen(events.add);
      addTearDown(sub.cancel);

      await _pumpHarness(
        tester,
        repo,
        bus: bus,
        harness: () => const _RestoreHarness(),
      );
      await tester.tap(find.text('Restore'));
      await tester.pumpAndSettle();

      expect(repo.restoreCallCount, 1);
      expect(events, hasLength(1));
      final dispatched = events.single as EntitlementUpdatedDispatched;
      expect(dispatched.entitlement, EntitlementEntity.free);
    },
  );

  testWidgets('a restore failure surfaces as MutationError', (tester) async {
    final repo = FakeSubscriptionRepository()
      ..restoreResult = const Left(UnknownFailure());

    final container = await _pumpHarness(
      tester,
      repo,
      harness: () => const _RestoreHarness(),
    );
    container.listen(restoreMutation, (_, _) {});
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();

    final state = container.read(restoreMutation);
    expect(state, isA<MutationError<EntitlementEntity>>());
  });
}
