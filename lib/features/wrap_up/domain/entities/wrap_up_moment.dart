import 'package:equatable/equatable.dart';

import 'wrap_up_collage_layout.dart';
import 'wrap_up_photo_ref.dart';

/// One of the film's up-to-8 Moment slots (#125 `moments`). [note] is the
/// traveller's own caption verbatim — `null` when the photo has none, never
/// a generated substitute. [badge] is non-null only for the (at most 3)
/// bonus-task completion photos, already formatted as
/// `"Dare · {title} · ✦{points}"` by the edge function.
///
/// [layout] is `null` for a card flip. Otherwise the moment plays as a
/// collage (#151): tile 0 is this moment's photo and [collageExtras] fill
/// tiles 1..n-1 in paint order — photos the generator guarantees appear
/// nowhere else in the film.
class WrapUpMoment extends Equatable {
  const WrapUpMoment({
    required this.photoId,
    this.dayDate,
    this.note,
    this.badge,
    this.layout,
    this.collageExtras = const [],
  });

  final String photoId;
  final DateTime? dayDate;
  final String? note;
  final String? badge;
  final WrapUpCollageLayout? layout;
  final List<WrapUpPhotoRef> collageExtras;

  WrapUpPhotoRef get photoRef =>
      WrapUpPhotoRef(photoId: photoId, dayDate: dayDate);

  /// Every photo this moment can show: its own, then any collage tiles.
  List<WrapUpPhotoRef> get allPhotoRefs => [photoRef, ...collageExtras];

  @override
  List<Object?> get props => [
    photoId,
    dayDate,
    note,
    badge,
    layout,
    collageExtras,
  ];
}
