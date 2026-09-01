import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

const _messages = [
  'Reliving your trip…',
  'Finding the best moments…',
  'Writing the story…',
  'Almost ready…',
];
const _messageInterval = Duration(seconds: 3);

/// First-open generation can take real seconds (a live Anthropic call) —
/// this is a reassuring wait, not a bare spinner (issue #94 AC). No fake
/// progress bar since the real duration is unknown.
class WrapUpGeneratingView extends StatefulWidget {
  const WrapUpGeneratingView({super.key});

  @override
  State<WrapUpGeneratingView> createState() => _WrapUpGeneratingViewState();
}

class _WrapUpGeneratingViewState extends State<WrapUpGeneratingView> {
  var _messageIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_messageInterval, (_) {
      setState(() => _messageIndex = (_messageIndex + 1) % _messages.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '✦',
              style: TextStyle(fontSize: 32, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            AnimatedSwitcher(
              duration: AppMotion.riseInDuration,
              child: Text(
                _messages[_messageIndex],
                key: ValueKey(_messageIndex),
                style: AppTypography.pullQuote,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
