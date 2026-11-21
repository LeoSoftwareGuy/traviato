import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/film_storyboard.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_story.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_timeline.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_canvas.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_story.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_track.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_story_fixture.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_story_timeline.dart';

/// The table's scene rows (after the header and the two table lines).
List<String> _rows(String table) =>
    table.split('\n').where((l) => RegExp(r'^\| \d+ \|').hasMatch(l)).toList();

String _short(String id) => id.length <= 6 ? id : id.substring(0, 6);

const _photos = [
  NnPhoto(id: 'photo-1', takenAt: '22:00'),
  NnPhoto(id: 'photo-2', takenAt: '22:10'),
];

void main() {
  test('Neon Night: one row per scene, its photos in play order (#442)', () {
    final story = NeonNightFixtures.reference;
    final table = FilmStoryboard.neonNight(story, memory: 'Night out');
    final timeline = NeonNightCanvas.timelineFor(story, beat: NeonTrack.beat);

    expect(table, startsWith('# Night out · Neon Night\n'));
    expect(table, contains('Length ${timeline.total.toStringAsFixed(1)} s'));
    final rows = _rows(table);
    expect(rows, hasLength(timeline.scenes.length));
    expect(rows.first, contains('Ignition'));
    expect(rows.last, contains('Ending'));

    final chapter = story.chapters.first;
    final card = rows.firstWhere((r) => r.contains('Ch 1 card'));
    expect(card, contains('${chapter.cardPhotos.length}: '));
    expect(
      card,
      contains(
        '${chapter.cardPhotos.first.takenAt} '
        '#${_short(chapter.cardPhotos.first.id)}',
      ),
    );
    final moment = chapter.moments.first;
    final momentRow = rows.firstWhere((r) => r.contains('Ch 1 · '));
    expect(momentRow, contains('${moment.photos.length}: '));
  });

  test('Sky Story: a row per page with its hero, extras and words', () {
    final story = SkyStoryFixtures.lisbon;
    final table = FilmStoryboard.skyStory(story, memory: story.title);
    final rows = _rows(table);

    expect(rows, hasLength(SkyStoryTimeline.forStory(story).scenes.length));
    final pages = rows.where((r) => r.contains('| Page ')).toList();
    expect(pages, hasLength(story.pages.length));
    expect(pages.first, contains('(hero)'));
    expect(
      pages.first,
      contains('${1 + story.pages.first.extras.length}: '),
    );
  });

  test(
    'Golden Vows: hero pages with their notes, photo times from the map',
    () {
      final story = GoldenVowsFixtures.wedding;
      final hero = story.heroes.first;
      final table = FilmStoryboard.goldenVows(
        story,
        memory: story.names,
        takenAt: {hero.photoId: DateTime(2026, 6, 12, 14, 5)},
      );
      final rows = _rows(table);

      expect(
        rows,
        hasLength(GoldenVowsTimeline.forStory(story).film.scenes.length),
      );
      final heroRow = rows.firstWhere((r) => r.contains('| Hero 1 |'));
      expect(heroRow, contains('14:05 #'));
      if (hero.note case final note?) expect(heroRow, contains(note.trim()));
      expect(rows.last, contains('Ending'));
    },
  );

  test('a pipe or a line break in the words never breaks the table', () {
    final story = NeonNightStory(
      title: 'A | B',
      date: DateTime(2026, 10, 24),
      chapters: [
        NnChapter(
          title: 'One\nTwo',
          from: '22:00',
          to: '23:00',
          photos: _photos,
          note: 'left | right',
          moments: [
            NnTimeline(_photos),
          ],
        ),
      ],
    );
    final table = FilmStoryboard.neonNight(story, memory: story.title);
    for (final row in _rows(table)) {
      expect('|'.allMatches(row).length, 7, reason: row);
    }
    expect(table, contains('One Two'));
  });
}
