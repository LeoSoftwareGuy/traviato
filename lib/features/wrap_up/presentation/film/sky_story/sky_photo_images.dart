import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Resolves the film's photos to decoded images for painting (#345). Where
/// they come from is the caller's: bundled assets in the preview, signed
/// URLs once a real memory plays. A photo that fails, or has no provider,
/// stays null and the polaroid paints a warm placeholder.
class SkyPhotoImages extends ChangeNotifier {
  SkyPhotoImages(this._provider);

  final ImageProvider? Function(String id) _provider;
  final _infos = <String, ImageInfo>{};
  final _streams = <String, (ImageStream, ImageStreamListener)>{};
  final _pending = <String, Completer<void>>{};
  bool _disposed = false;

  ui.Image? operator [](String id) => _infos[id]?.image;

  /// How many photos have arrived so far.
  int get loadedCount => _infos.length;

  /// Starts loading [ids]; repaints as each arrives.
  void load(Iterable<String> ids) {
    for (final id in ids) {
      if (_streams.containsKey(id) || _infos.containsKey(id)) continue;
      final provider = _provider(id);
      if (provider == null) continue;
      final done = Completer<void>();
      _pending[id] = done;
      final stream = provider.resolve(ImageConfiguration.empty);
      late final ImageStreamListener listener;
      listener = ImageStreamListener(
        (info, _) {
          if (_disposed) {
            info.dispose();
            return;
          }
          _infos.remove(id)?.dispose();
          _infos[id] = info;
          _settle(id);
          notifyListeners();
        },
        onError: (_, _) => _settle(id),
      );
      _streams[id] = (stream, listener);
      stream.addListener(listener);
    }
  }

  void _settle(String id) {
    final done = _pending.remove(id);
    if (done != null && !done.isCompleted) done.complete();
  }

  /// Completes once every photo asked for so far has loaded or failed.
  Future<void> get ready => Future.wait([
    for (final pending in _pending.values) pending.future,
  ]);

  @override
  void dispose() {
    _disposed = true;
    for (final (stream, listener) in _streams.values) {
      stream.removeListener(listener);
    }
    for (final info in _infos.values) {
      info.dispose();
    }
    _infos.clear();
    super.dispose();
  }
}
