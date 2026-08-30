import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/home/data/models/profile_stats_model.dart';

void main() {
  test('fromJson maps a profile_stats_view row', () {
    final model = ProfileStatsModel.fromJson({
      'user_id': 'u1',
      'memories_count': 3,
      'places_count': 5,
      'countries_count': 2,
      'days_logged': 7,
      'stars_total': 42,
    });

    expect(model.memories, 3);
    expect(model.places, 5);
    expect(model.days, 7);
    expect(model.stars, 42);
  });
}
