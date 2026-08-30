import 'dart:typed_data';

import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/presentation_failure_exception.dart';
import '../../../../core/events/global_event.dart';
import '../../../../core/events/global_event_bus.dart';
import '../../../journal/presentation/controllers/journal_controller.dart';
import '../../domain/entities/photo_entity.dart';
import '../providers/photo_providers.dart';

final addPhotoMutation = Mutation<PhotoEntity>();

/// Reads EXIF, compresses, uploads, inserts the row, and awards ✦2.
///
/// [rawBytes] must be the *original* picked bytes — EXIF is read from them
/// before [PhotoCompressor] (which strips EXIF) runs. GPS is only kept when
/// [locationPermissionGranted] — the caller resolves that (with its rationale
/// UI) before invoking this, since permission prompts need a `BuildContext`
/// that a mutation shouldn't own.
Future<PhotoEntity> runAddPhoto({
  required WidgetRef ref,
  required String tripId,
  required DateTime dayDate,
  required Uint8List rawBytes,
  required bool locationPermissionGranted,
  String? caption,
  String? placeText,
}) {
  return addPhotoMutation.run(ref, (tsx) async {
    final repo = tsx.get(photoRepositoryProvider);
    final compressor = tsx.get(photoCompressorProvider);
    final exifReader = tsx.get(photoExifReaderProvider);
    final controller = tsx.get(journalControllerProvider(tripId).notifier);

    final exif = await exifReader.read(rawBytes);
    final compressed = await compressor.compress(rawBytes);

    final result = await repo.addPhoto(
      tripId: tripId,
      dayDate: dayDate,
      bytes: compressed,
      fileExtension: 'jpg',
      caption: caption,
      placeText: placeText,
      lat: locationPermissionGranted ? exif.lat : null,
      lng: locationPermissionGranted ? exif.lng : null,
      takenAt: exif.takenAt,
    );
    return result.fold(
      (failure) => throw PresentationFailureException(failure),
      (
        photo,
      ) {
        controller.applyPhotoAdded(photo);
        tsx.get(globalEventBusProvider).add(const StarsAwardedDispatched());
        return photo;
      },
    );
  });
}
