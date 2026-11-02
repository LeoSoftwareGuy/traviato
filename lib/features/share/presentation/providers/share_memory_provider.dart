import 'package:equatable/equatable.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/presentation_failure_exception.dart';
import '../../../bonus/presentation/providers/bonus_task_providers.dart';
import '../../../photo/domain/entities/photo_entity.dart';
import '../../../photo/presentation/providers/photo_providers.dart';
import '../../../trip/domain/entities/trip_card_entity.dart';
import '../../../trip/presentation/providers/trip_providers.dart';
import '../../domain/share_teaser_photos.dart';

part 'share_memory_provider.g.dart';

/// What the share sheet, QR and story card show about a memory (#311): its
/// card (title, place, dates, cover) and the 6 teaser photos the link
/// shares, cover first — the story card's cover picker.
class ShareMemory extends Equatable {
  const ShareMemory({required this.trip, required this.teaserPhotos});

  final TripCardEntity trip;
  final List<PhotoEntity> teaserPhotos;

  @override
  List<Object?> get props => [trip, teaserPhotos];
}

@riverpod
Future<ShareMemory> shareMemory(Ref ref, String tripId) async {
  final trip = (await ref.watch(tripRepositoryProvider).getTripCard(tripId))
      .getOrElse((f) => throw PresentationFailureException(f));
  final photos =
      (await ref.watch(photoRepositoryProvider).getPhotosForTrip(tripId))
          .getOrElse((_) => const []);
  final assignments =
      (await ref
              .watch(bonusTaskRepositoryProvider)
              .getAssignmentsForTrip(tripId))
          .getOrElse((_) => const []);
  final completed =
      assignments
          .where((a) => a.completedAt != null && a.photoId != null)
          .toList()
        ..sort((a, b) => a.completedAt!.compareTo(b.completedAt!));
  return ShareMemory(
    trip: trip,
    teaserPhotos: shareTeaserPhotos(
      photos: photos,
      bonusPhotoIds: [for (final a in completed) a.photoId!],
      coverImagePath: trip.coverImagePath,
    ),
  );
}
