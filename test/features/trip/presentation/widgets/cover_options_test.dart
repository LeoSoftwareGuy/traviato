import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/trip/presentation/widgets/cover_options.dart';
import 'package:traviato/features/trip/presentation/widgets/vibe_chip_group.dart';

void main() {
  group('kCoverOptions', () {
    test('has unique ids', () {
      final ids = kCoverOptions.map((o) => o.id);
      expect(ids.toSet(), hasLength(kCoverOptions.length));
    });

    test('keeps the original 8 ids that existing memories store', () {
      expect(
        kCoverOptions.map((o) => o.id),
        containsAll(const [
          'hero',
          'honeymoon_escape',
          'solo_getaway',
          'family_adventure',
          'food_lovers_weekend',
          'bucket_list_moment',
          'epic_milestone',
          'new_memory',
        ]),
      );
    });

    test('includes occasion covers beyond travel', () {
      expect(
        kCoverOptions.map((o) => o.id),
        containsAll(const ['wedding', 'birthday', 'rooftop_gathering']),
      );
    });

    test('maps each canonical vibe to exactly one cover', () {
      final vibes = kCoverOptions.map((o) => o.vibe).nonNulls.toList();
      expect(vibes.toSet(), hasLength(vibes.length));
      expect(vibes.toSet(), kTripVibes.toSet());
    });

    test('every asset path is bundled', () {
      for (final option in kCoverOptions) {
        expect(
          File(option.assetPath).existsSync(),
          isTrue,
          reason: option.assetPath,
        );
      }
    });
  });

  group('suggestedCover', () {
    test('returns the option whose vibe matches the selected vibe', () {
      expect(suggestedCover({'Romantic'}).id, 'romantic');
      expect(suggestedCover({'Nightlife'}).id, 'nightlife');
      expect(suggestedCover({'Chill'}).id, 'autumn_woods');
    });

    test('returns the first matching option in list order when multiple '
        'vibes are selected', () {
      // 'Road trip' (a travel cover) comes before 'Romantic' (an occasion
      // cover) in kCoverOptions, so it wins.
      expect(suggestedCover({'Romantic', 'Road trip'}).id, 'departure');
    });

    test('falls back to the first option when no vibe matches', () {
      final result = suggestedCover({'Not a vibe'});
      expect(result.id, kCoverOptions.first.id);
    });

    test('falls back to the first option when no vibes are selected', () {
      final result = suggestedCover(const {});
      expect(result.id, kCoverOptions.first.id);
    });
  });

  group('assetCoverImagePath / resolveAssetCoverPath', () {
    test('round-trips a cover id through the asset: prefix', () {
      final path = assetCoverImagePath('hero');
      expect(path, 'asset:hero');
      expect(resolveAssetCoverPath(path), kCoverOptions.first.assetPath);
    });

    test('returns null for a non-asset path (a real upload URL)', () {
      expect(
        resolveAssetCoverPath('https://example.com/photo.jpg'),
        isNull,
      );
    });

    test('returns null for null', () {
      expect(resolveAssetCoverPath(null), isNull);
    });

    test('returns null for an unrecognized asset id', () {
      expect(resolveAssetCoverPath('asset:not-a-real-id'), isNull);
    });
  });
}
