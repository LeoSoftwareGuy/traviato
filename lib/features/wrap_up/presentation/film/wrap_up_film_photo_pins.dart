import 'dart:async';

import 'package:flutter/widgets.dart';

/// Holds decoded film photos live for the film's lifetime (#178).
///
/// A precached image only sits in the image cache's LRU, so later precaches
/// can evict it before playback reaches it. A pinned image keeps a listener
/// on its stream, which makes it a *live* image that eviction can't drop:
/// the frame that builds it later still resolves it synchronously.
class WrapUpFilmPhotoPins {
  final _pins = <(ImageStream, ImageStreamListener)>[];

  /// Decodes [provider] and keeps it live until [dispose]. Completes on the
  /// first frame or on error — a broken photo must not hold up the film.
  Future<void> pin(ImageProvider provider) {
    final loaded = Completer<void>();
    final stream = provider.resolve(ImageConfiguration.empty);
    final listener = ImageStreamListener(
      (_, _) {
        if (!loaded.isCompleted) loaded.complete();
      },
      onError: (_, _) {
        if (!loaded.isCompleted) loaded.complete();
      },
    );
    stream.addListener(listener);
    _pins.add((stream, listener));
    return loaded.future;
  }

  void dispose() {
    for (final (stream, listener) in _pins) {
      stream.removeListener(listener);
    }
    _pins.clear();
  }
}
