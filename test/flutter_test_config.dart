import 'dart:async';

import 'package:intl/date_symbol_data_local.dart';

/// Runs before every test file. Mirrors `main()`'s
/// `initializeDateFormatting()` so locale-aware `DateFormat(…, locale)` works
/// in widget tests for en/ru/et (#220).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await initializeDateFormatting();
  await testMain();
}
