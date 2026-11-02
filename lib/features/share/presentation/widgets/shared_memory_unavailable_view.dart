import 'package:flutter/material.dart';

import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/dashed_rrect_border.dart';

/// A link that is unknown, turned off, or whose memory was deleted (#310,
/// design 2d) — one screen for all of them.
class SharedMemoryUnavailableView extends StatelessWidget {
  const SharedMemoryUnavailableView({
    required this.onClose,
    required this.onStartOwn,
    super.key,
  });

  final VoidCallback onClose;
  final VoidCallback onStartOwn;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final titleStyle = AppTypography.serif(
      fontSize: 30,
      height: 1.12,
      color: AppColors.textPrimary,
    );
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Material(
                color: AppColors.tint(AppColors.textPrimary, .08),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  key: const Key('shared-memory-close'),
                  onTap: onClose,
                  child: SizedBox.square(
                    dimension: 38,
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: AppColors.textPrimary,
                      semanticLabel: MaterialLocalizations.of(
                        context,
                      ).closeButtonTooltip,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(34, 40, 34, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DashedRRectBorder(
                    color: AppColors.tint(AppColors.textSecondary, .3),
                    strokeWidth: 1.5,
                    child: SizedBox(
                      width: 96,
                      height: 120,
                      child: Center(
                        child: Text(
                          '✦',
                          style: AppTypography.serif(
                            fontSize: 28,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.share_unavailable_eyebrow.toUpperCase(),
                    style: AppTypography.mono.copyWith(
                      color: AppColors.textTertiary,
                      letterSpacing: AppTypography.eyebrowTracking(9.5),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text.rich(
                    TextSpan(
                      text: l10n.share_unavailable_title,
                      children: [
                        TextSpan(
                          text: l10n.share_unavailable_titleEmphasis,
                          style: titleStyle.copyWith(
                            fontStyle: FontStyle.italic,
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ],
                    ),
                    style: titleStyle,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.share_unavailable_body,
                    style: AppTypography.caption.copyWith(
                      fontSize: 13,
                      height: 1.6,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
            child: ElevatedButton(
              key: const Key('shared-memory-start-own'),
              onPressed: onStartOwn,
              child: Text(l10n.share_startOwn),
            ),
          ),
        ],
      ),
    );
  }
}
