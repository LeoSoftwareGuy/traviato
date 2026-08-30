import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/trip/presentation/widgets/cover_picker.dart';
import 'package:traviato/features/trip/presentation/widgets/cover_upload_tile.dart';

// A minimal valid 1x1 transparent PNG — Image.memory needs real image bytes
// to decode without an async "Invalid image data" error, matching the
// photo feature's own test fixture (add_photo_details_sheet_test.dart).
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
  WidgetTester tester, {
  String? selectedCoverId,
  Uint8List? customCoverBytes,
  ValueChanged<String>? onSelect,
  Future<void> Function(Uint8List)? onUploadCustom,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CoverPicker(
          selectedCoverId: selectedCoverId,
          selectedVibes: const {},
          customCoverBytes: customCoverBytes,
          onSelect: onSelect ?? (_) {},
          onUploadCustom: onUploadCustom,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('the upload tile only appears when onUploadCustom is given', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.byType(CoverUploadTile), findsNothing);

    await _pump(tester, onUploadCustom: (_) async {});
    expect(find.byType(CoverUploadTile), findsOneWidget);
  });

  testWidgets('tapping a bundled thumbnail calls onSelect with its id', (
    tester,
  ) async {
    String? selected;
    await _pump(tester, onSelect: (id) => selected = id);

    await tester.tap(find.byKey(const Key('cover-thumbnail-hero')));
    expect(selected, 'hero');
  });

  testWidgets('customCoverBytes takes priority over selectedCoverId in the '
      'preview slot', (tester) async {
    await _pump(
      tester,
      selectedCoverId: 'hero',
      customCoverBytes: _onePixelPng,
      onUploadCustom: (_) async {},
    );

    final image = tester.widget<Image>(find.byType(Image).first);
    expect(image.image, isA<MemoryImage>());
    expect((image.image as MemoryImage).bytes, _onePixelPng);
    expect(find.text('YOUR COVER'), findsOneWidget);
    // High filter quality on the upscaled preview (issue #82).
    expect(image.filterQuality, FilterQuality.high);
  });

  testWidgets('bundled thumbnails render at high filter quality', (
    tester,
  ) async {
    await _pump(tester);

    final thumbnail = tester.widget<Image>(
      find.descendant(
        of: find.byKey(const Key('cover-thumbnail-hero')),
        matching: find.byType(Image),
      ),
    );
    expect(thumbnail.filterQuality, FilterQuality.high);
  });
}
