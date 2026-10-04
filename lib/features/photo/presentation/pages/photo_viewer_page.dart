import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/failure_message.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/show_error_snackbar.dart';
import '../../domain/entities/photo_entity.dart';
import '../widgets/storage_photo_image.dart';

final _takenAtFormat = DateFormat('MMM d, h:mm a');

const _fadeInDuration = Duration(milliseconds: 350);
const _snapDuration = Duration(milliseconds: 300);
const _snapCurve = Cubic(.22, 1, .36, 1);

/// A release past this many pixels commits to the neighbouring photo;
/// anything shorter springs back (#149).
const _commitDistance = 60.0;

/// A quick flick commits even when shorter than [_commitDistance].
const _commitVelocity = 600.0;

/// Horizontal room around each slide's image, so the neighbouring photo
/// peeks in from the clipped edge while dragging.
const _slidePadding = 40.0;

/// How far the close button hangs outside the track's top-right corner.
const _closeOverhangTop = 16.0;
const _closeOverhangRight = 12.0;

/// Real photo-list index an unbounded track page maps to — the track keeps
/// counting past either end and the photo is picked by modulo, which is
/// what makes wrap-around a plain one-step slide.
int wrappedPhotoIndex(int page, int photoCount) =>
    photoCount <= 1 ? 0 : page % photoCount;

/// Full-screen, day-scoped photo swiper opened from the Journal's photo
/// strip (#117, reworked in #149).
///
/// A blurred overlay rather than a pushed page. The track follows the
/// finger 1:1 while dragging (no animation), then snaps with a soft
/// cubic on release — past [_commitDistance] (or a fast flick) to the
/// neighbour, otherwise back to centre. Paging wraps at both ends.
///
/// When [onDelete] is given, a trash button (top-left, mirroring close)
/// deletes the current photo at once — no confirmation (#165), so clearing
/// several photos stays one tap each. The viewer moves on to the next photo,
/// closes once none are left, and puts the photo back if [onDelete] throws.
///
/// Otherwise deliberately minimal: no place row, people tagging, caption
/// editing, or Set-as-cover/Use-in-wrap-up actions — those belong to the
/// M3-8 detail screen.
class PhotoViewerPage extends StatefulWidget {
  const PhotoViewerPage({
    required this.photos,
    required this.initialIndex,
    this.onDelete,
    super.key,
  }) : assert(photos.length > 0, 'PhotoViewerPage needs at least one photo');

  final List<PhotoEntity> photos;
  final int initialIndex;

  /// Deletes a photo; throws on failure. `null` hides the trash button.
  final Future<void> Function(PhotoEntity photo)? onDelete;

  static Future<void> show(
    BuildContext context, {
    required List<PhotoEntity> photos,
    required int initialIndex,
    Future<void> Function(PhotoEntity photo)? onDelete,
  }) {
    return showGeneralDialog<void>(
      context: context,
      // The viewer paints its own blurred backdrop and handles
      // tap-to-close itself, so the route's barrier stays invisible/inert.
      barrierColor: Colors.transparent,
      transitionDuration: _fadeInDuration,
      pageBuilder: (_, _, _) => PhotoViewerPage(
        photos: photos,
        initialIndex: initialIndex,
        onDelete: onDelete,
      ),
      transitionBuilder: (_, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    );
  }

  @override
  State<PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends State<PhotoViewerPage>
    with SingleTickerProviderStateMixin {
  /// Track position in (unbounded) page units: the committed [_page] at
  /// rest, fractional while dragging or snapping.
  late final AnimationController _track;

  /// The committed page — unbounded, mapped onto the photo list by
  /// [wrappedPhotoIndex].
  late int _page;

  /// The viewer's own copy, so a delete can drop a photo without waiting on
  /// the Journal to rebuild the route.
  late final List<PhotoEntity> _photos = [...widget.photos];

  /// Context under the viewer's own [ScaffoldMessenger] — the Journal's
  /// messenger sits behind this overlay, so its snackbars wouldn't show.
  late BuildContext _overlayContext;

  double _dragStartValue = 0;
  double _dragDx = 0;
  double _trackWidth = 1;

  int get _count => _photos.length;
  bool get _hasMultiple => _count > 1;
  int get _currentIndex => wrappedPhotoIndex(_page, _count);

  @override
  void initState() {
    super.initState();
    _page = widget.initialIndex.clamp(0, _count - 1);
    _track = AnimationController.unbounded(
      vsync: this,
      value: _page.toDouble(),
    );
  }

  @override
  void dispose() {
    _track.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    setState(() => _page = page);
    _track.animateTo(
      page.toDouble(),
      duration: _snapDuration,
      curve: _snapCurve,
    );
  }

  void _goPrev() => _goTo(_page - 1);
  void _goNext() => _goTo(_page + 1);

  void _onDragStart(DragStartDetails _) {
    // Grab the track where it is, even mid-snap, so it never jumps under
    // the finger.
    _track.stop();
    _dragStartValue = _track.value;
    _dragDx = 0;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _dragDx += details.delta.dx;
    _track.value = _dragStartValue - _dragDx / _trackWidth;
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (_dragDx > _commitDistance || velocity > _commitVelocity) {
      _goPrev();
    } else if (_dragDx < -_commitDistance || velocity < -_commitVelocity) {
      _goNext();
    } else {
      _goTo(_page);
    }
    _dragDx = 0;
  }

  void _close() => Navigator.of(context).pop();

  /// Jumps (no slide) to [index] — used when the list itself changes.
  void _showIndex(int index) {
    _page = index;
    _track.value = index.toDouble();
  }

  Future<void> _deleteCurrent() async {
    final onDelete = widget.onDelete;
    if (onDelete == null) return;
    final index = _currentIndex;
    final photo = _photos[index];
    if (_count == 1) {
      _close();
    } else {
      setState(() {
        _photos.removeAt(index);
        // The same slot now holds the next photo; past the end, wrap to
        // the first — the same direction "next" pages.
        _showIndex(index < _count ? index : 0);
      });
    }

    try {
      await onDelete(photo);
    } catch (error) {
      // Closed already (it was the last photo): the Journal shows the
      // error and its strip gets the photo back.
      if (!mounted) return;
      // Show the photo that came back, so the error reads against it.
      setState(() {
        final at = index.clamp(0, _count);
        _photos.insert(at, photo);
        _showIndex(at);
      });
      showErrorSnackbar(
        _overlayContext,
        message: presentationFailureMessage(error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // A general-dialog route has no Material of its own — the transparent
    // Scaffold supplies the default text style and ink surface, and its
    // messenger lets a failed delete's snackbar show above the overlay.
    return ScaffoldMessenger(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Builder(
          builder: (context) {
            _overlayContext = context;
            return _buildOverlay();
          },
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            key: const Key('photo-viewer-backdrop'),
            behavior: HitTestBehavior.opaque,
            onTap: _close,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: ColoredBox(
                color: AppColors.tint(AppColors.background50, .9),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl - _closeOverhangRight,
              AppSpacing.xl - _closeOverhangTop,
              AppSpacing.xl - _closeOverhangRight,
              AppSpacing.xl,
            ),
            child: Center(
              // Swallows taps on the content (the Flutter equivalent of
              // stopPropagation) so only the bare backdrop closes; drags
              // are claimed by the track's own recognizer before any tap
              // could resolve.
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: _buildTrackArea()),
                    _PhotoInfo(
                      photo: _photos[_currentIndex],
                      index: _currentIndex,
                      total: _count,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxImageHeight = MediaQuery.sizeOf(context).height * .8;
        final height = math.min(
          constraints.maxHeight,
          maxImageHeight + _closeOverhangTop,
        );
        return SizedBox(
          width: constraints.maxWidth,
          height: height,
          // The close button sits in this padding band, outside the clipped
          // track, so the clip never cuts it and it stays hit-testable.
          child: Stack(
            children: [
              Positioned.fill(
                top: _closeOverhangTop,
                left: _closeOverhangRight,
                right: _closeOverhangRight,
                child: _buildTrack(maxImageHeight),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: _RoundIconButton(
                  key: const Key('photo-viewer-close'),
                  icon: Icons.close,
                  diameter: 32,
                  iconSize: 16,
                  onTap: _close,
                ),
              ),
              if (widget.onDelete != null)
                Positioned(
                  top: 0,
                  left: 0,
                  child: _RoundIconButton(
                    key: const Key('photo-viewer-delete'),
                    icon: Icons.delete_outline,
                    semanticLabel: 'Delete photo',
                    diameter: 32,
                    iconSize: 16,
                    onTap: _deleteCurrent,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrack(double maxImageHeight) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _trackWidth = constraints.maxWidth;
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                key: const Key('photo-viewer-pager'),
                behavior: HitTestBehavior.opaque,
                // Count the slop distance too, so the photo lines up with
                // the finger from the moment the drag is recognized.
                dragStartBehavior: DragStartBehavior.down,
                onHorizontalDragStart: _hasMultiple ? _onDragStart : null,
                onHorizontalDragUpdate: _hasMultiple ? _onDragUpdate : null,
                onHorizontalDragEnd: _hasMultiple ? _onDragEnd : null,
                onHorizontalDragCancel: _hasMultiple
                    ? () => _goTo(_page)
                    : null,
                child: ClipRect(
                  child: AnimatedBuilder(
                    animation: _track,
                    builder: (context, _) => _buildSlides(maxImageHeight),
                  ),
                ),
              ),
            ),
            if (_hasMultiple) ...[
              Positioned(
                left: AppSpacing.sm,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _RoundIconButton(
                    key: const Key('photo-viewer-prev'),
                    icon: Icons.chevron_left,
                    diameter: 40,
                    iconSize: 20,
                    onTap: _goPrev,
                  ),
                ),
              ),
              Positioned(
                right: AppSpacing.sm,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _RoundIconButton(
                    key: const Key('photo-viewer-next'),
                    icon: Icons.chevron_right,
                    diameter: 40,
                    iconSize: 20,
                    onTap: _goNext,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  /// Lays out only the slides that can be on screen: each unbounded page
  /// `k` sits at `(k - position) * width`, showing photo `k mod count`.
  Widget _buildSlides(double maxImageHeight) {
    final position = _hasMultiple ? _track.value : 0.0;
    final first = _hasMultiple ? position.floor() - 1 : 0;
    final last = _hasMultiple ? position.ceil() + 1 : 0;
    return Stack(
      children: [
        for (var page = first; page <= last; page++)
          Positioned(
            key: ValueKey(page),
            left: (page - position) * _trackWidth,
            top: 0,
            bottom: 0,
            width: _trackWidth,
            child: _Slide(
              photo: _photos[wrappedPhotoIndex(page, _count)],
              maxImageHeight: maxImageHeight,
            ),
          ),
      ],
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.photo, required this.maxImageHeight});

  final PhotoEntity photo;
  final double maxImageHeight;

  @override
  Widget build(BuildContext context) {
    final url = photo.imageUrl;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _slidePadding),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxImageHeight),
          // Under loose constraints the image sizes itself to its own
          // aspect ratio, so the rounded clip hugs the photo, not the slide.
          child: ClipRRect(
            borderRadius: AppRadius.cardRadius,
            child: url == null
                ? const SizedBox.square(
                    dimension: 160,
                    child: ColoredBox(
                      color: AppColors.surface,
                      child: Icon(
                        Icons.photo_outlined,
                        color: AppColors.textMuted,
                        size: 40,
                      ),
                    ),
                  )
                : StoragePhotoImage(
                    url: url,
                    storagePath: photo.storagePath,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  ),
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    super.key,
    required this.icon,
    required this.diameter,
    required this.iconSize,
    required this.onTap,
    this.semanticLabel,
  });

  final IconData icon;
  final String? semanticLabel;
  final double diameter;
  final double iconSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.tint(AppColors.surfaceElevated, .9),
      shape: const CircleBorder(
        side: BorderSide(color: AppColors.surfaceBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox.square(
          dimension: diameter,
          child: Icon(
            icon,
            color: AppColors.textPrimary,
            size: iconSize,
            semanticLabel: semanticLabel,
          ),
        ),
      ),
    );
  }
}

/// Caption, timestamp and "i / n" counter below the image. The counter only
/// renders when the day has more than one photo.
class _PhotoInfo extends StatelessWidget {
  const _PhotoInfo({
    required this.photo,
    required this.index,
    required this.total,
  });

  final PhotoEntity photo;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final caption = photo.caption?.trim();
    final takenAt = photo.takenAt;
    final smallStyle = AppTypography.caption.copyWith(
      fontSize: 11,
      letterSpacing: 0,
    );
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.base),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (caption != null && caption.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                caption,
                textAlign: TextAlign.center,
                style: AppTypography.fieldLabel.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          if (takenAt != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(_takenAtFormat.format(takenAt), style: smallStyle),
          ],
          if (total > 1) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${index + 1} / $total',
              key: const Key('photo-viewer-counter'),
              style: smallStyle,
            ),
          ],
        ],
      ),
    );
  }
}
