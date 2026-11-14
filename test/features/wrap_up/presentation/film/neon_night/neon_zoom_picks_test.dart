import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_zoom_picks.dart';

void main() {
  test('every long card zooms three times, however few tiles', () {
    for (var chapter = 1; chapter <= 5; chapter++) {
      for (var tiles = 1; tiles <= 34; tiles++) {
        final picks = NeonZoomPicks.pick(chapterNumber: chapter, tiles: tiles);
        expect(picks, hasLength(3), reason: 'ch $chapter, $tiles tiles');
        expect(picks.every((i) => i >= 0 && i < tiles), isTrue);
      }
    }
  });

  test('3+ tiles: three different tiles', () {
    for (var tiles = 3; tiles <= 34; tiles++) {
      final picks = NeonZoomPicks.pick(chapterNumber: 3, tiles: tiles);
      expect(picks.toSet(), hasLength(3), reason: '$tiles tiles');
    }
  });

  test('2 tiles alternate; 1 tile is zoomed three times', () {
    final two = NeonZoomPicks.pick(chapterNumber: 1, tiles: 2);
    expect(two[0], isNot(two[1]));
    expect(two[1], isNot(two[2]));
    expect(NeonZoomPicks.pick(chapterNumber: 1, tiles: 1), [0, 0, 0]);
  });

  test('the same chapter and tiles give the same picks', () {
    expect(
      NeonZoomPicks.pick(chapterNumber: 2, tiles: 10),
      NeonZoomPicks.pick(chapterNumber: 2, tiles: 10),
    );
  });
}
