import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static checks on the photo film-pick columns (#294): `use_in_wrap_up`
/// is three-state (nullable, no default — null is Auto), and the pick's
/// stamp is set server-side by a trigger only when the pick changes.
void main() {
  late String sql;

  setUpAll(() {
    final file = Directory('supabase/migrations')
        .listSync()
        .whereType<File>()
        .singleWhere((f) => f.path.endsWith('_add_photos_use_in_wrap_up.sql'));
    // Comments hold revert notes and prose that mention the same names.
    sql = file.readAsStringSync().replaceAll(RegExp(r'--.*'), '');
  });

  test('adds both columns nullable, with no default', () {
    expect(sql, contains('add column use_in_wrap_up boolean,'));
    expect(sql, contains('add column use_in_wrap_up_set_at timestamptz;'));
    expect(sql, isNot(contains('not null')));
    expect(sql, isNot(contains('default')));
  });

  test('stamps the pick from a before-update trigger, only on a change', () {
    expect(sql, contains('before update on public.photos'));
    expect(
      sql,
      contains('new.use_in_wrap_up is distinct from old.use_in_wrap_up'),
    );
    expect(sql, contains('new.use_in_wrap_up_set_at := now()'));
    expect(
      sql,
      contains('new.use_in_wrap_up_set_at := old.use_in_wrap_up_set_at'),
    );
    expect(sql, contains('set search_path = public'));
  });
}
