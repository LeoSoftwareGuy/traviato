import '../../l10n/app_localizations.dart';
import 'failures.dart';
import 'presentation_failure_exception.dart';

/// Converts any error object surfaced to the presentation layer into a
/// user-facing string. Use this when handling `MutationError` / `AsyncError`.
///
/// Failures whose copy the app writes itself are translated through [l10n]
/// (#220). [Failure.message] stays English for logs; server- or
/// exception-provided messages (e.g. an [AuthenticationFailure] from
/// Supabase, an [UnknownFailure] carrying an exception message) pass through
/// as they are.
String presentationFailureMessage(Object error, AppLocalizations l10n) {
  final failure = switch (error) {
    PresentationFailureException(:final failure) => failure,
    Failure() => error,
    _ => null,
  };
  if (failure == null) return error.toString();
  return _localizedMessage(failure, l10n) ?? failure.message;
}

String? _localizedMessage(Failure failure, AppLocalizations l10n) {
  return switch (failure) {
    NetworkFailure() when failure == const NetworkFailure() =>
      l10n.error_network,
    PermissionFailure() when failure == const PermissionFailure() =>
      l10n.error_permission,
    NotFoundFailure() when failure == const NotFoundFailure() =>
      l10n.error_notFound,
    UnknownFailure() when failure == const UnknownFailure() =>
      l10n.error_unknown,
    AuthLinkFailure() when failure == const AuthLinkFailure() =>
      l10n.error_authLink,
    FreeTierLimitFailure() => l10n.error_freeTierMemories,
    PhotoLimitFailure() => l10n.error_freeTierPhotos,
    QuestPlanningClosedFailure() => l10n.error_questPlanningClosed,
    RateLimitedFailure(isEmailQuota: true) => l10n.error_rateLimitedEmail,
    RateLimitedFailure(:final retryAfterSeconds?) when retryAfterSeconds > 0 =>
      l10n.error_rateLimitedSeconds(retryAfterSeconds),
    RateLimitedFailure() => l10n.error_rateLimited,
    _ => null,
  };
}
