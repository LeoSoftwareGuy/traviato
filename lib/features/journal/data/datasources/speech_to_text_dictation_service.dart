import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../domain/dictation/dictation_service.dart';

/// [DictationService] on the platform recogniser, via `speech_to_text`
/// (Apple Speech on iOS, the system RecognitionService on Android).
class SpeechToTextDictationService implements DictationService {
  SpeechToTextDictationService({SpeechToText? speech})
    : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;
  StreamController<DictationEvent>? _session;

  /// Errors that just mean nobody spoke (or not for long enough) — the
  /// session ends quietly, it isn't a failure.
  static const _silenceErrors = {'error_no_match', 'error_speech_timeout'};

  @override
  Future<DictationReadiness> prepare() async {
    try {
      final ready = await _speech.initialize(
        onError: _onError,
        onStatus: _onStatus,
      );
      if (ready) return DictationReadiness.ready;
      return await _speech.hasPermission
          ? DictationReadiness.unavailable
          : DictationReadiness.permissionDenied;
    } catch (e) {
      debugPrint('Speech recogniser failed to initialise: $e');
      return DictationReadiness.unavailable;
    }
  }

  @override
  Stream<DictationEvent> listen({
    required Duration pauseFor,
    required Duration listenFor,
  }) {
    _close();
    final session = StreamController<DictationEvent>();
    _session = session;
    // The session's events arrive on the listeners below; the future
    // itself only reports a failure to start.
    unawaited(
      _speech
          .listen(
            onResult: (result) => _add(
              DictationWords(
                result.recognizedWords,
                isFinal: result.finalResult,
              ),
            ),
            onSoundLevelChange: (level) => _add(DictationLevel(level)),
            listenOptions: SpeechListenOptions(
              partialResults: true,
              listenMode: ListenMode.dictation,
              autoPunctuation: true,
              cancelOnError: true,
              pauseFor: pauseFor,
              listenFor: listenFor,
            ),
          )
          .catchError((Object e) {
            debugPrint('Speech recogniser failed to start: $e');
            _end(const DictationFailed(DictationReadiness.unavailable));
          }),
    );
    return session.stream;
  }

  @override
  Future<void> stop() => _speech.stop();

  @override
  Future<void> cancel() async {
    await _speech.cancel();
    _close();
  }

  void _onStatus(String status) {
    // `done` comes after the final result; `notListening` comes before it.
    if (status == SpeechToText.doneStatus) _end(const DictationEnded());
  }

  void _onError(SpeechRecognitionError error) {
    final msg = error.errorMsg;
    if (_silenceErrors.contains(msg)) {
      _end(const DictationEnded());
    } else if (msg.contains('permission')) {
      _end(const DictationFailed(DictationReadiness.permissionDenied));
    } else {
      debugPrint(
        'Speech recogniser error: $msg (permanent: ${error.permanent})',
      );
      _end(const DictationFailed(DictationReadiness.unavailable));
    }
  }

  void _add(DictationEvent event) {
    final session = _session;
    if (session != null && !session.isClosed) session.add(event);
  }

  void _end(DictationEvent last) {
    _add(last);
    _close();
  }

  void _close() {
    final session = _session;
    _session = null;
    if (session != null && !session.isClosed) unawaited(session.close());
  }
}
