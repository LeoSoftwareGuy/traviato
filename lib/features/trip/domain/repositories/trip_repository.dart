import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/trip_card_entity.dart';
import '../entities/trip_entity.dart';

abstract interface class TripRepository {
  Future<Either<Failure, List<TripCardEntity>>> getTripCards();

  Future<Either<Failure, TripCardEntity>> getTripCard(String tripId);

  Future<Either<Failure, TripEntity>> createTrip({
    required String name,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    List<String> vibes,
    String? coverImagePath,
  });

  Future<Either<Failure, void>> deleteTrip(String id);

  /// Plain authenticated update — used for both a rename and a cover
  /// change. Pass only the field(s) being changed.
  Future<Either<Failure, TripEntity>> updateTrip({
    required String id,
    String? name,
    String? coverImagePath,
  });

  /// Shifts the trip's start/end dates and every one of its quests'
  /// `day_date` by [deltaDays] in one transaction (the `shift_trip_dates`
  /// RPC) — a client-side batched update across two tables risks a partial
  /// failure leaving them out of sync.
  Future<Either<Failure, TripEntity>> shiftTripDates({
    required String id,
    required int deltaDays,
  });

  /// Uploads [bytes] as [tripId]'s custom cover at a stable
  /// `{user_id}/{trip_id}/cover.jpg` path in the `trip-photos` bucket —
  /// not a `photos` row (issue #81). Best-effort deletes any object
  /// already at that path first (a plain re-upload, not a storage
  /// `upsert` — the bucket's RLS only grants insert/select/delete, no
  /// update). Returns the raw storage path to persist via [updateTrip];
  /// does not update the trip row itself.
  Future<Either<Failure, String>> uploadCoverImage({
    required String tripId,
    required Uint8List bytes,
  });

  /// Deletes [tripId]'s custom-cover object at the stable path, if one
  /// exists (a no-op otherwise). Call only when the trip's *previous*
  /// cover was a custom upload (never for a bundled `asset:` cover) and
  /// the trip is switching away from it — [uploadCoverImage] already
  /// handles the replace-with-another-upload case by overwriting in place.
  Future<Either<Failure, void>> deleteCoverImage(String tripId);

  /// Signs a stored cover path (as persisted by [uploadCoverImage]) into a
  /// short-lived URL the UI can load — `trip-photos` is a private bucket.
  Future<Either<Failure, String>> getCoverImageUrl(String storagePath);
}
