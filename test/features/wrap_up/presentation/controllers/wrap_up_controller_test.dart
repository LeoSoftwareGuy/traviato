import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/photo/domain/entities/photo_entity.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_entity.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_moment.dart';
import 'package:traviato/features/photo/presentation/providers/photo_providers.dart';
import 'package:traviato/features/trip/presentation/providers/trip_providers.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_dates.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_invitation.dart';
import 'package:traviato/features/wrap_up/presentation/controllers/wrap_up_controller.dart';
import 'package:traviato/features/wrap_up/presentation/providers/wrap_up_providers.dart';

import '../../../photo/fakes/fake_photo_repository.dart';
import '../../../trip/fakes/fake_trip_repository.dart';
import '../../fakes/fake_wrap_up_repository.dart';

void main() {
  // Baked before #186: a single-day trip stored as "12–12 August 2026" and
  // "1 days.".
  final staleWrapUp = buildWrapUpEntity(
    dates: WrapUpDates(
      startDate: DateTime(2026, 8, 12),
      endDate: DateTime(2026, 8, 12),
      formatted: '12–12 August 2026',
    ),
    invitation: const WrapUpInvitation(
      line1: '1 days.',
      line2: 'One bright day.',
    ),
  );

  ProviderContainer container(
    FakeTripRepository tripRepo, {
    WrapUpEntity? wrapUp,
    List<PhotoEntity> photos = const [],
  }) {
    final c = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        wrapUpRepositoryProvider.overrideWithValue(
          FakeWrapUpRepository()
            ..getOrGenerateResult = Right(wrapUp ?? staleWrapUp),
        ),
        photoRepositoryProvider.overrideWithValue(
          FakePhotoRepository()..photosResult = Right(photos),
        ),
        tripRepositoryProvider.overrideWithValue(tripRepo),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('re-derives the date line and day count from live trip dates', () async {
    // The trip was shifted after the wrap-up was generated.
    final tripRepo = FakeTripRepository()
      ..tripCardResult = Right(
        buildTripCard(
          id: 't1',
          startDate: DateTime(2026, 8, 13),
          endDate: DateTime(2026, 8, 17),
        ),
      );

    final state = await container(
      tripRepo,
    ).read(wrapUpControllerProvider('t1').future);

    expect(state.wrapUp.dates.formatted, '13–17 August 2026');
    expect(state.wrapUp.invitation.line1, 'Five days.');
    // The AI-written line is left alone.
    expect(state.wrapUp.invitation.line2, 'One bright day.');
  });

  test('falls back to the stored dates when the trip fetch fails', () async {
    final tripRepo = FakeTripRepository()
      ..tripCardResult = const Left(NetworkFailure());

    final state = await container(
      tripRepo,
    ).read(wrapUpControllerProvider('t1').future);

    expect(state.wrapUp.dates.formatted, '12 August 2026');
    expect(state.wrapUp.invitation.line1, 'One day.');
  });

  test('never plays a photo that no longer exists (#187)', () async {
    // A kept-forever wrap-up still references a photo deleted since.
    final published = buildWrapUpEntity(
      publishedAt: DateTime(2026, 6, 7),
      moments: const [
        WrapUpMoment(photoId: 'kept'),
        WrapUpMoment(photoId: 'deleted'),
      ],
    );

    final state = await container(
      FakeTripRepository(),
      wrapUp: published,
      photos: [buildPhotoEntity(id: 'kept', imageUrl: 'https://x/kept.jpg')],
    ).read(wrapUpControllerProvider('t1').future);

    expect(state.wrapUp.moments.map((m) => m.photoId), ['kept']);
  });
}
