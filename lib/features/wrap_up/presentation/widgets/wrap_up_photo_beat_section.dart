import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/photo_scrim.dart';
import '../../domain/entities/wrap_up_photo_beat.dart';
import 'ken_burns_image.dart';
import 'wrap_up_photo_image.dart';

/// Chapter two — "What you saw": one full-bleed ken-burns photo per beat,
/// captioned with day/time + place, then the AI narrative below in italic
/// serif (docs/design/README.md § 12).
class WrapUpPhotoBeatSection extends StatelessWidget {
  const WrapUpPhotoBeatSection({
    required this.beats,
    required this.imageUrlForPhoto,
    super.key,
  });

  final List<WrapUpPhotoBeat> beats;
  final String? Function(String photoId) imageUrlForPhoto;

  @override
  Widget build(BuildContext context) {
    if (beats.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CHAPTER TWO · WHAT YOU SAW',
          style: AppTypography.mono.copyWith(color: AppColors.primaryLight),
        ),
        const SizedBox(height: AppSpacing.base),
        for (final beat in beats) ...[
          _PhotoBeat(beat: beat, imageUrl: imageUrlForPhoto(beat.photoId)),
          const SizedBox(height: AppSpacing.xl),
        ],
      ],
    );
  }
}

class _PhotoBeat extends StatelessWidget {
  const _PhotoBeat({required this.beat, required this.imageUrl});

  final WrapUpPhotoBeat beat;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final dayDate = beat.dayDate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: AppRadius.mediaRadius,
          child: SizedBox(
            height: 300,
            child: PhotoScrim(
              image: KenBurnsImage(child: WrapUpPhotoImage(imageUrl: imageUrl)),
              child: dayDate == null
                  ? null
                  : Positioned(
                      left: AppSpacing.base,
                      bottom: AppSpacing.base,
                      child: Text(
                        DateFormat('MMM d').format(dayDate).toUpperCase(),
                        style: AppTypography.mono.copyWith(
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.base),
        Text(beat.narrative, style: AppTypography.pullQuote),
      ],
    );
  }
}
