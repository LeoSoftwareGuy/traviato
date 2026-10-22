import 'package:flutter/material.dart';

import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../kept_memory_labels.dart';

/// "▶ Play the film 1:19" and "Slideshow" under the hero (#279, spec
/// § 3.2). [filmDuration] shows once the film's schedule is known;
/// [onSlideshow] null (no photos) disables the slideshow.
class KeptMemoryActions extends StatelessWidget {
  const KeptMemoryActions({
    required this.onPlayFilm,
    required this.onSlideshow,
    this.filmDuration,
    super.key,
  });

  final VoidCallback onPlayFilm;
  final VoidCallback? onSlideshow;
  final Duration? filmDuration;

  static const _radius = BorderRadius.all(Radius.circular(16));

  @override
  Widget build(BuildContext context) {
    final duration = filmDuration;
    final labelStyle = AppTypography.buttonLabel.copyWith(
      fontSize: 14,
      color: AppColors.background,
    );
    return Row(
      children: [
        Expanded(
          child: Material(
            color: AppColors.primary,
            borderRadius: _radius,
            child: InkWell(
              key: const Key('kept-memory-play-film'),
              borderRadius: _radius,
              onTap: onPlayFilm,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('▶', style: labelStyle.copyWith(fontSize: 11)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        context.l10n.keptMemory_playFilm,
                        style: labelStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (duration != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        KeptMemoryLabels.filmDuration(duration),
                        style: AppTypography.mono.copyWith(
                          fontSize: 10.5,
                          letterSpacing: 0,
                          color: AppColors.tint(AppColors.background, .7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: _radius,
            side: BorderSide(
              color: AppColors.tint(AppColors.textSecondary, .28),
            ),
          ),
          child: InkWell(
            key: const Key('kept-memory-slideshow'),
            borderRadius: _radius,
            onTap: onSlideshow,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Text(
                context.l10n.keptMemory_slideshow,
                style: AppTypography.buttonLabel.copyWith(
                  fontSize: 13,
                  color: onSlideshow == null
                      ? AppColors.textTertiary
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
