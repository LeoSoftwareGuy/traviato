import 'package:equatable/equatable.dart';

import 'wrap_up_photo_ref.dart';

/// Every photo not shown in a Moment, in chronological order (#125
/// `flurry_leftovers`). [totalRemainingLabel] speaks the count of photos
/// shown nowhere in the film, or `null` under the spec's ~10 threshold.
///
/// [flurry1]/[flurry2] are the generator's resolved Flurry contents (#151)
/// — an empty list means that scene is cut entirely. Pre-#151 wrap-ups
/// don't carry them; see `WrapUpEntity.flurry1Photos` for the fallback.
class WrapUpFlurryLeftovers extends Equatable {
  const WrapUpFlurryLeftovers({
    this.photos = const [],
    this.flurry1 = const [],
    this.flurry2 = const [],
    this.totalRemainingLabel,
  });

  final List<WrapUpPhotoRef> photos;
  final List<WrapUpPhotoRef> flurry1;
  final List<WrapUpPhotoRef> flurry2;
  final String? totalRemainingLabel;

  @override
  List<Object?> get props => [photos, flurry1, flurry2, totalRemainingLabel];
}
