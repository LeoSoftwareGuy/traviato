import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/presentation_failure_exception.dart';
import '../../../../core/events/global_event.dart';
import '../../../../core/events/global_event_bus.dart';
import '../../../../core/providers/supabase_providers.dart';
import '../../../trip/domain/entities/trip_card_entity.dart';
import '../../../trip/presentation/providers/trip_providers.dart';
import '../../data/datasources/star_breakdown_remote_data_source.dart';
import '../../data/datasources/supabase_star_breakdown_remote_data_source.dart';
import '../../data/repositories/star_breakdown_repository_impl.dart';
import '../../domain/draw/bonus_tray_draw.dart';
import '../../domain/entities/bonus_task_template_entity.dart';
import '../../domain/entities/star_summary.dart';
import '../../domain/repositories/star_breakdown_repository.dart';
import '../controllers/bonus_empty_state.dart';
import 'bonus_task_providers.dart';

part 'bonus_empty_state_providers.g.dart';

@riverpod
StarBreakdownRemoteDataSource starBreakdownRemoteDataSource(Ref ref) =>
    SupabaseStarBreakdownRemoteDataSource(
      client: ref.watch(supabaseClientProvider),
    );

@riverpod
StarBreakdownRepository starBreakdownRepository(Ref ref) =>
    StarBreakdownRepositoryImpl(
      remote: ref.watch(starBreakdownRemoteDataSourceProvider),
    );

/// "Now" for the Bonus page's state choice — overridden in tests so the
/// days-until math can be pinned to a date (#219).
@riverpod
DateTime Function() bonusClock(Ref ref) => DateTime.now;

/// The user's memories, refetched whenever one is created, changed or
/// deleted, or stars move.
@riverpod
Future<List<TripCardEntity>> bonusTripCards(Ref ref) async {
  final sub = ref.watch(globalEventBusProvider).stream.listen((event) {
    if (event is! EntitlementUpdatedDispatched &&
        event is! FilmPhotosChangedDispatched) {
      ref.invalidateSelf();
    }
  });
  ref.onDispose(sub.cancel);

  return (await ref.watch(tripRepositoryProvider).getTripCards()).fold(
    (failure) => throw PresentationFailureException(failure),
    (trips) => trips,
  );
}

/// Stars by type and by memory (frames 1a/1b, and the All memories list).
@riverpod
Future<StarSummary> starSummary(Ref ref) async {
  final trips = await ref.watch(bonusTripCardsProvider.future);
  final groups =
      (await ref.watch(starBreakdownRepositoryProvider).getBreakdown()).fold(
        (failure) => throw PresentationFailureException(failure),
        (groups) => groups,
      );
  return StarSummary.fromGroups(groups, trips);
}

@riverpod
Future<BonusEmptyState> bonusEmptyState(Ref ref) async {
  final trips = await ref.watch(bonusTripCardsProvider.future);
  final summary = await ref.watch(starSummaryProvider.future);
  final state = BonusEmptyState.resolve(
    trips: trips,
    summary: summary,
    today: ref.watch(bonusClockProvider)(),
  );
  if (state is! BonusUpcoming) return state;
  return BonusUpcoming(
    trip: state.trip,
    daysUntil: state.daysUntil,
    summary: state.summary,
    teasers: await _firstDayTeasers(ref, state.trip),
  );
}

/// The two regular tasks the memory's first-day tray will actually draw —
/// the draw is deterministic, so the preview is honest. Best-effort: the
/// page reads fine without them.
Future<List<BonusTaskTemplateEntity>> _firstDayTeasers(
  Ref ref,
  TripCardEntity trip,
) async {
  final templates = await ref.watch(bonusTaskRepositoryProvider).getTemplates();
  return templates.fold(
    (failure) {
      debugPrint('Bonus teaser templates failed to load: $failure');
      return const [];
    },
    (templates) => BonusTrayDraw.drawDaily(
      tripId: trip.id,
      dayDate: trip.startDate!,
      tripStartDate: trip.startDate!,
      tripEndDate: trip.endDate,
      templates: templates,
      existingAssignments: const [],
    ).where((t) => t.kind == BonusTaskKind.regular).take(2).toList(),
  );
}
