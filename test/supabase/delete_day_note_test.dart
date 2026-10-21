import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static checks on the `delete_day_note` migration (#276) — no database
/// here, so these guard the agreed rules: owner-checked, the note's ✦1 is
/// taken back, and a missing note is a no-op.
void main() {
  late String body;

  setUpAll(() {
    final file = Directory('supabase/migrations')
        .listSync()
        .whereType<File>()
        .singleWhere((f) => f.path.endsWith('_create_delete_day_note_rpc.sql'));
    // Comments hold revert notes and prose that mention the same names.
    body = file.readAsStringSync().replaceAll(RegExp(r'--.*'), '');
  });

  test('only the owner can delete; anything else is 42501', () {
    expect(body, contains('if v_owner is distinct from auth.uid() then'));
    expect(body, contains("errcode = '42501'"));
  });

  test('an already-deleted note is a no-op', () {
    expect(
      body.indexOf('if v_owner is null then'),
      lessThan(body.indexOf('delete from')),
    );
  });

  test("takes back the note's own star, then deletes the note", () {
    final stars = body.indexOf(
      "where user_id = v_owner and source = 'note' and source_id = p_note_id",
    );
    expect(stars, isNot(-1));
    expect(
      stars,
      lessThan(
        body.indexOf('delete from public.day_notes where id = p_note_id'),
      ),
    );
  });

  test('is callable by signed-in users only', () {
    expect(body, contains('from public, anon;'));
    expect(body, contains('to authenticated;'));
  });
}
