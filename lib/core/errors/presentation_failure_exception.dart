import 'failures.dart';

/// Bridges a domain [Failure] back into the exception channel so it can travel
/// through `throw` inside Mutations / AsyncNotifiers (which surface errors as
/// `MutationError` / `AsyncError`). The widget layer then converts it to a
/// message via `presentationFailureMessage` (see `failure_message.dart`).
class PresentationFailureException implements Exception {
  PresentationFailureException(this.failure);

  final Failure failure;

  @override
  String toString() => failure.message;
}
