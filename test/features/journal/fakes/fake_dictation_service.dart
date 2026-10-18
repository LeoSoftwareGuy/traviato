import 'dart:async';

import 'package:traviato/features/journal/domain/dictation/dictation_service.dart';

/// A recogniser the test drives by hand: [emit] pushes events into the
/// open session.
class FakeDictationService implements DictationService {
  DictationReadiness readiness = DictationReadiness.ready;
  var prepareCallCount = 0;
  var listenCallCount = 0;
  var stopCallCount = 0;
  var cancelCallCount = 0;
  Duration? lastPauseFor;
  Duration? lastListenFor;
  String? lastLocaleId;

  /// What [supportedLocaleIds] reports; `null` = unknown (no permission).
  List<String>? supported = const ['en_US', 'ru_RU', 'et_EE'];
  var supportedCallCount = 0;

  @override
  Future<List<String>?> supportedLocaleIds({
    required bool askPermission,
  }) async {
    supportedCallCount++;
    return supported;
  }

  StreamController<DictationEvent>? _session;

  @override
  Future<DictationReadiness> prepare() async {
    prepareCallCount++;
    return readiness;
  }

  @override
  Stream<DictationEvent> listen({
    required Duration pauseFor,
    required Duration listenFor,
    String? localeId,
  }) {
    listenCallCount++;
    lastLocaleId = localeId;
    lastPauseFor = pauseFor;
    lastListenFor = listenFor;
    _session = StreamController<DictationEvent>();
    return _session!.stream;
  }

  void emit(DictationEvent event) => _session?.add(event);

  void partial(String words) => emit(DictationWords(words, isFinal: false));

  void finalWords(String words) => emit(DictationWords(words, isFinal: true));

  /// Ends the session the way the platform does: last event, then close.
  Future<void> end([DictationEvent last = const DictationEnded()]) async {
    final session = _session;
    _session = null;
    if (session == null) return;
    session.add(last);
    await session.close();
  }

  @override
  Future<void> stop() async {
    stopCallCount++;
  }

  @override
  Future<void> cancel() async {
    cancelCallCount++;
    await _session?.close();
    _session = null;
  }
}
