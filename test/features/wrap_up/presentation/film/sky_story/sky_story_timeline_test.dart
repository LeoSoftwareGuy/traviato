import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_scene_spec.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_story.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_story_timeline.dart';

SkyStory _story(List<int> extrasPerPage) => SkyStory(
  title: 'Memory',
  startDate: DateTime(2026, 6, 1),
  endDate: DateTime(2026, 6, 10),
  pages: [
    for (final (i, extras) in extrasPerPage.indexed)
      SkyPage(
        firstDay: i + 1,
        date: DateTime(2026, 6, 1 + i),
        photoCount: extras + 1,
        hero: SkyPhoto(id: 'h$i'),
        extras: [for (var k = 0; k < extras; k++) SkyPhoto(id: 'e$i$k')],
      ),
  ],
);

List<SkyPageLayout> _specLayouts(SkyStory story) => [
  for (final scene in SkyStoryTimeline.forStory(story).scenes)
    if (scene.spec case final SkyChapterSpec chapter) chapter.layout,
];

void main() {
  test('every page count lands within 40–75 s, one page aside', () {
    expect(
      [
        for (var n = 1; n <= SkyStoryTimeline.maxChapters; n++)
          SkyStoryTimeline.forChapters(n).total,
      ],
      [32.5, 41.5, 54.0, 66.5, 75.0],
    );
  });

  test('the 3-page reference keeps its boundaries', () {
    final ends = [
      for (final scene in SkyStoryTimeline.forChapters(3).scenes) scene.end,
    ];
    expect(ends, [5, 7, 16.5, 19.5, 29, 31.5, 43, 46, 54]);
  });

  test('a taped page with too few photos to fill its grid is a fan', () {
    expect(SkyPageLayout.forPage(1, 3, extras: 4), SkyPageLayout.taped);
    expect(SkyPageLayout.forPage(1, 3, extras: 2), SkyPageLayout.taped);
    expect(SkyPageLayout.forPage(1, 3, extras: 1), SkyPageLayout.fan);
    expect(SkyPageLayout.forPage(2, 3, extras: 0), SkyPageLayout.flyOut);
  });

  test('the timeline plays each page in its own layout', () {
    expect(_specLayouts(_story([3, 4, 3])), [
      SkyPageLayout.fan,
      SkyPageLayout.taped,
      SkyPageLayout.flyOut,
    ]);
    // Page 2 has one photo besides its hero: a fan, not taped.
    final sparse = _story([3, 1, 3, 2, 0]);
    expect(sparse.layouts, [
      SkyPageLayout.fan,
      SkyPageLayout.fan,
      SkyPageLayout.fan,
      SkyPageLayout.taped,
      SkyPageLayout.flyOut,
    ]);
    expect(_specLayouts(sparse), sparse.layouts);
  });
}
