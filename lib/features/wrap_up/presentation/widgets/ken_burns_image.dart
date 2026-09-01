import 'package:flutter/material.dart';

import '../../../../core/theme/app_motion.dart';

/// Slow infinite-alternate pan/zoom over [child] — the `kenburns` motion
/// token (docs/design/README.md § Motion): scale 1.03→1.18, translate
/// -2%→-2%, 16-18s ease-out. Used for the hero cover and each photo beat.
class KenBurnsImage extends StatefulWidget {
  const KenBurnsImage({required this.child, super.key});

  final Widget child;

  @override
  State<KenBurnsImage> createState() => _KenBurnsImageState();
}

class _KenBurnsImageState extends State<KenBurnsImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.kenBurnsDuration,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.kenBurnsCurve,
    );
    return AnimatedBuilder(
      animation: curved,
      child: widget.child,
      builder: (context, child) {
        final t = curved.value;
        final scale = 1.03 + (1.18 - 1.03) * t;
        final translatePercent = -0.02 * t;
        return ClipRect(
          child: Transform.scale(
            scale: scale,
            child: FractionalTranslation(
              translation: Offset(translatePercent, translatePercent),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
