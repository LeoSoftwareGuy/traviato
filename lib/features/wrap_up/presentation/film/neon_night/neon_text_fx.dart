import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'neon_random.dart';
import 'neon_tokens.dart';
import 'neon_type.dart';

/// Lays out [text] on one line in [style] (no wrapping).
TextPainter neonLayout(String text, TextStyle style) => TextPainter(
  text: TextSpan(text: text, style: style),
  textDirection: TextDirection.ltr,
  maxLines: 1,
)..layout();

/// Paints [draw] through one layer at [alpha], blurred by [sigma] (a
/// Gaussian's standard deviation; CSS blur radius ÷ 2) when given.
void neonLayer(
  Canvas canvas,
  Rect bounds,
  double alpha,
  void Function() draw, {
  double sigma = 0,
}) {
  if (alpha <= 0.002) return;
  if (alpha >= 0.999 && sigma <= 0.01) {
    draw();
    return;
  }
  final paint = Paint()..color = Color.fromRGBO(0, 0, 0, alpha.clamp(0, 1));
  if (sigma > 0.01) {
    paint.imageFilter = ui.ImageFilter.blur(
      sigmaX: sigma,
      sigmaY: sigma,
      tileMode: TileMode.decal,
    );
  }
  canvas.saveLayer(bounds.inflate(sigma * 3 + 2), paint);
  draw();
  canvas.restore();
}

/// A neon-tube title (§3.1): the letters' outline as a [color] tube with
/// two glows (CSS `drop-shadow 0 0 6g px, 0 0 22g px`: σ 3g and 11g) and
/// a [core] stroke over it at 35 % of the width.
class NeonTubeText {
  factory NeonTubeText(
    String text, {
    required double size,
    required double maxWidth,
    required double stroke,
    required Color color,
    int weight = 800,
    Color core = NeonColors.white,
    double coreAlpha = 0.9,
  }) {
    TextPainter layout(double size, Color c, double width, double alpha) =>
        neonLayout(
          text,
          NeonType.display(
            size,
            weight: weight,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = width
              ..strokeJoin = StrokeJoin.round
              ..color = c.withValues(alpha: alpha),
          ),
        );
    // The spec's fit counts characters; a wider face (Cyrillic falls back
    // to another font) is also held to the measured width.
    var fitted = size;
    final probe = layout(size, color, stroke, 1);
    if (probe.width > maxWidth) fitted = size * maxWidth / probe.width;
    probe.dispose();
    return NeonTubeText._(
      fitted,
      layout(fitted, color, stroke, 1),
      layout(fitted, core, stroke * 0.35, coreAlpha),
    );
  }

  NeonTubeText._(this.fontSize, this._outline, this._core);

  final double fontSize;
  final TextPainter _outline;
  final TextPainter _core;

  Size get size => _outline.size;

  /// Paints it with its top-left at [offset].
  void paint(Canvas canvas, Offset offset, {double alpha = 1, double g = 1}) {
    if (alpha <= 0.002) return;
    final bounds = offset & size;
    for (final sigma in [11 * g, 3 * g]) {
      neonLayer(
        canvas,
        bounds,
        alpha,
        () => _outline.paint(canvas, offset),
        sigma: sigma,
      );
    }
    neonLayer(canvas, bounds, alpha, () {
      _outline.paint(canvas, offset);
      _core.paint(canvas, offset);
    });
  }

  void dispose() {
    _outline.dispose();
    _core.dispose();
  }
}

/// Filled text that can light up (§5.2's done rows): [plain] while off;
/// lit, a [lit] fill over glows in [glowColor] (CSS `text-shadow 0 0 2px,
/// 0 0 14px, 0 0 34px`: σ 1, 7, 17).
class NeonGlowText {
  NeonGlowText(
    String text,
    TextStyle style, {
    required Color plain,
    required Color lit,
    required Color glowColor,
  }) : _plain = neonLayout(text, style.copyWith(color: plain)),
       _lit = neonLayout(text, style.copyWith(color: lit)),
       _glow = neonLayout(text, style.copyWith(color: glowColor));

  final TextPainter _plain;
  final TextPainter _lit;
  final TextPainter _glow;

  static const glowSigmas = [17.0, 7.0, 1.0];

  Size get size => _plain.size;

  double get baseline =>
      _plain.computeDistanceToActualBaseline(TextBaseline.alphabetic);

  /// Paints it at [offset]: [on] crossfades plain → lit (0–1), [flare]
  /// (0–1) adds one more wide glow.
  void paint(
    Canvas canvas,
    Offset offset, {
    double alpha = 1,
    double on = 0,
    double flare = 0,
  }) {
    final bounds = offset & size;
    if (on < 1) {
      neonLayer(
        canvas,
        bounds,
        alpha * (1 - on),
        () => _plain.paint(canvas, offset),
      );
    }
    if (on <= 0) return;
    for (final sigma in glowSigmas) {
      neonLayer(
        canvas,
        bounds,
        alpha * on,
        () => _glow.paint(canvas, offset),
        sigma: sigma,
      );
    }
    if (flare > 0.002) {
      neonLayer(
        canvas,
        bounds,
        alpha * on * flare,
        () => _glow.paint(canvas, offset),
        sigma: glowSigmas.first,
      );
    }
    neonLayer(canvas, bounds, alpha * on, () => _lit.paint(canvas, offset));
  }

  void dispose() {
    _plain.dispose();
    _lit.dispose();
    _glow.dispose();
  }
}

/// The glitch-in (§3.5): for 0.5 s after [at], a base copy jittering and
/// three horizontal slices torn sideways, re-drawn every frame from
/// `rng(seed × 131 + f)`; then still. Reduced flashing: a 0.3 s fade.
///
/// [paintAt] draws the text shifted by `dx` at an alpha.
void neonGlitchIn(
  Canvas canvas, {
  required double t,
  required double at,
  required int seed,
  required Rect bounds,
  required bool reducedFlashing,
  required void Function(double dx, double alpha) paintAt,
  double alpha = 1,
}) {
  final dt = t - at;
  if (dt < 0 || alpha <= 0.002) return;
  if (reducedFlashing) {
    paintAt(0, alpha * (dt / 0.3).clamp(0.0, 1.0));
    return;
  }
  if (dt >= glitchDuration) {
    paintAt(0, alpha);
    return;
  }
  final f = (dt * 30 + 1e-9).floor();
  final p = dt / glitchDuration;
  final r = NeonRandom(NeonSeeds.glitch(seed, f));
  final base = r.next();
  final baseAlpha = f < 3 ? (base > 0.35 ? 1.0 : 0.25) : 1.0;
  paintAt((base - 0.5) * 60 * (1 - p), alpha * baseAlpha);
  for (var i = 0; i < 3; i++) {
    final top = r.next() * 0.80;
    final height = 0.06 + r.next() * 0.18;
    final dx = (r.next() - 0.5) * 120 * (1 - p);
    canvas
      ..save()
      ..clipRect(
        Rect.fromLTWH(
          bounds.left - 400,
          bounds.top + bounds.height * top,
          bounds.width + 800,
          bounds.height * height,
        ),
      );
    paintAt(dx, alpha);
    canvas.restore();
  }
}

/// How long a glitch-in tears, s.
const glitchDuration = 0.5;
