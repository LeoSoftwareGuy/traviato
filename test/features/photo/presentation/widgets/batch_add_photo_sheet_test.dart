import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/core/theme/app_theme.dart';
import 'package:traviato/features/photo/data/services/photo_compressor.dart';
import 'package:traviato/features/photo/presentation/providers/photo_providers.dart';
import 'package:traviato/features/photo/presentation/widgets/batch_add_photo_sheet.dart';

import '../../fakes/fake_photo_repository.dart';

/// `PhotoCompressor.compress` calls a native plugin unavailable in widget
/// tests — override it with a pass-through so `runAddPhoto` never touches a
/// real platform channel.
class _IdentityCompressor extends PhotoCompressor {
  const _IdentityCompressor();

  @override
  Future<Uint8List> compress(Uint8List bytes) async => bytes;
}

const _permissionChannel = MethodChannel(
  'flutter.baseflow.com/permissions/methods',
);

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

Future<void> _pump(
  WidgetTester tester,
  FakePhotoRepository photoRepo, {
  required int imageCount,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        photoRepositoryProvider.overrideWithValue(photoRepo),
        photoCompressorProvider.overrideWithValue(const _IdentityCompressor()),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => BatchAddPhotoSheet.show(
                  context,
                  tripId: 't1',
                  dayDate: DateTime(2026, 8, 18),
                  images: List.generate(imageCount, (_) => _onePixelPng),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
}

/// Pumps in short steps until [finder] matches, instead of `pumpAndSettle`
/// — the star toast is a ~1.65s self-dismissing animation, so settling
/// fully would run right past it and find it already gone. A further
/// buffer after the match lets the sheet's own entrance transition (and
/// content `RiseIn`) finish so a subsequent tap actually lands on-screen,
/// while still nowhere near the toast's dismiss point.
Future<void> _pumpUntilVisible(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 40; i++) {
    if (finder.evaluate().isNotEmpty) break;
    await tester.pump(const Duration(milliseconds: 50));
  }
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUp(() {
    // Permanently-denied location permission means `resolveLocationPermission`
    // resolves without showing (or needing to tap through) a rationale
    // dialog — unrelated to what this file is testing.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_permissionChannel, (call) async {
          if (call.method == 'checkPermissionStatus') {
            return 4; // permanentlyDenied
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_permissionChannel, null);
  });

  testWidgets('shows per-batch progress while uploading', (tester) async {
    await _pump(tester, FakePhotoRepository(), imageCount: 3);
    await tester.pump(); // first build only — before any upload settles

    expect(find.byKey(const Key('batch-photo-progress')), findsOneWidget);
    expect(find.text('Uploading 1 of 3…'), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets(
    'uploads every selected image independently and shows one batched toast',
    (tester) async {
      final photoRepo = FakePhotoRepository();
      await _pump(tester, photoRepo, imageCount: 3);
      final toast = find.text('✦ +6 stars · 3 photos logged');
      await _pumpUntilVisible(tester, toast);

      expect(photoRepo.addPhotoCallCount, 3);
      expect(toast, findsOneWidget);

      await tester.pumpAndSettle(); // let the toast's own timer finish cleanly
    },
  );

  testWidgets(
    'a single failure among several leaves the others uploaded and offers '
    'a retry for just the failed one',
    (tester) async {
      final photoRepo = FakePhotoRepository()
        ..addPhotoResultsQueue = [
          Right(buildPhotoEntity(id: 'p1')),
          const Left(NetworkFailure()),
          Right(buildPhotoEntity(id: 'p3')),
        ];
      await _pump(tester, photoRepo, imageCount: 3);
      await _pumpUntilVisible(tester, find.text('2 uploaded, 1 failed.'));

      // Batch stays open (not auto-dismissed) with the correct counts —
      // the two successes are not rolled back.
      expect(photoRepo.addPhotoCallCount, 3);
      expect(find.text('2 uploaded, 1 failed.'), findsOneWidget);
      expect(find.text('Retry failed (1)'), findsOneWidget);

      await tester.tap(find.byKey(const Key('batch-photo-retry')));
      final toast = find.text('✦ +6 stars · 3 photos logged');
      await _pumpUntilVisible(tester, toast);

      // Only the failed photo was re-attempted (one more call, not three).
      expect(photoRepo.addPhotoCallCount, 4);
      expect(toast, findsOneWidget);

      await tester.pumpAndSettle();
    },
  );

  testWidgets('"Done" dismisses the batch without retrying failures', (
    tester,
  ) async {
    final photoRepo = FakePhotoRepository()
      ..addPhotoResultsQueue = [
        Right(buildPhotoEntity(id: 'p1')),
        const Left(NetworkFailure()),
      ];
    await _pump(tester, photoRepo, imageCount: 2);
    final doneButton = find.byKey(const Key('batch-photo-done'));
    await _pumpUntilVisible(tester, doneButton);

    expect(doneButton, findsOneWidget);

    await tester.tap(doneButton);
    // Unlike the toast-visibility checks above, settling fully here is
    // fine (and needed) — dismissal includes a route-exit transition, and
    // this assertion only cares that the sheet is gone, not that any
    // toast (there is one, for the one successful upload) stays visible.
    await tester.pumpAndSettle();

    expect(doneButton, findsNothing);
    expect(photoRepo.addPhotoCallCount, 2);
  });
}
