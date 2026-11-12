import 'package:flutter/material.dart';

import '../film/golden_vows/golden_vows_canvas.dart';
import '../film/golden_vows/golden_vows_story.dart';

/// Debug builds only (#346): plays the Golden Vows film full screen with
/// the spec's wedding. EN/RU switches the film's language (and the
/// fixture's words). Built up phase by phase: phase 3 adds the album.
/// No photos ship with the app, so its prints are empty mats here.
/// Reached from the Plan inspector; never routed in release.
class GoldenVowsPreviewPage extends StatefulWidget {
  const GoldenVowsPreviewPage({super.key});

  @override
  State<GoldenVowsPreviewPage> createState() => _GoldenVowsPreviewPageState();
}

class _GoldenVowsPreviewPageState extends State<GoldenVowsPreviewPage> {
  bool _russian = false;

  @override
  Widget build(BuildContext context) {
    final locale = Locale(_russian ? 'ru' : 'en');
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Localizations.override(
              context: context,
              locale: locale,
              child: GoldenVowsCanvas(
                key: ValueKey(locale),
                story: _russian
                    ? GoldenVowsFixtures.weddingRu
                    : GoldenVowsFixtures.wedding,
              ),
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                const BackButton(color: Colors.white),
                const Spacer(),
                TextButton(
                  key: const Key('golden-vows-language'),
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
