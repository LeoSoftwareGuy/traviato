import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static checks on the `film_seen_at` migration (#279): Home decides
/// between the film and the Kept Memory page from `trip_card_view`, so the
/// latest definition of that view must still carry the column, and only
/// already-kept memories are backfilled as seen.
void main() {
  late List<File> migrations;

  String sqlOf(File file) =>
      // Comments hold revert notes and prose that mention the same names.
      file.readAsStringSync().replaceAll(RegExp(r'--.*'), '');

  setUpAll(() {
    migrations =
        Directory('supabase/migrations')
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.sql'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
  });

  test('adds the column and backfills only kept memories', () {
    final sql = sqlOf(
      migrations.singleWhere(
        (f) => f.path.endsWith('_add_trips_film_seen_at.sql'),
      ),
    );

    expect(
      sql,
      contains('alter table public.trips add column film_seen_at timestamptz'),
    );
    final backfill = sql.substring(
      sql.indexOf('update public.trips'),
      sql.indexOf(';', sql.indexOf('update public.trips')),
    );
    expect(backfill, contains('w.published_at is not null'));
  });

  test('the latest trip_card_view still selects film_seen_at, last', () {
    String? latestView;
    for (final file in migrations) {
      final sql = sqlOf(file);
      final start = sql.indexOf('create or replace view public.trip_card_view');
      if (start == -1) continue;
      latestView = sql.substring(start, sql.indexOf(';', start));
    }

    expect(latestView, isNotNull);
    final selectList = latestView!.substring(
      latestView.indexOf('select'),
      latestView.lastIndexOf('from public.trips t'),
    );
    expect(selectList.trimRight(), endsWith('t.film_seen_at'));
  });
}
