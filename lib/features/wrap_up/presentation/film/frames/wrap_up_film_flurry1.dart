import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../wrap_up_film_motion.dart';
import '../wrap_up_film_scenes.dart';
import 'wrap_up_film_small_print.dart';

/// Everything the film didn't stop on, dropped onto a table: a 3×5 grid,
/// bottom row landing first so a short trip never leaves a hole at the
/// bottom (docs/design/WRAP_UP_FILM_FLUTTER_SPEC.md § Flurry1). [photoUrls] holds up to
/// 15 entries (the player's own display cap) already sliced from the
/// content's chronological leftover list.
class WrapUpFilmFlurry1 extends StatelessWidget {
  const WrapUpFilmFlurry1({
    required this.t,
    required this.scenes,
    required this.photoUrls,
    super.key,
  });

  final double t;
  final WrapUpFilmScenes scenes;
  final List<String?> photoUrls;

  static const _cols = 3;
  static const _rows = 5;
  static const _colW = 1080 / _cols;
  static const _top = 210.0;
  static final _rowH = (1920 - _top - 340) / _rows;

  /// Bottom row's cells first, then upward — so a short list fills the
  /// bottom of the grid rather than leaving a hole there.
  static const _fillOrder = [12, 13, 14, 9, 10, 11, 6, 7, 8, 3, 4, 5, 0, 1, 2];

  @override
  Widget build(BuildContext context) {
    final a = scenes.flurry1Start;
    final next = scenes.bridge2Start;
    final grp = band(t, a + 0.05, 0.5, next - 1.0, 0.8);
    if (grp <= 0.004 || photoUrls.isEmpty) return const SizedBox.shrink();

    final specs = <_DropCardSpec>[];
    final count = photoUrls.length < 15 ? photoUrls.length : 15;
    for (var k = 0; k < count; k++) {
      final i = _fillOrder[k];
      final r = i ~/ _cols;
      final c = i % _cols;
      final w = _colW * 0.82 + rnd(i, 31) * 46;
      specs.add(
        _DropCardSpec(
          imageUrl: photoUrls[k],
          at: a + 0.15 + (_rows - 1 - r) * 0.46 + c * 0.13 + rnd(i, 34) * 0.12,
          x: c * _colW + (_colW - w) * (0.2 + rnd(i, 32) * 0.6),
          landY: _top + r * _rowH + (rnd(i, 33) - 0.5) * _rowH * 0.3,
          w: w,
          h: w * (0.66 + rnd(i, 35) * 0.20),
          rotZ: (rnd(i, 36) - 0.5) * 18,
        ),
      );
    }
    specs.sort((p, q) => p.landY.compareTo(q.landY));

    return Positioned.fill(
      child: Stack(
        children: [
          for (final spec in specs)
            _WrapUpFilmDropCard(t: t, spec: spec, opacity: grp),
        ],
      ),
    );
  }
}

class _DropCardSpec {
  const _DropCardSpec({
    required this.imageUrl,
    required this.at,
    required this.x,
    required this.landY,
    required this.w,
    required this.h,
    required this.rotZ,
  });

  final String? imageUrl;
  final double at;
  final double x;
  final double landY;
  final double w;
  final double h;
  final double rotZ;
}

class _WrapUpFilmDropCard extends StatelessWidget {
  const _WrapUpFilmDropCard({
    required this.t,
    required this.spec,
    required this.opacity,
  });

  final double t;
  final _DropCardSpec spec;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final fall = Curves.easeOutCubic.transform(
      ((t - spec.at) / 1.05).clamp(0.0, 1.0),
    );
    final settle = Curves.easeOutCubic.transform(
      ((t - (spec.at + 0.3)) / 0.85).clamp(0.0, 1.0),
    );
    final o = (((t - spec.at) / 0.14).clamp(0.0, 1.0) * opacity).clamp(
      0.0,
      1.0,
    );
    if (o <= 0.004) return const SizedBox.shrink();

    final y = mix(spec.landY - 760, spec.landY, fall);
    final tiltDeg = 86 * (1 - settle);

    return Positioned(
      left: 0,
      top: 0,
      child: Transform(
        transform: Matrix4.identity()..translateByDouble(spec.x, y, 0, 1),
        child: RepaintBoundary(
          child: Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.identity()
              ..rotateZ(spec.rotZ * settle * math.pi / 180)
              ..setEntry(3, 2, -1 / 1500)
              ..rotateX(tiltDeg * math.pi / 180),
            child: Opacity(
              opacity: o,
              child: WrapUpFilmSmallPrint(
                imageUrl: spec.imageUrl,
                width: spec.w,
                height: spec.h,
                shadowBlur: 24 + 44 * settle,
                shadowOffsetY: 10 + 26 * settle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
