import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../settings/presentation/controllers/reduce_flashing_controller.dart';

import '../film/neon_night/neon_night_canvas.dart';
import '../film/neon_night/neon_night_story.dart';
import '../film/neon_night/neon_placeholder_photo.dart';

/// Debug builds only (#363): plays the Neon Night film full screen on the
/// spec's reference night, with placeholder photos. Built up phase by
/// phase: phase 4 adds the chapter cards. EN/RU switches the film's language (and the fixture's
/// words). It starts reduced when the phone reduces motion or You →
/// Settings → Reduce flashing is on; "Reduced"/"Full" overrides that (§6).
/// Reached from the Plan inspector; never routed in release.
class NeonNightPreviewPage extends ConsumerStatefulWidget {
  const NeonNightPreviewPage({super.key});

  @override
  ConsumerState<NeonNightPreviewPage> createState() =>
      _NeonNightPreviewPageState();
}

class _NeonNightPreviewPageState extends ConsumerState<NeonNightPreviewPage> {
  /// The debug toggle; null follows the setting.
  bool? _reducedOverride;
  bool _russian = false;

  @override
  Widget build(BuildContext context) {
    final reduced = _reducedOverride ?? watchReduceFlashing(context, ref);
    final locale = Locale(_russian ? 'ru' : 'en');
    final story = _russian
        ? NeonNightFixtures.referenceRu
        : NeonNightFixtures.reference;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Localizations.override(
              context: context,
              locale: locale,
              child: NeonNightCanvas(
                key: ValueKey(locale),
                story: story,
                photo: NeonPlaceholderPhoto.forIds(
                  NeonNightFixtures.photoIds(story),
                ),
                reducedFlashing: reduced,
              ),
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                const BackButton(color: Colors.white),
                const Spacer(),
                TextButton(
                  key: const Key('neon-night-reduced'),
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  onPressed: () => setState(() => _reducedOverride = !reduced),
                  child: Text(reduced ? 'Reduced' : 'Full'),
                ),
                TextButton(
                  key: const Key('neon-night-language'),
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  onPressed: () => setState(() => _russian = !_russian),
                  child: Text(_russian ? 'RU' : 'EN'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
