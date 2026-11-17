import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _code(File f) => f.readAsStringSync().replaceAll(RegExp(r'--.*'), '');

/// #406: the old one-note-per-day table is dropped, and nothing written
/// after the drop refers to it. The migration was also replayed on a
/// scratch Postgres: no function or view mentioned `day_notes`, and legacy
/// notes stayed in `journal_notes`.
void main() {
  final migrations =
      Directory('supabase/migrations')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.sql'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  final dropIndex = migrations.indexWhere(
    (f) => f.path.endsWith('_drop_day_notes.sql'),
  );

  test('a migration drops day_notes', () {
    expect(dropIndex, isNot(-1));
    expect(
      _code(migrations[dropIndex]),
      contains('drop table public.day_notes;'),
    );
  });

  test('no later migration refers to day_notes', () {
    for (final f in migrations.skip(dropIndex + 1)) {
      expect(_code(f), isNot(contains('day_notes')), reason: f.path);
    }
  });

  test('no edge function or app code refers to day_notes', () {
    final sources =
        [
          ...Directory('supabase/functions').listSync(recursive: true),
          ...Directory('lib').listSync(recursive: true),
        ].whereType<File>().where(
          (f) => f.path.endsWith('.ts') || f.path.endsWith('.dart'),
        );
    for (final f in sources) {
      final code = f.readAsStringSync().replaceAll(RegExp(r'//.*'), '');
      expect(code, isNot(contains('day_notes')), reason: f.path);
    }
  });
}
