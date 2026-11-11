import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_mosaic.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_scene_spec.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_story_timeline.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_world.dart';

void main() {
  final mosaic = SkyMosaic(gatherStart: 43, photoCount: 12);
  final envelope = [
    for (final tile in mosaic.tiles)
      if (tile.tint != SkyTileTint.basket) tile,
  ];

  group('layout (the reference at 50 s)', () {
    test('250 envelope tiles in the box, 8 basket tiles', () {
      expect(envelope, hasLength(250));
      expect(
        mosaic.tiles.where((t) => t.tint == SkyTileTint.basket),
        hasLength(8),
      );
      for (final tile in envelope) {
        expect(tile.home.dx - tile.size / 2, greaterThanOrEqualTo(222));
        expect(tile.home.dx + tile.size / 2, lessThanOrEqualTo(858));
        expect(tile.home.dy - tile.size / 2, greaterThanOrEqualTo(320));
        expect(tile.home.dy + tile.size / 2, lessThanOrEqualTo(1156));
      }
      expect(SkyMosaic.grid.every((row) => row.length == 16), isTrue);
      expect(SkyMosaic.grid, hasLength(21));
    });

    test('symmetric about the middle, tint and all', () {
      final byHome = {for (final t in envelope) t.home: t.tint};
      for (final tile in envelope) {
        final mirror = Offset(1080 - tile.home.dx, tile.home.dy);
        expect(byHome[mirror], tile.tint, reason: '${tile.home}');
      }
    });

    test('red and cream gores alternate across the widest row', () {
      expect(SkyMosaic.grid[8], 'RRccRRRccRRRccRR');
      final cream = envelope.where((t) => t.tint == SkyTileTint.cream).length;
      expect(cream / envelope.length, inInclusiveRange(0.35, 0.5));
    });
  });

  group('choreography', () {
    test('nothing before gather + 0.7; everything locked by + 3.5', () {
      for (final tile in mosaic.tiles) {
        expect(tile.start, greaterThanOrEqualTo(43.7));
        expect(tile.at(tile.start - 0.01), isNull);
        expect(tile.lockedAt, lessThanOrEqualTo(46.5 + 1e-9));
        final locked = tile.at(46.5)!;
        expect(locked.center, tile.home);
        expect(locked.angle, 0);
        expect(locked.opacity, 1);
      }
      expect(mosaic.lockedAt, closeTo(46.5, 1e-9));
    });

    test('built bottom-up: the basket first, the crown last', () {
      double meanStart(Iterable<SkyMosaicTile> tiles) =>
          tiles.map((t) => t.start).reduce((a, b) => a + b) / tiles.length;
      final basket = mosaic.tiles.where((t) => t.tint == SkyTileTint.basket);
      final bottom = envelope.where((t) => t.home.dy > 1100);
      final crown = envelope.where((t) => t.home.dy < 380);
      expect(meanStart(basket), lessThan(meanStart(bottom)));
      expect(meanStart(bottom) + 1, lessThan(meanStart(crown)));
    });

    test('tiles come from below the frame and never jump', () {
      for (final tile in mosaic.tiles) {
        expect(tile.at(tile.start)!.center.dy, greaterThan(1920));
        var previous = tile.at(tile.start)!.center;
        for (var t = tile.start; t <= tile.lockedAt + 0.1; t += 1 / 60) {
          final now = tile.at(t)!.center;
          expect((now - previous).distance, lessThan(60), reason: 't=$t');
          previous = now;
        }
      }
    });

    test('deterministic: the same film every time', () {
      final again = SkyMosaic(gatherStart: 43, photoCount: 12);
      for (final (i, tile) in mosaic.tiles.indexed) {
        expect(again.tiles[i].start, tile.start);
        expect(again.tiles[i].from, tile.from);
        expect(again.tiles[i].photo, tile.photo);
      }
    });

    test('every film length: locked by its gather + 3.5', () {
      for (var n = 1; n <= SkyStoryTimeline.maxChapters; n++) {
        final timeline = SkyStoryTimeline.forChapters(n);
        final gather = timeline.first<SkyGatherSpec>()!.start;
        final outro = timeline.first<SkyOutroSpec>()!;
        final m = SkyMosaic(gatherStart: gather, photoCount: 3);
        expect(m.lockedAt, closeTo(gather + 3.5, 1e-9));
        // The words have all arrived well before the film ends.
        expect(
          gather + SkyMosaic.brandAt + 0.6,
          lessThan(outro.end - 2),
          reason: 'n=$n',
        );
      }
    });

    test('the glow comes up with the basket', () {
      expect(mosaic.glowAt(43), 0);
      expect(mosaic.glowAt(44.5), 0);
      expect(mosaic.glowAt(46), 1);
    });
  });

  group('photos on the tiles', () {
    test('no photos: every tile is a placeholder', () {
      final m = SkyMosaic(gatherStart: 43, photoCount: 0);
      expect(m.tiles.every((t) => t.photo == -1), isTrue);
    });

    test('one photo fills every tile', () {
      final m = SkyMosaic(gatherStart: 43, photoCount: 1);
      expect(m.tiles.every((t) => t.photo == 0), isTrue);
    });

    test('every photo is used, and neighbours differ where they can', () {
      for (final count in [3, 12, 60]) {
        final m = SkyMosaic(gatherStart: 43, photoCount: count);
        expect({for (final t in m.tiles) t.photo}, hasLength(count));
        final byHome = {
          for (final t in m.tiles)
            if (t.tint != SkyTileTint.basket) t.home: t.photo,
        };
        for (final MapEntry(key: home, value: photo) in byHome.entries) {
          for (final d in const [Offset(40, 0), Offset(0, 40)]) {
            final other = byHome[home + d];
            if (other != null) {
              expect(other, isNot(photo), reason: 'count=$count at $home');
            }
          }
        }
      }
    });
  });

  test('the balloon has flown off before the first tiles', () {
    final world = SkyWorld(SkyStoryTimeline.forChapters(3));
    expect(world.balloon.at(43.9), isNull);
    expect(world.balloon.at(42.6), isNotNull);
  });
}
