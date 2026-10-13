import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// Pages are bound on the left: square at the spine, rounded on the right.
const notePageRadius = BorderRadius.horizontal(right: Radius.circular(16));

/// The shadow where the page curves into the binding — 28px on the left
/// edge of both the writing page and the title page.
class SpineGutter extends StatelessWidget {
  const SpineGutter({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      top: 0,
      bottom: 0,
      width: 28,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.tint(AppColors.paperInk, .22),
                AppColors.tint(AppColors.paperInk, 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A non-interactive dark gradient laid over a page during the turn.
/// [opacity] is driven by the turn's controller.
class NotePageShade extends StatelessWidget {
  const NotePageShade({
    required this.opacity,
    required this.colors,
    this.reversed = false,
    super.key,
  });

  /// Writing page: dark at the spine, lighter outward.
  NotePageShade.writing({required double opacity, Key? key})
    : this(
        opacity: opacity,
        colors: [
          AppColors.tint(AppColors.filmBackground, .6),
          AppColors.tint(AppColors.filmBackground, .2),
        ],
        key: key,
      );

  /// Turning page front: darker at the outer edge as it lifts from the
  /// light.
  NotePageShade.front({required double opacity, Key? key})
    : this(
        opacity: opacity,
        colors: [
          AppColors.tint(AppColors.filmBackground, .5),
          AppColors.tint(AppColors.filmBackground, .1),
        ],
        reversed: true,
        key: key,
      );

  final double opacity;
  final List<Color> colors;

  /// Gradient runs right → left instead of left → right.
  final bool reversed;

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: notePageRadius,
              gradient: LinearGradient(
                begin: reversed ? Alignment.centerRight : Alignment.centerLeft,
                end: reversed ? Alignment.centerLeft : Alignment.centerRight,
                colors: colors,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
