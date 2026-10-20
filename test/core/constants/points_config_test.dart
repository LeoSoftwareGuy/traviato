import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/constants/points_config.dart';

/// [PointsConfig] mirrors values the server owns (#219). Reads the
/// migrations in order, so a later redefinition is what counts.
List<String> _migrations() {
  final files =
      Directory('supabase/migrations')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.sql'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  // Comments hold revert notes with old definitions.
  return [
    for (final f in files) f.readAsStringSync().replaceAll(RegExp(r'--.*'), ''),
  ];
}

void main() {
  test('photo/note/quest rates match the latest award_points', () {
    final definition = _migrations().lastWhere(
      (sql) => RegExp(
        r'create (or replace )?function public\.award_points\(',
      ).hasMatch(sql),
    );
    int rateFor(String source) => int.parse(
      RegExp(
        "p_source = '$source' then"
        r'.*?v_points := (\d+);',
        dotAll: true,
      ).firstMatch(definition)![1]!,
    );

    expect(rateFor('photo'), PointsConfig.photo);
    expect(rateFor('note'), PointsConfig.note);
    expect(rateFor('quest'), PointsConfig.quest);
  });

  test('the bonus range spans the seeded regular templates', () {
    final seed = _migrations().lastWhere(
      (sql) => sql.contains('insert into public.bonus_task_templates'),
    );
    final points = RegExp(
      r", (\d+), '\w+', 'regular'\)",
    ).allMatches(seed).map((m) => int.parse(m[1]!)).toList();

    expect(points, isNotEmpty);
    expect(points.reduce((a, b) => a < b ? a : b), PointsConfig.bonusTaskMin);
    expect(points.reduce((a, b) => a > b ? a : b), PointsConfig.bonusTaskMax);
  });
}
