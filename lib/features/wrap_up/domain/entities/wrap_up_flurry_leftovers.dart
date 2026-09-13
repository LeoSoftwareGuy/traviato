import 'package:equatable/equatable.dart';

import 'wrap_up_photo_ref.dart';

/// Every photo not shown as a Moment, in chronological order (#125
/// `flurry_leftovers`). The player only ever displays the first 30 (15 in
/// Flurry1, 15 in Flurry2) — [totalRemainingLabel] speaks the true count
/// beyond that cap, or `null` when it's under the spec's ~10 threshold.
class WrapUpFlurryLeftovers extends Equatable {
  const WrapUpFlurryLeftovers({
    this.photos = const [],
    this.totalRemainingLabel,
  });

  final List<WrapUpPhotoRef> photos;
  final String? totalRemainingLabel;

  @override
  List<Object?> get props => [photos, totalRemainingLabel];
}
