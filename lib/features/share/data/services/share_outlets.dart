import 'dart:io';

import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:share_plus/share_plus.dart';

/// Where a share link and its images leave the app (#311): the system
/// share sheet, Instagram Stories, the photo library, and the screen
/// brightness the QR route borrows. One seam, so widget tests swap it out.
class ShareOutlets {
  const ShareOutlets({this.facebookAppId});

  /// Meta App ID; Instagram only takes a story with one. Null → Instagram
  /// Stories falls back to the system share sheet.
  final String? facebookAppId;

  static const _instagram = MethodChannel('com.leo.storyni/instagram_stories');

  /// The system share sheet with `{title}: {url}`.
  Future<void> shareLink({required String title, required String url}) =>
      SharePlus.instance.share(
        ShareParams(text: '$title: $url', subject: title),
      );

  /// The story card straight into Instagram Stories when Instagram is
  /// installed and an App ID is set; otherwise the system share sheet with
  /// the PNG. Returns whether Instagram took it.
  Future<bool> shareStoryCard({
    required Uint8List png,
    required String url,
  }) async {
    final file = await _writeStoryFile(png);
    final appId = facebookAppId;
    if (appId != null && appId.isNotEmpty) {
      try {
        final opened = await _instagram.invokeMethod<bool>('share', {
          'imagePath': file.path,
          'appId': appId,
          'contentUrl': url,
        });
        if (opened ?? false) return true;
      } on PlatformException {
        // Fall through to the system sheet.
      } on MissingPluginException {
        // Desktop / tests: no native channel.
      }
    }
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        text: url,
      ),
    );
    return false;
  }

  /// Saves a PNG to the photo library (asks for add-only access).
  Future<void> saveToPhotos(Uint8List png) async {
    if (!await Gal.hasAccess()) await Gal.requestAccess();
    await Gal.putImageBytes(png, name: 'storyni_${_stamp()}');
  }

  /// Full brightness for the QR route; [restoreBrightness] undoes it.
  Future<void> maxBrightness() =>
      ScreenBrightness.instance.setApplicationScreenBrightness(1);

  Future<void> restoreBrightness() =>
      ScreenBrightness.instance.resetApplicationScreenBrightness();

  /// Under cache/story_share/ — the Android FileProvider's shared folder.
  Future<File> _writeStoryFile(Uint8List png) async {
    final dir = Directory(
      '${(await getTemporaryDirectory()).path}/story_share',
    );
    await dir.create(recursive: true);
    final file = File('${dir.path}/storyni_story.png');
    return file.writeAsBytes(png, flush: true);
  }

  String _stamp() => DateTime.now().millisecondsSinceEpoch.toString();
}
