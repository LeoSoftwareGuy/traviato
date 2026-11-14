import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_zoom_picks.dart';

void main() {
  test('every long card zooms, each tile at most once', () {
    for (var chapter = 1; chapter <= 5; chapter++) {
      for (var tiles = 1; tiles <= 34; tiles++) {
        final picks = NeonZoomPicks.pick(chapterNumber: chapter, tiles: tiles);
        final reason = 'ch $chapter, $tiles tiles';
        expect(picks, hasLength(tiles < 3 ? tiles : 3), reason: reason);
        expect(picks.toSet(), hasLength(picks.length), reason: reason);
        expect(picks.every((i) => i >= 0 && i < tiles), isTrue);
      }
    }
  });

  test('1 tile: one zoom; 2 tiles: both, once each', () {
    expect(NeonZoomPicks.pick(chapterNumber: 1, tiles: 1), [0]);
    expect(
      NeonZoomPicks.pick(chapterNumber: 1, tiles: 2).toSet(),
      {0, 1},
    );
  });

  test('the same chapter and tiles give the same picks', () {
    expect(
      NeonZoomPicks.pick(chapterNumber: 2, tiles: 10),
      NeonZoomPicks.pick(chapterNumber: 2, tiles: 10),
    );
  });

  test('countFor: one zoom per photo, at most 3', () {
    expect(
      [for (var n = 1; n <= 5; n++) NeonZoomPicks.countFor(n)],
      [
        1,
        2,
        3,
        3,
        3,
      ],
    );
  });
}
