import '../../../../core/l10n/context_l10n.dart';

/// The UI label for a vibe. Vibes are stored in `trips.vibes` by their
/// canonical English name (see [kTripVibes]); only the label is translated
/// (#220). An unknown value (e.g. a vibe dropped from the list) is shown
/// as stored.
String vibeLabel(AppLocalizations l10n, String vibe) => switch (vibe) {
  'Romantic' => l10n.vibe_romantic,
  'Adventure' => l10n.vibe_adventure,
  'Cultural' => l10n.vibe_cultural,
  'Chill' => l10n.vibe_chill,
  'Foodie' => l10n.vibe_foodie,
  'Road trip' => l10n.vibe_roadTrip,
  'Wellness' => l10n.vibe_wellness,
  'Wildlife' => l10n.vibe_wildlife,
  'Nightlife' => l10n.vibe_nightlife,
  'Photography' => l10n.vibe_photography,
  _ => vibe,
};
