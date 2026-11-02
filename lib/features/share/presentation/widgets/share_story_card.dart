import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../trip/presentation/widgets/trip_cover_image.dart';
import 'share_qr_code.dart';

/// The Instagram story card (#311, design 1d), laid out at its export size
/// — 1080×1920 — and shown scaled down in a [FittedBox]. The design's
/// 300pt preview × 3.6 gives every size here.
class ShareStoryCard extends StatelessWidget {
  const ShareStoryCard({
    required this.title,
    required this.eyebrow,
    required this.dates,
    required this.coverPath,
    required this.url,
    super.key,
  });

  static const width = 1080.0;
  static const height = 1920.0;

  /// ≥ 200px in the export so it scans off another screen.
  static const qrSize = 240.0;

  final String title;
  final String eyebrow;
  final String? dates;
  final String? coverPath;
  final String url;

  @override
  Widget build(BuildContext context) {
    // Its own Material, so the exported PNG never depends on where the
    // card sits (no debug text style without one).
    return Material(
      type: MaterialType.transparency,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            TripCoverImage(imagePath: coverPath),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppColors.tint(AppColors.background, .95),
                    AppColors.tint(AppColors.background, .5),
                    AppColors.tint(AppColors.background, 0),
                    AppColors.tint(AppColors.background, .35),
                  ],
                  stops: const [0, .38, .6, 1],
                ),
              ),
            ),
            const Positioned(top: 86, left: 72, right: 72, child: _TopRow()),
            Positioned(
              left: 72,
              right: 72,
              bottom: 96,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: _TitleBlock(
                      title: title,
                      eyebrow: eyebrow,
                      dates: dates,
                    ),
                  ),
                  const SizedBox(width: 48),
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary,
                      borderRadius: BorderRadius.circular(43),
                    ),
                    child: ShareQrCode(url: url, size: qrSize),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopRow extends StatelessWidget {
  const _TopRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: '${AppConstants.appName} '),
              TextSpan(
                text: '✦',
                style: AppTypography.serif(
                  fontSize: 60,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          style: AppTypography.serif(
            fontSize: 72,
            fontStyle: FontStyle.italic,
            color: AppColors.textOnPhoto,
          ),
        ),
        const Spacer(),
        Flexible(
          flex: 3,
          child: Text(
            context.l10n.story_badge.toUpperCase(),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.mono.copyWith(
              fontSize: 32,
              letterSpacing: AppTypography.eyebrowTracking(32),
              color: AppColors.tint(AppColors.textOnPhoto, .8),
            ),
          ),
        ),
      ],
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({
    required this.title,
    required this.eyebrow,
    required this.dates,
  });

  final String title;
  final String eyebrow;
  final String? dates;

  @override
  Widget build(BuildContext context) {
    final dates = this.dates;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (eyebrow.isNotEmpty)
          Text(
            eyebrow.toUpperCase(),
            maxLines: 2,
            style: AppTypography.mono.copyWith(
              fontSize: 36,
              letterSpacing: AppTypography.eyebrowTracking(36),
              color: AppColors.primaryLight,
            ),
          ),
        const SizedBox(height: 24),
        Text(
          title,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.serif(
            fontSize: 108,
            height: 1.08,
            color: AppColors.textOnPhoto,
          ),
        ),
        if (dates != null) ...[
          const SizedBox(height: 28),
          Text(
            dates,
            style: AppTypography.mono.copyWith(
              fontSize: 36,
              letterSpacing: AppTypography.eyebrowTracking(36),
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
