import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:traviato/core/theme/app_typography.dart';

/// Runs before every test file. Mirrors `main()`'s
/// `initializeDateFormatting()` so locale-aware `DateFormat(…, locale)` works
/// in widget tests for en/ru/et (#220).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await initializeDateFormatting();
  // Typography is per-locale static state (#239/#241); start every test in
  // English so a ru/et test can't leak into the next one.
  setUp(() => AppTypography.useLocale(const Locale('en')));
  await testMain();
}
