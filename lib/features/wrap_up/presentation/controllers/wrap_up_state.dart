import 'package:equatable/equatable.dart';

import '../../domain/entities/wrap_up_entity.dart';
import '../film/sky_story/sky_story.dart';

class WrapUpState extends Equatable {
  const WrapUpState({
    required this.wrapUp,
    this.photoUrlById = const {},
    this.isOutOfDate = false,
    this.skyStory,
  });

  final WrapUpEntity wrapUp;

  /// A kept film whose photos or picks changed since it was built (#294) —
  /// offers "Photos changed · Rebuild film".
  final bool isOutOfDate;

  /// `photos.id -> signed imageUrl`, resolved once for the whole screen —
  /// every moment/flurry photo references a trip photo only by id.
  final Map<String, String> photoUrlById;

  /// The Sky Story film for this wrap-up (#345), from `content.sky` and
  /// the memory's photos; null plays the classic film. Not played yet
  /// outside the debug preview (phase 7).
  final SkyStory? skyStory;

  String? imageUrlForPhoto(String? photoId) =>
      photoId == null ? null : photoUrlById[photoId];

  WrapUpState copyWith({WrapUpEntity? wrapUp}) => WrapUpState(
    wrapUp: wrapUp ?? this.wrapUp,
    photoUrlById: photoUrlById,
    isOutOfDate: isOutOfDate,
    skyStory: skyStory,
  );

  @override
  List<Object?> get props => [wrapUp, photoUrlById, isOutOfDate, skyStory];
}
