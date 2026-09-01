import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/wrap_up_route_chapter.dart';
import 'wrap_up_route_path_painter.dart';

/// Chapter one — "The route": an illustrated (non-geographic) path panel.
/// Renders the same way whether the trip has one stop or several
/// (docs/design/README.md § 12).
class WrapUpRouteChapterSection extends StatefulWidget {
  const WrapUpRouteChapterSection({required this.chapter, super.key});

  final WrapUpRouteChapter chapter;

  @override
  State<WrapUpRouteChapterSection> createState() =>
      _WrapUpRouteChapterSectionState();
}

class _WrapUpRouteChapterSectionState extends State<WrapUpRouteChapterSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.drawRouteDuration,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chapter = widget.chapter;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CHAPTER ONE · THE ROUTE',
          style: AppTypography.mono.copyWith(color: AppColors.primaryLight),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(chapter.intro, style: AppTypography.pullQuote),
        const SizedBox(height: AppSpacing.base),
        Container(
          height: 260,
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            borderRadius: AppRadius.mediaRadius,
            gradient: AppGradients.screenGroundVertical(
              topColor: AppGradients.groundTopPlanChecklistExpenses,
              stop: 0,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              final points = layoutRoutePoints(
                chapter.stops.length,
                size,
              );
              return AnimatedBuilder(
                animation: CurvedAnimation(
                  parent: _controller,
                  curve: AppMotion.drawRouteCurve,
                ),
                builder: (context, _) => Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: WrapUpRoutePathPainter(
                          points: points,
                          progress: _controller.value,
                        ),
                      ),
                    ),
                    for (var i = 0; i < points.length; i++)
                      _PlaceLabel(
                        point: points[i],
                        text: chapter.stops[i].placeText,
                        emphasize: i == points.length - 1,
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (chapter.totalKm != null) ...[
              _StatValue(
                value: NumberFormat.decimalPattern().format(
                  chapter.totalKm!.round(),
                ),
                unit: 'KM',
              ),
              const SizedBox(width: AppSpacing.lg),
            ],
            _StatValue(value: '${chapter.stopCount}', unit: 'STOPS'),
          ],
        ),
      ],
    );
  }
}

class _PlaceLabel extends StatelessWidget {
  const _PlaceLabel({
    required this.point,
    required this.text,
    required this.emphasize,
  });

  final Offset point;
  final String text;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: (point.dx - 40).clamp(0, double.infinity),
      top: point.dy + 8,
      width: 80,
      child: Text(
        text.toUpperCase(),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.mono.copyWith(
          color: emphasize ? AppColors.textOnPhoto : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _StatValue extends StatelessWidget {
  const _StatValue({required this.value, required this.unit});

  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: AppTypography.bigNumber.copyWith(fontSize: 15)),
        const SizedBox(width: AppSpacing.xs),
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(unit, style: AppTypography.mono),
        ),
      ],
    );
  }
}
