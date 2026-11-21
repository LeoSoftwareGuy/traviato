import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/config/film_debug_flags.dart';

void main() {
  test(
    'the Plan inspector: in debug builds, else only with the switch (#440)',
    () {
      expect(
        hasPlanInspector,
        kDebugMode || const bool.fromEnvironment('PLAN_INSPECTOR'),
      );
    },
  );
}
