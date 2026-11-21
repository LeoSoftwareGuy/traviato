import 'golden_vows/golden_vows_scene_spec.dart';
import 'golden_vows/golden_vows_story.dart';
import 'golden_vows/golden_vows_timeline.dart';
import 'neon_night/neon_night_canvas.dart';
import 'neon_night/neon_night_scene_spec.dart';
import 'neon_night/neon_night_story.dart';
import 'neon_night/neon_track.dart';
import 'sky_story/sky_scene_spec.dart';
import 'sky_story/sky_story.dart';
import 'sky_story/sky_story_timeline.dart';

/// A film as it plays, as a Markdown table (#442): one row per scene with
/// its start, length, photos and words, from the same story and timeline
/// the player uses. The Plan inspector copies it, so the user can edit it
/// into a reference storyboard for the film.
abstract final class FilmStoryboard {
  /// Neon Night, on its music's clock.
  static String neonNight(NeonNightStory story, {required String memory}) {
    final timeline = NeonNightCanvas.timelineFor(story, beat: NeonTrack.beat);
    final momentIndex = <int, int>{};
    final rows = <_Row>[
      for (final scene in timeline.scenes)
        switch (scene.spec) {
          NnIgnitionSpec() => _Row(scene.start, scene.duration, 'Ignition'),
          NnPlanSpec() => _Row(
            scene.start,
            scene.duration,
            'Plan',
            words: [
              for (final row in story.plan)
                '${row.time} ${row.item}${row.done ? ' ✓' : ''}',
            ],
          ),
          NnChapterCardSpec(:final chapter, :final zooms) => () {
            final c = story.chapters[chapter];
            return _Row(
              scene.start,
              scene.duration,
              'Ch ${chapter + 1} card · ${c.title} · ${c.from}–${c.to}'
              '${zooms > 0 ? ' · $zooms zoom${zooms == 1 ? '' : 's'}' : ''}',
              photos: [for (final p in c.cardPhotos) _nn(p)],
              words: [?c.note],
            );
          }(),
          NnMomentSpec(:final chapter, :final type) => () {
            final k = momentIndex[chapter] = (momentIndex[chapter] ?? -1) + 1;
            final moments = story.chapters[chapter].moments;
            final moment = k < moments.length ? moments[k] : null;
            return _Row(
              scene.start,
              scene.duration,
              'Ch ${chapter + 1} · ${type.name}',
              photos: [for (final p in moment?.photos ?? const []) _nn(p)],
              words: [
                for (final p in moment?.photos ?? const <NnPhoto>[])
                  ?(p.line ?? p.caption),
              ],
            );
          }(),
          NnNoteSpec() => _Row(
            scene.start,
            scene.duration,
            'Note',
            photos: [if (story.note?.photo case final p?) _nn(p)],
            words: [?story.note?.text],
          ),
          NnFinaleSpec() => _Row(
            scene.start,
            scene.duration,
            'Finale · heart of ${story.heartIds.length}',
            words: [?story.headline],
          ),
          NnEndingSpec() => _Row(scene.start, scene.duration, 'Ending'),
        },
    ];
    return _table(
      memory: memory,
      film: 'Neon Night',
      total: timeline.total,
      target: story.targetSeconds,
      rows: rows,
    );
  }

  /// Sky Story.
  static String skyStory(SkyStory story, {required String memory}) {
    final timeline = SkyStoryTimeline.forStory(story);
    final rows = <_Row>[
      for (final scene in timeline.scenes)
        switch (scene.spec) {
          SkyOpeningSpec() => _Row(
            scene.start,
            scene.duration,
            'Opening',
            words: [story.title],
          ),
          SkyInterludeSpec() => _Row(scene.start, scene.duration, 'Interlude'),
          SkyChapterSpec(:final index) => () {
            final page = story.pages[index];
            final days = page.lastDay == null || page.lastDay == page.firstDay
                ? 'day ${page.firstDay}'
                : 'days ${page.firstDay}–${page.lastDay}';
            return _Row(
              scene.start,
              scene.duration,
              'Page ${index + 1} · $days · ${story.layouts[index].name}',
              photos: [
                '${_sky(page.hero)} (hero)',
                for (final p in page.extras) _sky(p),
              ],
              words: [
                ?page.headline,
                if (page.noteLines.isNotEmpty)
                  ...page.noteLines
                else
                  ?(page.note ?? page.skyLine),
                ?page.hero.caption,
              ],
            );
          }(),
          SkyGatherSpec() => _Row(
            scene.start,
            scene.duration,
            'Gather · mosaic of ${story.mosaicPhotoIds.length}',
          ),
          SkyOutroSpec() => _Row(scene.start, scene.duration, 'Outro'),
        },
    ];
    return _table(
      memory: memory,
      film: 'Sky Story',
      total: timeline.total,
      target: story.targetSeconds,
      rows: rows,
    );
  }

  /// Golden Vows. [takenAt] gives each photo's time, for the rows.
  static String goldenVows(
    GoldenVowsStory story, {
    required String memory,
    Map<String, DateTime> takenAt = const {},
  }) {
    final timeline = GoldenVowsTimeline.forStory(story);
    String photo(String id) => _labelled(takenAt[id], id);
    final rows = <_Row>[
      for (final scene in timeline.film.scenes)
        switch (scene.spec) {
          GvInvitationSpec() => _Row(
            scene.start,
            scene.duration,
            'Invitation',
            words: [?story.occasionLine, story.names],
          ),
          GvPackingCardSpec() => _Row(
            scene.start,
            scene.duration,
            'Packing card',
            words: story.packed,
          ),
          GvAlbumOpenSpec() => _Row(scene.start, scene.duration, 'Album opens'),
          GvPageSpec(:final kind, :final index) => switch (kind) {
            GvPageKind.hero => _Row(
              scene.start,
              scene.duration,
              'Hero ${index + 1}',
              photos: [photo(story.heroes[index].photoId)],
              words: [
                ?story.heroes[index].caption,
                ?story.heroes[index].note,
              ],
            ),
            GvPageKind.chapter => _Row(
              scene.start,
              scene.duration,
              'Chapter ${index + 1} · ${story.chapters[index].title}',
              photos: [
                for (final id in story.chapters[index].photoIds.take(
                  GoldenVowsStory.maxChapterPhotos,
                ))
                  photo(id),
              ],
              words: [?story.chapters[index].line],
            ),
            GvPageKind.carousel => _Row(
              scene.start,
              scene.duration,
              'Carousel',
              photos: [
                for (final id
                    in story.carousel?.photoIds.take(
                          GoldenVowsStory.maxCarouselPhotos,
                        ) ??
                        const <String>[])
                  photo(id),
              ],
              words: [?story.carousel?.title],
            ),
            GvPageKind.heart => _Row(
              scene.start,
              scene.duration,
              'Heart of ${story.heartPhotos.length}',
            ),
          },
          GvAlbumCloseSpec() => _Row(
            scene.start,
            scene.duration,
            'Album closes',
          ),
          GvEndingSpec() => _Row(
            scene.start,
            scene.duration,
            'Ending',
            words: [?story.endLine],
          ),
        },
    ];
    return _table(
      memory: memory,
      film: 'Golden Vows',
      total: timeline.total,
      target: story.targetSeconds,
      rows: rows,
    );
  }

  static String _nn(NnPhoto photo) => '${photo.takenAt} #${_short(photo.id)}';

  static String _sky(SkyPhoto photo) => _labelled(photo.takenAt, photo.id);

  static String _labelled(DateTime? at, String id) => at == null
      ? '#${_short(id)}'
      : '${_two(at.hour)}:${_two(at.minute)} #${_short(id)}';

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// Enough of a photo's id to tell it apart in one memory.
  static String _short(String id) => id.length <= 6 ? id : id.substring(0, 6);

  static String _table({
    required String memory,
    required String film,
    required double total,
    required double? target,
    required List<_Row> rows,
  }) {
    final buffer = StringBuffer()
      ..writeln('# $memory · $film')
      ..writeln(
        'Length ${total.toStringAsFixed(1)} s'
        '${target == null ? '' : ' · target ${target.toStringAsFixed(1)} s'}'
        ' · ${rows.length} scenes',
      )
      ..writeln()
      ..writeln('| # | at | length | scene | photos | words |')
      ..writeln('|---|---|---|---|---|---|');
    for (final (i, row) in rows.indexed) {
      buffer.writeln(
        '| ${i + 1} | ${row.start.toStringAsFixed(1)} s '
        '| ${row.length.toStringAsFixed(1)} s | ${_cell(row.scene)} '
        '| ${row.photos.isEmpty ? '—' : '${row.photos.length}: ${row.photos.map(_cell).join(', ')}'} '
        '| ${row.words.isEmpty ? '—' : row.words.map((w) => '“${_cell(w)}”').join(' / ')} |',
      );
    }
    return buffer.toString();
  }

  /// [text] fit for one table cell.
  static String _cell(String text) =>
      text.replaceAll('|', '/').replaceAll(RegExp(r'\s+'), ' ').trim();
}

class _Row {
  const _Row(
    this.start,
    this.length,
    this.scene, {
    this.photos = const [],
    this.words = const [],
  });

  final double start;
  final double length;
  final String scene;
  final List<String> photos;
  final List<String> words;
}
