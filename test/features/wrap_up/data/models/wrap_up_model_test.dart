import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/data/models/wrap_up_model.dart';

Map<String, dynamic> _validContent() => {
  'hero': {
    'title': 'Dolomites, slowly',
    'subtitle': 'Five days of thin air.',
    'cover_photo_id': 'p1',
  },
  'route_chapter': {
    'intro': 'You started in Venice and let the trams carry you.',
    'stops': [
      {
        'place_text': 'Venice',
        'day_date': '2026-06-01',
        'lat': 45.4,
        'lng': 12.3,
      },
      {
        'place_text': 'Cortina',
        'day_date': '2026-06-03',
        'lat': 46.5,
        'lng': 12.1,
      },
    ],
    'stats': {'total_km': 312, 'stop_count': 2},
  },
  'photo_beats': [
    {'photo_id': 'p1', 'day_date': '2026-06-01', 'narrative': 'Golden hour.'},
  ],
  'stat_chapter': {
    'stats': [
      {'label': 'Days', 'value': '5'},
    ],
  },
  'achievement_moment': {
    'code': 'first_adventure',
    'title': 'First Adventure',
    'description': 'Logged your first trip.',
  },
  'close': {'line': "This one you'll keep."},
};

void main() {
  group('WrapUpModel.fromRow', () {
    test('parses every block from a well-formed row', () {
      final model = WrapUpModel.fromRow({
        'content': _validContent(),
        'generated_at': '2026-06-06T00:00:00Z',
        'published_at': null,
      });

      expect(model.hero?.title, 'Dolomites, slowly');
      expect(model.hero?.coverPhotoId, 'p1');
      expect(model.routeChapter?.stops.length, 2);
      expect(model.routeChapter?.stops.first.placeText, 'Venice');
      expect(model.routeChapter?.totalKm, 312.0);
      expect(model.routeChapter?.stopCount, 2);
      expect(model.photoBeats.single.narrative, 'Golden hour.');
      expect(model.statChapter?.stats.single.label, 'Days');
      expect(model.achievementMoment?.code, 'first_adventure');
      expect(model.close?.line, "This one you'll keep.");
      expect(model.generatedAt, DateTime.parse('2026-06-06T00:00:00Z'));
      expect(model.publishedAt, isNull);
    });

    test('parses published_at when present', () {
      final model = WrapUpModel.fromRow({
        'content': _validContent(),
        'generated_at': '2026-06-06T00:00:00Z',
        'published_at': '2026-06-07T00:00:00Z',
      });

      expect(model.publishedAt, DateTime.parse('2026-06-07T00:00:00Z'));
      expect(model.isPublished, isTrue);
    });

    test('a missing content column degrades to every block null/empty', () {
      final model = WrapUpModel.fromRow({
        'content': null,
        'generated_at': '2026-06-06T00:00:00Z',
        'published_at': null,
      });

      expect(model.hero, isNull);
      expect(model.routeChapter, isNull);
      expect(model.photoBeats, isEmpty);
      expect(model.statChapter, isNull);
      expect(model.achievementMoment, isNull);
      expect(model.close, isNull);
    });

    test(
      'a malformed hero (wrong type) degrades to null, other blocks unaffected',
      () {
        final content = _validContent();
        content['hero'] = {'title': 42}; // title must be a String

        final model = WrapUpModel.fromRow({
          'content': content,
          'generated_at': '2026-06-06T00:00:00Z',
          'published_at': null,
        });

        expect(model.hero, isNull);
        expect(model.close?.line, "This one you'll keep."); // rest still parses
      },
    );

    test('a malformed photo_beats entry is skipped, valid ones kept', () {
      final content = _validContent();
      content['photo_beats'] = [
        {'photo_id': 'p1', 'narrative': 'Kept.'},
        {'photo_id': 'p2'}, // missing narrative -> skipped
        {'narrative': 'No id.'}, // missing photo_id -> skipped
      ];

      final model = WrapUpModel.fromRow({
        'content': content,
        'generated_at': '2026-06-06T00:00:00Z',
        'published_at': null,
      });

      expect(model.photoBeats.length, 1);
      expect(model.photoBeats.single.photoId, 'p1');
    });

    test('an empty stat_chapter.stats degrades the whole block to null', () {
      final content = _validContent();
      content['stat_chapter'] = {'stats': <Map<String, dynamic>>[]};

      final model = WrapUpModel.fromRow({
        'content': content,
        'generated_at': '2026-06-06T00:00:00Z',
        'published_at': null,
      });

      expect(model.statChapter, isNull);
    });

    test('a route stop missing day_date is dropped from the stops list', () {
      final content = _validContent();
      content['route_chapter']['stops'] = [
        {'place_text': 'Venice', 'lat': 45.4, 'lng': 12.3},
      ];

      final model = WrapUpModel.fromRow({
        'content': content,
        'generated_at': '2026-06-06T00:00:00Z',
        'published_at': null,
      });

      expect(model.routeChapter?.stops, isEmpty);
    });

    test(
      'no location data at all still parses a route chapter with zero stops',
      () {
        final content = _validContent();
        content['route_chapter'] = {
          'intro': 'You never left the lake.',
          'stops': <Map<String, dynamic>>[],
          'stats': {'total_km': null, 'stop_count': 0},
        };

        final model = WrapUpModel.fromRow({
          'content': content,
          'generated_at': '2026-06-06T00:00:00Z',
          'published_at': null,
        });

        expect(model.routeChapter?.stops, isEmpty);
        expect(model.routeChapter?.stopCount, 0);
        expect(model.routeChapter?.totalKm, isNull);
      },
    );
  });
}
