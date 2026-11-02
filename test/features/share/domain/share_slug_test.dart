import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/share/domain/share_slug.dart';

void main() {
  group('parseShareSlug (#310)', () {
    test('the public link, with or without scheme, query or slash', () {
      for (final input in [
        'https://storyni.app/m/k7Qm2xPa9c',
        'storyni.app/m/k7Qm2xPa9c',
        '  https://storyni.app/m/k7Qm2xPa9c/  ',
        'https://storyni.app/m/k7Qm2xPa9c?open=1',
        'https://www.storyni.app/m/k7Qm2xPa9c',
        'http://storyni.app/m/k7Qm2xPa9c#top',
      ]) {
        expect(parseShareSlug(input), 'k7Qm2xPa9c', reason: input);
      }
    });

    test("the app's own scheme (the web page's Open in the app)", () {
      expect(parseShareSlug('com.leo.storyni://m/k7Qm2xPa9c'), 'k7Qm2xPa9c');
    });

    test('anything else is null', () {
      for (final input in [
        '',
        'k7Qm2xPa9c',
        'https://storyni.app/m/short',
        'https://storyni.app/m/k7Qm2xPa9c/extra',
        'https://storyni.app/x/k7Qm2xPa9c',
        'https://evil.example/m/k7Qm2xPa9c',
        'com.leo.storyni://login-callback?code=abc',
        'https://storyni.app/m/k7Qm2xPa9!',
      ]) {
        expect(parseShareSlug(input), isNull, reason: input);
      }
    });
  });

  group('parseReferrerSlug (#310)', () {
    test('reads storyni_slug from the Play referrer', () {
      expect(parseReferrerSlug('storyni_slug=k7Qm2xPa9c'), 'k7Qm2xPa9c');
      expect(
        parseReferrerSlug('utm_source=google&storyni_slug=k7Qm2xPa9c'),
        'k7Qm2xPa9c',
      );
    });

    test('organic installs and bad values are null', () {
      expect(parseReferrerSlug(null), isNull);
      expect(parseReferrerSlug('utm_source=google-play'), isNull);
      expect(parseReferrerSlug('storyni_slug=nope'), isNull);
    });
  });
}
