import 'package:equatable/equatable.dart';

import '../../../trip/domain/entities/trip_card_entity.dart';
import '../../domain/entities/wrap_up_entity.dart';

class WrapUpState extends Equatable {
  const WrapUpState({
    required this.wrapUp,
    required this.trip,
    this.photoUrlById = const {},
  });

  final WrapUpEntity wrapUp;
  final TripCardEntity trip;

  /// `photos.id -> signed imageUrl`, resolved once for the whole screen —
  /// every block references a photo only by id.
  final Map<String, String> photoUrlById;

  String? imageUrlForPhoto(String? photoId) =>
      photoId == null ? null : photoUrlById[photoId];

  WrapUpState copyWith({WrapUpEntity? wrapUp}) => WrapUpState(
    wrapUp: wrapUp ?? this.wrapUp,
    trip: trip,
    photoUrlById: photoUrlById,
  );

  @override
  List<Object?> get props => [wrapUp, trip, photoUrlById];
}
