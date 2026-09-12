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
import '../film/wrap_up_film_canvas.dart';
import '../film/wrap_up_film_hud.dart';
import '../widgets/wrap_up_generating_view.dart';

class WrapUpPage extends ConsumerWidget {
  const WrapUpPage({required this.tripId, super.key});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wrapUpAsync = ref.watch(wrapUpControllerProvider(tripId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: wrapUpAsync.when(
        loading: () => const WrapUpGeneratingView(),
        error: (error, _) => AsyncErrorRetryScaffold(
          message: presentationFailureMessage(error),
          onRetry: () => ref.invalidate(wrapUpControllerProvider(tripId)),
        ),
        data: (state) => Stack(
          children: [
            Positioned.fill(
              child: _WrapUpFilmReady(
                // Keyed on generatedAt (stable across a "Keep forever"
                // publish) so asset prep — signed cover URL, precache, grain
                // generation — runs once per wrap-up, not on every state
                // change.
                key: ValueKey(state.wrapUp.generatedAt),
                state: state,
              ),
            ),
            // Independent of asset prep — closing the film or publishing
            // must never wait on photo precaching.
            WrapUpFilmHud(
              tripId: tripId,
              isPublished: state.wrapUp.isPublished,
            ),
          ],
        ),
      ),
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

  @override
  void initState() {
    super.initState();
    _assetsFuture = _prepareAssets();
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

    // Only what the film can ever show: the ≤8 moment photos and the first
    // 30 flurry leftovers (15 + 15, the player's own display cap) — bounded
    // regardless of trip size.
    final urls = <String>{};
    for (final moment in wrapUp.moments) {
      final url = widget.state.imageUrlForPhoto(moment.photoId);
      if (url != null) urls.add(url);
    }
    for (final photoRef in wrapUp.flurryLeftovers.photos.take(30)) {
      final url = widget.state.imageUrlForPhoto(photoRef.photoId);
      if (url != null) urls.add(url);
    }

    final grainFuture = WrapUpFilmGrain.generate();

    // A single slow/unreachable photo must not hold up the whole film
    // indefinitely — precaching is best-effort within a bounded wait, not a
    // hard prerequisite (the frame widgets already degrade gracefully when
    // an image is still loading or missing).
    await Future.wait([
      for (final url in urls) _safePrecache(CachedNetworkImageProvider(url)),
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
