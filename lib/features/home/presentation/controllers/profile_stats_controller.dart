import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/presentation_failure_exception.dart';
import '../../../../core/events/global_event.dart';
import '../../../../core/events/global_event_bus.dart';
import '../../domain/entities/profile_stats_entity.dart';
import '../providers/profile_stats_provider.dart';

part 'profile_stats_controller.g.dart';

/// Home's stats-bar totals and stars badge. Refetches whenever a
/// [StarsAwardedDispatched] event arrives — quest check-off, day-note
/// save, photo add, or bonus-task completion (issue #77) — so the badge
/// updates live instead of only on the next cold load.
@riverpod
class ProfileStatsController extends _$ProfileStatsController {
  @override
  Future<ProfileStatsEntity> build() async {
    final sub = ref.watch(globalEventBusProvider).stream.listen(_onEvent);
    ref.onDispose(sub.cancel);
    return _fetch();
  }

  void _onEvent(GlobalEvent event) {
    if (event is StarsAwardedDispatched) ref.invalidateSelf();
  }

  Future<ProfileStatsEntity> _fetch() async {
    final repo = ref.watch(profileStatsRepositoryProvider);
    return (await repo.getStats()).fold(
      (failure) => throw PresentationFailureException(failure),
      (stats) => stats,
    );
  }
}
