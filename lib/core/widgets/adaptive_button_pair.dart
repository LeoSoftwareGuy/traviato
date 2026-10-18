import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Two buttons side by side, unless either label won't fit on one line at
/// half width — then they stack, **primary on top** (localization spec 4t,
/// "Paired buttons", frame 4b). Measured with [labelStyle], the style the
/// buttons render their label in, plus [labelPadding] for the button's own
/// horizontal padding (#241).
class AdaptiveButtonPair extends StatelessWidget {
  const AdaptiveButtonPair({
    required this.primary,
    required this.secondary,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.labelStyle,
    this.primaryFirstInRow = false,
    this.gap = AppSpacing.sm,
    this.labelPadding = 32,
    super.key,
  });

  final Widget primary;
  final Widget secondary;
  final String primaryLabel;
  final String secondaryLabel;
  final TextStyle labelStyle;

  /// Side-by-side order; most pairs put the primary action on the right.
  final bool primaryFirstInRow;
  final double gap;
  final double labelPadding;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final half = (constraints.maxWidth - gap) / 2 - labelPadding;
        double widthOf(String label) {
          final painter = TextPainter(
            text: TextSpan(text: label, style: labelStyle),
            maxLines: 1,
            textDirection: direction,
            textScaler: scaler,
          )..layout();
          final width = painter.width;
          painter.dispose();
          return width;
        }

        final stack =
            constraints.maxWidth.isFinite &&
            (widthOf(primaryLabel) > half || widthOf(secondaryLabel) > half);
        if (stack) {
          return Column(
            key: const Key('adaptive-button-pair-stacked'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              primary,
              SizedBox(height: gap),
              secondary,
            ],
          );
        }
        final first = primaryFirstInRow ? primary : secondary;
        final second = primaryFirstInRow ? secondary : primary;
        return Row(
          key: const Key('adaptive-button-pair-row'),
          children: [
            Expanded(child: first),
            SizedBox(width: gap),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}
