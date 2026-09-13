import 'package:equatable/equatable.dart';

import 'wrap_up_cover_photo.dart';
import 'wrap_up_dates.dart';
import 'wrap_up_flurry_leftovers.dart';
import 'wrap_up_footnote.dart';
import 'wrap_up_invitation.dart';
import 'wrap_up_keepsake.dart';
import 'wrap_up_moment.dart';
import 'wrap_up_unlock.dart';

/// The generated Wrap-Up Film data (docs/data-model.md `wrap_ups`, #125's
/// schema). Every field is parsed defensively at the data layer — a
/// malformed field falls back to an empty/neutral default rather than
/// throwing, so playback degrades gracefully instead of crashing (#126 AC).
class WrapUpEntity extends Equatable {
  const WrapUpEntity({
    required this.dates,
    required this.coverPhoto,
    required this.invitation,
    this.bridges = const ['', '', ''],
    this.moments = const [],
    this.flurryLeftovers = const WrapUpFlurryLeftovers(),
    required this.footnote,
    this.unlock,
    required this.keepsake,
    required this.generatedAt,
    this.publishedAt,
  });

  final WrapUpDates dates;
  final WrapUpCoverPhoto coverPhoto;
  final WrapUpInvitation invitation;

  /// Always exactly 3 entries — AI text, never a photograph.
  final List<String> bridges;
  final List<WrapUpMoment> moments;
  final WrapUpFlurryLeftovers flurryLeftovers;
  final WrapUpFootnote footnote;
  final WrapUpUnlock? unlock;
  final WrapUpKeepsake keepsake;
  final DateTime generatedAt;
  final DateTime? publishedAt;

  bool get isPublished => publishedAt != null;

  WrapUpEntity copyWith({DateTime? Function()? publishedAt}) => WrapUpEntity(
    dates: dates,
    coverPhoto: coverPhoto,
    invitation: invitation,
    bridges: bridges,
    moments: moments,
    flurryLeftovers: flurryLeftovers,
    footnote: footnote,
    unlock: unlock,
    keepsake: keepsake,
    generatedAt: generatedAt,
    publishedAt: publishedAt != null ? publishedAt() : this.publishedAt,
  );

  @override
  List<Object?> get props => [
    dates,
    coverPhoto,
    invitation,
    bridges,
    moments,
    flurryLeftovers,
    footnote,
    unlock,
    keepsake,
    generatedAt,
    publishedAt,
  ];
}
