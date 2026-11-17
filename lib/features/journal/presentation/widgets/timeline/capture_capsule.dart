import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/l10n/context_l10n.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_gradients.dart';
import '../../../../../core/theme/app_typography.dart';

const _halfWidth = 84.0;
const _gapWidth = 26.0;
const capsuleWidth = _halfWidth * 2 + _gapWidth;
const capsuleHeight = 60.0;

/// The split capture button (#401, docs/design/journal-notes/ §4): one
/// gradient capsule, Photo on the left and Note on the right, with the
/// Storyni balloon punched through the gap between them. Each half is its
/// own 84×60 target; pressing dims it and ticks a light haptic.
class CaptureCapsule extends StatelessWidget {
  const CaptureCapsule({
    required this.onPhoto,
    required this.onNote,
    super.key,
  });

  final VoidCallback onPhoto;
  final VoidCallback onNote;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      key: const Key('capture-capsule'),
      width: capsuleWidth,
      height: capsuleHeight,
      decoration: BoxDecoration(
        gradient: AppGradients.primaryCta,
        borderRadius: BorderRadius.circular(capsuleHeight / 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.tint(Colors.black, .45),
            offset: const Offset(0, 16),
            blurRadius: 34,
          ),
          BoxShadow(
            color: AppColors.tint(AppColors.primary, .32),
            offset: const Offset(0, 8),
            blurRadius: 22,
          ),
        ],
      ),
      child: CustomPaint(
        foregroundPainter: const BalloonCutoutPainter(),
        child: Row(
          children: [
            _Half(
              key: const Key('capture-photo'),
              icon: Icons.photo_camera_outlined,
              label: l10n.timeline_capturePhoto,
              semantics: l10n.timeline_addPhotoSemantics,
              onTap: onPhoto,
              isLeft: true,
            ),
            const SizedBox(width: _gapWidth),
            _Half(
              key: const Key('capture-note'),
              icon: Icons.sticky_note_2_outlined,
              label: l10n.timeline_captureNote,
              semantics: l10n.timeline_addNoteSemantics,
              onTap: onNote,
              isLeft: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _Half extends StatefulWidget {
  const _Half({
    required this.icon,
    required this.label,
    required this.semantics,
    required this.onTap,
    required this.isLeft,
    super.key,
  });

  final IconData icon;
  final String label;
  final String semantics;
  final VoidCallback onTap;
  final bool isLeft;

  @override
  State<_Half> createState() => _HalfState();
}

class _HalfState extends State<_Half> {
  var _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    const outer = Radius.circular(capsuleHeight / 2);
    return Semantics(
      button: true,
      label: widget.semantics,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        child: Container(
          width: _halfWidth,
          height: capsuleHeight,
          decoration: BoxDecoration(
            color: _pressed
                ? AppColors.tint(AppColors.background, .1)
                : Colors.transparent,
            borderRadius: widget.isLeft
                ? const BorderRadius.horizontal(left: outer)
                : const BorderRadius.horizontal(right: outer),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 22, color: AppColors.background),
              const SizedBox(height: 2),
              Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.captureLabel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The balloon silhouette (26×52) in the screen's background colour, drawn
/// in the capsule's centre gap — the envelope over the top two-thirds, two
/// ropes, a small basket — plus the capsule's inner top highlight.
class BalloonCutoutPainter extends CustomPainter {
  const BalloonCutoutPainter();

  static Path balloonPath() {
    // Envelope: a rounded top narrowing to the ropes.
    return Path()
      ..moveTo(13, 35)
      ..cubicTo(7, 30, 1, 22, 1, 13)
      ..arcToPoint(const Offset(25, 13), radius: const Radius.circular(12))
      ..cubicTo(25, 22, 19, 30, 13, 35)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final highlight = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.center,
        colors: [
          AppColors.tint(Colors.white, .3),
          AppColors.tint(Colors.white, 0),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(.5),
        Radius.circular(size.height / 2),
      ),
      highlight,
    );

    final origin = Offset((size.width - _gapWidth) / 2, (size.height - 52) / 2);
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    final fill = Paint()..color = AppColors.background;
    canvas.drawPath(balloonPath(), fill);
    final rope = Paint()
      ..color = AppColors.background
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(9.5, 33), const Offset(11.4, 45), rope);
    canvas.drawLine(const Offset(16.5, 33), const Offset(14.6, 45), rope);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(10.4, 45, 5.2, 5.4),
        const Radius.circular(1.2),
      ),
      fill,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
