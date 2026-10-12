import 'trip_images.dart';

/// One bundled cover choice in the New memory cover picker.
class CoverOption {
  const CoverOption({required this.id, required this.assetPath, this.vibe});

  /// A cover from `assets/images/covers/`, named after its [id] (#194).
  const CoverOption.bundled(this.id, {this.vibe})
    : assetPath = 'assets/images/covers/$id.jpg';

  /// Persisted as `trips.cover_image_path = 'asset:<id>'`
  /// (data-model.md's bundled-asset convention). Never rename one: existing
  /// memories store it.
  final String id;
  final String assetPath;

  /// The vibe this cover auto-suggests for, or null for a pick-only cover.
  /// Each of the 10 canonical vibes maps to exactly one cover.
  final String? vibe;
}

/// Every bundled cover, travel first, then occasions (#194). The first 8
/// are the original set (#40) and keep their ids and assets; since #194
/// each vibe suggests the new cover drawn for it instead.
const kCoverOptions = [
  CoverOption(id: 'hero', assetPath: 'assets/images/guest/hero.png'),
  CoverOption(
    id: 'honeymoon_escape',
    assetPath: 'assets/images/guest/honeymoon_escape.png',
  ),
  CoverOption(
    id: 'solo_getaway',
    assetPath: 'assets/images/guest/solo_getaway.jpg',
  ),
  CoverOption(
    id: 'family_adventure',
    assetPath: 'assets/images/guest/newYork.jpg',
  ),
  CoverOption(
    id: 'food_lovers_weekend',
    assetPath: 'assets/images/guest/food_lovers_weekend.png',
  ),
  CoverOption(
    id: 'bucket_list_moment',
    assetPath: 'assets/images/guest/dolomites.jpg',
  ),
  CoverOption(
    id: 'epic_milestone',
    assetPath: 'assets/images/guest/epic_milestone.png',
  ),
  CoverOption(id: 'new_memory', assetPath: TripImages.newMemory),
  CoverOption.bundled('maui'),
  CoverOption.bundled('cime_mountains', vibe: 'Adventure'),
  CoverOption.bundled('lago_di_braies'),
  CoverOption.bundled('lake_ice'),
  CoverOption.bundled('sunset_peaks'),
  CoverOption.bundled('summit_lookout'),
  CoverOption.bundled('forest_waterfall', vibe: 'Wildlife'),
  CoverOption.bundled('canoe'),
  CoverOption.bundled('a_frame_cabin'),
  CoverOption.bundled('rainy_cabin', vibe: 'Chill'),
  CoverOption.bundled('autumn_woods'),
  CoverOption.bundled('mountain_town'),
  CoverOption.bundled('picnic_on_the_edge'),
  CoverOption.bundled('road_trip', vibe: 'Road trip'),
  CoverOption.bundled('departure'),
  CoverOption.bundled('cultural', vibe: 'Cultural'),
  // Occasions — weddings, birthdays, nights out: not just travel.
  CoverOption.bundled('wedding'),
  CoverOption.bundled('birthday'),
  CoverOption.bundled('rooftop_gathering'),
  CoverOption.bundled('cozy_restaurant'),
  CoverOption.bundled('romantic', vibe: 'Romantic'),
  CoverOption.bundled('foodie', vibe: 'Foodie'),
  CoverOption.bundled('nightlife', vibe: 'Nightlife'),
  CoverOption.bundled('wellness', vibe: 'Wellness'),
  CoverOption.bundled('photography', vibe: 'Photography'),
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
