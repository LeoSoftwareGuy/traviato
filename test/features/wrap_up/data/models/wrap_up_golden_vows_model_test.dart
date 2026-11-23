import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/data/models/wrap_up_golden_vows_model.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_golden_vows.dart';

Map<String, dynamic> _content([Map<String, dynamic> overrides = const {}]) => {
  'golden_vows': {
    'gv_version': 1,
    'occasion': 'wedding',
    'occasion_line': 'Our Wedding Day',
    'names': 'Anna & Marco',
    'start_date': '2026-06-14',
    'end_date': '2026-06-14',
    'day_count': 1,
    'place': 'Lake Bled',
    'packing': {
      'source': 'checklist',
      'items': [
        {'text': 'Rings', 'suggestion_code': null},
        {'text': 'Passport', 'suggestion_code': 'passport'},
      ],
      'checked': 2,
      'total': 9,
    },
    'heroes': [
      {
        'photo_id': 'p1',
        'label': 'The vows',
        'taken_at': '2026-06-14T13:10:00Z',
        'note': 'You cried before I did.',
      },
      {'photo_id': 'p2', 'label': 'First dance', 'taken_at': null},
    ],
    'chapters': [
      {
        'title': 'Getting ready',
        'line': 'Chapter one · Morning',
        'photo_ids': ['p3', 'p4', 'p5'],
        'layout': 'B',
      },
    ],
    'carousel': {
      'title': 'And the night went on',
      'line': 'Chapter two',
      'photo_ids': ['p6', 'p7'],
    },
    'heart_photo_ids': ['p1', 'p2', 'p3'],
    'moment_count': 240,
    'end_line': 'Forever starts here',
    ...overrides,
  },
};

void main() {
  test('reads a whole album', () {
    final gv = parseWrapUpGoldenVows(_content())!;
    expect(gv.occasion, 'wedding');
    expect(gv.occasionLine, 'Our Wedding Day');
    expect(gv.names, 'Anna & Marco');
    expect(gv.startDate, DateTime(2026, 6, 14));
    expect(gv.place, 'Lake Bled');
    expect(
      gv.packing,
      const WrapUpGoldenVowsPacking(
        items: [
          WrapUpGoldenVowsPackedItem('Rings'),
          WrapUpGoldenVowsPackedItem('Passport', suggestionCode: 'passport'),
        ],
        checked: 2,
        total: 9,
      ),
    );
    expect(gv.heroes.first.takenAt, DateTime.utc(2026, 6, 14, 13, 10));
    expect(gv.heroes.first.note, 'You cried before I did.');
    expect(gv.heroes.last.note, isNull);
    expect(gv.chapters.single.layout, 'B');
    expect(gv.carousel!.photoIds, ['p6', 'p7']);
    expect(gv.carousel!.layout, isNull);
    expect(gv.heartPhotoIds, ['p1', 'p2', 'p3']);
    expect(gv.momentCount, 240);
    expect(gv.endLine, 'Forever starts here');
  });

  test('none, another version, no name or nothing to show: null', () {
    expect(parseWrapUpGoldenVows(const {}), isNull);
    expect(parseWrapUpGoldenVows(_content({'gv_version': 2})), isNull);
    expect(parseWrapUpGoldenVows(_content({'names': ' '})), isNull);
    expect(
      parseWrapUpGoldenVows(_content({'heroes': [], 'chapters': 'x'})),
      isNull,
    );
  });

  test('malformed pieces are dropped, the rest kept', () {
    final gv = parseWrapUpGoldenVows(
      _content({
        'heroes': [
          {'label': 'No photo'},
          'junk',
          {'photo_id': 'p2', 'taken_at': 'not a date'},
        ],
        'chapters': [
          {'title': 'Empty', 'photo_ids': []},
          {
            'title': 'Odd layout',
            'photo_ids': ['p3'],
            'layout': 'D',
          },
        ],
        'packing': {
          'source': 'quests',
          'items': [
            {'text': ''},
            {'text': 'Ceremony'},
          ],
        },
        'carousel': null,
        'day_count': 0,
      }),
    )!;
    expect(gv.heroes.single.photoId, 'p2');
    expect(gv.heroes.single.takenAt, isNull);
    expect(gv.chapters.single.title, 'Odd layout');
    expect(gv.chapters.single.layout, isNull);
    expect(gv.packing!.isFromQuests, isTrue);
    expect(gv.packing!.items.single.text, 'Ceremony');
    expect(gv.packing!.checked, isNull);
    expect(gv.carousel, isNull);
    expect(gv.dayCount, 1);
  });

  test('chapter pages and the play order (#460)', () {
    final gv = parseWrapUpGoldenVows(
      _content({
        'heroes': [
          {'photo_id': 'h1', 'order': 1},
        ],
        'chapters': [
          {
            'title': 'Day one',
            'photo_ids': ['a', 'b', 'c', 'd'],
            'layout': 'B2',
            'pages': [
              {
                'photo_ids': ['a', 'b'],
                'layout': 'B2',
                'order': 0,
              },
              {
                'photo_ids': ['c', 'd'],
                'layout': 'B2',
                'order': 2,
              },
            ],
          },
          {
            // A page without its order: the chapter plays as one page.
            'title': 'Day two',
            'photo_ids': ['e', 'f', 'g'],
            'pages': [
              {
                'photo_ids': ['e', 'f', 'g'],
              },
            ],
          },
        ],
      }),
    )!;
    expect(gv.heroes.single.order, 1);
    expect(gv.chapters.first.layout, 'B2');
    expect(gv.chapters.first.pages, const [
      WrapUpGoldenVowsChapterPage(photoIds: ['a', 'b'], order: 0, layout: 'B2'),
      WrapUpGoldenVowsChapterPage(photoIds: ['c', 'd'], order: 2, layout: 'B2'),
    ]);
    expect(gv.chapters.last.pages, isEmpty);
  });
}
