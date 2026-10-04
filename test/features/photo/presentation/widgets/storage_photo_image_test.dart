import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/theme/app_colors.dart';
import 'package:traviato/features/photo/presentation/widgets/storage_photo_image.dart';

const _path = 'u1/t1/p1.jpg';

// Two signings of the same file — the token differs every time (#179).
const _firstVisitUrl =
    'https://x.supabase.co/storage/v1/object/sign/trip-photos/$_path?token=aaa';
const _revisitUrl =
    'https://x.supabase.co/storage/v1/object/sign/trip-photos/$_path?token=bbb';

final _placeholder = find.byWidgetPredicate(
  (w) => w is ColoredBox && w.color == AppColors.surface,
);

Future<Object> _keyFor(String url, {int? maxDecodeDimension}) =>
    StoragePhotoImage.providerFor(
      url: url,
      storagePath: _path,
      maxDecodeDimension: maxDecodeDimension,
    ).obtainKey(ImageConfiguration.empty);

/// What a first Journal visit leaves behind: the decoded photo in the
/// image cache under [url]'s provider key. No network involved.
Future<void> _seedDecoded(
  WidgetTester tester,
  String url, {
  int? maxDecodeDimension,
}) async {
  final image = await tester.runAsync(() => createTestImage());
  imageCache.putIfAbsent(
    await _keyFor(url, maxDecodeDimension: maxDecodeDimension),
    () => OneFrameImageStreamCompleter(
      SynchronousFuture(ImageInfo(image: image!)),
    ),
  );
  addTearDown(imageCache.clear);
}

Widget _app(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: 80, height: 100, child: child)),
  ),
);

void main() {
  group('cache key', () {
    testWidgets('a re-signed URL for the same file keys the same cache '
        'entry', (tester) async {
      expect(await _keyFor(_firstVisitUrl), await _keyFor(_revisitUrl));
      expect(
        await _keyFor(_firstVisitUrl, maxDecodeDimension: 480),
        await _keyFor(_revisitUrl, maxDecodeDimension: 480),
      );
    });

    testWidgets('different files never share an entry', (tester) async {
      final other = await StoragePhotoImage.providerFor(
        url: _firstVisitUrl,
        storagePath: 'u1/t1/p2.jpg',
      ).obtainKey(ImageConfiguration.empty);

      expect(other, isNot(await _keyFor(_firstVisitUrl)));
    });
  });

  testWidgets('revisiting with a freshly signed URL paints the cached photo '
      'in the first frame — no refetch, no placeholder', (tester) async {
    await _seedDecoded(tester, _firstVisitUrl);

    await tester.pumpWidget(
      _app(const StoragePhotoImage(url: _revisitUrl, storagePath: _path)),
    );

    expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
    expect(_placeholder, findsNothing);
  });

  testWidgets('a thumbnail revisit hits the cache at its decode size', (
    tester,
  ) async {
    const size = Size(80, 100);
    await _seedDecoded(
      tester,
      _firstVisitUrl,
      maxDecodeDimension: StoragePhotoImage.maxDecodeDimensionFor(
        size,
        tester.view.devicePixelRatio,
      ),
    );

    await tester.pumpWidget(
      _app(
        const StoragePhotoImage(
          url: _revisitUrl,
          storagePath: _path,
          decodeSize: size,
        ),
      ),
    );

    expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
    expect(_placeholder, findsNothing);
  });

  testWidgets('a first-ever load shows a placeholder, not a blank gap', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const StoragePhotoImage(url: _revisitUrl, storagePath: _path)),
    );

    expect(_placeholder, findsOneWidget);
  });

  test('thumbnail decode box is twice the larger side in physical px', () {
    expect(
      StoragePhotoImage.maxDecodeDimensionFor(const Size(80, 100), 3),
      600,
    );
    expect(
      StoragePhotoImage.maxDecodeDimensionFor(const Size.square(18), 2),
      72,
    );
  });
}
