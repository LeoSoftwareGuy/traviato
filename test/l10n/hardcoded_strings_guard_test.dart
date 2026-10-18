import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every UI label goes through `context.l10n` (#220); this keeps hard-coded
/// `Text('…')` copy out of `lib/features`. A literal only counts as copy
/// when a word (two letters in a row, any script) is left after removing
/// interpolations — so `'✦$points'`, `'@$username'` or
/// `'${l10n.x} ▸'` pass, while `'Save'` fails.
final _textLiteral = RegExp(r'''Text\(\s*(['"])((?:(?!\1).)*)\1''');
final _interpolation = RegExp(r'\$\{[^}]*\}|\$\w+');
final _word = RegExp(r'\p{L}{2,}', unicode: true);

/// Literals that are glyphs by design, not translatable copy.
const _allowed = {
  'Aa', // note page "type" button (localization spec 2a)
};

Iterable<String> _copyLiterals(String source) => _textLiteral
    .allMatches(source)
    .map((m) => m.group(2)!)
    .where((literal) => !_allowed.contains(literal))
    .where((literal) => _word.hasMatch(literal.replaceAll(_interpolation, '')));

void main() {
  test('no hard-coded Text literals in lib/features', () {
    final offenders = <String>[];
    final files = Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    for (final file in files) {
      for (final literal in _copyLiterals(file.readAsStringSync())) {
        offenders.add("${file.path.replaceAll('\\', '/')}: '$literal'");
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'Move UI strings into lib/l10n/app_en.arb (+ ru/et) and use '
          'context.l10n instead of Text(\'…\').',
    );
  });

  test('the check itself tells copy from glyphs and interpolations', () {
    expect(_copyLiterals("Text('Save')"), ['Save']);
    expect(_copyLiterals("Text('Сохранить')"), ['Сохранить']);
    expect(_copyLiterals(r"Text('✦$points')"), isEmpty);
    expect(_copyLiterals(r"Text('@$username')"), isEmpty);
    expect(_copyLiterals(r"Text('${l10n.home_recap} ▸')"), isEmpty);
    expect(_copyLiterals("Text('Aa')"), isEmpty);
    expect(_copyLiterals(r"Text('Day $n')"), ['Day \$n']);
  });
}
