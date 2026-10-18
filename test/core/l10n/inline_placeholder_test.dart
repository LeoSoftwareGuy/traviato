import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/l10n/inline_placeholder.dart';

void main() {
  test('splits around the placeholder wherever it sits', () {
    expect(
      splitAroundPlaceholder((p) => 'Sent to $p. Open it.'),
      (before: 'Sent to ', after: '. Open it.'),
    );
    expect(
      splitAroundPlaceholder((p) => '$p is waiting'),
      (before: '', after: ' is waiting'),
    );
  });

  test('keeps the whole text when there is no placeholder', () {
    expect(
      splitAroundPlaceholder((_) => 'No slot'),
      (before: 'No slot', after: ''),
    );
  });
}
