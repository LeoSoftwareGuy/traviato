import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/core/errors/presentation_failure_exception.dart';
import 'package:traviato/features/journal/presentation/controllers/journal_controller.dart';
import 'package:traviato/features/journal/presentation/providers/day_note_providers.dart';
import 'package:traviato/features/photo/data/services/photo_compressor.dart';
import 'package:traviato/features/photo/domain/entities/photo_entity.dart';
import 'package:traviato/features/photo/presentation/mutations/photo_mutations.dart';
import 'package:traviato/features/photo/presentation/providers/photo_providers.dart';
import 'package:traviato/features/subscription/presentation/controllers/entitlement_controller.dart';
import 'package:traviato/features/subscription/presentation/providers/subscription_providers.dart';
import 'package:traviato/features/trip/presentation/providers/trip_providers.dart';

import '../../../journal/fakes/fake_day_note_repository.dart';
import '../../../subscription/fakes/fake_subscription_repository.dart';
import '../../../trip/fakes/fake_trip_repository.dart';
import '../../fakes/fake_photo_repository.dart';

/// `PhotoCompressor.compress` calls a native plugin unavailable in widget
/// tests — override it with a pass-through, same as
/// `batch_add_photo_sheet_test.dart`.
class _IdentityCompressor extends PhotoCompressor {
  const _IdentityCompressor();

  @override
  Future<Uint8List> compress(Uint8List bytes) async => bytes;
}

final _onePixelPng = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

const _tripId = 't1';

class _Harness extends ConsumerWidget {
  const _Harness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Forces JournalController and EntitlementController to build (and this
    // widget to rebuild once they settle) so the mutation's pre-check reads
    // real state instead of a still-loading AsyncValue.
    ref.watch(journalControllerProvider(_tripId));
    ref.watch(entitlementControllerProvider);
    return MaterialApp(
      home: Scaffold(
        body: ElevatedButton(
          onPressed: () async {
            try {
              await runAddPhoto(
                ref: ref,
                tripId: _tripId,
                dayDate: DateTime(2026, 8, 18),
                rawBytes: _onePixelPng,
                locationPermissionGranted: false,
              );
            } catch (_) {
              // Surfaced via the mutation's MutationError state instead.
            }
          },
          child: const Text('Add'),
        ),
      ),
    );
  }
}

Future<ProviderContainer> _pumpHarness(
  WidgetTester tester, {
  required FakePhotoRepository photoRepo,
  required FakeSubscriptionRepository subscriptionRepo,
}) async {
  late final ProviderContainer container;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tripRepositoryProvider.overrideWithValue(FakeTripRepository()),
        photoRepositoryProvider.overrideWithValue(photoRepo),
        dayNoteRepositoryProvider.overrideWithValue(FakeDayNoteRepository()),
        subscriptionRepositoryProvider.overrideWithValue(subscriptionRepo),
        photoCompressorProvider.overrideWithValue(const _IdentityCompressor()),
      ],
      child: Builder(
        builder: (context) {
          container = ProviderScope.containerOf(context);
          return const _Harness();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

FakePhotoRepository _photoRepoWithCount(int count) =>
    FakePhotoRepository()
      ..photosResult = Right(
        List.generate(
          count,
          (i) => buildPhotoEntity(id: 'p$i', tripId: _tripId),
        ),
      );

void main() {
  testWidgets(
    'blocks the free-tier add-photo mutation client-side at the 40-photo '
    'cap (#139) — never reaches the repository',
    (tester) async {
      final photoRepo = _photoRepoWithCount(40);
      final subscriptionRepo = FakeSubscriptionRepository();

      final container = await _pumpHarness(
        tester,
        photoRepo: photoRepo,
        subscriptionRepo: subscriptionRepo,
      );
      container.listen(addPhotoMutation, (_, _) {});
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(photoRepo.addPhotoCallCount, 0);
      final state = container.read(addPhotoMutation);
      expect(state, isA<MutationError<PhotoEntity>>());
      final error = (state as MutationError<PhotoEntity>).error;
      expect(error, isA<PresentationFailureException>());
      expect(
        (error as PresentationFailureException).failure,
        isA<PhotoLimitFailure>(),
      );
    },
  );

  testWidgets(
    'allows the free-tier add-photo mutation under the 40-photo cap',
    (tester) async {
      final photoRepo = _photoRepoWithCount(39);
      final subscriptionRepo = FakeSubscriptionRepository();

      await _pumpHarness(
        tester,
        photoRepo: photoRepo,
        subscriptionRepo: subscriptionRepo,
      );
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(photoRepo.addPhotoCallCount, 1);
    },
  );

  testWidgets(
    'a Pro user is never blocked client-side past the 40-photo cap',
    (tester) async {
      final photoRepo = _photoRepoWithCount(100);
      final subscriptionRepo = FakeSubscriptionRepository()
        ..entitlementResult = Right(buildProEntitlement());

      await _pumpHarness(
        tester,
        photoRepo: photoRepo,
        subscriptionRepo: subscriptionRepo,
      );
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(photoRepo.addPhotoCallCount, 1);
    },
  );
}
