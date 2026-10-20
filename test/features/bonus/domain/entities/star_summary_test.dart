import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/bonus/domain/entities/star_ledger_group_entity.dart';
import 'package:traviato/features/bonus/domain/entities/star_summary.dart';

import '../../../trip/fakes/fake_trip_repository.dart';

StarLedgerGroupEntity _group(
  String? tripId,
  StarSource source,
  int count,
  int points,
) => StarLedgerGroupEntity(
  tripId: tripId,
  source: source,
  entryCount: count,
  points: points,
);

void main() {
  final dolomites = buildTripCard(id: 'd', name: 'Dolomites, slowly');
  final tartu = buildTripCard(id: 't', name: 'Tartu in the rain');

  final groups = [
    _group('d', StarSource.photo, 6, 12),
    _group('d', StarSource.note, 5, 5),
    _group('t', StarSource.photo, 3, 6),
    _group('t', StarSource.bonusTask, 2, 4),
    _group(null, StarSource.quest, 2, 2),
    // Deleted between the two reads: no longer among the trips.
    _group('gone', StarSource.note, 1, 1),
  ];

  late StarSummary summary;
  setUp(() => summary = StarSummary.fromGroups(groups, [dolomites, tartu]));

  test('the total matches the ledger and the type rows add up to it', () {
    expect(summary.totalStars, 30);
    expect(summary.bySource.fold(0, (sum, s) => sum + s.points), 30);
  });

  test('types come in the fixed order, counts summed across memories', () {
    expect(summary.bySource, const [
      StarSourceTotal(source: StarSource.photo, count: 9, points: 18),
      StarSourceTotal(source: StarSource.note, count: 6, points: 6),
      StarSourceTotal(source: StarSource.quest, count: 2, points: 2),
      StarSourceTotal(source: StarSource.bonusTask, count: 2, points: 4),
    ]);
  });

  test('leaves out types with no stars', () {
    final only = StarSummary.fromGroups(
      [
        _group('d', StarSource.note, 1, 1),
      ],
      [dolomites],
    );
    expect(only.bySource.map((s) => s.source), [StarSource.note]);
  });

  test('memories sorted by stars, null and deleted trips folded into one '
      'Earlier memories row', () {
    expect(summary.byMemory, [
      StarMemoryTotal(trip: dolomites, points: 17),
      StarMemoryTotal(trip: tartu, points: 10),
      const StarMemoryTotal(trip: null, points: 3),
    ]);
  });

  test('Earlier memories never counts toward memoryCount', () {
    expect(summary.memoryCount, 2);
  });

  test('no ledger rows is an empty summary', () {
    final empty = StarSummary.fromGroups(const [], [dolomites]);
    expect(empty, const StarSummary.empty());
    expect(empty.hasStars, isFalse);
  });
}
