import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';

/// The bottom nav's centre action (#424): the Journal's hot-air balloon
/// (docs/design/JOURNAL_NAVBAR_SPEC.md § Balloon cut-out) filled with the
/// primary→coral CTA gradient, a "+" in the middle of its envelope. It
/// shrinks a touch while pressed and taps with a light haptic.
class BalloonCreateButton extends StatefulWidget {
  const BalloonCreateButton({
    required this.onTap,
    required this.semanticLabel,
    this.width = defaultWidth,
    super.key,
  });

  final VoidCallback onTap;
  final String semanticLabel;
  final double width;

  static const double defaultWidth = 54;

  /// The balloon's height for a given [width] (its frame is 48 × 57).
  static double heightFor(double width) =>
      width * _BalloonPainter.frameHeight / _BalloonPainter.frameWidth;

  @override
  State<BalloonCreateButton> createState() => _BalloonCreateButtonState();
}

class _BalloonCreateButtonState extends State<BalloonCreateButton> {
  var _pressed = false;

  void _setPressed(bool isOn) {
    if (_pressed != isOn) setState(() => _pressed = isOn);
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        key: const Key('nav-create-balloon'),
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _pressed ? .92 : 1,
          duration: reducedMotion
              ? Duration.zero
              : const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: CustomPaint(
            size: Size(
              widget.width,
              BalloonCreateButton.heightFor(widget.width),
            ),
            painter: const _BalloonPainter(),
          ),
        ),
      ),
    );
  }
}

/// The balloon on a 48 × 57 frame: the envelope (the spec's envelope path,
/// moved to the origin), two ropes and the basket.
class _BalloonPainter extends CustomPainter {
  const _BalloonPainter();

  static const double frameWidth = 48;
  static const double frameHeight = 57;

  static Path _envelope() => Path()
    ..moveTo(24, 0)
    ..cubicTo(8, 0, 0, 7, 0, 17)
    ..cubicTo(0, 26, 8, 33, 15, 43)
    ..lineTo(33, 43)
    ..cubicTo(40, 33, 48, 26, 48, 17)
    ..cubicTo(48, 7, 40, 0, 24, 0)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / frameWidth, size.height / frameHeight);
    const bounds = Rect.fromLTWH(0, 0, frameWidth, frameHeight);
    final envelope = _envelope();

    // The old square's soft primary glow, under the envelope.
    canvas.drawPath(
      envelope.shift(const Offset(0, 4)),
      Paint()
        ..color = AppColors.tint(AppColors.primary, .34)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );

    final shader = AppGradients.primaryCta.createShader(bounds);
    canvas.drawPath(envelope, Paint()..shader = shader);
    canvas.drawPath(
      Path()
        ..moveTo(18, 43)
        ..lineTo(19, 49)
        ..moveTo(30, 43)
        ..lineTo(29, 49),
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(18, 49, 12, 8),
        const Radius.circular(1.6),
      ),
      Paint()..shader = shader,
    );

    // "+" in the envelope's middle, in the old plus's dark ink.
    const centre = Offset(24, 19);
    const arm = 6.5;
    canvas.drawPath(
      Path()
        ..moveTo(centre.dx - arm, centre.dy)
        ..lineTo(centre.dx + arm, centre.dy)
        ..moveTo(centre.dx, centre.dy - arm)
        ..lineTo(centre.dx, centre.dy + arm),
      Paint()
        ..color = AppColors.background
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_BalloonPainter oldDelegate) => false;
}
