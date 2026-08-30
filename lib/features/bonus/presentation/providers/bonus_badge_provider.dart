import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../controllers/bonus_tray_loader.dart';

part 'bonus_badge_provider.g.dart';

/// Open (incomplete) task count for a trip's stars badge dot — Home's
/// "available-count dot when tray has open tasks" (issue #64 AC). Runs the
/// same ensure-tray orchestration the tray screen does, so the dot is
/// accurate the moment Home loads rather than only after Bonus has been
/// opened once.
@riverpod
Future<int> bonusOpenCountForTrip(Ref ref, String tripId) async {
  final state = await loadBonusTrayState(ref, tripId);
  final openDaily = state.dailyTasks.where((t) => !t.isCompleted).length;
  final streakSaverOpen = state.activeStreakSaver == null ? 0 : 1;
  return openDaily + streakSaverOpen;
}
