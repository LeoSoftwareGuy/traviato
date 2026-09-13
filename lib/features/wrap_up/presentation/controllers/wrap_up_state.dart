import 'package:equatable/equatable.dart';

import '../../domain/entities/wrap_up_entity.dart';

class WrapUpState extends Equatable {
  const WrapUpState({required this.wrapUp, this.photoUrlById = const {}});

  final WrapUpEntity wrapUp;

  /// `photos.id -> signed imageUrl`, resolved once for the whole screen —
  /// every moment/flurry photo references a trip photo only by id.
  final Map<String, String> photoUrlById;

  String? imageUrlForPhoto(String? photoId) =>
      photoId == null ? null : photoUrlById[photoId];

  WrapUpState copyWith({WrapUpEntity? wrapUp}) =>
      WrapUpState(wrapUp: wrapUp ?? this.wrapUp, photoUrlById: photoUrlById);

  @override
  List<Object?> get props => [wrapUp, photoUrlById];
}
