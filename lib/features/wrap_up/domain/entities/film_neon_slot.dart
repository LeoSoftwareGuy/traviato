import 'package:equatable/equatable.dart';

/// One slot of a Neon Night (#454) or Golden Vows (#458) film as the
/// director run left it (`wrap_ups.director.neon_slots` / `gv_slots`): the
/// candidates code listed, what the director picked, what plays and why.
/// Debug-only, for the Plan inspector.
class FilmNeonSlot extends Equatable {
  const FilmNeonSlot({
    required this.slot,
    this.candidates = const [],
    this.pickedIds = const [],
    this.freeText,
    this.chosenIds = const [],
    this.chosen = const [],
    this.source = 'none',
    this.reason = '',
  });

  /// `note`, `headline`, `ch1.title`, `ch1.card`, `ch1.m1`, …
  final String slot;

  /// Code's list, best first.
  final List<FilmNeonCandidate> candidates;

  /// The director's ids, without their slot prefix; empty when it picked
  /// none (or never ran).
  final List<String> pickedIds;

  /// The director's own title or headline, if it wrote one.
  final String? freeText;

  /// What plays: candidate ids (`free` for the director's own words,
  /// `day` for "Day N").
  final List<String> chosenIds;
  final List<String> chosen;

  /// `director`, `code` or `none`.
  final String source;
  final String reason;

  @override
  List<Object?> get props => [
    slot,
    candidates,
    pickedIds,
    freeText,
    chosenIds,
    chosen,
    source,
    reason,
  ];
}

class FilmNeonCandidate extends Equatable {
  const FilmNeonCandidate({
    required this.id,
    required this.text,
    this.score = 0,
  });

  final String id;
  final String text;
  final int score;

  @override
  List<Object?> get props => [id, text, score];
}
