import 'package:equatable/equatable.dart';

/// One scene of the director's film plan (#328, plan_version 2): its type
/// (`card_flip`, `collage_3`, `burst`, …), the photos it shows in order,
/// the note it illustrates, a text card's line, and how long it lasts.
class FilmPlanScene extends Equatable {
  const FilmPlanScene({
    required this.type,
    this.photoIds = const [],
    this.captionNoteId,
    this.text,
    required this.durationSeconds,
    this.isHero = false,
  });

  final String type;
  final List<String> photoIds;
  final String? captionNoteId;
  final String? text;
  final double durationSeconds;
  final bool isHero;

  @override
  List<Object?> get props => [
    type,
    photoIds,
    captionNoteId,
    text,
    durationSeconds,
    isHero,
  ];
}
