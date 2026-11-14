import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'neon_ambient.dart';
import 'neon_beat.dart';
import 'neon_chapter_card_painter.dart';
import 'neon_eases.dart';
import 'neon_heart.dart';
import 'neon_night_scene_spec.dart';
import 'neon_night_story.dart';
import 'neon_night_texts.dart';
import 'neon_night_timeline.dart';
import 'neon_photo.dart';
import 'neon_text_fx.dart';
import 'neon_tokens.dart';

/// The Finale's heart of photos (#363, NEON_NIGHT_SPEC.md §5.8), in the
/// scene layer: tiles popping in, the outline drawing itself, the
/// heartbeat and the glow-up; in the Ending it shrinks to 0.85 and fades
/// (§5.9). Everything is a pure function of `t`.
class NnHeartPainter {
  NnHeartPainter({
    required this.timeline,
    required this.story,
    required this.photos,
    required this.reducedFlashing,
  }) : heart = NnHeart(photos: story.allPhotos.length),
       _ids = [for (final photo in story.allPhotos) photo.id];

  final NeonNightTimeline timeline;
  final NeonNightStory story;
  final NeonPhotoSource photos;
  final bool reducedFlashing;
  final NnHeart heart;
  final List<String> _ids;

  NeonBeat get beat => timeline.beat;

  /// Every frame flare is softened when reduced (§6).
  double get _flareScale => reducedFlashing ? 0.4 : 1;

  /// The Ending's fade: 0 → 1 over its first 1.5 beats.
  double endingFade(double t) =>
      ((t - timeline.endingCue) / beat.beatToSec(1.5)).clamp(0.0, 1.0);

  void paint(Canvas canvas, double t) {
    final finale = timeline.finaleCue;
    final lb = beat.secToBeat(t - finale);
    final out = endingFade(t);
    final alpha = 1 - out;
    if (alpha <= 0) return;
    final scale =
        NnHeart.beatScale(t, finale, beat, reducedFlashing: reducedFlashing) *
        (1 - 0.15 * NeonEases.enter(out));
    final glowUp = NeonBeat.flare(t, finale + beat.beatToSec(8), 0.5);

    canvas
      ..save()
      ..translate(NnHeart.centre.dx, NnHeart.centre.dy)
      ..scale(scale)
      ..translate(-NnHeart.centre.dx, -NnHeart.centre.dy);
    _tiles(canvas, t, lb, alpha, glowUp);
    _outline(canvas, lb, alpha, glowUp);
    canvas.restore();
  }

  void _tiles(
    Canvas canvas,
    double t,
    double lb,
    double alpha,
    double glowUp,
  ) {
    // The glow-up: + 0.6 flare, then + 0.15 held.
    final lift = lb < 8 ? 0.0 : 0.15 + 0.6 * glowUp * _flareScale;
    for (var k = 0; k < heart.cells.length; k++) {
      final (s, degrees) = heart.popAt(lb, k, beat);
      if (s <= 0) continue;
      final cell = heart.cells[k];
      final pop = NeonBeat.flare(
        t,
        timeline.finaleCue + beat.beatToSec(heart.popBeat(k)),
        0.3,
      );
      final color = heart.tileColor(k);
      final rrect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: NnHeart.tileSize,
          height: NnHeart.tileSize,
        ),
        const Radius.circular(NnHeart.tileRadius),
      );
      canvas
        ..save()
        ..translate(cell.center.dx, cell.center.dy)
        ..rotate(degrees * math.pi / 180)
        ..scale(s);
      final id = _ids[heart.photoFor(k)];
      neonPaintPhoto(
        canvas,
        photos.tile(id) ?? photos.thumb(id),
        rrect,
        brightness: 1 + 0.5 * pop * _flareScale + lift,
        alpha: alpha,
      );
      canvas
        ..drawRRect(
          rrect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = NnHeart.tileBorder
            ..color = color.withValues(alpha: 0.8 * alpha)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        )
        ..drawRRect(
          rrect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = NnHeart.tileBorder
            ..color = color.withValues(alpha: alpha),
        )
        ..restore();
    }
  }

  /// The outline draws itself from lb 6 over 2 beats: pink 2.6 vb with a
  /// white 0.9 vb core and glows σ 1.6g / 4.8g (vb units × 4.5). g is 0.9,
  /// then 1.4 + 0.9 × the glow-up flare from lb 8 (0.3 when reduced).
  void _outline(Canvas canvas, double lb, double alpha, double glowUp) {
    final p = NnHeart.outlineAt(lb);
    if (p <= 0) return;
    final g = lb < 8 ? 0.9 : 1.4 + (reducedFlashing ? 0.3 : 0.9) * glowUp;
    final path = p >= 1 ? NnHeart.outline : _part(NnHeart.outline, p);
    const vb = NnHeart.scale;
    Paint stroke(Color c, double width, double opacity, [double sigma = 0]) =>
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = c.withValues(alpha: (opacity * alpha).clamp(0, 1))
          ..maskFilter = sigma > 0
              ? MaskFilter.blur(BlurStyle.normal, sigma)
              : null;
    canvas
      ..drawPath(path, stroke(NeonColors.pink, 2.6 * vb, 0.7, 4.8 * g * vb))
      ..drawPath(path, stroke(NeonColors.pink, 2.6 * vb, 1, 1.6 * g * vb))
      ..drawPath(path, stroke(NeonColors.pink, 2.6 * vb, 1))
      ..drawPath(path, stroke(NeonColors.white, 0.9 * vb, 0.9));
  }

  /// The first [p] (0–1) of [path]'s length.
  static Path _part(Path path, double p) {
    final out = Path();
    final metrics = path.computeMetrics().toList();
    var left = p * metrics.fold(0.0, (sum, m) => sum + m.length);
    for (final metric in metrics) {
      if (left <= 0) break;
      out.addPath(
        metric.extractPath(0, math.min(left, metric.length)),
        Offset.zero,
      );
      left -= metric.length;
    }
    return out;
  }
}

/// Layer 6 (§4): the Finale's confetti and headline, and the end card,
/// above the sign and under the flash.
class NeonTopPainter extends CustomPainter {
  NeonTopPainter({
    required this.timeline,
    required this.texts,
    required this.time,
    this.reducedFlashing = false,
  }) : super(repaint: time);

  final NeonNightTimeline timeline;
  final NeonNightTexts texts;
  final ValueListenable<double> time;
  final bool reducedFlashing;

  NeonBeat get beat => timeline.beat;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final (:scene, lb: _) = timeline.sceneAt(t);
    if (scene.spec is! NnFinaleSpec && scene.spec is! NnEndingSpec) return;
    // The headline and the confetti fade with the heart over the
    // Ending's first 1.5 beats.
    final fade =
        1 - ((t - timeline.endingCue) / beat.beatToSec(1.5)).clamp(0.0, 1.0);
    if (fade > 0) {
      _confetti(canvas, t, fade);
      _headline(canvas, t, fade);
    }
    if (scene.spec is NnEndingSpec) _ending(canvas, t);
  }

  void _confetti(Canvas canvas, double t, double fade) {
    for (final (seed, pieces, lb) in NnConfetti.bursts) {
      final since = t - timeline.finaleCue - beat.beatToSec(lb);
      if (since < 0 || since > NnConfetti.life) continue;
      for (var k = 0; k < pieces; k++) {
        final piece = NnConfetti.piece(seed, k, since);
        if (piece == null) continue;
        final a = piece.opacity * fade;
        if (a <= 0.002) continue;
        final rect = Rect.fromCenter(
          center: Offset.zero,
          width: piece.size.width,
          height: piece.size.height,
        );
        canvas
          ..save()
          ..translate(piece.position.dx, piece.position.dy)
          ..rotate(piece.degrees * math.pi / 180)
          ..drawRect(
            rect,
            Paint()
              ..color = piece.color.withValues(alpha: a)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
          )
          ..drawRect(rect, Paint()..color = piece.color.withValues(alpha: a))
          ..restore();
      }
    }
  }

  /// Glitches in at lb 9 (seed 81) with a pop from 1.3×.
  void _headline(Canvas canvas, double t, double fade) {
    final at = timeline.finaleCue + beat.beatToSec(9);
    if (t < at) return;
    final headline = texts.finale.headline;
    final topLeft = Offset((NeonAmbient.width - headline.size.width) / 2, 1230);
    final bounds = topLeft & headline.size;
    final pop = NeonEases.pop(((t - at) / 0.5).clamp(0.0, 1.0));
    final scale = 1.3 - 0.3 * pop;
    canvas
      ..save()
      ..translate(bounds.center.dx, bounds.center.dy)
      ..scale(scale)
      ..translate(-bounds.center.dx, -bounds.center.dy);
    neonGlitchIn(
      canvas,
      t: t,
      at: at,
      seed: 81,
      bounds: bounds,
      reducedFlashing: reducedFlashing,
      alpha: fade,
      paintAt: (dx, a) =>
          headline.paint(canvas, topLeft + Offset(dx, 0), alpha: a),
    );
    canvas.restore();
  }

  /// The end card: each line fades in and rises 24 px over 0.5 s (enter).
  void _ending(Canvas canvas, double t) {
    final ending = texts.ending;
    final cue = timeline.endingCue;
    double enter(double lb) =>
        NeonEases.enter(((t - cue - beat.beatToSec(lb)) / 0.5).clamp(0, 1));
    Offset centred(double width, double top, double e) =>
        Offset((NeonAmbient.width - width) / 2, top + 24 * (1 - e));

    final moments = enter(3);
    if (moments > 0) {
      ending.moments.paint(
        canvas,
        centred(ending.moments.size.width, 870, moments),
        alpha: moments,
      );
    }
    final totals = enter(4);
    if (totals > 0) {
      final at = centred(ending.totals.width, 1050, totals);
      neonLayer(canvas, at & ending.totals.size, totals, () {
        ending.totals.paint(canvas, at);
      });
    }
    final titleDate = enter(4.5);
    if (titleDate > 0) {
      final at = centred(ending.titleDate.width, 1110, titleDate);
      final bounds = at & ending.titleDate.size;
      neonLayer(canvas, bounds, titleDate, () {
        ending.titleDate.paint(canvas, at);
      }, sigma: 7);
      neonLayer(canvas, bounds, titleDate, () {
        ending.titleDate.paint(canvas, at);
      });
    }
    final logo = enter(5.5);
    if (logo > 0) {
      ending.logo.paint(
        canvas,
        centred(ending.logo.size.width, 1250, logo),
        alpha: logo,
      );
    }
  }

  @override
  bool shouldRepaint(NeonTopPainter oldDelegate) =>
      oldDelegate.timeline != timeline ||
      oldDelegate.texts != texts ||
      oldDelegate.reducedFlashing != reducedFlashing;
}
