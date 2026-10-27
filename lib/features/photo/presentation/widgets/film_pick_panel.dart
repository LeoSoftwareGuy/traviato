import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/film_pick.dart';

const _segmentDuration = Duration(milliseconds: 150);

/// "▸ IN THE FILM" panel under the photo viewer's photo (#294,
/// docs/design/WRAP_UP_PHOTO_PICK_SPEC.md Phase 2): a hint for the current
/// photo and an Auto · Always · Leave out segmented control. Stateless —
/// the viewer passes the current pick and saves the change.
class FilmPickPanel extends StatelessWidget {
  const FilmPickPanel({
    required this.pick,
    required this.isAutoPicked,
    required this.onChanged,
    super.key,
  });

  final FilmPick pick;

  /// Whether the film gives this photo a main moment while it's on Auto.
  final bool isAutoPicked;
  final ValueChanged<FilmPick> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (hint, hintColor) = _hint(l10n);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          key: const Key('film-pick-panel'),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.tint(AppColors.filmBackground, .62),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.tint(AppColors.textOnPhoto, .1),
            ),
          ),
          // The panel claims horizontal drags so the segments are easy to
          // hit; swiping between photos works everywhere else.
          child: GestureDetector(
            onHorizontalDragStart: (_) {},
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '▸ ${l10n.film_inTheFilm}'.toUpperCase(),
                        style: AppTypography.mono.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hint,
                          key: const Key('film-pick-hint'),
                          textAlign: TextAlign.right,
                          style: AppTypography.caption.copyWith(
                            fontSize: 10.5,
                            letterSpacing: 0,
                            color: hintColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _Segments(pick: pick, onChanged: onChanged),
              ],
            ),
          ),
        ),
      ),
    );
  }

  (String, Color) _hint(AppLocalizations l10n) => switch (pick) {
    FilmPick.auto when isAutoPicked => (
      l10n.film_hintAutoPicked,
      AppColors.primaryLight,
    ),
    FilmPick.auto => (l10n.film_hintAutoNot, AppColors.textTertiary),
    FilmPick.always => (l10n.film_hintAlways, AppColors.primaryLight),
    FilmPick.never => (l10n.film_hintNever, AppColors.textTertiary),
  };
}

class _Segments extends StatelessWidget {
  const _Segments({required this.pick, required this.onChanged});

  final FilmPick pick;
  final ValueChanged<FilmPick> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.tint(AppColors.textOnPhoto, .06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final (index, option) in FilmPick.values.indexed) ...[
            if (index > 0) const SizedBox(width: 3),
            Expanded(
              child: _Segment(
                label: switch (option) {
                  FilmPick.auto => l10n.film_pickAuto,
                  FilmPick.always => l10n.film_pickAlways,
                  FilmPick.never => l10n.film_pickNever,
                },
                option: option,
                isSelected: option == pick,
                onTap: () {
                  if (option != pick) onChanged(option);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final FilmPick option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isLeaveOut = option == FilmPick.never;
    final background = !isSelected
        ? Colors.transparent
        : isLeaveOut
        ? AppColors.tint(AppColors.textSecondary, .22)
        : AppColors.primary;
    final foreground = !isSelected
        ? AppColors.textSecondary
        : isLeaveOut
        ? AppColors.textPrimary
        : AppColors.background;
    return Semantics(
      button: true,
      selected: isSelected,
      child: GestureDetector(
        key: Key('film-pick-${option.name}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // 38 tall, plus the track's padding: a ≥44 hit area.
        child: AnimatedContainer(
          duration: _segmentDuration,
          constraints: const BoxConstraints(minHeight: 38),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(9),
          ),
          // Never truncates: a long (RU) label shrinks instead.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: AppTypography.chipLabel.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
