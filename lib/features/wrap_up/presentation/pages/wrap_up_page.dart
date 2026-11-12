import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_message.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/async_error_retry_scaffold.dart';
import '../../../trip/presentation/providers/cover_image_url_provider.dart';
import '../../../trip/presentation/widgets/cover_options.dart';
import '../controllers/wrap_up_controller.dart';
import '../controllers/wrap_up_state.dart';
import '../film/chrome/wrap_up_film_grain.dart';
import '../film/sky_story/sky_story.dart';
import '../film/sky_story/sky_story_canvas.dart';
import '../film/film_music.dart';
import '../film/wrap_up_film_canvas.dart';
import '../film/wrap_up_film_hud.dart';
import '../film/wrap_up_film_photo.dart';
import '../film/wrap_up_film_photo_pins.dart';
import '../widgets/wrap_up_generating_view.dart';
import '../../../../core/l10n/context_l10n.dart';

class WrapUpPage extends ConsumerStatefulWidget {
  const WrapUpPage({
    required this.tripId,
    this.openedFromMemory = false,
    this.skyMusic = JustAudioFilmMusicPlayer.skyStory,
    super.key,
  });

  final String tripId;

  /// Opened from the Kept Memory page's "Play the film" (#279) — the film
  /// then leads back there.
  final bool openedFromMemory;

  /// The Sky Story film's music player; tests pass a fake.
  final FilmMusicPlayer Function() skyMusic;

  @override
  ConsumerState<WrapUpPage> createState() => _WrapUpPageState();
}

/// Plays the Sky Story film (#345) whenever the wrap-up has one — every
/// draft with photos, and films kept since — else the classic film. If
/// Sky Story fails while it plays, the classic film takes over for good.
class _WrapUpPageState extends ConsumerState<WrapUpPage> {
  bool _skyFailed = false;
  bool _muted = false;

  @override
  Widget build(BuildContext context) {
    final tripId = widget.tripId;
    final wrapUpAsync = ref.watch(wrapUpControllerProvider(tripId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: wrapUpAsync.when(
        loading: () => const WrapUpGeneratingView(),
        error: (error, _) => AsyncErrorRetryScaffold(
          message: presentationFailureMessage(error, context.l10n),
          onRetry: () => ref.invalidate(wrapUpControllerProvider(tripId)),
        ),
        data: (state) {
          final skyStory = _skyFailed ? null : state.skyStory;
          return Stack(
            children: [
              Positioned.fill(
                child: skyStory != null
                    ? _SkyStoryFilm(
                        state: state,
                        story: skyStory,
                        music: widget.skyMusic,
                        muted: _muted,
                        onFailure: () => setState(() => _skyFailed = true),
                      )
                    : _WrapUpFilmReady(
                        // Keyed on generatedAt (stable across a "Keep
                        // forever" publish) so asset prep — signed cover
                        // URL, precache, grain generation — runs once per
                        // wrap-up, not on every state change.
                        key: ValueKey(state.wrapUp.generatedAt),
                        state: state,
                      ),
              ),
              // Independent of asset prep — closing the film or publishing
              // must never wait on photo precaching.
              WrapUpFilmHud(
                tripId: tripId,
                isPublished: state.wrapUp.isPublished,
                openedFromMemory: widget.openedFromMemory,
                isOutOfDate: state.isOutOfDate,
                muted: _muted,
                onToggleMute: skyStory == null
                    ? null
                    : () => setState(() => _muted = !_muted),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The Sky Story film over the memory's photos. It starts at once — its
/// first seconds are sky and title — and the photos stream in behind it,
/// decoded no bigger than the film can show.
class _SkyStoryFilm extends StatefulWidget {
  const _SkyStoryFilm({
    required this.state,
    required this.story,
    required this.music,
    required this.muted,
    required this.onFailure,
  });

  final WrapUpState state;
  final SkyStory story;
  final FilmMusicPlayer Function() music;
  final bool muted;
  final VoidCallback onFailure;

  @override
  State<_SkyStoryFilm> createState() => _SkyStoryFilmState();
}

class _SkyStoryFilmState extends State<_SkyStoryFilm> {
  /// A method tear-off, so it stays equal across rebuilds and the film
  /// doesn't restart; it reads the latest URLs from the widget.
  ImageProvider? _photo(String id) {
    final url = widget.state.imageUrlForPhoto(id);
    return url == null ? null : WrapUpFilmPhoto.providerFor(url);
  }

  @override
  Widget build(BuildContext context) {
    return SkyStoryCanvas(
      story: widget.story,
      photo: _photo,
      music: widget.music,
      muted: widget.muted,
      onFailure: (_, _) => widget.onFailure(),
    );
  }
}

class _ResolvedFilmAssets {
  const _ResolvedFilmAssets({this.coverImage, this.grainImage});

  final ImageProvider? coverImage;
  final ui.Image? grainImage;
}

class _WrapUpFilmReady extends ConsumerStatefulWidget {
  const _WrapUpFilmReady({required this.state, super.key});

  final WrapUpState state;

  @override
  ConsumerState<_WrapUpFilmReady> createState() => _WrapUpFilmReadyState();
}

class _WrapUpFilmReadyState extends ConsumerState<_WrapUpFilmReady> {
  late final Future<_ResolvedFilmAssets> _assetsFuture;
  final _photoPins = WrapUpFilmPhotoPins();

  @override
  void initState() {
    super.initState();
    _assetsFuture = _prepareAssets();
  }

  @override
  void dispose() {
    _photoPins.dispose();
    super.dispose();
  }

  Future<void> _safePrecache(ImageProvider provider) async {
    if (!mounted) return;
    try {
      await precacheImage(provider, context);
    } catch (_) {
      // A broken/unreachable photo shouldn't block the whole film.
    }
  }

  Future<_ResolvedFilmAssets> _prepareAssets() async {
    final wrapUp = widget.state.wrapUp;

    ImageProvider? coverImage;
    final coverPath = wrapUp.coverPhoto.imagePath;
    if (coverPath != null && coverPath.isNotEmpty) {
      final assetPath = resolveAssetCoverPath(coverPath);
      if (assetPath != null) {
        coverImage = AssetImage(assetPath);
      } else {
        try {
          final url = await ref.read(coverImageUrlProvider(coverPath).future);
          coverImage = CachedNetworkImageProvider(url);
        } catch (_) {
          coverImage = null;
        }
      }
    }

    // Only what the film can ever show: the ≤8 moment photos with their
    // collage tiles (≤6 per moment) and the two Flurries' photos (≤15
    // each) — bounded regardless of trip size.
    //
    // Each Moment's own photo is the one a print flips face-up onto, so
    // those are pinned live for the whole film — the rest (≤ 8×5 collage
    // extras + ≤ 30 Flurry prints) are best-effort in the LRU image cache,
    // where pinning them all could cost hundreds of MB on a big memory.
    final pinnedUrls = <String>{
      for (final moment in wrapUp.moments)
        ?widget.state.imageUrlForPhoto(moment.photoId),
    };
    final urls = <String>{};
    for (final photoRef in [
      for (final moment in wrapUp.moments) ...moment.allPhotoRefs,
      ...wrapUp.flurry1Photos,
      ...wrapUp.flurry2Photos,
    ]) {
      final url = widget.state.imageUrlForPhoto(photoRef.photoId);
      if (url != null && !pinnedUrls.contains(url)) urls.add(url);
    }

    final grainFuture = WrapUpFilmGrain.generate();

    // Closed during the cover-URL await: pins taken now would outlive
    // dispose() and never be released.
    if (!mounted) return const _ResolvedFilmAssets();

    // A single slow/unreachable photo must not hold up the whole film
    // indefinitely — precaching is best-effort within a bounded wait, not a
    // hard prerequisite (the frame widgets already degrade gracefully when
    // an image is still loading or missing).
    await Future.wait([
      for (final url in pinnedUrls)
        _photoPins.pin(WrapUpFilmPhoto.providerFor(url)),
      for (final url in urls) _safePrecache(WrapUpFilmPhoto.providerFor(url)),
      if (coverImage != null) _safePrecache(coverImage),
    ]).timeout(const Duration(seconds: 6), onTimeout: () => const []);

    final grainImage = await grainFuture;
    return _ResolvedFilmAssets(coverImage: coverImage, grainImage: grainImage);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ResolvedFilmAssets>(
      future: _assetsFuture,
      builder: (context, snapshot) {
        final assets = snapshot.data;
        if (assets == null) return const WrapUpGeneratingView();

        return WrapUpFilmCanvas(
          wrapUp: widget.state.wrapUp,
          photoUrlById: widget.state.photoUrlById,
          coverImage: assets.coverImage,
          grainImage: assets.grainImage,
        );
      },
    );
  }
}
