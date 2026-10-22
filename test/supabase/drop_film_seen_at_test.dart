import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static checks on dropping `trips.film_seen_at` (#281): the latest
/// `trip_card_view` must no longer select it (else the drop would fail),
/// and recreating the view must restore its grant.
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

  test('drops the view before the column, then recreates and grants it', () {
    final sql = sqlOf(
      migrations.singleWhere(
        (f) => f.path.endsWith('_drop_trips_film_seen_at.sql'),
      ),
    );

    final dropView = sql.indexOf('drop view public.trip_card_view');
    final dropColumn = sql.indexOf(
      'alter table public.trips drop column film_seen_at',
    );
    final create = sql.indexOf('create view public.trip_card_view');
    final grant = sql.indexOf(
      'grant select on public.trip_card_view to authenticated',
    );
    expect(dropView, isNot(-1));
    expect(dropView, lessThan(dropColumn));
    expect(dropColumn, lessThan(create));
    expect(create, lessThan(grant));
    expect(sql, isNot(contains('cascade')));
  });

  test('the latest trip_card_view no longer selects film_seen_at', () {
    String? latestView;
    for (final file in migrations) {
      final sql = sqlOf(file);
      final start = sql.indexOf(
        RegExp(r'create (or replace )?view public\.trip_card_view'),
      );
      if (start == -1) continue;
      latestView = sql.substring(start, sql.indexOf(';', start));
    }

    expect(latestView, isNotNull);
    expect(latestView, isNot(contains('film_seen_at')));
    expect(latestView, contains('quest_count'));
  });
}
