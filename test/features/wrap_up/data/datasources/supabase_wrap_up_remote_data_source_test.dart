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
}
