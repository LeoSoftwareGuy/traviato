import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/twinkle_dot.dart';

/// Four twinkling dots scattered over the guest landing nav/hero area.
/// `docs/design/README.md` § 1.
class StarSpecks extends StatelessWidget {
  const StarSpecks({super.key});

  static const _specks = [
    _Speck(top: 4, left: 210, size: 3, color: AppColors.primary, delayMs: 0),
    _Speck(
      top: 46,
      left: 30,
      size: 2,
      color: Color(0xFFF6C77A),
      delayMs: 900,
    ),
    _Speck(top: 18, left: 130, size: 2, color: Colors.white, delayMs: 1700),
    _Speck(
      top: 60,
      left: 270,
      size: 3,
      color: AppColors.primary,
      delayMs: 2500,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          for (final speck in _specks)
            Positioned(
              top: speck.top,
              left: speck.left,
              child: TwinkleDot(
                size: speck.size,
                color: speck.color,
                delayMs: speck.delayMs,
              ),
            ),
        ],
      ),
    );
  }
}

class _Speck {
  const _Speck({
    required this.top,
    required this.left,
    required this.size,
    required this.color,
    required this.delayMs,
  });

  final double top;
  final double left;
  final double size;
  final Color color;
  final int delayMs;
}
