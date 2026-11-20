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
    });
  });
}
