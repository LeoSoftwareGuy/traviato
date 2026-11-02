import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_colors.dart';

/// The share link as a QR (#311): error correction M, ink on transparent —
/// callers put it on a cream card so phone cameras read it.
class ShareQrCode extends StatelessWidget {
  const ShareQrCode({required this.url, required this.size, super.key});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return QrImageView(
      data: url,
      size: size,
      padding: EdgeInsets.zero,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
      backgroundColor: Colors.transparent,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: AppColors.background,
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: AppColors.background,
      ),
    );
  }
}

/// PNG bytes of the [RepaintBoundary] behind [key], at its own logical size
/// × [pixelRatio].
Future<Uint8List> captureBoundaryPng(
  GlobalKey key, {
  double pixelRatio = 1,
}) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: pixelRatio);
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}
