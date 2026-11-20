import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/domain/film_template.dart';

FilmTemplate _byCode(String code) =>
    FilmTemplate.values.firstWhere((t) => t.code == code);

void main() {
  test('matches the edge function mapping (#433)', () {
    final json =
        jsonDecode(
              File(
                'supabase/functions/generate_wrap_up/film_templates.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final priority = [
      for (final rule in json['priority'] as List<dynamic>)
        [
          (rule as Map<String, dynamic>)['template'] as String,
          ...(rule['vibes'] as List<dynamic>).cast<String>(),
        ],
    ];
    expect(priority, [
      for (final (template, vibes) in FilmTemplate.priority)
        [template.code, ...vibes],
    ]);
    expect(_byCode(json['default'] as String), FilmTemplate.fallback);
    expect({
      for (final e in (json['playsAs'] as Map<String, dynamic>).entries)
        _byCode(e.key): _byCode(e.value as String),
    }, FilmTemplate.playsAs);
  });

  test('vibes choose the film, by priority', () {
    expect(FilmTemplate.playedFor(['Nightlife']), FilmTemplate.neonNight);
    expect(FilmTemplate.playedFor(['Romantic']), FilmTemplate.goldenVows);
    expect(FilmTemplate.chosenFor(['Wildlife']), FilmTemplate.fieldNotes);
    expect(FilmTemplate.playedFor(['Wildlife']), FilmTemplate.skyStory);
    expect(FilmTemplate.playedFor(['Foodie']), FilmTemplate.skyStory);
    expect(FilmTemplate.playedFor(const []), FilmTemplate.skyStory);
    expect(
      FilmTemplate.playedFor(['Nightlife', 'Romantic']),
      FilmTemplate.goldenVows,
    );
    expect(
      FilmTemplate.playedFor(['Adventure', 'Nightlife']),
      FilmTemplate.neonNight,
    );
  });
}
