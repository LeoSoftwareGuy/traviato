import 'package:equatable/equatable.dart';

import 'wrap_up_cover_photo.dart';
import 'wrap_up_dates.dart';
import 'wrap_up_film_cut.dart';
import 'wrap_up_flurry_leftovers.dart';
import 'wrap_up_footnote.dart';
import 'wrap_up_invitation.dart';
import 'wrap_up_keepsake.dart';
import 'wrap_up_moment.dart';
import 'wrap_up_photo_ref.dart';
import 'wrap_up_unlock.dart';

/// The generated Wrap-Up Film data (docs/data-model.md `wrap_ups`, #125's
/// schema). Every field is parsed defensively at the data layer — a
/// malformed field falls back to an empty/neutral default rather than
/// throwing, so playback degrades gracefully instead of crashing (#126 AC).
class WrapUpEntity extends Equatable {
  const WrapUpEntity({
    this.cut,
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

  /// The generator's resolved film plan (#151); `null` for a wrap-up
  /// generated before cuts existed, which plays exactly as it always did.
  final WrapUpFilmCut? cut;

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

  /// Pre-#151 wrap-ups carry no resolved Flurry lists, so the player keeps
  /// its original split of the leftovers: the first 15, then the next 15.
  bool get _isLegacy => cut == null;

  /// What Flurry1 shows; empty means the scene is cut.
  List<WrapUpPhotoRef> get flurry1Photos => _isLegacy
      ? flurryLeftovers.photos.take(15).toList()
      : flurryLeftovers.flurry1;

  /// What Flurry2 shows; empty means the scene is cut.
  List<WrapUpPhotoRef> get flurry2Photos => _isLegacy
      ? flurryLeftovers.photos.skip(15).take(15).toList()
      : flurryLeftovers.flurry2;

  WrapUpEntity copyWith({DateTime? Function()? publishedAt}) => WrapUpEntity(
    cut: cut,
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
    cut,
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
