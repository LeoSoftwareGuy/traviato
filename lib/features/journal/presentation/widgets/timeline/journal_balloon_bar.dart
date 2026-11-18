import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/l10n/context_l10n.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

/// The Journal day's floating Photo · Note bar (#414,
/// docs/design/JOURNAL_NAVBAR_SPEC.md) — the Journal's only bottom control
/// (#410), replacing the #401 capture capsule: an orange bar with a hot-air balloon
/// cut out of its centre, poking [balloonOverhang] above the top edge.
/// Pressing (or hovering) one half fills the matching half of the balloon.
///
/// The balloon is decorative; only the two halves are tappable.
class JournalBalloonBar extends StatefulWidget {
  const JournalBalloonBar({
    required this.onPhotoTap,
    required this.onNoteTap,
    super.key,
  });

  final VoidCallback onPhotoTap;
  final VoidCallback onNoteTap;

  static const double height = 60;
  static const double balloonOverhang = 16;

  @override
  State<JournalBalloonBar> createState() => _JournalBalloonBarState();
}

enum _Half { photo, note }

class _JournalBalloonBarState extends State<JournalBalloonBar> {
  static const _radius = 14.0;

  _Half? _hovered;
  _Half? _pressed;

  /// Only one half fills at a time; a press wins over a hover.
  _Half? get _active => _pressed ?? _hovered;

  void _setHovered(_Half half, bool isOn) => setState(() {
    if (isOn) {
      _hovered = half;
    } else if (_hovered == half) {
      _hovered = null;
    }
  });

  void _setPressed(_Half half, bool isOn) => setState(() {
    if (isOn) {
      _pressed = half;
    } else if (_pressed == half) {
      _pressed = null;
    }
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Stack(
      key: const Key('capture-capsule'),
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.balloonBarStart, AppColors.balloonBarEnd],
            ),
            borderRadius: BorderRadius.circular(_radius),
            boxShadow: const [
              BoxShadow(
                color: AppColors.balloonBarShadow,
                blurRadius: 34,
                offset: Offset(0, 16),
              ),
              BoxShadow(
                color: AppColors.balloonBarGlow,
                blurRadius: 22,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_radius),
            child: Stack(
              children: [
                Material(
                  type: MaterialType.transparency,
                  child: SizedBox(
                    height: JournalBalloonBar.height,
                    child: Row(
                      children: [
                        Expanded(
                          child: _BarButton(
                            key: const Key('capture-photo'),
                            icon: _BarIcons.camera,
                            label: l10n.timeline_capturePhoto,
                            semanticLabel: l10n.timeline_addPhotoSemantics,
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(_radius),
                            ),
                            onTap: widget.onPhotoTap,
                            onHover: (isOn) => _setHovered(_Half.photo, isOn),
                            onPressed: (isOn) => _setPressed(_Half.photo, isOn),
                          ),
                        ),
                        const SizedBox(width: _BalloonCutout.width),
                        Expanded(
                          child: _BarButton(
                            key: const Key('capture-note'),
                            icon: _BarIcons.note,
                            label: l10n.timeline_captureNote,
                            semanticLabel: l10n.timeline_addNoteSemantics,
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(_radius),
                            ),
                            onTap: widget.onNoteTap,
                            onHover: (isOn) => _setHovered(_Half.note, isOn),
                            onPressed: (isOn) => _setPressed(_Half.note, isOn),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // The spec's inset top highlight.
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 1,
                  child: IgnorePointer(
                    child: ColoredBox(color: AppColors.balloonBarHighlight),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: -JournalBalloonBar.balloonOverhang,
          left: 0,
          right: 0,
          child: Center(
            child: _BalloonCutout(
              fillsLeft: _active == _Half.photo,
              fillsRight: _active == _Half.note,
            ),
          ),
        ),
      ],
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.icon,
    required this.label,
    required this.semanticLabel,
    required this.borderRadius,
    required this.onTap,
    required this.onHover,
    required this.onPressed,
    super.key,
  });

  final String icon;
  final String label;
  final String semanticLabel;
  final BorderRadius borderRadius;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;
  final ValueChanged<bool> onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        onHover: onHover,
        onHighlightChanged: onPressed,
        borderRadius: borderRadius,
        hoverColor: AppColors.balloonBarHover,
        highlightColor: AppColors.balloonBarPressed,
        splashFactory: NoSplash.splashFactory,
        child: ExcludeSemantics(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.string(icon, width: 24, height: 24),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.balloonBarLabel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The balloon "hole" in the bar (spec § Balloon cut-out): the silhouette in
/// the screen's colour, the balloon outline inside it, and two half fills
/// that fade in while their button is pressed or hovered.
class _BalloonCutout extends StatelessWidget {
  const _BalloonCutout({required this.fillsLeft, required this.fillsRight});

  final bool fillsLeft;
  final bool fillsRight;

  static const double width = 84;
  static const double height = 76;
  static const _fade = Duration(milliseconds: 180);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            children: [
              SvgPicture.string(_BalloonSvg.base, width: width, height: height),
              _half(key: 'left', isOn: fillsLeft, svg: _BalloonSvg.leftFill),
              _half(key: 'right', isOn: fillsRight, svg: _BalloonSvg.rightFill),
            ],
          ),
        ),
      ),
    );
  }

  Widget _half({
    required String key,
    required bool isOn,
    required String svg,
  }) {
    return AnimatedOpacity(
      key: Key('journal-balloon-fill-$key'),
      opacity: isOn ? 1 : 0,
      duration: _fade,
      curve: Curves.ease,
      child: ClipRect(
        clipper: _HalfClipper(isLeft: key == 'left'),
        child: SvgPicture.string(svg, width: width, height: height),
      ),
    );
  }
}

class _HalfClipper extends CustomClipper<Rect> {
  const _HalfClipper({required this.isLeft});

  final bool isLeft;

  @override
  Rect getClip(Size size) => isLeft
      ? Rect.fromLTWH(0, 0, size.width / 2, size.height)
      : Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height);

  @override
  bool shouldReclip(_HalfClipper oldClipper) => oldClipper.isLeft != isLeft;
}

String _hex(Color color) =>
    '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

String _svg(int size, int height, String body) =>
    '<svg xmlns="http://www.w3.org/2000/svg" width="$size" height="$height" '
    'viewBox="0 0 $size $height">$body</svg>';

/// SVG geometry from the spec, on its 84 × 76 frame.
abstract class _BalloonSvg {
  static const _silhouette =
      'M42 1C17 1 4 11 4 25c0 11 9 19 20 33l6 17h24l6-17c11-14 20-22 20-33'
      'C80 11 67 1 42 1z';
  static const _envelope =
      'M42 9C26 9 18 16 18 26c0 9 8 16 15 26h18c7-10 15-17 15-26'
      'C66 16 58 9 42 9z';
  static const _leftStripe = 'M42 9C28 12 25.5 36 37.5 52';
  static const _centreStripe = 'M42 9v43';
  static const _rightStripe = 'M42 9C56 12 58.5 36 46.5 52';
  static const _leftRope = 'M36 52l1 6';
  static const _rightRope = 'M48 52l-1 6';
  static const _basket = '<rect x="36" y="58" width="12" height="8" rx="1.6"';

  static final _hole = _hex(AppColors.background);
  static final _line = _hex(AppColors.balloonBarOutline);

  static String _stroke(String color, String width) =>
      'stroke="$color" stroke-width="$width" '
      'stroke-linecap="round" stroke-linejoin="round"';

  static final String base = _svg(
    84,
    76,
    '<path d="$_silhouette" fill="$_hole"/>'
    '<g fill="none" ${_stroke(_line, '2.2')}>'
    '<path d="$_envelope"/>'
    '<path d="$_leftStripe"/><path d="$_centreStripe"/>'
    '<path d="$_rightStripe"/>'
    '<path d="$_leftRope"/><path d="$_rightRope"/>'
    '$_basket/>'
    '</g>',
  );

  static String _fill({required String stripe, required String rope}) => _svg(
    84,
    76,
    '<path d="$_envelope" fill="$_line" ${_stroke(_line, '2.2')}/>'
    '<g fill="none" ${_stroke(_hole, '2')}>'
    '<path d="$stripe"/><path d="$_centreStripe"/>'
    '</g>'
    '<path d="$rope" fill="none" ${_stroke(_line, '2.2')}/>'
    '$_basket fill="$_line" ${_stroke(_line, '2.2')}/>',
  );

  static final String leftFill = _fill(stripe: _leftStripe, rope: _leftRope);
  static final String rightFill = _fill(
    stripe: _rightStripe,
    rope: _rightRope,
  );
}

/// The two 24 × 24 line icons (spec § Buttons), stroked in the bar's ink.
abstract class _BarIcons {
  static final _ink = _hex(AppColors.background);

  static String _icon(String body) => _svg(
    24,
    24,
    '<g fill="none" stroke="$_ink" stroke-width="2" '
    'stroke-linecap="round" stroke-linejoin="round">$body</g>',
  );

  /// Outline camera: body + lens circle.
  static final String camera = _icon(
    '<path d="M22 18a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V9a2 2 0 0 1 2-2h3l2-3h6'
    'l2 3h3a2 2 0 0 1 2 2z"/>'
    '<circle cx="12" cy="13" r="3.5"/>',
  );

  /// Rounded document (14 × 18, r 3.5) with two lines.
  static final String note = _icon(
    '<rect x="5" y="3" width="14" height="18" rx="3.5"/>'
    '<path d="M9 9.5h6"/><path d="M9 13.5h6"/>',
  );
}
