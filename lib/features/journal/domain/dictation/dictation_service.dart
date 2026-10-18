import 'package:equatable/equatable.dart';

/// Whether voice dictation can be used right now.
enum DictationReadiness {
  ready,

  /// The user turned off the microphone or speech recognition.
  permissionDenied,

  /// No recogniser on the device, offline, or the platform failed.
  unavailable,
}

/// What a listening session reports, in order, until it ends with
/// [DictationEnded] or [DictationFailed].
sealed class DictationEvent extends Equatable {
  const DictationEvent();

  @override
  List<Object?> get props => [];
}

/// The session's transcript so far — cumulative, not a delta. [isFinal]
/// once the recogniser has settled on it.
class DictationWords extends DictationEvent {
  const DictationWords(this.words, {required this.isFinal});

  final String words;
  final bool isFinal;

  @override
  List<Object?> get props => [words, isFinal];
}

/// Raw microphone level from the platform. Its scale differs between
/// Android and iOS, so callers normalise it per session.
class DictationLevel extends DictationEvent {
  const DictationLevel(this.level);

  final double level;

  @override
  List<Object?> get props => [level];
}

/// Listening stopped normally: the user stopped it, a pause in speech, or
/// the time cap.
class DictationEnded extends DictationEvent {
  const DictationEnded();
}

/// Listening stopped because something went wrong.
class DictationFailed extends DictationEvent {
  const DictationFailed(this.reason);

  final DictationReadiness reason;

  @override
  List<Object?> get props => [reason];
}

/// The platform speech recogniser behind the note page's mic
/// (docs/design/JOURNAL_NOTE_PAGETURN_SPEC.md §4). One session at a time.
abstract class DictationService {
  /// Asks for microphone + speech permission on first use. Safe to call
  /// again, e.g. after the user was told the mic is off.
  Future<DictationReadiness> prepare();

  /// The recogniser's locale ids ("ru_RU", "et_EE", …). With
  /// [askPermission] false this never shows a permission dialog: it returns
  /// `null` (unknown) until the user has granted speech access (#218).
  Future<List<String>?> supportedLocaleIds({required bool askPermission});

  /// Starts a session with partial results, in [localeId] (one of
  /// [supportedLocaleIds]) or the device locale when `null`. The
  /// recogniser stops itself after [pauseFor] of silence or [listenFor] in
  /// total. The stream closes after its last event.
  Stream<DictationEvent> listen({
    required Duration pauseFor,
    required Duration listenFor,
    String? localeId,
  });

  /// Ends the session and keeps what was heard.
  Future<void> stop();

  /// Ends the session and drops anything still pending.
  Future<void> cancel();
}
