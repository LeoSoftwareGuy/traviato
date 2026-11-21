import 'package:flutter/foundation.dart';

/// Whether the director's Plan inspector (#328) is in this build: always in
/// debug builds, and in a profile or release build built with
/// `--dart-define=PLAN_INSPECTOR=true` (#440) — so the films can be
/// reviewed on a phone without a cable. Normal releases never have it.
const bool hasPlanInspector =
    kDebugMode || bool.fromEnvironment('PLAN_INSPECTOR');
