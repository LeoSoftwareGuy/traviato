import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Deleting a memory removes the stars it earned (#247): the ledger's trip
/// link must cascade. Reads the migrations in order, so a later one that
/// redefines the link is what counts.
void main() {
  test('the latest points_ledger trip link cascades on delete', () {
    final files =
        Directory('supabase/migrations')
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.sql'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    final link = RegExp(
      r'trip_id\b[^;]*?references public\.trips \(id\) on delete (set null|cascade)',
    );
    String? latest;
    for (final file in files) {
      // Comments hold revert notes with the old definition.
      final sql = file.readAsStringSync().replaceAll(RegExp(r'--.*'), '');
      if (!sql.contains('points_ledger')) continue;
      // Only statements about the ledger table itself.
      for (final statement in sql.split(';')) {
        if (!RegExp(
          r'(create table|alter table) public\.points_ledger\b',
        ).hasMatch(statement)) {
          continue;
        }
        final match = link.firstMatch(statement);
        if (match != null) latest = match[1];
      }
    }
    expect(latest, 'cascade');
  });
}
