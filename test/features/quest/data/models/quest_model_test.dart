import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/quest/data/models/quest_model.dart';

void main() {
  group('QuestModel.fromJson', () {
    test('parses a fully populated row', () {
      final model = QuestModel.fromJson({
        'id': 'q1',
        'trip_id': 't1',
        'day_date': '2026-08-18',
        'time': '08:00:00',
        'title': 'Pack the car',
        'place_text': 'Cooler, blankets, hiking boots',
        'position': 0,
        'completed_at': null,
        'created_at': '2026-01-01T00:00:00Z',
      });

      expect(model.id, 'q1');
      expect(model.dayDate, DateTime.parse('2026-08-18'));
      expect(model.time, const Duration(hours: 8));
      expect(model.title, 'Pack the car');
      expect(model.isCompleted, isFalse);
    });

    test('parses a null time and a completed_at timestamp', () {
      final model = QuestModel.fromJson({
        'id': 'q2',
        'trip_id': 't1',
        'day_date': '2026-08-18',
        'time': null,
        'title': 'Unpack & settle in',
        'place_text': null,
        'position': 1,
        'completed_at': '2026-08-18T10:00:00Z',
        'created_at': '2026-01-01T00:00:00Z',
      });

      expect(model.time, isNull);
      expect(model.placeText, isNull);
      expect(model.isCompleted, isTrue);
    });
  });

  group('parseTimeOfDayString / formatTimeOfDayString', () {
    test('round-trips HH:MM:SS', () {
      expect(
        parseTimeOfDayString('14:30:00'),
        const Duration(hours: 14, minutes: 30),
      );
      expect(
        formatTimeOfDayString(const Duration(hours: 14, minutes: 30)),
        '14:30:00',
      );
    });

    test('handles null', () {
      expect(parseTimeOfDayString(null), isNull);
      expect(formatTimeOfDayString(null), isNull);
    });
  });
}
