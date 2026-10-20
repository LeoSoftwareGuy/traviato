import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../trip/domain/entities/trip_card_entity.dart';
import '../../../trip/presentation/widgets/trip_cover_image.dart';
import '../../domain/entities/star_summary.dart';

/// One "By memory" row: cover · title + "AUG 2026 · KEPT" · ✦sum. The
/// "Earlier memories" row gets a neutral ✦ tile and isn't tappable.
class StarMemoryRow extends StatelessWidget {
  const StarMemoryRow({required this.total, this.onTap, super.key});

  final StarMemoryTotal total;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final trip = total.trip;
    return Material(
      color: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.cardRadius,
        side: BorderSide(color: AppColors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: trip == null ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: AppRadius.badgeRadius,
                child: SizedBox.square(
                  dimension: 42,
                  child: trip == null
                      ? const _EarlierTile()
                      : TripCoverImage(imagePath: trip.coverImagePath),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip?.name ?? context.l10n.stars_earlierMemories,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.serif(
                        fontSize: 15,
                        height: 1.25,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (trip != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        _meta(context.l10n, trip).toUpperCase(),
                        style: AppTypography.mono.copyWith(letterSpacing: 0),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '✦${total.points}',
                style: AppTypography.bodyEmphasis.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Month/year of the start date (creation date when undated), plus a
  /// status where it says something: kept, under way, or still to come.
  static String _meta(AppLocalizations l10n, TripCardEntity trip) {
    final month = DateFormat(
      'LLL y',
      l10n.localeName,
    ).format(trip.startDate ?? trip.createdAt.toLocal());
    final status = trip.isKeptForever
        ? l10n.stars_statusKept
        : switch (trip.status) {
            TripStatus.current => l10n.stars_statusNow,
            TripStatus.upcoming => l10n.stars_statusUpcoming,
            TripStatus.finished || TripStatus.undated => null,
          };
    return status == null ? month : '$month · $status';
  }
}

class _EarlierTile extends StatelessWidget {
  const _EarlierTile();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.hairline,
      child: Center(
        child: Text(
          '✦',
          style: AppTypography.bodyEmphasis.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}
