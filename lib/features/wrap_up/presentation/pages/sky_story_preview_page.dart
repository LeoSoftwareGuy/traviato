import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_typography.dart';
import '../controllers/wrap_up_controller.dart';
import '../film/sky_story/sky_story.dart';
import '../film/sky_story/sky_story_canvas.dart';
import '../film/sky_story/sky_story_fixture.dart';
import '../film/film_music.dart';

/// Debug builds only (#345): plays the Sky Story film full screen. With a
/// [tripId], that memory's own film (its `content.sky`, real photos);
/// without one, the reference's memory ("Lisbon, together", placeholder
/// photos). EN/RU switches the film's language (and the fixture's words);
/// the speaker mutes the music.
/// Reached from the Plan inspector; never routed in release.
class SkyStoryPreviewPage extends ConsumerStatefulWidget {
  const SkyStoryPreviewPage({
    this.tripId,
    this.music = JustAudioFilmMusicPlayer.skyStory,
    super.key,
  });

  final String? tripId;

  /// The music player; tests pass a fake.
  final FilmMusicPlayer Function() music;

  @override
  ConsumerState<SkyStoryPreviewPage> createState() =>
      _SkyStoryPreviewPageState();
}

class _SkyStoryPreviewPageState extends ConsumerState<SkyStoryPreviewPage> {
  bool _russian = false;
  bool _muted = false;

  /// The memory's signed photo URLs, read by [_memoryPhoto]: a method
  /// tear-off stays equal across builds, so toggling mute or language
  /// never restarts the film.
  Map<String, String> _urls = const {};

  ImageProvider? _memoryPhoto(String id) => switch (_urls[id]) {
    final url? => CachedNetworkImageProvider(url),
    null => null,
  };

  @override
  Widget build(BuildContext context) {
    final tripId = widget.tripId;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: tripId == null
                ? _film(
                    _russian
                        ? SkyStoryFixtures.lisbonRu
                        : SkyStoryFixtures.lisbon,
                    SkyStoryFixtures.photo,
                  )
                : _memoryFilm(tripId),
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

  Widget _memoryFilm(String tripId) {
    final state = ref.watch(wrapUpControllerProvider(tripId));
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _Message('Could not load the wrap-up: $error'),
      data: (data) {
        final story = data.skyStory;
        if (story == null) {
          return const _Message(
            'No Sky Story for this memory: it has no photos on its days, '
            'or the wrap-up was kept before Sky Story existed.',
          );
        }
        _urls = data.photoUrlById;
        return _film(story, _memoryPhoto);
      },
    );
  }

  Widget _film(SkyStory story, ImageProvider? Function(String) photo) {
    final locale = Locale(_russian ? 'ru' : 'en');
    return Localizations.override(
      context: context,
      locale: locale,
      child: SkyStoryCanvas(
        key: ValueKey(locale),
        story: story,
        photo: photo,
        music: widget.music,
        muted: _muted,
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTypography.bodyInput.copyWith(color: Colors.white),
      ),
    ),
  );
}
