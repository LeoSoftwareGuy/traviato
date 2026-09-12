import 'package:equatable/equatable.dart';

import 'wrap_up_photo_ref.dart';

/// One of the film's up-to-8 Moment slots (#125 `moments`). [note] is the
/// traveller's own caption verbatim — `null` when the photo has none, never
/// a generated substitute. [badge] is non-null only for the (at most 3)
/// bonus-task completion photos, already formatted as
/// `"Dare · {title} · ✦{points}"` by the edge function.
class WrapUpMoment extends Equatable {
  const WrapUpMoment({
    required this.photoId,
    this.dayDate,
    this.note,
    this.badge,
  });

  final String photoId;
  final DateTime? dayDate;
  final String? note;
  final String? badge;

  WrapUpPhotoRef get photoRef =>
      WrapUpPhotoRef(photoId: photoId, dayDate: dayDate);

  @override
  List<Object?> get props => [photoId, dayDate, note, badge];
}
