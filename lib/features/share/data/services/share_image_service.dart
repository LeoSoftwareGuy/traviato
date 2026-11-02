import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/og_card_content.dart';

/// Long edge of a teaser copy (#309): sharp on a phone, a fraction of the
/// original's size.
const _teaserMaxDimension = 1080;
const _teaserQuality = 80;

const ogCardSize = Size(1200, 630);

/// Makes a share link's public images (#309). Every output is a fresh JPEG
/// encode, so no EXIF (and no GPS) from the original survives.
class ShareImageService {
  const ShareImageService();

  /// A teaser copy: long edge ≤ 1080, JPEG q80.
  Future<Uint8List> downscale(Uint8List bytes) =>
      FlutterImageCompress.compressWithList(
        bytes,
        minWidth: _teaserMaxDimension,
        minHeight: _teaserMaxDimension,
        quality: _teaserQuality,
        format: CompressFormat.jpeg,
        keepExif: false,
      );

  /// The link-preview image (design 2a): [cover] filling the frame under a
  /// left-to-right scrim, the wordmark top left, title + eyebrow bottom
  /// left. Without a cover, the scrim sits on the app background.
  Future<Uint8List> renderOgCard({
    Uint8List? cover,
    required OgCardContent content,
  }) async {
    final wordmark = AppTypography.serif(
      fontSize: 44,
      fontStyle: FontStyle.italic,
      color: AppColors.textPrimary,
    );
    final title = AppTypography.serif(
      fontSize: 90,
      height: 1.05,
      color: AppColors.textPrimary,
    );
    final eyebrow = GoogleFonts.jetBrainsMono(
      fontSize: 30,
      fontWeight: FontWeight.w500,
      letterSpacing: 30 * .12,
      color: AppColors.primaryLight,
    );
    await GoogleFonts.pendingFonts();

    final coverImage = cover == null ? null : await _decode(cover);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    paintOgCard(
      canvas,
      cover: coverImage,
      content: content,
      wordmarkStyle: wordmark,
      titleStyle: title,
      eyebrowStyle: eyebrow,
    );
    final image = await recorder.endRecording().toImage(
      ogCardSize.width.toInt(),
      ogCardSize.height.toInt(),
    );
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    coverImage?.dispose();
    return FlutterImageCompress.compressWithList(
      png!.buffer.asUint8List(),
      minWidth: ogCardSize.width.toInt(),
      minHeight: ogCardSize.height.toInt(),
      quality: 85,
      format: CompressFormat.jpeg,
    );
  }

  Future<ui.Image> _decode(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }
}

/// Draws design 2a at 1200×630 — the 272-wide mockup scaled ×4.41.
void paintOgCard(
  Canvas canvas, {
  ui.Image? cover,
  required OgCardContent content,
  required TextStyle wordmarkStyle,
  required TextStyle titleStyle,
  required TextStyle eyebrowStyle,
}) {
  final frame = Offset.zero & ogCardSize;
  canvas.drawRect(frame, Paint()..color = AppColors.background);
  if (cover != null) {
    paintImage(canvas: canvas, rect: frame, image: cover, fit: BoxFit.cover);
  }
  canvas.drawRect(
    frame,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(ogCardSize.width, 0),
        [
          AppColors.background.withValues(alpha: .85),
          AppColors.background.withValues(alpha: .1),
          AppColors.background.withValues(alpha: .1),
        ],
        const [0, .7, 1],
      ),
  );

  const inset = 62.0;
  const maxTextWidth = 1200 * .7 - inset;

  TextPainter(
      text: TextSpan(
        text: 'Storyni',
        style: wordmarkStyle,
        children: [
          TextSpan(
            text: ' ✦',
            style: wordmarkStyle.copyWith(color: AppColors.primary),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )
    ..layout()
    ..paint(canvas, const Offset(inset, 50));

  final eyebrow = TextPainter(
    text: TextSpan(text: content.eyebrow, style: eyebrowStyle),
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: ogCardSize.width - inset * 2);
  final eyebrowTop = ogCardSize.height - 53 - eyebrow.height;
  eyebrow.paint(canvas, Offset(inset, eyebrowTop));

  final title = TextPainter(
    text: TextSpan(text: content.title, style: titleStyle),
    textDirection: TextDirection.ltr,
    maxLines: 2,
    ellipsis: '…',
  )..layout(maxWidth: maxTextWidth);
  title.paint(canvas, Offset(inset, eyebrowTop - 13 - title.height));
}
