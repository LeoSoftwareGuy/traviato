import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/photo_entity.dart';

final _takenAtFormat = DateFormat('MMM d, h:mm a');

/// How many full cycles of the day's photos are laid out on each side of the
/// tapped one, so wrap-around (#117) is a plain modulo over a very large but
/// finite page count rather than a truly unbounded `PageView` or hand-rolled
/// pointer math — nobody swipes this many times in one sitting.
const _wrapWindowCycles = 5000;

/// Real photo-list index a fake-infinite page number maps to.
int wrappedPhotoIndex(int page, int photoCount) =>
    photoCount <= 1 ? 0 : page % photoCount;

/// Full-bleed, day-scoped photo pager opened from the Journal's photo strip
/// (#117). `PageView`'s own physics supply drag-follow, neighbor peek (via
/// `viewportFraction` under 1.0) and spring-back release for free.
///
/// Deliberately minimal: no place row, people tagging, caption editing, or
/// Set-as-cover/Use-in-wrap-up actions — those belong to the not-yet-built
/// M3-8 detail screen this issue does not require.
class PhotoViewerPage extends StatefulWidget {
  const PhotoViewerPage({
    required this.photos,
    required this.initialIndex,
    super.key,
  }) : assert(photos.length > 0, 'PhotoViewerPage needs at least one photo');

  final List<PhotoEntity> photos;
  final int initialIndex;

  static Future<void> show(
    BuildContext context, {
    required List<PhotoEntity> photos,
    required int initialIndex,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            PhotoViewerPage(photos: photos, initialIndex: initialIndex),
      ),
    );
  }

  @override
  State<PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends State<PhotoViewerPage> {
  late final PageController _controller;
  late int _currentIndex = widget.initialIndex.clamp(
    0,
    widget.photos.length - 1,
  );

  bool get _hasMultiple => widget.photos.length > 1;

  int get _itemCount =>
      _hasMultiple ? widget.photos.length * _wrapWindowCycles * 2 : 1;

  int get _initialPage => _hasMultiple
      ? widget.photos.length * _wrapWindowCycles + _currentIndex
      : 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      initialPage: _initialPage,
      viewportFraction: 0.92,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(
      () => _currentIndex = wrappedPhotoIndex(page, widget.photos.length),
    );
  }

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final photo = widget.photos[_currentIndex];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(onClose: _close),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PageView.builder(
                    key: const Key('photo-viewer-pager'),
                    controller: _controller,
                    itemCount: _itemCount,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, page) {
                      final p =
                          widget.photos[wrappedPhotoIndex(
                            page,
                            widget.photos.length,
                          )];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                        ),
                        child: _PhotoImage(photo: p),
                      );
                    },
                  ),
                  if (_hasMultiple) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        child: _ArrowButton(
                          key: const Key('photo-viewer-prev'),
                          icon: Icons.chevron_left,
                          onTap: () => _controller.previousPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        child: _ArrowButton(
                          key: const Key('photo-viewer-next'),
                          icon: Icons.chevron_right,
                          onTap: () => _controller.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_hasMultiple)
              _BottomInfo(
                photo: photo,
                index: _currentIndex,
                total: widget.photos.length,
                onClose: _close,
              ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          // A separate sibling from the close button below — not an
          // overlapping GestureDetector behind it — so a tap can never be
          // ambiguous between "close via backdrop" and "close via button".
          Expanded(
            child: GestureDetector(
              key: const Key('photo-viewer-backdrop-top'),
              behavior: HitTestBehavior.opaque,
              onTap: onClose,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.base),
            child: _CloseButton(onTap: onClose),
          ),
        ],
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Material(
        color: AppColors.tint(AppColors.background, .55),
        child: InkWell(
          key: const Key('photo-viewer-close'),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.all(AppSpacing.sm),
            child: Icon(Icons.close, color: AppColors.textOnPhoto, size: 22),
          ),
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Material(
        color: AppColors.tint(AppColors.background, .55),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Icon(icon, color: AppColors.textOnPhoto, size: 28),
          ),
        ),
      ),
    );
  }
}

class _PhotoImage extends StatelessWidget {
  const _PhotoImage({required this.photo});

  final PhotoEntity photo;

  @override
  Widget build(BuildContext context) {
    final url = photo.imageUrl;
    if (url == null) {
      return const ColoredBox(
        color: AppColors.surface,
        child: Center(
          child: Icon(
            Icons.photo_outlined,
            color: AppColors.textMuted,
            size: 40,
          ),
        ),
      );
    }
    return Image.network(url, fit: BoxFit.contain);
  }
}

/// Caption/timestamp + "N / total" counter, below the image — only ever
/// shown when the day has more than one photo (#117). Wrapping this whole
/// block in one tap handler is safe (unlike the top bar) since it contains
/// no nested button of its own to conflict with.
class _BottomInfo extends StatelessWidget {
  const _BottomInfo({
    required this.photo,
    required this.index,
    required this.total,
    required this.onClose,
  });

  final PhotoEntity photo;
  final int index;
  final int total;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final caption = photo.caption?.trim();
    final takenAt = photo.takenAt;
    return GestureDetector(
      key: const Key('photo-viewer-backdrop-bottom'),
      behavior: HitTestBehavior.opaque,
      onTap: onClose,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.base,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (caption != null && caption.isNotEmpty) ...[
              Text(
                caption,
                textAlign: TextAlign.center,
                style: AppTypography.bodyInput.copyWith(
                  color: AppColors.textOnPhoto,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
            ] else if (takenAt != null) ...[
              Text(
                _takenAtFormat.format(takenAt),
                style: AppTypography.caption.copyWith(
                  color: AppColors.textOnPhotoMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            Text(
              '${index + 1} / $total',
              style: AppTypography.mono.copyWith(
                color: AppColors.textOnPhotoMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
