import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/l10n/l10n_dates.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Markers on a photo tile of the day timeline (#401).
enum _FilmBadgeKind { autoPicked, yourPick, leftOut }

/// A thumb's film marker (#294): "▸" when the film chose it, "▸ Your pick"
/// for Always, "Left out" for Leave out.
class FilmBadge extends StatelessWidget {
  const FilmBadge.autoPicked({this.maxWidth = 66, super.key})
    : _kind = _FilmBadgeKind.autoPicked;
  const FilmBadge.yourPick({this.maxWidth = 66, super.key})
    : _kind = _FilmBadgeKind.yourPick;
  const FilmBadge.leftOut({this.maxWidth = 66, super.key})
    : _kind = _FilmBadgeKind.leftOut;

  final _FilmBadgeKind _kind;

  /// The tile's width less its 7px inset on each side.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (label, foreground, background, border) = switch (_kind) {
      _FilmBadgeKind.autoPicked => (
        '▸',
        AppColors.primaryLight,
        AppColors.tint(AppColors.filmBackground, .6),
        AppColors.tint(AppColors.primary, .45),
      ),
      _FilmBadgeKind.yourPick => (
        '▸ ${l10n.film_badgeYourPick}',
        AppColors.background,
        AppColors.primary,
        AppColors.primary,
      ),
      _FilmBadgeKind.leftOut => (
        l10n.film_badgeLeftOut,
        AppColors.textSecondary,
        AppColors.tint(AppColors.filmBackground, .7),
        AppColors.tint(AppColors.textSecondary, .3),
      ),
    };
    return Container(
      key: Key('journal-photo-film-badge-${_kind.name}'),
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.caption.copyWith(
          fontSize: 9,
          height: 1.2,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: foreground,
        ),
      ),
    );
  }
}

/// Frosted time label on a tile of a photo group (#149, #401).
class PhotoTimePill extends StatelessWidget {
  const PhotoTimePill({required this.takenAt, required this.use24h, super.key});

  /// A wall-clock time already on the photo's place clock (#461:
  /// `PhotoEntity.localTime`).
  final DateTime takenAt;

  /// `HH:mm` or `h:mm a`, following the phone.
  final bool use24h;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(AppSpacing.xs)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: ColoredBox(
          color: AppColors.tint(AppColors.background50, .7),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Text(
              L10nDates.clock(
                context.l10n.localeName,
                use24h: use24h,
              ).format(takenAt),
              key: const Key('journal-photo-time-pill'),
              maxLines: 1,
              style: AppTypography.caption.copyWith(
                fontSize: 9,
                height: 1.2,
                letterSpacing: 0,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
