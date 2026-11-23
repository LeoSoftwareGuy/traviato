import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static checks on #461's columns: where photos were taken and notes
/// written, and the memory's resolved zone.
void main() {
  late String sql;

  setUpAll(() {
    final file = Directory('supabase/migrations')
        .listSync()
        .whereType<File>()
        .singleWhere(
          (f) => f.path.endsWith('_photo_note_trip_time_zones.sql'),
        );
    sql = file.readAsStringSync().replaceAll(RegExp(r'--.*'), '');
  });

  test('adds nullable, range-checked offsets and the zone', () {
    expect(sql, contains('add column utc_offset_minutes smallint'));
    expect(sql, contains('check (utc_offset_minutes between -1080 and 1080)'));
    expect(sql, contains("check (utc_offset_source in ('exif', 'device'))"));
    expect(sql, contains('add column time_zone text'));
    expect(sql, isNot(contains('not null')));
  });

  test("only the service role writes the trip's zone", () {
    expect(
      sql,
      contains('grant update (time_zone) on public.trips to service_role;'),
    );
  });

  test("an edit keeps a note's offset", () {
    expect(sql, contains('new.utc_offset_minutes := old.utc_offset_minutes;'));
  });

  test('trip_card_view gains time_zone as its last column', () {
    expect(sql, contains('create or replace view public.trip_card_view'));
    expect(
      sql,
      contains('as quest_count,\n  t.time_zone\nfrom public.trips t'),
    );
    expect(sql, contains('with (security_invoker = true)'));
    expect(
      sql,
      contains('grant select on public.trip_card_view to authenticated;'),
    );
  });
}
