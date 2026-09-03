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
      'photos_count': 11,
      'notes_count': 4,
    });

    expect(model.memories, 3);
    expect(model.places, 5);
    expect(model.countries, 2);
    expect(model.days, 7);
    expect(model.stars, 42);
    expect(model.photos, 11);
    expect(model.notes, 4);
  });
}
