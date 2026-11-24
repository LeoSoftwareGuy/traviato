import 'dart:typed_data';

import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/presentation_failure_exception.dart';
import '../../../../core/events/global_event.dart';
import '../../../../core/events/global_event_bus.dart';
import '../../../journal/presentation/controllers/journal_controller.dart';
import '../../../subscription/domain/entities/entitlement_entity.dart';
import '../../../subscription/presentation/controllers/entitlement_controller.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../../domain/entities/film_pick.dart';
import '../../domain/entities/photo_entity.dart';
import '../../domain/photo_capture_time.dart';
import '../providers/photo_providers.dart';

const _freeTierPhotoLimit = 40;

final addPhotoMutation = Mutation<PhotoEntity>();
final deletePhotoMutation = Mutation<void>();
final setFilmPickMutation = Mutation<void>();

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

    // App-side pre-check (server-side enforcement is the real guard, #139)
    // — reuses the already-loaded journal state's photo count, no extra
    // query. The entitlement is awaited: it's auto-dispose and nothing on
    // the Journal watches it, so reading `.value` here saw a fresh loading
    // state and blocked Pro users at 40 (#262). If it can't load, skip the
    // pre-check and let the server decide rather than block a paying user.
    final isPro = await tsx
        .get(entitlementControllerProvider.future)
        .then((entitlement) => entitlement.isPro, onError: (_) => true);
    final currentPhotoCount =
        tsx.get(journalControllerProvider(tripId)).value?.photos.length ?? 0;
    // The row may be stale for a paying user (a missed renewal webhook, a
    // DB reset — #466, as memories in #267): ask the server to re-check
    // RevenueCat before showing the upsell.
    if (!isPro &&
        currentPhotoCount >= _freeTierPhotoLimit &&
        !await _confirmedPro(tsx)) {
      throw PresentationFailureException(const PhotoLimitFailure());
    }

    final exif = await exifReader.read(rawBytes);
    final captured = PhotoCaptureTime.of(
      exifTakenAt: exif.takenAt,
      exifOffsetMinutes: exif.utcOffsetMinutes,
      now: DateTime.now(),
    );
    final compressed = await compressor.compress(rawBytes);

    Future<Either<Failure, PhotoEntity>> add() => repo.addPhoto(
      tripId: tripId,
      dayDate: dayDate,
      bytes: compressed,
      fileExtension: 'jpg',
      caption: caption,
      placeText: placeText,
      lat: locationPermissionGranted ? exif.lat : null,
      lng: locationPermissionGranted ? exif.lng : null,
      takenAt: captured.takenAt,
      utcOffsetMinutes: captured.utcOffsetMinutes,
      utcOffsetSource: captured.source,
    );
    var result = await add();
    // The server's cap (TRV02) read a stale row: once RevenueCat confirms
    // Pro, retry once (a failed insert already removed its upload).
    if (result case Left(value: PhotoLimitFailure())
        when await _confirmedPro(
          tsx,
        )) {
      result = await add();
    }
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

/// Whether the server, re-checking RevenueCat (`sync_entitlement`, #267),
/// confirms Pro. If so the repaired entitlement is published, so every
/// screen and the next photo see it. A refresh that fails confirms
/// nothing.
Future<bool> _confirmedPro(MutationTransaction tsx) async {
  final EntitlementEntity? entitlement;
  try {
    entitlement =
        (await tsx.get(subscriptionRepositoryProvider).refreshEntitlement())
            .toNullable();
  } catch (_) {
    // Not confirmed: the cap stands as the server set it.
    return false;
  }
  if (entitlement == null || !entitlement.isPro) return false;
  tsx
      .get(globalEventBusProvider)
      .add(EntitlementUpdatedDispatched(entitlement: entitlement));
  return true;
}

/// Deletes a photo optimistically (#165): the Journal's strip, day-tab
/// thumbnail and counts drop it at once (the caller has asked first, #424)
/// — and it's put back where it was if
/// the delete fails. The server takes back the photo's ✦2 (kept for a
/// bonus-task photo), so the star badges refetch on success.
///
/// From the timeline's long-press sheet (#424) it leaves after [foldFor] —
/// the tile's fold-away — while the delete is already under way, as a
/// deleted note does (#407).
Future<void> runDeletePhoto({
  required WidgetRef ref,
  required String tripId,
  required PhotoEntity photo,
  Duration foldFor = Duration.zero,
}) {
  return deletePhotoMutation.run(ref, (tsx) async {
    final repo = tsx.get(photoRepositoryProvider);
    final controller = tsx.get(journalControllerProvider(tripId).notifier);

    final deleting = repo.deletePhoto(photo);
    if (foldFor > Duration.zero) await Future<void>.delayed(foldFor);
    final index = controller.applyPhotoDeleted(photo.id);
    final result = await deleting;
    result.fold(
      (failure) {
        if (index != -1) controller.applyPhotoRestored(photo, index);
        throw PresentationFailureException(failure);
      },
      (_) => tsx.get(globalEventBusProvider)
        ..add(const StarsAwardedDispatched())
        // A deleted photo drops its pick, and may leave a kept film out of
        // date (#294).
        ..add(FilmPhotosChangedDispatched(tripId: tripId)),
    );
  });
}

/// Saves a photo's Wrap-Up Film pick (#294) at once, no save button: the
/// Journal's strip markers and the viewer's panel update optimistically,
/// and the pick is put back — then this throws — if the write fails.
/// Never an AI call; a kept film only learns of it through the
/// "Photos changed · Rebuild film" check.
Future<void> runSetFilmPick({
  required WidgetRef ref,
  required String tripId,
  required PhotoEntity photo,
  required FilmPick pick,
}) {
  return setFilmPickMutation.run(ref, (tsx) async {
    final repo = tsx.get(photoRepositoryProvider);
    final controller = tsx.get(journalControllerProvider(tripId).notifier);

    final previous = controller.applyPhotoFilmPick(photo.id, pick);
    final result = await repo.setFilmPick(photo.id, pick);
    result.fold(
      (failure) {
        controller.applyPhotoFilmPickSettled(
          photo.id,
          pick,
          previous: previous,
        );
        throw PresentationFailureException(failure);
      },
      (setAt) {
        controller.applyPhotoFilmPickSettled(photo.id, pick, setAt: setAt);
        tsx
            .get(globalEventBusProvider)
            .add(FilmPhotosChangedDispatched(tripId: tripId));
      },
    );
  });
}
