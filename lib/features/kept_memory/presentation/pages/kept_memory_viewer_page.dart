import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../bonus/presentation/widgets/bonus_template_text.dart';
import '../../../photo/presentation/widgets/storage_photo_image.dart';
import '../../domain/entities/kept_memory.dart';
import '../../domain/entities/kept_memory_day.dart';
import '../../domain/entities/kept_memory_photo.dart';
import '../../domain/viewer_progress.dart';
import '../kept_memory_labels.dart';

const _fadeInDuration = Duration(milliseconds: 200);
const _pageDuration = Duration(milliseconds: 300);

/// How long each photo stays up in the slideshow.
const slideshowInterval = Duration(milliseconds: 3200);
const _crossfadeDuration = Duration(milliseconds: 800);
const _kenBurnsDuration = Duration(milliseconds: 3400);

/// A downward drag past this (or a quick flick) closes the viewer.
const _closeDragDistance = 120.0;
const _closeDragVelocity = 700.0;

/// Full-screen viewer over every photo of a kept memory, in day order
/// (#279, spec § 4), with an autoplay slideshow.
///
/// Separate from the Journal's day-scoped `PhotoViewerPage` overlay (#117,
/// #149): that one is a blurred card with delete, this one is full-bleed,
/// read-only and memory-wide — sharing a widget would mean two UIs behind
/// flags. Both load through [StoragePhotoImage], so they share its cache.
///
/// Paused: swipe or tap the left third / right two-thirds to move, pinch to
/// zoom, swipe down to close. Playing: every [slideshowInterval] the next
/// photo crossfades in with a slow zoom (no zoom under reduced motion),
/// looping at the end; any manual move restarts the timer. The screen stays
/// awake while it plays, and it pauses when the app is backgrounded.
class KeptMemoryViewerPage extends StatefulWidget {
  const KeptMemoryViewerPage({
    required this.memory,
    required this.initialIndex,
    this.autoplay = false,
    super.key,
  });

  /// Must have at least one photo — [show] does nothing otherwise.
  final KeptMemory memory;
  final int initialIndex;
  final bool autoplay;

  static Future<void> show(
    BuildContext context, {
    required KeptMemory memory,
    required int initialIndex,
    bool autoplay = false,
  }) {
    if (memory.photos.isEmpty) return Future.value();
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: _fadeInDuration,
        reverseTransitionDuration: _fadeInDuration,
        pageBuilder: (_, _, _) => KeptMemoryViewerPage(
          memory: memory,
          initialIndex: initialIndex,
          autoplay: autoplay,
        ),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  State<KeptMemoryViewerPage> createState() => _KeptMemoryViewerPageState();
}

class _KeptMemoryViewerPageState extends State<KeptMemoryViewerPage> {
  late int _index;
  late bool _isPlaying;
  late final PageController _pageController;
  late final AppLifecycleListener _lifecycle;
  late final Map<int, KeptMemoryDay> _daysByIndex;
  late final List<int> _dayPhotoCounts;
  Timer? _timer;
  var _isZoomed = false;
  var _dragDy = 0.0;

  List<KeptMemoryPhoto> get _photos => widget.memory.photos;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, _photos.length - 1);
    _isPlaying = widget.autoplay;
    _pageController = PageController(initialPage: _index);
    _daysByIndex = {for (final d in widget.memory.days) d.dayIndex: d};
    _dayPhotoCounts = [
      for (final d in widget.memory.days)
        if (d.photos.isNotEmpty) d.photos.length,
    ];
    _lifecycle = AppLifecycleListener(onHide: _pause, onPause: _pause);
    if (_isPlaying) _startPlaying();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheAhead();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lifecycle.dispose();
    _pageController.dispose();
    _setScreenAwake(false);
    super.dispose();
  }

  /// Best-effort: a platform without the plugin (tests) just doesn't stay
  /// awake.
  void _setScreenAwake(bool awake) {
    unawaited(
      WakelockPlus.toggle(enable: awake).catchError((Object error) {
        debugPrint('Wakelock toggle failed: $error');
      }),
    );
  }

  void _startPlaying() {
    _setScreenAwake(true);
    _restartTimer();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (!_isPlaying) return;
    _timer = Timer(slideshowInterval, () {
      if (!mounted) return;
      _show(nextSlideshowIndex(_index, _photos.length));
    });
  }

  void _pause() {
    if (!_isPlaying) return;
    _timer?.cancel();
    _setScreenAwake(false);
    setState(() => _isPlaying = false);
    // The pager sat offstage while playing; bring it to the current photo.
    if (_pageController.hasClients) _pageController.jumpToPage(_index);
  }

  void _togglePlaying() {
    if (_isPlaying) {
      _pause();
    } else {
      setState(() {
        _isPlaying = true;
        _isZoomed = false;
      });
      _startPlaying();
    }
  }

  /// Moves to [index] — slides the pager when paused, crossfades when
  /// playing (and restarts the slideshow timer either way).
  void _show(int index) {
    if (index < 0 || index >= _photos.length) return;
    if (_isPlaying || !_pageController.hasClients) {
      setState(() => _index = index);
      _precacheAhead();
    } else {
      _pageController.animateToPage(
        index,
        duration: _pageDuration,
        curve: Curves.easeOutCubic,
      );
    }
    _restartTimer();
  }

  void _onPageChanged(int index) {
    setState(() {
      _index = index;
      _isZoomed = false;
    });
    _precacheAhead();
    _restartTimer();
  }

  /// Full images for the next two photos, so they're decoded by the time
  /// they're shown.
  void _precacheAhead() {
    for (var step = 1; step <= 2; step++) {
      final photo = _photos[(_index + step) % _photos.length].photo;
      final url = photo.imageUrl;
      if (url == null) continue;
      unawaited(
        precacheImage(
          StoragePhotoImage.providerFor(
            url: url,
            storagePath: photo.storagePath,
          ),
          context,
          onError: (_, _) {},
        ),
      );
    }
  }

  void _onTapUp(TapUpDetails details, double width) {
    if (details.localPosition.dx < width / 3) {
      _show(_index - 1);
    } else {
      _show(_index + 1);
    }
  }

  void _close() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    final current = _photos[_index];
    final canDragClose = !_isZoomed;
    return Scaffold(
      backgroundColor: AppColors.viewerBackground,
      body: GestureDetector(
        onVerticalDragUpdate: canDragClose
            ? (d) => setState(
                () =>
                    _dragDy = (_dragDy + d.delta.dy).clamp(0, double.infinity),
              )
            : null,
        onVerticalDragEnd: canDragClose
            ? (d) {
                if (_dragDy > _closeDragDistance ||
                    (d.primaryVelocity ?? 0) > _closeDragVelocity) {
                  _close();
                } else {
                  setState(() => _dragDy = 0);
                }
              }
            : null,
        child: Transform.translate(
          offset: Offset(0, _dragDy),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _TopBar(
                  dayIndex: current.dayIndex,
                  position: _index + 1,
                  total: _photos.length,
                  isPlaying: _isPlaying,
                  onClose: _close,
                  onTogglePlaying: _togglePlaying,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: _ProgressLine(
                    fills: dayProgressFills(_dayPhotoCounts, _index),
                    flexes: _dayPhotoCounts,
                  ),
                ),
                Expanded(child: _buildStage()),
                _CaptionBlock(
                  photo: current,
                  day: _daysByIndex[current.dayIndex],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStage() {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        key: const Key('kept-memory-viewer-stage'),
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => _onTapUp(d, constraints.maxWidth),
        // While playing there's no pager to swipe — a horizontal fling
        // moves instead.
        onHorizontalDragEnd: _isPlaying
            ? (d) {
                final v = d.primaryVelocity ?? 0;
                if (v < 0) _show(_index + 1);
                if (v > 0) _show(_index - 1);
              }
            : null,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Offstage(
              offstage: _isPlaying,
              child: PageView.builder(
                key: const Key('kept-memory-viewer-pager'),
                controller: _pageController,
                physics: _isZoomed
                    ? const NeverScrollableScrollPhysics()
                    : const PageScrollPhysics(),
                onPageChanged: _onPageChanged,
                itemCount: _photos.length,
                itemBuilder: (context, index) => _ZoomablePhoto(
                  photo: _photos[index],
                  onZoomChanged: (zoomed) {
                    if (zoomed != _isZoomed) {
                      setState(() => _isZoomed = zoomed);
                    }
                  },
                ),
              ),
            ),
            if (_isPlaying)
              AnimatedSwitcher(
                duration: _crossfadeDuration,
                layoutBuilder: (current, previous) => Stack(
                  fit: StackFit.expand,
                  children: [...previous, ?current],
                ),
                child: _KenBurnsPhoto(
                  key: ValueKey(_index),
                  photo: _photos[_index],
                  zoom: !reduceMotion,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ViewerImage extends StatelessWidget {
  const _ViewerImage({required this.photo, required this.fit});

  final KeptMemoryPhoto photo;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final url = photo.photo.imageUrl;
    if (url == null) {
      return const Center(
        child: Icon(Icons.photo_outlined, color: AppColors.textMuted, size: 40),
      );
    }
    return StoragePhotoImage(
      url: url,
      storagePath: photo.photo.storagePath,
      fit: fit,
      gaplessPlayback: true,
    );
  }
}

/// A paused photo: whole (`contain`), pinch to zoom. Reports when it's
/// zoomed in, so the pager and swipe-down step aside for panning.
class _ZoomablePhoto extends StatefulWidget {
  const _ZoomablePhoto({required this.photo, required this.onZoomChanged});

  final KeptMemoryPhoto photo;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_ZoomablePhoto> createState() => _ZoomablePhotoState();
}

class _ZoomablePhotoState extends State<_ZoomablePhoto> {
  final _transform = TransformationController();

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: _transform,
      maxScale: 4,
      onInteractionEnd: (_) =>
          widget.onZoomChanged(_transform.value.getMaxScaleOnAxis() > 1.01),
      child: SizedBox.expand(
        child: _ViewerImage(photo: widget.photo, fit: BoxFit.contain),
      ),
    );
  }
}

/// A playing photo: fills the frame and drifts from 1.02× to 1.12× over its
/// time on screen — or holds still under reduced motion.
class _KenBurnsPhoto extends StatelessWidget {
  const _KenBurnsPhoto({required this.photo, required this.zoom, super.key});

  final KeptMemoryPhoto photo;
  final bool zoom;

  @override
  Widget build(BuildContext context) {
    final image = _ViewerImage(photo: photo, fit: BoxFit.cover);
    if (!zoom) return ClipRect(child: image);
    return ClipRect(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.02, end: 1.12),
        duration: _kenBurnsDuration,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: image,
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.dayIndex,
    required this.position,
    required this.total,
    required this.isPlaying,
    required this.onClose,
    required this.onTogglePlaying,
  });

  final int dayIndex;
  final int position;
  final int total;
  final bool isPlaying;
  final VoidCallback onClose;
  final VoidCallback onTogglePlaying;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Material(
            color: AppColors.tint(AppColors.textPrimary, .08),
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: const Key('kept-memory-viewer-close'),
              onTap: onClose,
              child: SizedBox.square(
                dimension: 38,
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: AppColors.textPrimary,
                  semanticLabel: MaterialLocalizations.of(
                    context,
                  ).closeButtonTooltip,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              l10n
                  .keptMemory_viewerPosition(dayIndex, position, total)
                  .toUpperCase(),
              key: const Key('kept-memory-viewer-position'),
              textAlign: TextAlign.center,
              style: AppTypography.mono.copyWith(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Material(
            color: isPlaying
                ? AppColors.primary
                : AppColors.tint(AppColors.textPrimary, .08),
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              key: const Key('kept-memory-viewer-play'),
              borderRadius: BorderRadius.circular(999),
              onTap: onTogglePlaying,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                child: Text(
                  isPlaying
                      ? '❚❚ ${l10n.keptMemory_pause}'
                      : '▶ ${l10n.keptMemory_slideshow}',
                  style: AppTypography.buttonLabel.copyWith(
                    fontSize: 12,
                    color: isPlaying
                        ? AppColors.background
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One 2px segment per day, as wide as that day's photo count.
class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.fills, required this.flexes});

  final List<double> fills;
  final List<int> flexes;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2,
      child: Row(
        children: [
          for (var i = 0; i < flexes.length; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Expanded(
              flex: flexes[i],
              child: ClipRRect(
                borderRadius: BorderRadius.circular(1),
                child: ColoredBox(
                  color: AppColors.tint(AppColors.textPrimary, .14),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: fills[i],
                      heightFactor: 1,
                      child: const ColoredBox(color: AppColors.primary),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bonus-task pill, the photo's caption, then its date.
class _CaptionBlock extends StatelessWidget {
  const _CaptionBlock({required this.photo, required this.day});

  final KeptMemoryPhoto photo;
  final KeptMemoryDay? day;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bonus = photo.bonusTask;
    final caption = photo.photo.caption?.trim();
    final date = day?.date;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 120),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            38 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (bonus != null) ...[
                Container(
                  key: const Key('kept-memory-viewer-bonus'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.tint(AppColors.accentBlue, .14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.tint(AppColors.accentBlue, .35),
                    ),
                  ),
                  child: Text(
                    l10n.keptMemory_bonusTag(
                      bonusTemplateTitle(l10n, bonus),
                      bonus.points,
                    ),
                    style: AppTypography.chipLabel.copyWith(
                      fontSize: 11.5,
                      color: AppColors.accentBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              // User content — shown exactly as written.
              if (caption != null && caption.isNotEmpty) ...[
                Text(
                  caption,
                  style: AppTypography.serif(
                    fontSize: 17,
                    height: 1.45,
                    fontStyle: FontStyle.italic,
                    color: AppColors.noteText,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (date != null)
                Text(
                  KeptMemoryLabels.weekdayDate(
                    date,
                    l10n.localeName,
                  ).toUpperCase(),
                  style: AppTypography.mono,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
