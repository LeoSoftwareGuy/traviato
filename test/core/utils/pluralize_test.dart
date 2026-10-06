import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/utils/pluralize.dart';

void main() {
  test('uses the singular only for exactly one', () {
    expect(pluralize(1, 'DAY', 'DAYS'), 'DAY');
    expect(pluralize(0, 'DAY', 'DAYS'), 'DAYS');
    expect(pluralize(2, 'DAY', 'DAYS'), 'DAYS');
  });
}
