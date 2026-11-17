import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../../core/l10n/context_l10n.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_motion.dart';
import '../../../../../core/theme/app_typography.dart';

const _actionWidth = 80.0;

/// iOS only (#407, spec §5): swiping a note left reveals an 80px red
/// Delete; tapping it asks with the usual confirm ([onDelete]). Anywhere
/// else, [child] as is.
class SwipeToDelete extends StatefulWidget {
  const SwipeToDelete({
    required this.onDelete,
    required this.borderRadius,
    required this.child,
    super.key,
  });

  final VoidCallback onDelete;
  final BorderRadius borderRadius;
  final Widget child;

  @override
  State<SwipeToDelete> createState() => _SwipeToDeleteState();
}

class _SwipeToDeleteState extends State<SwipeToDelete>
    with SingleTickerProviderStateMixin {
  /// 0 closed … 1 open.
  late final AnimationController _open = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  @override
  void dispose() {
    _open.dispose();
    super.dispose();
  }

  void _snap(bool open) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _open.value = open ? 1 : 0;
    } else {
      _open.animateTo(open ? 1 : 0, curve: AppMotion.noteCurve);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.iOS) return widget.child;
    return GestureDetector(
      onHorizontalDragUpdate: (d) => _open.value =
          (_open.value - d.primaryDelta! / _actionWidth).clamp(0.0, 1.0),
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        _snap(v < -300 || (v <= 300 && _open.value > .5));
      },
      child: AnimatedBuilder(
        animation: _open,
        builder: (context, child) => Stack(
          children: [
            if (_open.value > 0)
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                width: _actionWidth,
                child: GestureDetector(
                  key: const Key('note-swipe-delete'),
                  onTap: () {
                    _snap(false);
                    widget.onDelete();
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: widget.borderRadius,
                    ),
                    child: Text(
                      context.l10n.common_delete,
                      style: AppTypography.timelineLink.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            Transform.translate(
              offset: Offset(-_actionWidth * _open.value, 0),
              child: GestureDetector(
                // A tap on the open card closes it instead of reaching it.
                behavior: HitTestBehavior.translucent,
                onTap: _open.value > 0 ? () => _snap(false) : null,
                child: IgnorePointer(ignoring: _open.value > 0, child: child),
              ),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}
