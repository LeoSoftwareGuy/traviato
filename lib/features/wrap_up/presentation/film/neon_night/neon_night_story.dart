import 'package:equatable/equatable.dart';

/// One row of "Tonight's plan" (#363, NEON_NIGHT_SPEC.md §5.2, §7): a
/// quest with a time, ticked if it was done.
class NnPlanRow extends Equatable {
  const NnPlanRow({required this.time, required this.item, this.done = false});

  /// 'HH:MM'.
  final String time;

  /// The quest's title, in the user's words (shown in capitals).
  final String item;
  final bool done;

  @override
  List<Object?> get props => [time, item, done];
}

/// What the Neon Night film shows of one memory (#363, spec §7). Grows
/// phase by phase: phase 3 has the title, the night's date and the plan.
class NeonNightStory extends Equatable {
  const NeonNightStory({
    required this.title,
    required this.date,
    this.plan = const [],
  });

  /// The memory's title, e.g. "Night out" (shown in capitals).
  final String title;

  /// The night it started; shown as 'SAT 14 NOV' in the UI language.
  final DateTime date;

  /// The memory's quests with times, in order; none → no Plan scene.
  final List<NnPlanRow> plan;

  bool get hasPlan => plan.isNotEmpty;

  @override
  List<Object?> get props => [title, date, plan];
}

/// The spec's reference night (the MP4 in docs/design/neon-night/), for
/// the debug preview and the goldens.
abstract final class NeonNightFixtures {
  static final reference = NeonNightStory(
    title: 'Night out',
    date: DateTime(2026, 11, 14),
    plan: const [
      NnPlanRow(time: '22:00', item: 'Pre-drinks', done: true),
      NnPlanRow(time: '23:30', item: 'Main stage', done: true),
      NnPlanRow(time: '01:00', item: 'Secret room', done: true),
      NnPlanRow(time: '03:00', item: 'Afterparty'),
      NnPlanRow(time: '06:00', item: 'Sunrise'),
    ],
  );

  static final referenceRu = NeonNightStory(
    title: 'Ночь в городе',
    date: DateTime(2026, 11, 14),
    plan: const [
      NnPlanRow(time: '22:00', item: 'Разогрев', done: true),
      NnPlanRow(time: '23:30', item: 'Главная сцена', done: true),
      NnPlanRow(time: '01:00', item: 'Тайная комната', done: true),
      NnPlanRow(time: '03:00', item: 'Афтепати'),
      NnPlanRow(time: '06:00', item: 'Рассвет'),
    ],
  );

  /// A longer plan: 8 quests, so "+3 MORE" shows.
  static final longPlan = NeonNightStory(
    title: 'Festival weekend',
    date: DateTime(2026, 7, 4),
    plan: const [
      NnPlanRow(time: '14:00', item: 'Gates open', done: true),
      NnPlanRow(time: '15:30', item: 'Tent stage', done: true),
      NnPlanRow(time: '18:00', item: 'Food trucks'),
      NnPlanRow(time: '20:00', item: 'Headliner', done: true),
      NnPlanRow(time: '22:00', item: 'Silent disco', done: true),
      NnPlanRow(time: '23:30', item: 'Fireworks', done: true),
      NnPlanRow(time: '01:00', item: 'Afterparty'),
      NnPlanRow(time: '04:00', item: 'Camp'),
    ],
  );
}
