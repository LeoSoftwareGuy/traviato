import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/presentation_failure_exception.dart';
import '../../../../core/events/global_event.dart';
import '../../../../core/events/global_event_bus.dart';
import '../../../trip/presentation/providers/trip_providers.dart';
import 'home_state.dart';

part 'home_controller.g.dart';

@riverpod
class HomeController extends _$HomeController {
  @override
  Future<HomeState> build() async {
    final sub = ref.watch(globalEventBusProvider).stream.listen(_onEvent);
    ref.onDispose(sub.cancel);

    final repo = ref.watch(tripRepositoryProvider);
    final result = await repo.getTripCards();
    return result.fold(
      (failure) => throw PresentationFailureException(failure),
      (trips) => HomeState(trips: trips),
    );
  }

  void _onEvent(GlobalEvent event) {
    final current = state.value;
    if (current == null) return;
    switch (event) {
      case TripCreatedDispatched(:final trip):
        if (current.trips.any((t) => t.id == trip.id)) return;
        state = AsyncData(current.copyWith(trips: [trip, ...current.trips]));
    }
  }
}
