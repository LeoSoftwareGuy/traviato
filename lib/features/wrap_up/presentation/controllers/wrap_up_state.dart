import 'package:equatable/equatable.dart';

import '../../domain/entities/wrap_up_entity.dart';
import '../film/golden_vows/golden_vows_story.dart';
import '../film/sky_story/sky_story.dart';

class WrapUpState extends Equatable {
  const WrapUpState({
    required this.wrapUp,
    this.photoUrlById = const {},
    this.isOutOfDate = false,
    this.skyStory,
    this.goldenVows,
  });

  final WrapUpEntity wrapUp;

  /// A kept film whose photos or picks changed since it was built (#294) —
  /// offers "Photos changed · Rebuild film".
  final bool isOutOfDate;

  /// `photos.id -> signed imageUrl`, resolved once for the whole screen —
  /// every moment/flurry photo references a trip photo only by id.
  final Map<String, String> photoUrlById;

  /// The Sky Story film for this wrap-up (#345), from `content.sky` and
  /// the memory's photos; null plays the classic film.
  final SkyStory? skyStory;

  /// The Golden Vows film (#346), from `content.golden_vows` and the
  /// memory's photos; it plays before [skyStory] when there is one.
  final GoldenVowsStory? goldenVows;

  String? imageUrlForPhoto(String? photoId) =>
      photoId == null ? null : photoUrlById[photoId];

  WrapUpState copyWith({WrapUpEntity? wrapUp}) => WrapUpState(
    wrapUp: wrapUp ?? this.wrapUp,
    photoUrlById: photoUrlById,
    isOutOfDate: isOutOfDate,
    skyStory: skyStory,
    goldenVows: goldenVows,
  );

  @override
  List<Object?> get props => [
    wrapUp,
    photoUrlById,
    isOutOfDate,
    skyStory,
    goldenVows,
  ];
}
