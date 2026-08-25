import 'trip_images.dart';

/// One bundled cover choice in the New memory cover picker.
class CoverOption {
  const CoverOption({
    required this.id,
    required this.assetPath,
    required this.vibe,
  });

  /// Persisted as `trips.cover_image_path = 'asset:<id>'`
  /// (data-model.md's bundled-asset convention).
  final String id;
  final String assetPath;

  /// The vibe this cover auto-suggests for, per the New memory spec.
  final String vibe;
}

/// The 8 bundled covers. Picked for visual variety across our own asset
/// library (not the handoff's sample images) and mapped to whichever of
/// our 10 canonical vibes each one actually reads as — see the plan
/// comment on issue #40 for how each was chosen. Chill and Nightlife have
/// no direct cover and fall back to the first option.
const kCoverOptions = [
  CoverOption(
    id: 'hero',
    assetPath: 'assets/images/guest/hero.png',
    vibe: 'Wellness',
  ),
  CoverOption(
    id: 'honeymoon_escape',
    assetPath: 'assets/images/guest/honeymoon_escape.png',
    vibe: 'Romantic',
  ),
  CoverOption(
    id: 'solo_getaway',
    assetPath: 'assets/images/guest/solo_getaway.png',
    vibe: 'Cultural',
  ),
  CoverOption(
    id: 'family_adventure',
    assetPath: 'assets/images/guest/family_adventure.png',
    vibe: 'Photography',
  ),
  CoverOption(
    id: 'food_lovers_weekend',
    assetPath: 'assets/images/guest/food_lovers_weekend.png',
    vibe: 'Foodie',
  ),
  CoverOption(
    id: 'bucket_list_moment',
    assetPath: 'assets/images/guest/bucket_list_moment.png',
    vibe: 'Wildlife',
  ),
  CoverOption(
    id: 'epic_milestone',
    assetPath: 'assets/images/guest/epic_milestone.png',
    vibe: 'Adventure',
  ),
  CoverOption(
    id: 'new_memory',
    assetPath: TripImages.newMemory,
    vibe: 'Road trip',
  ),
];

const _assetPrefix = 'asset:';

/// `'asset:<id>'` for persisting as `trips.cover_image_path`.
String assetCoverImagePath(String coverId) => '$_assetPrefix$coverId';

/// Resolves a stored `cover_image_path` to its bundled asset path, or null
/// if it isn't an `asset:` reference (a real upload path, once that ships)
/// or the id isn't one of [kCoverOptions].
String? resolveAssetCoverPath(String? coverImagePath) {
  final id = coverIdFromPath(coverImagePath);
  if (id == null) return null;
  for (final option in kCoverOptions) {
    if (option.id == id) return option.assetPath;
  }
  return null;
}

/// The bare id out of a stored `'asset:<id>'` path — null for a non-asset
/// path or null input. Used to mark the current selection in a thumbnail
/// strip.
String? coverIdFromPath(String? coverImagePath) {
  if (coverImagePath == null || !coverImagePath.startsWith(_assetPrefix)) {
    return null;
  }
  return coverImagePath.substring(_assetPrefix.length);
}

/// Auto-selection rule: the first cover option whose vibe is among
/// [selectedVibes], else the first option.
CoverOption suggestedCover(Set<String> selectedVibes) {
  for (final option in kCoverOptions) {
    if (selectedVibes.contains(option.vibe)) return option;
  }
  return kCoverOptions.first;
}
