import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static checks on the #285 backfill: every seeded suggestion's English and
/// Russian text maps back to its code, so existing checklists written in
/// either language get re-translated.
void main() {
  late String sql;
  late Set<(String, String)> backfilled;

  setUpAll(() {
    sql = Directory('supabase/migrations')
        .listSync()
        .whereType<File>()
        .singleWhere(
          (f) => f.path.endsWith('_add_checklist_item_suggestion_code.sql'),
        )
        .readAsStringSync()
        .replaceAll(RegExp(r'--.*'), '');
    backfilled = {
      for (final m in RegExp(
        r"\('((?:[^']|'')*)', '([a-z_]+)'\)",
      ).allMatches(sql))
        (m.group(1)!.replaceAll("''", "'"), m.group(2)!),
    };
  });

  Map<String, String> checklistStrings(String locale) {
    final arb =
        jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
            as Map<String, dynamic>;
    const prefix = 'content_checklist_';
    return {
      for (final e in arb.entries)
        if (e.key.startsWith(prefix))
          e.key.substring(prefix.length): e.value as String,
    };
  }

  test('adds a nullable suggestion_code to checklist_items', () {
    expect(
      sql,
      contains(
        'alter table public.checklist_items add column suggestion_code text',
      ),
    );
  });

  for (final locale in ['en', 'ru']) {
    test('backfills every $locale suggestion title', () {
      final strings = checklistStrings(locale);
      expect(strings, isNotEmpty);
      for (final MapEntry(key: code, value: title) in strings.entries) {
        expect(backfilled, contains((title, code)), reason: '$locale $code');
      }
    });
  }

  test('only matches within the suggestion\'s own category', () {
    expect(sql, contains('i.category = s.category'));
    expect(sql, contains('i.suggestion_code is null'));
  });
}
