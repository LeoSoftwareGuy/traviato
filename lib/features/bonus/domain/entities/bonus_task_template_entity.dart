import 'package:equatable/equatable.dart';

/// Gates which day of a trip a template can be drawn on (docs/data-model.md).
enum BonusTaskPhase {
  arrival('arrival'),
  middle('middle'),
  departure('departure'),
  anytime('anytime');

  const BonusTaskPhase(this.dbValue);

  final String dbValue;

  static BonusTaskPhase fromDbValue(String value) =>
      values.firstWhere((p) => p.dbValue == value);
}

/// Gates how a template is offered — the daily draw only ever picks
/// [regular] (plus one [starter] on day one); [stretch], [milestone], and
/// [streakSaver] are inserted by their own dedicated rules, never by the
/// regular draw (functionality.md §12).
enum BonusTaskKind {
  regular('regular'),
  starter('starter'),
  stretch('stretch'),
  milestone('milestone'),
  streakSaver('streak_saver');

  const BonusTaskKind(this.dbValue);

  final String dbValue;

  static BonusTaskKind fromDbValue(String value) =>
      values.firstWhere((k) => k.dbValue == value);
}

/// A row from the seeded `bonus_task_templates` pool — the fill-in-the-blank
/// shape a day's tray draws from. Read-only from the client.
class BonusTaskTemplateEntity extends Equatable {
  const BonusTaskTemplateEntity({
    required this.id,
    required this.code,
    required this.title,
    this.detail,
    required this.points,
    required this.phase,
    required this.kind,
  });

  final int id;
  final String code;
  final String title;
  final String? detail;
  final int points;
  final BonusTaskPhase phase;
  final BonusTaskKind kind;

  @override
  List<Object?> get props => [id, code, title, detail, points, phase, kind];
}
