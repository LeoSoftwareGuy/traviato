import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/data/datasources/supabase_wrap_up_remote_data_source.dart';

void main() {
  group('isFrozenWrapUpRow (#187)', () {
    test('a published wrap-up is read as stored', () {
      expect(
        isFrozenWrapUpRow({
          'content': <String, dynamic>{},
          'published_at': '2026-06-07T00:00:00Z',
        }),
        isTrue,
      );
    });

    test('a draft goes through the function to be rebuilt', () {
      expect(
        isFrozenWrapUpRow({
          'content': <String, dynamic>{},
          'published_at': null,
        }),
        isFalse,
      );
    });

    test('a row without content goes through the function', () {
      expect(
        isFrozenWrapUpRow({
          'content': null,
          'published_at': '2026-06-07T00:00:00Z',
        }),
        isFalse,
      );
    });
  });

  test('the generate_wrap_up body carries the UI language (#250) and asks '
      'for the 16-moment film (#304)', () {
    final now = DateTime.now();
    expect(generateWrapUpBody('t1', 'ru', now: now), {
      'trip_id': 't1',
      'language': 'ru',
      'moment_slots': 16,
      'utc_offset_minutes': now.timeZoneOffset.inMinutes,
    });
  });

  test('a rebuild request asks the function to re-assemble a kept film '
      '(#294)', () {
    expect(generateWrapUpBody('t1', 'en', rebuild: true)['rebuild'], isTrue);
  });

  test('the body carries the phone UTC offset in minutes (#363)', () {
    final body = generateWrapUpBody('t1', 'en');
    expect(body['utc_offset_minutes'], DateTime.now().timeZoneOffset.inMinutes);
    expect(body['utc_offset_minutes'], isA<int>());
  });
}
