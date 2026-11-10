@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_story_canvas.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_story_timeline.dart';

// The Sky Story world (#345, phase 1) at the reference stills' instants
// (docs/design/sky-story/ref-*.png), on the reference's 3-chapter
// timeline. Made on Windows and skipped elsewhere, like the classic
// film's goldens. Regenerate with
// `flutter test --update-goldens --tags golden`.
final bool _skip = !Platform.isWindows;

void main() {
  testWidgets('the world at the reference instants', skip: _skip, (
    tester,
  ) async {
    tester.view.physicalSize = const Size(540, 960);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      SkyStoryCanvas(timeline: SkyStoryTimeline.forChapters(3)),
    );
    var elapsed = 0.0;
    for (final (name, at) in [
      ('00', 0.5),
      ('03', 3.0),
      ('06', 6.0),
      ('18', 18.0),
      ('30', 30.0),
      ('45', 45.0),
      ('54', 53.8),
    ]) {
      await tester.pump(
        Duration(milliseconds: ((at - elapsed) * 1000).round()),
      );
      elapsed = at;
      await expectLater(
        find.byType(SkyStoryCanvas),
        matchesGoldenFile('goldens/world_$name.png'),
      );
    }
  });
}
