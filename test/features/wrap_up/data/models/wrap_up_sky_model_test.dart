import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/data/models/wrap_up_model.dart';
import 'package:traviato/features/wrap_up/data/models/wrap_up_sky_model.dart';

Map<String, dynamic> _page({
  int firstDay = 1,
  Object? lastDay,
  Object? heroPhotoId = 'p1',
  Object? date = '2026-06-12',
  List<Object?> extras = const ['p2', 'p3'],
}) => {
  'first_day': firstDay,
  'last_day': lastDay,
  'date': date,
  'end_date': lastDay == null ? null : '2026-06-15',
  'photo_count': 64,
  'headline': 'Lost, on purpose',
  'hero_photo_id': heroPhotoId,
  'extra_photo_ids': extras,
  'note_id': 'n1',
  'note': 'Took the 28 tram the wrong way, twice.',
  'sky_line': null,
};

Map<String, dynamic> _content({
  Object? version = 1,
  Object? pages,
  Object? source = 'director',
}) => {
  'sky': {
    'sky_version': version,
    'source': source,
    'title': 'Lisbon, together',
    'first_name': 'Jonas',
    'moment_count': 187,
    'mosaic_photo_ids': ['p1', 'p2', 3, ''],
    'pages': pages ?? [_page()],
  },
};

void main() {
  group('parseWrapUpSky', () {
    test('reads a whole content.sky', () {
      final sky = parseWrapUpSky(_content())!;
      expect(sky.isFromDirector, isTrue);
      expect(sky.title, 'Lisbon, together');
      expect(sky.firstName, 'Jonas');
      expect(sky.momentCount, 187);
      expect(sky.mosaicPhotoIds, ['p1', 'p2']);
      final page = sky.pages.single;
      expect(page.firstDay, 1);
      expect(page.lastDay, isNull);
      expect(page.date, DateTime(2026, 6, 12));
      expect(page.photoCount, 64);
      expect(page.headline, 'Lost, on purpose');
      expect(page.heroPhotoId, 'p1');
      expect(page.extraPhotoIds, ['p2', 'p3']);
      expect(page.noteId, 'n1');
      expect(page.note, startsWith('Took the 28 tram'));
      expect(page.skyLine, isNull);
    });

    test('code-built pages and day ranges', () {
      final sky = parseWrapUpSky(
        _content(
          source: 'code',
          pages: [_page(firstDay: 4, lastDay: 7)],
        ),
      )!;
      expect(sky.isFromDirector, isFalse);
      expect(sky.pages.single.lastDay, 7);
      expect(sky.pages.single.endDate, DateTime(2026, 6, 15));
    });

    test('null without a sky, another version or no whole page', () {
      expect(parseWrapUpSky(const {}), isNull);
      expect(parseWrapUpSky(_content(version: 2)), isNull);
      expect(parseWrapUpSky(_content(pages: const [])), isNull);
      expect(parseWrapUpSky(_content(pages: 'nope')), isNull);
      expect(
        parseWrapUpSky(_content(pages: [_page(heroPhotoId: null)])),
        isNull,
      );
    });

    test('drops malformed pages, keeps at most five, cleans ids', () {
      final sky = parseWrapUpSky(
        _content(
          pages: [
            _page(date: 'not a date'),
            for (var d = 1; d <= 6; d++)
              _page(firstDay: d, extras: ['p1', 'p2', 7, '']),
            'not a page',
          ],
        ),
      )!;
      expect(sky.pages, hasLength(maxSkyPages));
      expect(sky.pages.first.firstDay, 1);
      // The hero is never among its own extras.
      expect(sky.pages.first.extraPhotoIds, ['p2']);
    });

    test('a range ending on its first day reads as one day', () {
      final sky = parseWrapUpSky(
        _content(pages: [_page(firstDay: 3, lastDay: 3)]),
      )!;
      expect(sky.pages.single.lastDay, isNull);
    });
  });

  test('WrapUpModel carries content.sky', () {
    final model = WrapUpModel.fromRow({
      'content': _content(),
      'generated_at': '2026-11-12T10:00:00Z',
    });
    expect(model.sky?.pages, hasLength(1));
    expect(
      WrapUpModel.fromRow({
        'content': const <String, dynamic>{},
        'generated_at': '2026-11-12T10:00:00Z',
      }).sky,
      isNull,
    );
  });
}
