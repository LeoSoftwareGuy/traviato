import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/trip/data/models/trip_card_model.dart';
import 'package:traviato/features/trip/domain/entities/trip_card_entity.dart';

void main() {
  group('TripCardModel.fromJson', () {
    test('parses a fully populated row', () {
      final model = TripCardModel.fromJson({
        'id': 't1',
        'user_id': 'u1',
        'name': 'Weekend in the woods',
        'destination': 'Blue Ridge, GA',
        'country_code': 'US',
        'start_date': '2026-08-18',
        'end_date': '2026-08-22',
        'vibes': ['Adventure', 'Chill'],
        'cover_image_path': null,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
        'status': 'current',
        'duration_days': 5,
        'photo_count': 3,
        'stars': 7,
        'expense_total': 120.5,
      });

      expect(model.id, 't1');
      expect(model.status, TripStatus.current);
      expect(model.startDate, DateTime.parse('2026-08-18'));
      expect(model.vibes, ['Adventure', 'Chill']);
      expect(model.durationDays, 5);
      expect(model.expenseTotal, 120.5);
    });

    test('parses null dates and an unknown status as undated', () {
      final model = TripCardModel.fromJson({
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
        'status': 'undated',
        'duration_days': null,
        'photo_count': 0,
        'stars': 0,
        'expense_total': 0,
      });

      expect(model.startDate, isNull);
      expect(model.endDate, isNull);
      expect(model.vibes, isEmpty);
      expect(model.status, TripStatus.undated);
      expect(model.durationDays, isNull);
    });
  });
}
