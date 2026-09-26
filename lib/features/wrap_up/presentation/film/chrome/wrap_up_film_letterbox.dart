import 'package:flutter/material.dart';

import '../wrap_up_film_motion.dart';

/// Black bars top and bottom, growing in shortly after the Dust frame opens
/// (docs/design/WRAP_UP_FILM_FLUTTER_SPEC.md §6) — drawn above everything else.
class WrapUpFilmLetterbox extends StatelessWidget {
  const WrapUpFilmLetterbox({required this.t, super.key});

  final double t;

  @override
  Widget build(BuildContext context) {
    final height = swell(t, 3.0, 1.6, 0, 96);
    if (height <= 0.001) return const SizedBox.shrink();
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: height,
            child: const ColoredBox(color: Colors.black),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: height,
            child: const ColoredBox(color: Colors.black),
          ),
        ],
      ),
    );
  }
}
