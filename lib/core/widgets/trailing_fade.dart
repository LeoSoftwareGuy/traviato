import 'package:flutter/material.dart';

/// Fades the trailing [width] of a horizontally scrolling row, so a chip
/// cut off by the edge reads as "more this way" (localization spec 4t,
/// occasion/category chips, #241).
class TrailingFade extends StatelessWidget {
  const TrailingFade({required this.child, this.width = 16, super.key});

  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) {
        final stop = bounds.width <= 0
            ? 1.0
            : (1 - width / bounds.width).clamp(0.0, 1.0);
        return LinearGradient(
          begin: rtl ? Alignment.centerRight : Alignment.centerLeft,
          end: rtl ? Alignment.centerLeft : Alignment.centerRight,
          colors: const [Colors.black, Colors.black, Colors.transparent],
          stops: [0, stop, 1],
        ).createShader(bounds);
      },
      child: child,
    );
  }
}
