import 'failures.dart';
import 'presentation_failure_exception.dart';

/// Converts any error object surfaced to the presentation layer into a
/// user-facing string. Use this when handling `MutationError` / `AsyncError`.
String presentationFailureMessage(Object error) {
  if (error is PresentationFailureException) return error.failure.message;
  if (error is Failure) return error.message;
  return error.toString();
}
