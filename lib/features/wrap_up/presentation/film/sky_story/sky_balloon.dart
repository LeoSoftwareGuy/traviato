import 'dart:math' as math;
import 'dart:ui';

import 'sky_story_tokens.dart';

/// Paints Sky Story's hot-air balloon (#345, spec §2): a red envelope with
/// three cream stripes that meet at the crown, ropes, a basket and the
/// burner's glow. Custom-painted, so it costs no asset or dependency and
/// stays sharp at any size.
///
/// [center] is the middle of the whole figure (crown to basket) and
/// [width] the envelope's widest span; the figure is [skyBalloonHeight]
/// tall. The shapes are built once at unit size and scaled per draw.
void paintSkyBalloon(
  Canvas canvas, {
  required Offset center,
  required double width,
  double opacity = 1,
  bool glow = true,
}) {
  final alpha = opacity.clamp(0.0, 1.0);
  if (alpha <= 0.004 || width <= 0) return;

  canvas
    ..save()
    ..translate(center.dx, center.dy - skyBalloonHeight(width) / 2)
    ..scale(width);

  canvas.drawPath(
    _envelope,
    Paint()
      ..shader = Gradient.linear(
        Offset.zero,
        const Offset(0, _mouthY),
        [
          SkyStoryColors.balloonRedTop.withValues(alpha: alpha),
          SkyStoryColors.balloonRed.withValues(alpha: alpha),
          SkyStoryColors.balloonRedBottom.withValues(alpha: alpha),
          SkyStoryColors.balloonMouth.withValues(alpha: alpha),
        ],
        const [0, 0.45, 0.82, 1],
      ),
  );
  canvas.drawPath(
    _stripes,
    Paint()
      ..shader = Gradient.linear(
        Offset.zero,
        const Offset(0, _mouthY),
        [
          SkyStoryColors.balloonStripeShade.withValues(alpha: alpha),
          SkyStoryColors.balloonStripe.withValues(alpha: alpha),
          SkyStoryColors.balloonStripe.withValues(alpha: alpha),
        ],
        const [0, 0.5, 1],
      ),
  );
  // The burner's light, over the envelope's mouth and behind the basket.
  if (glow) {
    const glowCenter = Offset(0, _mouthY + 0.11);
    canvas.drawCircle(
      glowCenter,
      0.36,
      Paint()
        ..shader = Gradient.radial(
          glowCenter,
          0.36,
          [
            SkyStoryColors.burnerGlow.withValues(alpha: alpha),
            SkyStoryColors.burnerGlow.withValues(alpha: 0.72 * alpha),
            SkyStoryColors.burnerGlow.withValues(alpha: 0.26 * alpha),
            SkyStoryColors.burnerGlow.withValues(alpha: 0),
          ],
          const [0, 0.14, 0.45, 1],
        ),
    );
  }
  final rope = Paint()
    ..color = SkyStoryColors.balloonRope.withValues(alpha: alpha)
    ..strokeWidth = math.max(0.018, 1.2 / width);
  canvas
    ..drawLine(
      const Offset(-0.1, _mouthY),
      const Offset(-0.1, _basketTop),
      rope,
    )
    ..drawLine(const Offset(0.1, _mouthY), const Offset(0.1, _basketTop), rope)
    ..drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.135, _basketTop, 0.27, 0.165),
        const Radius.circular(0.03),
      ),
      Paint()..color = SkyStoryColors.balloonBasket.withValues(alpha: alpha),
    );

  canvas.restore();
}

/// The whole figure's height, crown to basket, for an envelope [width]
/// wide.
double skyBalloonHeight(double width) => width * _figureHeight;

/// Unit geometry (envelope width 1, crown at y 0).
const double _mouthY = 1.08;
const double _basketTop = _mouthY + 0.17;
const double _figureHeight = _basketTop + 0.165 + 0.005;

/// The cream stripes as fractions of the envelope's half-width at each
/// height (−1 left edge … 1 right edge): from the reference, a wide centre
/// stripe and a narrower one on each side.
const _stripeBands = [(-0.47, -0.33), (-0.14, 0.14), (0.33, 0.47)];

const int _steps = 40;

/// The envelope's half-width at [y] (0 crown … [_mouthY] mouth): a round
/// crown, widest at 0.5, tapering with a slight bulge to the mouth.
double _halfWidthAt(double y) {
  if (y <= 0.5) {
    final dy = 0.5 - y;
    return math.sqrt(math.max(0, 0.25 - dy * dy));
  }
  final u = ((y - 0.5) / (_mouthY - 0.5)).clamp(0.0, 1.0);
  return 0.5 - (0.5 - 0.165) * u * u * (1.6 - 0.6 * u);
}

/// A band between two fractions of the half-width, crown to mouth; the
/// envelope itself is the band (−1, 1).
Path _band(double from, double to) {
  final path = Path();
  for (var i = 0; i <= _steps; i++) {
    final y = _mouthY * i / _steps;
    final x = _halfWidthAt(y) * to;
    i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
  }
  for (var i = _steps; i >= 0; i--) {
    final y = _mouthY * i / _steps;
    path.lineTo(_halfWidthAt(y) * from, y);
  }
  return path..close();
}

final Path _envelope = _band(-1, 1);

final Path _stripes = () {
  final path = Path();
  for (final (from, to) in _stripeBands) {
    path.addPath(_band(from, to), Offset.zero);
  }
  return path;
}();
