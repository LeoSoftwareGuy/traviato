import 'package:flutter/material.dart';

import '../film/sky_story/sky_story_canvas.dart';
import '../film/sky_story/sky_story_fixture.dart';
import '../film/sky_story/sky_story_music.dart';

/// Debug builds only (#345): plays the Sky Story film full screen on the
/// reference's memory ("Lisbon, together", placeholder photos), so its
/// look can be checked on a device while the template is being built.
/// EN/RU switches both the film's language and the memory's words; the
/// speaker mutes the music.
/// Reached from the Plan inspector; never routed in release.
class SkyStoryPreviewPage extends StatefulWidget {
  const SkyStoryPreviewPage({
    this.music = JustAudioSkyMusicPlayer.new,
    super.key,
  });

  /// The music player; tests pass a fake.
  final SkyMusicPlayer Function() music;

  @override
  State<SkyStoryPreviewPage> createState() => _SkyStoryPreviewPageState();
}

class _SkyStoryPreviewPageState extends State<SkyStoryPreviewPage> {
  bool _russian = false;
  bool _muted = false;

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
              child: SkyStoryCanvas(
                key: ValueKey(locale),
                story: _russian
                    ? SkyStoryFixtures.lisbonRu
                    : SkyStoryFixtures.lisbon,
                photo: SkyStoryFixtures.photo,
                music: widget.music,
                muted: _muted,
              ),
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                const BackButton(color: Colors.white),
                const Spacer(),
                IconButton(
                  key: const Key('sky-story-mute'),
                  color: Colors.white,
                  onPressed: () => setState(() => _muted = !_muted),
                  icon: Icon(
                    _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  ),
                ),
                TextButton(
                  key: const Key('sky-story-language'),
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
