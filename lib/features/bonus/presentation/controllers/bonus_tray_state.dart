import 'package:equatable/equatable.dart';

import '../../../trip/domain/entities/trip_card_entity.dart';
import '../../domain/draw/bonus_tray_draw.dart';
import '../../domain/entities/bonus_task_assignment_entity.dart';
import '../../domain/entities/bonus_task_template_entity.dart';

/// A tray row ready for display — an assignment paired with its resolved
/// template. Presentation-only; never persisted.
class BonusTrayTask extends Equatable {
  const BonusTrayTask({required this.assignment, required this.template});

  final BonusTaskAssignmentEntity assignment;
  final BonusTaskTemplateEntity template;

  bool get isCompleted => assignment.isCompleted;

  @override
  List<Object?> get props => [assignment, template];
}

class BonusTrayState extends Equatable {
  const BonusTrayState({
    required this.trip,
    required this.templates,
    required this.assignments,
    required this.today,
  });

  final TripCardEntity trip;
  final List<BonusTaskTemplateEntity> templates;
  final List<BonusTaskAssignmentEntity> assignments;
  final DateTime today;

  BonusTaskTemplateEntity? _templateFor(int templateId) =>
      templates.where((t) => t.id == templateId).firstOrNull;

  bool _isToday(BonusTaskAssignmentEntity a) =>
      a.dayDate.year == today.year &&
      a.dayDate.month == today.month &&
      a.dayDate.day == today.day;

  List<BonusTrayTask> _resolve(Iterable<BonusTaskAssignmentEntity> rows) => [
    for (final a in rows)
      if (_templateFor(a.templateId) case final template?)
        BonusTrayTask(assignment: a, template: template),
  ];

  /// Today's tray, excluding the streak-saver (rendered separately since it
  /// persists across days).
  List<BonusTrayTask> get todaysTasks => _resolve(
    assignments.where(
      (a) =>
          _isToday(a) &&
          _templateFor(a.templateId)?.kind != BonusTaskKind.streakSaver,
    ),
  )..sort((a, b) => a.assignment.createdAt.compareTo(b.assignment.createdAt));

  /// The 2 (or 3 on day one) daily tasks — excludes a claimed stretch task,
  /// which only appears once both dailies are already done.
  List<BonusTrayTask> get dailyTasks => todaysTasks
      .where((t) => t.template.kind != BonusTaskKind.stretch)
      .toList();

  BonusTrayTask? get claimedStretchToday => todaysTasks
      .where((t) => t.template.kind == BonusTaskKind.stretch)
      .firstOrNull;

  bool get bothDailiesDone =>
      dailyTasks.isNotEmpty && dailyTasks.every((t) => t.isCompleted);

  int get starsEarnedToday => todaysTasks
      .where((t) => t.isCompleted)
      .fold(0, (sum, t) => sum + t.template.points);

  BonusTrayTask? get activeStreakSaver {
    final rows = _resolve(
      assignments.where(
        (a) =>
            !a.isCompleted &&
            _templateFor(a.templateId)?.kind == BonusTaskKind.streakSaver,
      ),
    );
    return rows.firstOrNull;
  }

  /// The opt-in stretch offer — only computed once both dailies are done and
  /// nothing has been claimed yet today. Never auto-inserted.
  BonusTaskTemplateEntity? get stretchOffer {
    if (!bothDailiesDone || claimedStretchToday != null) return null;
    return BonusTrayDraw.pickStretchTemplate(
      tripId: trip.id,
      dayDate: today,
      templates: templates,
      existingAssignments: assignments,
    );
  }

  /// Past completions, most recent first, for the COMPLETED history section.
  List<BonusTrayTask> get completedHistory {
    final rows = _resolve(
      assignments.where((a) => a.isCompleted && !_isToday(a)),
    )..sort((a, b) => b.assignment.dayDate.compareTo(a.assignment.dayDate));
    return rows;
  }

  int dayIndexFor(DateTime dayDate) => trip.startDate == null
      ? 0
      : BonusTrayDraw.dayIndexFor(
          tripStartDate: trip.startDate!,
          dayDate: dayDate,
        );

  BonusTrayState copyWith({
    TripCardEntity? trip,
    List<BonusTaskTemplateEntity>? templates,
    List<BonusTaskAssignmentEntity>? assignments,
  }) => BonusTrayState(
    trip: trip ?? this.trip,
    templates: templates ?? this.templates,
    assignments: assignments ?? this.assignments,
    today: today,
  );

  @override
  List<Object?> get props => [trip, templates, assignments, today];
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
