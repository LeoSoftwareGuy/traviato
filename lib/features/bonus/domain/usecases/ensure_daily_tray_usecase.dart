import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../trip/domain/entities/trip_card_entity.dart';
import '../draw/bonus_tray_draw.dart';
import '../entities/bonus_task_assignment_entity.dart';
import '../entities/bonus_task_template_entity.dart';
import '../repositories/bonus_task_repository.dart';

/// The templates + this trip's full assignment history, after ensuring
/// today's tray (and, if due, a streak-saver) exist.
class BonusTrayResult extends Equatable {
  const BonusTrayResult({required this.templates, required this.assignments});

  final List<BonusTaskTemplateEntity> templates;
  final List<BonusTaskAssignmentEntity> assignments;

  @override
  List<Object?> get props => [templates, assignments];
}

/// Orchestrates the one real piece of business logic in this feature:
/// on first load for an active trip, draw + persist today's tray if it
/// doesn't exist yet, and separately insert a streak-saver if the user has
/// gone quiet. Reused by both the tray screen and the Home badge-dot
/// provider so both reflect the same state (guidelines doc 05 — a use case
/// is warranted once real orchestration/reuse appears).
class EnsureDailyTrayUseCase {
  EnsureDailyTrayUseCase({required BonusTaskRepository repository})
    : _repo = repository;

  final BonusTaskRepository _repo;

  Future<Either<Failure, BonusTrayResult>> call({
    required TripCardEntity trip,
    required DateTime today,
    required Set<DateTime> activityDates,
  }) async {
    try {
      final templates = await _require(_repo.getTemplates());
      var assignments = await _require(_repo.getAssignmentsForTrip(trip.id));

      final start = trip.startDate;
      final end = trip.endDate;
      if (start != null && end != null) {
        final day = _dateOnly(today);
        final startDay = _dateOnly(start);
        final endDay = _dateOnly(end);
        final isActiveToday = !day.isBefore(startDay) && !day.isAfter(endDay);

        if (isActiveToday) {
          final templatesById = {for (final t in templates) t.id: t};

          final hasRegularToday = assignments.any((a) {
            if (a.tripId != trip.id || !_sameDate(a.dayDate, day)) {
              return false;
            }
            return templatesById[a.templateId]?.kind !=
                BonusTaskKind.streakSaver;
          });
          if (!hasRegularToday) {
            final picks = BonusTrayDraw.drawDaily(
              tripId: trip.id,
              dayDate: day,
              tripStartDate: startDay,
              tripEndDate: endDay,
              templates: templates,
              existingAssignments: assignments,
            );
            if (picks.isNotEmpty) {
              final inserted = await _require(
                _repo.assignForDay(
                  tripId: trip.id,
                  dayDate: day,
                  templateIds: [for (final p in picks) p.id],
                ),
              );
              assignments = _merge(assignments, inserted);
            }
          }

          final hasActiveStreakSaver = assignments.any((a) {
            if (a.tripId != trip.id || a.isCompleted) return false;
            return templatesById[a.templateId]?.kind ==
                BonusTaskKind.streakSaver;
          });
          if (!hasActiveStreakSaver &&
              BonusTrayDraw.isStreakSaverDue(
                today: day,
                activityDates: activityDates,
              )) {
            final streakTemplate = templates
                .where((t) => t.kind == BonusTaskKind.streakSaver)
                .firstOrNull;
            if (streakTemplate != null) {
              final inserted = await _require(
                _repo.assignForDay(
                  tripId: trip.id,
                  dayDate: day,
                  templateIds: [streakTemplate.id],
                ),
              );
              assignments = _merge(assignments, inserted);
            }
          }
        }
      }

      return Right(
        BonusTrayResult(templates: templates, assignments: assignments),
      );
    } on _FailureSignal catch (e) {
      return Left(e.failure);
    }
  }

  Future<T> _require<T>(Future<Either<Failure, T>> future) async {
    final either = await future;
    return either.fold((f) => throw _FailureSignal(f), (r) => r);
  }
}

List<BonusTaskAssignmentEntity> _merge(
  List<BonusTaskAssignmentEntity> existing,
  List<BonusTaskAssignmentEntity> fresh,
) {
  final byId = {for (final a in existing) a.id: a};
  for (final a in fresh) {
    byId[a.id] = a;
  }
  return byId.values.toList();
}

class _FailureSignal implements Exception {
  _FailureSignal(this.failure);
  final Failure failure;
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

bool _sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
