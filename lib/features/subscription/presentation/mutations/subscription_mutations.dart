import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/presentation_failure_exception.dart';
import '../../../../core/events/global_event.dart';
import '../../../../core/events/global_event_bus.dart';
import '../../domain/entities/entitlement_entity.dart';
import '../providers/subscription_providers.dart';

/// `null` success value means the user cancelled the store sheet — the page
/// distinguishes this from a real purchase to decide whether to show the
/// "Trial started" confirmation.
final purchaseMutation = Mutation<EntitlementEntity?>();
final restoreMutation = Mutation<EntitlementEntity>();

Future<EntitlementEntity?> runPurchase({
  required WidgetRef ref,
  required String offeringIdentifier,
}) {
  return purchaseMutation.run(ref, (tsx) async {
    final repo = tsx.get(subscriptionRepositoryProvider);
    final result = await repo.purchase(offeringIdentifier);
    final entitlement = result.fold(
      (f) => throw PresentationFailureException(f),
      (entitlement) => entitlement,
    );
    if (entitlement != null) {
      tsx
          .get(globalEventBusProvider)
          .add(EntitlementUpdatedDispatched(entitlement: entitlement));
    }
    return entitlement;
  });
}

Future<EntitlementEntity> runRestore({required WidgetRef ref}) {
  return restoreMutation.run(ref, (tsx) async {
    final repo = tsx.get(subscriptionRepositoryProvider);
    final result = await repo.restore();
    final entitlement = result.fold(
      (f) => throw PresentationFailureException(f),
      (entitlement) => entitlement,
    );
    tsx
        .get(globalEventBusProvider)
        .add(EntitlementUpdatedDispatched(entitlement: entitlement));
    return entitlement;
  });
}
