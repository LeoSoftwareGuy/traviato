import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/trip/data/models/trip_model.dart';

void main() {
  group('TripModel.fromJson', () {
    test('parses a fully populated row', () {
      final model = TripModel.fromJson({
        'id': 't1',
        'user_id': 'u1',
        'name': 'Summer in Tokyo',
        'destination': 'Tokyo, Japan',
        'country_code': 'JP',
        'start_date': '2026-08-18',
        'end_date': '2026-08-22',
        'vibes': ['Foodie', 'Cultural'],
        'cover_image_path': null,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      });

      expect(model.id, 't1');
      expect(model.userId, 'u1');
      expect(model.name, 'Summer in Tokyo');
      expect(model.startDate, DateTime.parse('2026-08-18'));
      expect(model.vibes, ['Foodie', 'Cultural']);
    });

    test('parses null optional fields', () {
      final model = TripModel.fromJson({
        'id': 't2',
        'user_id': 'u1',
        'name': 'Someday trip',
        'destination': null,
        'country_code': null,
        'start_date': null,
        'end_date': null,
        'vibes': null,
        'cover_image_path': null,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      });

      expect(model.destination, isNull);
      expect(model.startDate, isNull);
      expect(model.endDate, isNull);
      expect(model.vibes, isEmpty);
    });
  });
}
