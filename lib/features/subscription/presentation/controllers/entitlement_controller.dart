import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/presentation_failure_exception.dart';
import '../../../../core/events/global_event.dart';
import '../../../../core/events/global_event_bus.dart';
import '../../domain/entities/entitlement_entity.dart';
import '../providers/subscription_providers.dart';

part 'entitlement_controller.g.dart';

/// The shared read of the caller's tier — M6-3/M6-4/M6-5/M6-6 gate their UI
/// on this rather than each re-fetching `entitlements` themselves.
@riverpod
class EntitlementController extends _$EntitlementController {
  @override
  Future<EntitlementEntity> build() async {
    final sub = ref.watch(globalEventBusProvider).stream.listen(_onGlobalEvent);
    ref.onDispose(sub.cancel);

    final repo = ref.watch(subscriptionRepositoryProvider);
    final result = await repo.getEntitlement();
    return result.fold(
      (f) => throw PresentationFailureException(f),
      (entitlement) => entitlement,
    );
  }

  void _onGlobalEvent(GlobalEvent event) {
    switch (event) {
      case EntitlementUpdatedDispatched(:final entitlement):
        state = AsyncData(entitlement);
      case TripCreatedDispatched():
      case TripDeletedDispatched():
      case TripUpdatedDispatched():
      case StarsAwardedDispatched():
      case WrapUpPublishedDispatched():
      // Not relevant to entitlement state.
    }
  }
}
