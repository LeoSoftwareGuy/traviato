import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/config/router/app_router.dart';
import '../../../../core/config/router/route_constants.dart';
import '../../../../core/events/global_event.dart';
import '../../../../core/events/global_event_bus.dart';
import '../../../settings/presentation/controllers/app_language_controller.dart';
import '../../../trip/domain/entities/trip_card_entity.dart';
import '../../../trip/presentation/providers/trip_providers.dart';
import '../../domain/rules/bonus_notification_rules.dart';
import '../providers/notification_providers.dart';

part 'bonus_notifications_lifecycle_controller.g.dart';

/// Owns the whole local-notification lifecycle for the bonus daily-tray
/// loop (issue #65): plugin init, the arrival-notification reaction to
/// trip create/edit/delete, the app-open/close-driven re-evaluation of
/// today's morning/evening nudges, and routing a tapped notification to the
/// tray. `keepAlive` — this must survive for the whole app session, exactly
/// like the global event bus it subscribes to (guidelines doc 02).
/// Instantiated once by `ref.watch`ing this provider from
/// `TraviatoApp.build()` in `main.dart`.
@Riverpod(keepAlive: true)
class BonusNotificationsLifecycleController
    extends _$BonusNotificationsLifecycleController {
  AppLifecycleListener? _lifecycleListener;

  @override
  void build() {
    final notificationRepo = ref.watch(bonusNotificationRepositoryProvider);
    unawaited(notificationRepo.init(onNotificationTap: _onNotificationTap));

    final eventSub = ref
        .watch(globalEventBusProvider)
        .stream
        .listen(_onGlobalEvent);
    ref.onDispose(eventSub.cancel);

    _lifecycleListener = AppLifecycleListener(
      onResume: () => unawaited(_evaluate()),
      onPause: () => unawaited(_evaluate()),
    );
    ref.onDispose(() => _lifecycleListener?.dispose());

    // Pending reminders carry the language they were scheduled in, so a
    // switch re-schedules them all in the new one (#252).
    ref.listen(appLocaleProvider, (previous, next) {
      if (previous != next) unawaited(_rescheduleAll());
    });

    unawaited(_evaluate());
  }

  /// Re-evaluates today's morning/evening pair and re-schedules every
  /// memory's arrival reminder (or cancels it if its day has passed).
  Future<void> _rescheduleAll() async {
    await _evaluate();
    try {
      final trips = await ref.read(tripRepositoryProvider).getTripCards();
      for (final trip in trips.getOrElse((_) => const [])) {
        await _scheduleOrCancelArrival(trip);
      }
    } catch (e) {
      debugPrint('Re-scheduling arrival reminders threw: $e');
    }
  }

  /// Wrapped in a broad `try/catch`, not just an `Either` fold: unlike a
  /// user-triggered mutation, this runs silently off app lifecycle events
  /// with nothing to show a failure to, so even a provider-construction
  /// error (e.g. a dependency not yet ready) should log and degrade rather
  /// than propagate into `build()`'s caller (guidelines doc 03).
  Future<void> _evaluate() async {
    try {
      final useCase = ref.read(evaluateBonusNotificationsUseCaseProvider);
      final result = await useCase(now: DateTime.now());
      result.fold(
        (f) => debugPrint('Bonus notification evaluation failed: ${f.message}'),
        (_) {},
      );
    } catch (e) {
      debugPrint('Bonus notification evaluation threw: $e');
    }
  }

  void _onGlobalEvent(GlobalEvent event) {
    switch (event) {
      case TripCreatedDispatched(:final trip):
        unawaited(_scheduleOrCancelArrival(trip));
      case TripUpdatedDispatched(:final trip):
        unawaited(_scheduleOrCancelArrival(trip));
      case TripDeletedDispatched(:final tripId):
        unawaited(
          ref.read(bonusNotificationRepositoryProvider).cancelArrival(tripId),
        );
      case StarsAwardedDispatched():
      case WrapUpPublishedDispatched():
      case EntitlementUpdatedDispatched():
      // Not relevant to the notification schedule directly — the next
      // resume/pause evaluation re-derives everything it needs itself.
    }
  }

  Future<void> _scheduleOrCancelArrival(TripCardEntity trip) async {
    final repo = ref.read(bonusNotificationRepositoryProvider);
    final start = trip.startDate;
    if (start == null ||
        !BonusNotificationRules.shouldScheduleArrival(
          now: DateTime.now(),
          startDate: start,
        )) {
      await repo.cancelArrival(trip.id);
      return;
    }
    await repo.scheduleArrival(
      fireAt: BonusNotificationRules.arrivalFireTime(start),
      tripId: trip.id,
    );
  }

  void _onNotificationTap(String? payload) {
    final router = ref.read(routerProvider);
    try {
      if (payload != null && payload.isNotEmpty) {
        router.pushNamed(
          RouteNames.tripBonusTasks,
          pathParameters: {'tripId': payload},
        );
      } else {
        router.pushNamed(RouteNames.bonusTasks);
      }
    } catch (e) {
      // Best-effort: a cold-start tap can arrive before the router's
      // Navigator is attached (see #65's plan comment, assumption 4).
      debugPrint('Could not deep-link a bonus notification tap: $e');
    }
  }
}
