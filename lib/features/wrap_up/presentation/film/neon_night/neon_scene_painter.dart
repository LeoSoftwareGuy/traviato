import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../film_eases.dart';
import 'neon_ambient.dart';
import 'neon_balloon.dart';
import 'neon_beat.dart';
import 'neon_chapter_card_painter.dart';
import 'neon_eases.dart';
import 'neon_moment_painter.dart';
import 'neon_night_scene_spec.dart';
import 'neon_night_story.dart';
import 'neon_night_texts.dart';
import 'neon_night_timeline.dart';
import 'neon_photo.dart';
import 'neon_text_fx.dart';
import 'neon_tokens.dart';

/// Layer 3 (#363, NEON_NIGHT_SPEC.md §4): the content of whichever scene
/// is playing, cut hard on every cue. So far Ignition (§5.1), Plan (§5.2),
/// the chapter cards (§5.3), their moments (§5.4–5.6) and the Note (§5.7).
class NeonScenePainter extends CustomPainter {
  NeonScenePainter({
    required this.timeline,
    required this.story,
    required this.texts,
    required this.photos,
    required this.time,
    this.reducedFlashing = false,
  }) : _cards = {
         for (final scene in timeline.scenes)
           if (scene.spec case final NnChapterCardSpec spec)
             spec.chapter: NnChapterCardPainter(
               spec: spec,
               chapter: story.chapters[spec.chapter],
               texts: texts.chapters[spec.chapter],
               photos: photos,
               beat: timeline.beat,
               reducedFlashing: reducedFlashing,
             ),
       },
       _moments = _momentPainters(
         timeline,
         story,
         texts,
         photos,
         reducedFlashing,
       ),
       super(repaint: time);

  /// One painter per moment scene, keyed by its cue: a chapter's moments
  /// play in the order the story lists them.
  static Map<double, NnMomentPainter> _momentPainters(
    NeonNightTimeline timeline,
    NeonNightStory story,
    NeonNightTexts texts,
    NeonPhotoSource photos,
    bool reducedFlashing,
  ) {
    final out = <double, NnMomentPainter>{};
    final seen = <int, int>{};
    for (final scene in timeline.scenes) {
      if (scene.spec case final NnMomentSpec spec) {
        final k = seen[spec.chapter] = (seen[spec.chapter] ?? -1) + 1;
        out[scene.start] = NnMomentPainter(
          spec: spec,
          moment: story.chapters[spec.chapter].moments[k],
          texts: texts.chapters[spec.chapter].moments[k],
          photos: photos,
          beat: timeline.beat,
          reducedFlashing: reducedFlashing,
        );
      }
    }
    return out;
  }

  final NeonNightTimeline timeline;
  final NeonNightStory story;
  final NeonNightTexts texts;
  final NeonPhotoSource photos;
  final ValueListenable<double> time;
  final bool reducedFlashing;
  final Map<int, NnChapterCardPainter> _cards;
  final Map<double, NnMomentPainter> _moments;

  NeonBeat get beat => timeline.beat;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final (:scene, lb: _) = timeline.sceneAt(t);
    switch (scene.spec) {
      case NnIgnitionSpec():
        _ignition(canvas, t, scene.start);
      case NnPlanSpec():
        final plan = texts.plan;
        if (plan != null) _plan(canvas, t, scene.start, plan);
      case NnChapterCardSpec(:final chapter):
        _cards[chapter]?.paint(canvas, t, scene.start, scene.duration);
      case NnMomentSpec():
        _moments[scene.start]?.paint(canvas, t, scene.start, scene.duration);
      case NnNoteSpec():
        final note = texts.note;
        if (note != null) _note(canvas, t, scene.start, scene.duration, note);
      default:
        break;
    }
  }

  /// Seconds into the scene at [cue] where local beat [lb] falls.
  double _at(double cue, double lb) => cue + beat.beatToSec(lb);

  // ---- Note (§5.7) ---------------------------------------------------

  void _note(
    Canvas canvas,
    double t,
    double cue,
    double duration,
    NnNoteTexts note,
  ) {
    // Exit: a 0.25 s fade at the end.
    final exit = 1 - ((t - (cue + duration - 0.25)) / 0.25).clamp(0.0, 1.0);
    if (exit <= 0) return;
    _noteBackground(canvas, t, cue, duration, exit);

    final tag = note.tag;
    final tagAlpha =
        FilmEases.at(t, _at(cue, 0.5), 0.3, FilmEases.linear) * exit;
    tag.paint(
      canvas,
      Offset((NeonAmbient.width - tag.size.width) / 2, 550),
      alpha: tagAlpha,
    );

    final g = 1 + 0.3 * beat.beatEnv(t);
    for (final (i, line) in note.lines.indexed) {
      final dt = t - _at(cue, 1.0 + 2 * i);
      if (dt < 0) continue;
      final on = reducedFlashing
          ? NeonBalloon.fadeOn(dt)
          : NeonBalloon.flicker(dt);
      line.paint(
        canvas,
        Offset((NeonAmbient.width - line.size.width) / 2, lineTop(note, i)),
        alpha: on * exit,
        g: g,
      );
    }

    final signature = note.signature;
    if (signature != null) {
      final a =
          FilmEases.at(
            t,
            _at(cue, 1.0 + 2 * note.lines.length),
            0.4,
            FilmEases.linear,
          ) *
          exit;
      if (a > 0.002) {
        final last = note.lines.length - 1;
        final at = Offset(
          (NeonAmbient.width - signature.width) / 2,
          lineTop(note, last) + note.lines[last].size.height + 40,
        );
        neonLayer(canvas, at & signature.size, a, () {
          signature.paint(canvas, at);
        });
      }
    }
  }

  /// Line [i]'s top: `720 + i × 1.06 × size`.
  static double lineTop(NnNoteTexts note, int i) =>
      720 + i * 1.06 * note.fontSize;

  /// The note's photo, blurred and dimmed under a violet → black wash,
  /// bled 60 px past the frame. Fades in over 0.2 s; scales 1.15 → 1.07.
  void _noteBackground(
    Canvas canvas,
    double t,
    double cue,
    double duration,
    double exit,
  ) {
    final a = FilmEases.at(t, cue, 0.2, FilmEases.linear) * exit;
    if (a <= 0.002) return;
    const frame = Rect.fromLTWH(0, 0, NeonAmbient.width, NeonAmbient.height);
    final id = story.note?.photo?.id;
    final image = id == null ? null : photos.large(id) ?? photos.thumb(id);
    if (image != null) {
      final p = ((t - cue) / duration).clamp(0.0, 1.0);
      final scale = 1.15 - 0.08 * p;
      canvas
        ..saveLayer(
          frame,
          Paint()
            ..color = Color.fromRGBO(0, 0, 0, a)
            ..imageFilter = ui.ImageFilter.blur(
              sigmaX: 14,
              sigmaY: 14,
              tileMode: TileMode.decal,
            ),
        )
        ..translate(frame.center.dx, frame.center.dy)
        ..scale(scale)
        ..translate(-frame.center.dx, -frame.center.dy);
      neonPaintPhoto(
        canvas,
        image,
        RRect.fromRectAndRadius(frame.inflate(60), Radius.zero),
        brightness: 0.5,
      );
      canvas.restore();
    }
    canvas.drawRect(
      frame,
      Paint()
        ..shader = ui.Gradient.linear(frame.topCenter, frame.bottomCenter, [
          NeonColors.violet.withValues(alpha: 0.35 * a),
          NeonColors.black.withValues(alpha: 0.55 * a),
        ]),
    );
  }

  // ---- Ignition (§5.1) ------------------------------------------------

  static const _titleTop = 1240.0;

  void _ignition(Canvas canvas, double t, double cue) {
    final ign = texts.ignition;
    final title = ign.title;
    final exit = 1 - FilmEases.at(t, _at(cue, 7.4), 0.5, FilmEases.linear);
    if (exit <= 0) return;
    final x = (NeonAmbient.width - title.size.width) / 2;
    final titleRect = Offset(x, _titleTop) & title.size;

    // The reflection: the title flipped under itself, strongest by the
    // title and gone 65 % of the way down.
    final reflection =
        0.22 * FilmEases.at(t, _at(cue, 4.5), 0.4, FilmEases.linear) * exit;
    if (reflection > 0.002) {
      final top = _titleTop + 1.05 * title.fontSize + 30;
      final rect = Offset(x, top) & title.size;
      canvas.saveLayer(rect.inflate(40), Paint());
      canvas
        ..save()
        ..translate(0, top + title.size.height)
        ..scale(1, -1);
      title.paint(canvas, Offset(x, 0), alpha: reflection);
      canvas.restore();
      canvas
        ..drawRect(
          rect.inflate(40),
          Paint()
            ..blendMode = BlendMode.dstIn
            ..shader = ui.Gradient.linear(
              Offset(0, rect.top),
              Offset(0, rect.top + rect.height * 0.65),
              const [Color(0xFF000000), Color(0x00000000)],
            ),
        )
        ..restore();
    }

    neonGlitchIn(
      canvas,
      t: t,
      at: _at(cue, 4),
      seed: 11,
      bounds: titleRect,
      reducedFlashing: reducedFlashing,
      alpha: exit,
      paintAt: (dx, alpha) =>
          title.paint(canvas, titleRect.topLeft + Offset(dx, 0), alpha: alpha),
    );

    final metaIn = FilmEases.at(t, _at(cue, 6), 0.5, NeonEases.enter);
    if (metaIn > 0) {
      final meta = ign.meta;
      final offset = Offset(
        (NeonAmbient.width - meta.width) / 2,
        _titleTop + title.fontSize + 30 + 16 * (1 - metaIn),
      );
      neonLayer(
        canvas,
        offset & meta.size,
        metaIn * exit,
        () => meta.paint(canvas, offset),
      );
    }
  }

  // ---- Plan (§5.2) ----------------------------------------------------

  static const _rowTop = 520.0;
  static const _rowPitch = 200.0;
  static const _timeX = 110.0;
  static const _itemX = 420.0;
  static const _centre = Offset(NeonAmbient.width / 2, NeonAmbient.height / 2);

  /// The tick (§5.2) in its 96 × 86 box.
  static final _tick =
      (Path()
            ..moveTo(4, 40)
            ..lineTo(28, 66)
            ..lineTo(76, 6))
          .computeMetrics()
          .first;

  void _plan(Canvas canvas, double t, double cue, NnPlanTexts plan) {
    final exitP = FilmEases.at(t, _at(cue, 11.4), 0.5, FilmEases.linear);
    final exit = 1 - exitP;
    if (exit <= 0) return;
    final scale = 1 + 0.04 * exitP;
    canvas
      ..save()
      ..translate(_centre.dx, _centre.dy)
      ..scale(scale)
      ..translate(-_centre.dx, -_centre.dy);

    final title = plan.title;
    final titleRect =
        Offset((NeonAmbient.width - title.size.width) / 2, 250) & title.size;
    neonGlitchIn(
      canvas,
      t: t,
      at: cue,
      seed: 21,
      bounds: titleRect,
      reducedFlashing: reducedFlashing,
      alpha: exit,
      paintAt: (dx, alpha) =>
          title.paint(canvas, titleRect.topLeft + Offset(dx, 0), alpha: alpha),
    );

    for (var i = 0; i < plan.rows.length; i++) {
      _row(canvas, t, cue, i, plan.rows[i], exit);
    }

    final more = plan.more;
    if (more != null) {
      final a = FilmEases.at(t, _at(cue, 2), 0.4, FilmEases.linear) * exit;
      const offset = Offset(_itemX, 1530);
      neonLayer(
        canvas,
        offset & more.size,
        a,
        () => more.paint(canvas, offset),
      );
    }
    canvas.restore();
  }

  void _row(
    Canvas canvas,
    double t,
    double cue,
    int i,
    NnPlanRowTexts row,
    double exit,
  ) {
    final enterAt = _at(cue, 1) + 0.1 * i;
    final e = FilmEases.at(t, enterAt, 0.45, NeonEases.enter);
    final alpha = e * exit;
    if (alpha <= 0.002) return;
    final y = _rowTop + _rowPitch * i + 30 * (1 - e);

    var on = 0.0;
    var flare = 0.0;
    double litAt = double.infinity;
    final d = row.doneIndex;
    if (d != null) {
      litAt = _at(cue, 3.0 + d);
      if (reducedFlashing) {
        on = ((t - litAt) / 0.2).clamp(0.0, 1.0);
      } else {
        on = t >= litAt ? 1 : 0;
        flare = NeonBeat.flare(t, litAt, 0.25);
      }
    }

    row.time.paint(
      canvas,
      Offset(_timeX, y),
      alpha: alpha,
      on: on,
      flare: flare,
    );
    row.item.paint(
      canvas,
      Offset(_itemX, y + row.itemDrop),
      alpha: alpha,
      on: on,
      flare: flare,
    );
    if (d == null || t < litAt) return;

    // Underlines under the time and the item, growing in.
    final grow = FilmEases.at(t, litAt, 0.3, NeonEases.enter);
    final lines = [
      RRect.fromLTRBR(
        _timeX,
        y + 148,
        _timeX + 270 * grow,
        y + 158,
        const Radius.circular(5),
      ),
      RRect.fromLTRBR(
        _itemX,
        y + 148,
        _itemX + 440 * grow,
        y + 158,
        const Radius.circular(5),
      ),
    ];
    final lineBounds = Rect.fromLTRB(_timeX, y + 148, _itemX + 440, y + 158);
    neonLayer(canvas, lineBounds, alpha * 0.8, () {
      for (final line in lines) {
        canvas.drawRRect(line, Paint()..color = row.color);
      }
    }, sigma: 7);
    neonLayer(canvas, lineBounds, alpha, () {
      for (final line in lines) {
        canvas.drawRRect(line, Paint()..color = row.color);
      }
    });

    // The tick, drawn on.
    final drawn = FilmEases.at(t, litAt, 0.25, NeonEases.enter);
    final tick = _tick
        .extractPath(0, (120 * drawn).clamp(0, _tick.length))
        .shift(Offset(890, y + 30));
    final tickBounds = Rect.fromLTWH(890, y + 30, 96, 86);
    Paint stroke(Color color) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    for (final sigma in const [17.0, 7.0]) {
      neonLayer(
        canvas,
        tickBounds,
        alpha,
        () => canvas.drawPath(tick, stroke(row.color)),
        sigma: sigma,
      );
    }
    neonLayer(
      canvas,
      tickBounds,
      alpha,
      () => canvas.drawPath(tick, stroke(row.tint)),
    );
  }

  @override
  bool shouldRepaint(NeonScenePainter oldDelegate) =>
      oldDelegate.timeline != timeline ||
      oldDelegate.texts != texts ||
      oldDelegate.time != time ||
      oldDelegate.reducedFlashing != reducedFlashing;
}
