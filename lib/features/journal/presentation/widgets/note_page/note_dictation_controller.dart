import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../domain/dictation/dictation_service.dart';
import 'dictation_insertion.dart';
import 'note_draft_controller.dart';

/// Inline message under the dock when voice can't be used. Typing always
/// works regardless.
enum DictationNotice { none, micOff, unavailable }

/// The note page's voice half of the Idle / Listening / Typing state
/// machine (docs/design/JOURNAL_NOTE_PAGETURN_SPEC.md §4). Typing is just
/// the field having focus; this tracks whether we're listening, the
/// `m:ss` timer, the waveform levels and the inline notice, and streams
/// the transcript into [draft] at the caret.
class NoteDictationController extends ChangeNotifier {
  NoteDictationController({
    required this.service,
    required this.draft,
    this.resolveLocale,
  });

  final DictationService service;
  final NoteDraftController draft;

  /// Called once speech access is granted, right before listening: which
  /// recogniser locale to use, or `isAvailable: false` when the chosen
  /// dictation language can't be recognised on this device (#218). `null`
  /// listens in the device locale.
  final Future<({bool isAvailable, String? localeId})> Function()?
  resolveLocale;

  /// Auto-stop after this long without speech…
  static const silenceTimeout = Duration(seconds: 8);

  /// …or after this long in total.
  static const maxDuration = Duration(seconds: 90);

  static const barCount = 24;
  static const _minBar = .3;

  var _listening = false;
  var _starting = false;
  var _disposed = false;
  var _elapsed = Duration.zero;
  var _notice = DictationNotice.none;
  var _levels = List<double>.filled(barCount, _minBar);
  var _levelEvents = 0;
  var _levelMin = double.infinity;
  var _levelMax = double.negativeInfinity;

  StreamSubscription<DictationEvent>? _session;
  Timer? _ticker;
  DictationInsertion? _insertion;
  String? _lastApplied;

  bool get isListening => _listening;
  Duration get elapsed => _elapsed;
  DictationNotice get notice => _notice;

  /// One bar height (0.3…1) per waveform bar, oldest first.
  List<double> get levels => List.unmodifiable(_levels);

  /// False until the mic has reported a usable spread of levels — the
  /// waveform falls back to its staggered loop until then.
  bool get hasLiveLevels =>
      _levelEvents >= 2 && _levelMax - _levelMin >= _minLevelSpread;
  static const _minLevelSpread = 1.0;

  /// Mic tap: start when idle, stop when listening.
  Future<void> toggle() => _listening ? stop() : start();

  Future<void> start() async {
    if (_listening || _starting || _disposed) return;
    _starting = true;
    final readiness = await service.prepare();
    _starting = false;
    if (_disposed) return;
    if (readiness != DictationReadiness.ready) {
      _notice = _noticeFor(readiness);
      notifyListeners();
      return;
    }

    final locale = await resolveLocale?.call();
    if (_disposed) return;
    if (locale != null && !locale.isAvailable) {
      // The page shows the "not available" state (design 2d); typing works.
      notifyListeners();
      return;
    }

    _notice = DictationNotice.none;
    _insertion = DictationInsertion.at(draft.value);
    _lastApplied = draft.text;
    _listening = true;
    _elapsed = Duration.zero;
    _levels = List<double>.filled(barCount, _minBar);
    _levelEvents = 0;
    _levelMin = double.infinity;
    _levelMax = double.negativeInfinity;
    // A previous, stopped session may still be settling; its late final
    // result belongs to the old anchor, so drop it.
    unawaited(_session?.cancel());
    _session = service
        .listen(
          pauseFor: silenceTimeout,
          listenFor: maxDuration,
          localeId: locale?.localeId,
        )
        .listen(_onEvent);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed += const Duration(seconds: 1);
      // Our own cap too, in case the platform doesn't honour listenFor.
      if (_elapsed >= maxDuration) {
        unawaited(stop());
      } else {
        notifyListeners();
      }
    });
    notifyListeners();
  }

  /// Stops listening and keeps what was heard. A late final result still
  /// lands, unless the user has edited the draft since.
  Future<void> stop() async {
    if (!_listening) return;
    _finish();
    await service.stop();
  }

  /// Stops listening and drops the session (closing the book on Cancel).
  Future<void> cancel() async {
    // A stopped session may still be waiting on its final result — drop
    // that too.
    final session = _session;
    _session = null;
    _insertion = null;
    _finish();
    if (session == null) return;
    unawaited(session.cancel());
    await service.cancel();
  }

  void _onEvent(DictationEvent event) {
    switch (event) {
      case DictationWords(:final words, :final isFinal):
        _applyWords(words, isFinal: isFinal);
      case DictationLevel(:final level):
        if (_listening) _pushLevel(level);
      case DictationEnded():
        _finish();
      case DictationFailed(:final reason):
        _notice = _noticeFor(reason);
        _finish();
    }
  }

  void _applyWords(String words, {required bool isFinal}) {
    final insertion = _insertion;
    // Ignore stragglers once stopped (unless final), and never overwrite
    // something the user typed in the meantime.
    if (insertion == null || (!_listening && !isFinal)) return;
    if (draft.text != _lastApplied) return;
    draft.applyDictation(
      insertion.apply(words),
      pending: isFinal || !_listening
          ? TextRange.empty
          : insertion.rangeOf(words),
    );
    _lastApplied = draft.text;
  }

  void _pushLevel(double raw) {
    _levelEvents++;
    _levelMin = math.min(_levelMin, raw);
    _levelMax = math.max(_levelMax, raw);
    final spread = _levelMax - _levelMin;
    final normalised = spread < _minLevelSpread
        ? 0.0
        : (raw - _levelMin) / spread;
    _levels = [..._levels.skip(1), _minBar + (1 - _minBar) * normalised];
    notifyListeners();
  }

  void _finish() {
    _ticker?.cancel();
    _ticker = null;
    draft.clearPending();
    if (!_listening) {
      if (!_disposed) notifyListeners();
      return;
    }
    _listening = false;
    if (!_disposed) notifyListeners();
  }

  static DictationNotice _noticeFor(DictationReadiness readiness) =>
      switch (readiness) {
        DictationReadiness.ready => DictationNotice.none,
        DictationReadiness.permissionDenied => DictationNotice.micOff,
        DictationReadiness.unavailable => DictationNotice.unavailable,
      };

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    final session = _session;
    _session = null;
    if (session != null) {
      unawaited(session.cancel());
      unawaited(service.cancel());
    }
    _listening = false;
    super.dispose();
  }
}
