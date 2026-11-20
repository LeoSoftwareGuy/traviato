import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/domain/wrap_up_limits.dart';

void main() {
  test('WrapUpLimits matches the edge function config (#432)', () {
    final json =
        jsonDecode(
              File(
                'supabase/functions/generate_wrap_up/wrap_up_limits.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    expect(json, {
      'minPhotos': WrapUpLimits.minPhotos,
      'maxFilmPhotos': WrapUpLimits.maxFilmPhotos,
      'minNotes': WrapUpLimits.minNotes,
      'maxNoteLines': WrapUpLimits.maxNoteLines,
      'maxVibes': WrapUpLimits.maxVibes,
      'shortestFilmSeconds': WrapUpLimits.shortestFilmSeconds,
      'longestFilmSeconds': WrapUpLimits.longestFilmSeconds,
      'shortestFilmPhotos': WrapUpLimits.shortestFilmPhotos,
      'longestFilmPhotos': WrapUpLimits.longestFilmPhotos,
    });
  });

  test('filmSeconds: 30 s at 15 photos, 75 s at 40 or more (#434)', () {
    expect(WrapUpLimits.filmSeconds(10), 30);
    expect(WrapUpLimits.filmSeconds(15), 30);
    expect(WrapUpLimits.filmSeconds(25), 48);
    expect(WrapUpLimits.filmSeconds(40), 75);
    expect(WrapUpLimits.filmSeconds(60), 75);
  });
}
