import 'package:equatable/equatable.dart';

import '../../../trip/domain/entities/trip_card_entity.dart';
import '../../domain/entities/quest_entity.dart';

class PlanState extends Equatable {
  const PlanState({
    required this.trip,
    required this.quests,
    this.currentDayDate,
  });

  final TripCardEntity trip;
  final List<QuestEntity> quests;
  final DateTime? currentDayDate;

  /// A trip needs both dates before it can be planned day-by-day.
  bool get hasDateRange => trip.startDate != null && trip.endDate != null;

  int get totalDays =>
      hasDateRange ? trip.endDate!.difference(trip.startDate!).inDays + 1 : 0;

  int get totalQuestsPlanned => quests.length;

  int? get currentDayNumber {
    final day = currentDayDate;
    if (!hasDateRange || day == null) return null;
    return day.difference(trip.startDate!).inDays + 1;
  }

  bool get canGoToPreviousDay {
    final day = currentDayDate;
    return hasDateRange && day != null && day.isAfter(trip.startDate!);
  }

  bool get canGoToNextDay {
    final day = currentDayDate;
    return hasDateRange && day != null && day.isBefore(trip.endDate!);
  }

  List<QuestEntity> get questsForCurrentDay {
    final day = currentDayDate;
    if (day == null) return const [];
    final forDay = quests.where((q) => _isSameDate(q.dayDate, day)).toList()
      ..sort(_byTimeThenPosition);
    return forDay;
  }

  PlanState copyWith({
    TripCardEntity? trip,
    List<QuestEntity>? quests,
    DateTime? Function()? currentDayDate,
  }) => PlanState(
    trip: trip ?? this.trip,
    quests: quests ?? this.quests,
    currentDayDate: currentDayDate != null
        ? currentDayDate()
        : this.currentDayDate,
  );

  @override
  List<Object?> get props => [trip, quests, currentDayDate];
}

int _byTimeThenPosition(QuestEntity a, QuestEntity b) {
  final at = a.time;
  final bt = b.time;
  if (at == null && bt == null) return a.position.compareTo(b.position);
  if (at == null) return 1;
  if (bt == null) return -1;
  final cmp = at.compareTo(bt);
  return cmp != 0 ? cmp : a.position.compareTo(b.position);
}

bool _isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
