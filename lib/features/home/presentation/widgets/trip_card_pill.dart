import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

/// Small rounded badge overlaid on a trip cover photo (vibe chip, countdown,
/// Recap badge, duration badge).
class TripCardPill extends StatelessWidget {
  const TripCardPill({required this.color, required this.child, super.key});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.pillRadius,
      ),
      child: child,
    );
  }
}
