import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/core/theme/app_theme.dart';
import 'package:traviato/features/photo/data/services/photo_compressor.dart';
import 'package:traviato/features/photo/presentation/providers/photo_providers.dart';
import 'package:traviato/features/photo/presentation/widgets/add_photo_sheet.dart';

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

// A minimal valid 1x1 transparent PNG — `Image.memory` needs real image
// bytes to decode, unlike the repository/exif tests which only care that
// bytes flow through untouched.
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

/// Opens the sheet the same way real usage does — via `.show`, pushed as a
/// modal route — rather than pumping it as a page body. `_save` pops its own
/// route on success, which needs a real pushed route to pop.
Future<void> _pump(WidgetTester tester, FakePhotoRepository photoRepo) async {
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
                onPressed: () => AddPhotoDetailsSheet.show(
                  context,
                  tripId: 't1',
                  dayDate: DateTime(2026, 8, 18),
                  bytes: _onePixelPng,
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
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    // Report the location permission as permanently denied so `_save`
    // resolves without showing (or needing to tap through) the rationale
    // dialog — GPS-gating itself is covered by photo_mutations behavior,
    // this test is about the caption/place form + save flow.
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

  testWidgets('shows a preview of the picked photo', (tester) async {
    await _pump(tester, FakePhotoRepository());

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Add photo'), findsOneWidget);
  });

  testWidgets('saving sends the trimmed caption and place to the repository', (
    tester,
  ) async {
    final photoRepo = FakePhotoRepository();
    await _pump(tester, photoRepo);

    await tester.enterText(find.byType(TextField).first, '  Sunset  ');
    await tester.enterText(find.byType(TextField).last, '  Old Town  ');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
    await tester.pump(); // one frame: the mutation + toast are synchronous

    expect(photoRepo.addPhotoCallCount, 1);
    expect(find.text('✦ +2 stars · photo logged'), findsOneWidget);

    await tester.pumpAndSettle(); // let the toast's own timer finish cleanly
  });

  testWidgets('shows an error snackbar when the upload fails', (
    tester,
  ) async {
    final photoRepo = FakePhotoRepository()
      ..addPhotoResult = const Left(NetworkFailure());
    await _pump(tester, photoRepo);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Please check your connection.'), findsOneWidget);
  });
}
