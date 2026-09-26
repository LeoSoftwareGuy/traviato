import 'package:flutter/material.dart';

/// Always-on radial vignette (docs/design/WRAP_UP_FILM_FLUTTER_SPEC.md §6) — darkens
/// the edges of the canvas so photos and text read consistently regardless
/// of what's behind them.
class WrapUpFilmVignette extends StatelessWidget {
  const WrapUpFilmVignette({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.12),
            radius: 0.85,
            colors: [
              Color(0x00000000),
              Color(0x9407091A),
              Color(0xEB07091A),
            ],
            stops: [0.32, 0.76, 1.0],
          ),
        ),
      ),
    );
  }
}
