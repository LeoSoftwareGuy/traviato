import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/bonus/data/models/bonus_task_assignment_model.dart';

void main() {
  group('BonusTaskAssignmentModel.fromJson', () {
    test('parses an open (uncompleted) assignment', () {
      final model = BonusTaskAssignmentModel.fromJson({
        'id': 'a1',
        'trip_id': 't1',
        'template_id': 40,
        'day_date': '2026-08-18',
        'completed_at': null,
        'photo_id': null,
        'created_at': '2026-08-18T09:00:00Z',
      });

      expect(model.id, 'a1');
      expect(model.dayDate, DateTime.parse('2026-08-18'));
      expect(model.isCompleted, isFalse);
      expect(model.photoId, isNull);
    });

    test('parses a completed assignment with a photo', () {
      final model = BonusTaskAssignmentModel.fromJson({
        'id': 'a2',
        'trip_id': 't1',
        'template_id': 1,
        'day_date': '2026-08-18',
        'completed_at': '2026-08-18T10:00:00Z',
        'photo_id': 'p1',
        'created_at': '2026-08-18T09:00:00Z',
      });

      expect(model.isCompleted, isTrue);
      expect(model.photoId, 'p1');
    });
  });
}
