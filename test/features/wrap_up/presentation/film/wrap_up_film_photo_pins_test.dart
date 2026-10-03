import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/wrap_up_film_photo.dart';
import 'package:traviato/features/wrap_up/presentation/film/wrap_up_film_photo_pins.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const url = 'https://example.com/moment.jpg';

  /// Stands in for a finished network decode: the test image sits in the
  /// cache under the real provider's key, so `pin` resolves it from there.
  Future<Object> seedDecodedPhoto(WidgetTester tester) async {
    final image = await tester.runAsync(() => createTestImage());
    final key = await WrapUpFilmPhoto.providerFor(
      url,
    ).obtainKey(ImageConfiguration.empty);
    imageCache.putIfAbsent(
      key,
      () => OneFrameImageStreamCompleter(
        SynchronousFuture(ImageInfo(image: image!)),
      ),
    );
    addTearDown(() {
      imageCache.clear();
      imageCache.clearLiveImages();
    });
    return key;
  }

  testWidgets('providerFor gives one cache key per URL, so precache and the '
      'frames hit the same entry', (tester) async {
    final a = await WrapUpFilmPhoto.providerFor(
      url,
    ).obtainKey(ImageConfiguration.empty);
    final b = await WrapUpFilmPhoto.providerFor(
      url,
    ).obtainKey(ImageConfiguration.empty);
    expect(a, b);
  });

  testWidgets('a pinned photo survives the LRU cache being emptied — what '
      'later precaches did to Moment photos before #178', (tester) async {
    final key = await seedDecodedPhoto(tester);
    final pins = WrapUpFilmPhotoPins();

    await pins.pin(WrapUpFilmPhoto.providerFor(url));
    imageCache.clear();

    expect(imageCache.statusForKey(key).live, isTrue);

    pins.dispose();
    expect(imageCache.statusForKey(key).live, isFalse);
  });

  testWidgets('without a pin the same eviction drops the photo', (
    tester,
  ) async {
    final key = await seedDecodedPhoto(tester);

    imageCache.clear();

    expect(imageCache.statusForKey(key).untracked, isTrue);
  });

  testWidgets('pin completes on error so a broken photo never blocks', (
    tester,
  ) async {
    final pins = WrapUpFilmPhotoPins();
    addTearDown(pins.dispose);

    await tester.runAsync(
      () => pins
          .pin(MemoryImage(Uint8List.fromList([0, 1, 2])))
          .timeout(const Duration(seconds: 5)),
    );
  });
}
