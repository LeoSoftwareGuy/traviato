import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _arb(String locale) =>
    jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
        as Map<String, dynamic>;

Set<String> _messageKeys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

void main() {
  final en = _arb('en');

  for (final locale in ['ru', 'et']) {
    group('app_$locale.arb', () {
      final arb = _arb(locale);

      test('has exactly the English keys', () {
        expect(_messageKeys(arb), _messageKeys(en));
      });

      test('marks every draft translation for native-speaker review', () {
        final unmarked = _messageKeys(arb).where(
          (k) => (arb['@$k'] as Map<String, dynamic>?)?['x-review'] == null,
        );
        expect(unmarked, isEmpty);
      });

      test('never stores caps-lock copy (uppercase happens in code)', () {
        final shouted = _messageKeys(arb).where((k) {
          final value = arb[k] as String;
          final letters = value.replaceAll(
            RegExp(r'\{[^}]*\}|[^\p{L}]', unicode: true),
            '',
          );
          return letters.length > 3 && letters == letters.toUpperCase();
        });
        expect(shouted, isEmpty);
      });
    });
  }
}
