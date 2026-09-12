import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/data/models/wrap_up_model.dart';

Map<String, dynamic> _validContent() => {
  'dates': {
    'start_date': '2026-06-01',
    'end_date': '2026-06-05',
    'formatted': '1–5 June 2026',
  },
  'cover_photo': {'image_path': 'asset:hero'},
  'invitation': {'line1': 'Five days.', 'line2': 'One long road.'},
  'bridges': ['The first stretch.', 'The middle of it.', 'The last light.'],
  'moments': [
    {
      'photo_id': 'p1',
      'storage_path': 'u/t/p1.jpg',
      'day_date': '2026-06-01',
      'note': 'Golden hour',
      'badge': 'Dare · Snap anything at all · ✦1',
    },
    {
      'photo_id': 'p2',
      'storage_path': 'u/t/p2.jpg',
      'day_date': '2026-06-02',
      'note': null,
      'badge': null,
    },
  ],
  'flurry_leftovers': {
    'photos': [
      {
        'photo_id': 'p3',
        'storage_path': 'u/t/p3.jpg',
        'day_date': '2026-06-03',
      },
    ],
    'total_remaining_label': null,
  },
  'footnote': {'photo_count': 10, 'bonus_completed_count': 2, 'stars': 14},
  'unlock': {
    'code': 'first_adventure',
    'name': 'First Adventure',
    'reason': 'You logged every single day of this one.',
  },
  'keepsake': {
    'title_line1': 'Lisbon',
    'title_line2': 'Getaway',
    'closing_quote': "This one's yours to keep.",
  },
};

void main() {
  group('WrapUpModel.fromRow', () {
    test('parses every field from a well-formed row', () {
      final model = WrapUpModel.fromRow({
        'content': _validContent(),
        'generated_at': '2026-06-06T00:00:00Z',
        'published_at': null,
      });

      expect(model.dates.formatted, '1–5 June 2026');
      expect(model.dates.startDate, DateTime.parse('2026-06-01'));
      expect(model.coverPhoto.imagePath, 'asset:hero');
      expect(model.invitation.line1, 'Five days.');
      expect(model.invitation.line2, 'One long road.');
      expect(model.bridges, [
        'The first stretch.',
        'The middle of it.',
        'The last light.',
      ]);
      expect(model.moments, hasLength(2));
      expect(model.moments.first.photoId, 'p1');
      expect(model.moments.first.badge, 'Dare · Snap anything at all · ✦1');
      expect(model.moments.last.note, isNull);
      expect(model.flurryLeftovers.photos.single.photoId, 'p3');
      expect(model.footnote.photoCount, 10);
      expect(model.footnote.bonusCompletedCount, 2);
      expect(model.footnote.stars, 14);
      expect(model.unlock?.code, 'first_adventure');
      expect(model.keepsake.titleLine1, 'Lisbon');
      expect(model.keepsake.titleLine2, 'Getaway');
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

    test(
      'a missing content column degrades every field to a neutral default',
      () {
        final model = WrapUpModel.fromRow({
          'content': null,
          'generated_at': '2026-06-06T00:00:00Z',
          'published_at': null,
        });

        expect(model.dates.formatted, '');
        expect(model.coverPhoto.imagePath, isNull);
        expect(model.invitation.line1, '');
        expect(model.bridges, ['', '', '']);
        expect(model.moments, isEmpty);
        expect(model.flurryLeftovers.photos, isEmpty);
        expect(model.footnote.photoCount, 0);
        expect(model.unlock, isNull);
        expect(model.keepsake.titleLine1, '');
      },
    );

    test('a malformed dates block degrades to an empty formatted string', () {
      final content = _validContent();
      content['dates'] = {'start_date': 42}; // wrong type

      final model = WrapUpModel.fromRow({
        'content': content,
        'generated_at': '2026-06-06T00:00:00Z',
        'published_at': null,
      });

      expect(model.dates.formatted, '');
      expect(model.keepsake.titleLine1, 'Lisbon'); // rest still parses
    });

    test('a malformed moments entry is skipped, valid ones kept', () {
      final content = _validContent();
      content['moments'] = [
        {'photo_id': 'p1', 'note': 'Kept.'},
        {'note': 'No id.'}, // missing photo_id -> skipped
      ];

      final model = WrapUpModel.fromRow({
        'content': content,
        'generated_at': '2026-06-06T00:00:00Z',
        'published_at': null,
      });

      expect(model.moments, hasLength(1));
      expect(model.moments.single.photoId, 'p1');
    });

    test(
      'bridges shorter than 3 are padded with empty strings, never dropped',
      () {
        final content = _validContent();
        content['bridges'] = ['Only one.'];

        final model = WrapUpModel.fromRow({
          'content': content,
          'generated_at': '2026-06-06T00:00:00Z',
          'published_at': null,
        });

        expect(model.bridges, ['Only one.', '', '']);
      },
    );

    test('a malformed unlock block degrades to null', () {
      final content = _validContent();
      content['unlock'] = {'code': 'first_adventure'}; // missing name/reason

      final model = WrapUpModel.fromRow({
        'content': content,
        'generated_at': '2026-06-06T00:00:00Z',
        'published_at': null,
      });

      expect(model.unlock, isNull);
    });

    test('zero photos and zero leftovers still parse without error', () {
      final content = _validContent();
      content['moments'] = <Map<String, dynamic>>[];
      content['flurry_leftovers'] = {
        'photos': <Map<String, dynamic>>[],
        'total_remaining_label': null,
      };

      final model = WrapUpModel.fromRow({
        'content': content,
        'generated_at': '2026-06-06T00:00:00Z',
        'published_at': null,
      });

      expect(model.moments, isEmpty);
      expect(model.flurryLeftovers.photos, isEmpty);
    });
  });
}
