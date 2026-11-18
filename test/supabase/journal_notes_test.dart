import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static checks on the `journal_notes` migration (#400, part of #397) —
/// no database here, so these guard the agreed rules. The migration was
/// also replayed with seeded data on a scratch Postgres (see the PR).
void main() {
  late String body;

  setUpAll(() {
    final file = Directory('supabase/migrations')
        .listSync()
        .whereType<File>()
        .singleWhere((f) => f.path.endsWith('_create_journal_notes.sql'));
    // Comments hold revert notes and prose that mention the same names.
    body = file.readAsStringSync().replaceAll(RegExp(r'--.*'), '');
  });

  test('RLS on, one owner-only policy per operation, explicit grants', () {
    expect(
      body,
      contains('alter table public.journal_notes enable row level security;'),
    );
    for (final op in ['select', 'insert', 'update', 'delete']) {
      expect(body, contains('"journal_notes_${op}_own"'), reason: op);
    }
    expect(
      body,
      contains(
        'grant select, insert, update, delete on public.journal_notes '
        'to authenticated;',
      ),
    );
    expect(
      body,
      contains('grant select on public.journal_notes to service_role;'),
    );
  });

  test("a note's photo must belong to the same trip and can go first", () {
    expect(
      'p.trip_id = journal_notes.trip_id'.allMatchesIn(body),
      2,
      reason: 'insert and update both check it',
    );
    expect(
      body,
      contains('references public.photos (id) on delete set null'),
    );
  });

  test('old day notes are copied once, same id, text unchanged', () {
    final insert = body.indexOf('insert into public.journal_notes');
    final copy = body.substring(insert, body.indexOf(';', insert));
    expect(copy, contains('select id, trip_id, day_date, updated_at'));
    expect(copy, contains('content, false, true'));
    expect(copy, contains("where content ~ '\\S'"));
  });

  test('edits keep the time and the legacy flag', () {
    expect(body, contains('new.taken_at := old.taken_at;'));
    expect(body, contains('new.legacy := old.legacy;'));
    expect(body, contains('new.edited_at := now();'));
  });

  test('note stars: at most 3 a day, counted in the ledger', () {
    expect(body, contains('add column day_date date'));
    expect(body, contains(') >= 3 then'));
    expect(body, contains("and source = 'note' and day_date = v_day"));
  });

  test('deleting a note keeps its star; day_notes goes read-only', () {
    expect(body, contains('drop function public.delete_day_note(uuid);'));
    expect(
      body,
      contains('revoke insert, update, delete on public.day_notes'),
    );
    expect(body, isNot(contains('from public.day_notes where id')));
  });

  test('Storyteller counts days with a note', () {
    expect(
      'select distinct jn.trip_id, jn.day_date'.allMatchesIn(body),
      2,
      reason: 'check_achievements and profile_stats_view',
    );
  });

  test('nothing reads day_notes for live data any more', () {
    final outsideCopy = body
        .replaceFirst(RegExp(r'insert into public\.journal_notes[^;]*;'), '')
        .replaceFirst(RegExp(r'update public\.points_ledger l[^;]*;'), '');
    expect(
      RegExp(r'from public\.day_notes').hasMatch(outsideCopy),
      isFalse,
    );
  });
}

extension on String {
  int allMatchesIn(String text) => allMatches(text).length;
}
