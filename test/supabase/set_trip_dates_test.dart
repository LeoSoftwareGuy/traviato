import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static checks on the `set_trip_dates` migration (#271) — the date rules
/// live in SQL, so these guard the agreed behavior without a database:
/// quests move with the start date, notes/photos/bonus tasks keep their
/// calendar date, a dry run changes nothing, and stars are taken back
/// before the rows they're keyed by disappear.
void main() {
  late String body;

  setUpAll(() {
    final file = Directory('supabase/migrations')
        .listSync()
        .whereType<File>()
        .singleWhere((f) => f.path.endsWith('_set_trip_dates.sql'));
    // Comments hold revert notes and prose that mention the same names.
    final sql = file.readAsStringSync().replaceAll(RegExp(r'--.*'), '');
    body = sql.substring(
      sql.indexOf('create function public.set_trip_dates'),
      sql.indexOf(r'end;'),
    );
  });

  int at(String needle) {
    final index = body.indexOf(needle);
    expect(index, isNot(-1), reason: 'missing: $needle');
    return index;
  }

  test('quests move by the start-date delta', () {
    expect(body, contains('v_delta := p_start - v_trip.start_date'));
    expect(body, contains('set day_date = day_date + v_delta'));
  });

  test('notes, photos and bonus tasks are judged by their own date', () {
    for (final table in ['day_notes', 'photos', 'bonus_task_assignments']) {
      final delete = RegExp(
        'delete from public\\.$table\\s+where trip_id = p_trip_id'
        '[^;]*\\(day_date < p_start or day_date > p_end\\)',
      );
      expect(delete.hasMatch(body), isTrue, reason: table);
    }
  });

  test('a dry run returns before anything is deleted or updated', () {
    final dryRunReturn = at('if p_dry_run then');
    for (final write in ['delete from', 'update public.']) {
      expect(body.indexOf(write), greaterThan(dryRunReturn), reason: write);
    }
  });

  test('stars are taken back before their source rows are deleted', () {
    final noteStars = at("l.source = 'note'");
    final photoStars = at("l.source = 'photo'");
    expect(noteStars, lessThan(at('delete from public.day_notes')));
    expect(photoStars, lessThan(at('delete from public.photos')));
  });

  test('a photo that completed a bonus task keeps its stars', () {
    final photoStars = body.substring(at("l.source = 'photo'"));
    expect(
      photoStars,
      contains(
        'where a.photo_id = p.id and a.completed_at is not null',
      ),
    );
  });

  test('the old ±1 shift_trip_dates is dropped', () {
    final file = Directory('supabase/migrations')
        .listSync()
        .whereType<File>()
        .singleWhere((f) => f.path.endsWith('_set_trip_dates.sql'));
    expect(
      file.readAsStringSync(),
      contains('drop function public.shift_trip_dates(uuid, int);'),
    );
  });
}
