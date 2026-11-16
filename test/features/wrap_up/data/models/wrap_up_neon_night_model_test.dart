import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/data/models/wrap_up_model.dart';
import 'package:traviato/features/wrap_up/data/models/wrap_up_neon_night_model.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_neon_night.dart';

Map<String, dynamic> _content() => {
  'neon_night': {
    'nn_version': 1,
    'title': 'Night out',
    'start_date': '2026-11-14',
    'place': 'Tallinn',
    'plan': [
      {'time': '22:00', 'title': 'Pre-drinks', 'done': true},
      {'time': '25:00', 'title': 'Bad time'},
      {'time': '03:00', 'title': 'Afterparty', 'done': false},
    ],
    'chapters': [
      {
        'title': 'Doors open',
        'photos': [
          {'id': 'p1', 'taken_at': '2026-11-14T20:10:00Z'},
          {
            'id': 'p2',
            'taken_at': '2026-11-14T20:20:00Z',
            'caption': 'Lost the keys',
          },
          {'id': 'broken'},
        ],
        'note': 'Queue was worth it.',
        'card_photo_ids': ['p2', 3],
        'moments': [
          {
            'type': 'split',
            'photo_ids': ['p1', 'p2'],
            'place': 'Main stage',
          },
          {
            'type': 'slideshow',
            'photo_ids': ['p1', 'p2'],
          },
        ],
      },
      {'title': 'No photos', 'photos': <Object>[], 'moments': <Object>[]},
    ],
    'note': {
      'text': 'Best night ever',
      'number': 4,
      'written_at': '2026-11-14T22:31:00Z',
      'photo_id': 'p2',
    },
    'headline': 'Best night ever',
    'first_name': 'Leo',
    'totals': {'photos': 2, 'notes': 4, 'ticks': 1, 'moments': 2},
    'heart_photo_ids': ['p1', 7, 'p2'],
  },
};

void main() {
  test('reads content.neon_night, dropping what is malformed (#363)', () {
    final nn = parseWrapUpNeonNight(_content())!;

    expect(nn.title, 'Night out');
    expect(nn.startDate, DateTime(2026, 11, 14));
    expect(nn.place, 'Tallinn');
    expect(nn.plan, const [
      WrapUpNeonPlanRow(time: '22:00', title: 'Pre-drinks', done: true),
      WrapUpNeonPlanRow(time: '03:00', title: 'Afterparty'),
    ]);
    expect(nn.chapters, hasLength(1));
    final chapter = nn.chapters.single;
    expect(chapter.photos.map((p) => p.id), ['p1', 'p2']);
    expect(chapter.photos.first.takenAt, DateTime.utc(2026, 11, 14, 20, 10));
    // The user's caption (#387); none → null.
    expect(chapter.photos.first.caption, isNull);
    expect(chapter.photos[1].caption, 'Lost the keys');
    expect(chapter.note, 'Queue was worth it.');
    expect(chapter.moments, const [
      WrapUpNeonMoment(
        type: 'split',
        photoIds: ['p1', 'p2'],
        place: 'Main stage',
      ),
    ]);
    expect(nn.note!.number, 4);
    expect(nn.note!.writtenAt, DateTime.utc(2026, 11, 14, 22, 31));
    expect(nn.note!.photoId, 'p2');
    expect(nn.headline, 'Best night ever');
    expect(nn.firstName, 'Leo');
    expect(
      nn.totals,
      const WrapUpNeonTotals(photos: 2, notes: 4, ticks: 1, moments: 2),
    );
    expect(nn.heartPhotoIds, ['p1', 'p2']);
    // The card's own photos (#390), malformed ids dropped.
    expect(chapter.cardPhotoIds, ['p2']);
  });

  test('older content without heart_photo_ids: an empty list (#378)', () {
    final content = _content();
    (content['neon_night'] as Map).remove('heart_photo_ids');
    expect(parseWrapUpNeonNight(content)!.heartPhotoIds, isEmpty);
  });

  test('no title, no chapter with photos, or another version: none', () {
    for (final edit in <void Function(Map<String, dynamic>)>[
      (nn) => nn['nn_version'] = 2,
      (nn) => nn['title'] = '  ',
      (nn) => nn['chapters'] = [
        {'title': 'Empty', 'photos': <Object>[]},
      ],
    ]) {
      final content = _content();
      edit(content['neon_night'] as Map<String, dynamic>);
      expect(parseWrapUpNeonNight(content), isNull);
    }
    expect(parseWrapUpNeonNight(const {}), isNull);
  });

  test('a wrap-up row carries it', () {
    final model = WrapUpModel.fromRow({
      'content': _content(),
      'generated_at': '2026-11-15T00:00:00Z',
    });
    expect(model.neonNight?.title, 'Night out');
    expect(
      WrapUpModel.fromRow({
        'content': const <String, dynamic>{},
        'generated_at': '2026-11-15T00:00:00Z',
      }).neonNight,
      isNull,
    );
  });
}
