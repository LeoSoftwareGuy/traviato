/// Data-layer error currency.
///
/// Data sources catch SDK/network errors and translate them into these typed
/// exceptions (see the canonical Supabase `catch` ladder in guidelines doc 04).
/// They must never escape the data layer — repositories map them to [Failure]s.
library;

class AppException implements Exception {
  const AppException({required this.message});

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class AuthenticationException extends AppException {
  const AuthenticationException({required super.message});
}

/// The user dismissed a native social sign-in sheet (Apple/Google) without
/// completing it — not an error, so the repository maps this to a silent
/// no-op instead of a [Failure] (issue #84).
class SignInCancelledException extends AppException {
  const SignInCancelledException({
    super.message = 'Sign-in was cancelled.',
  });
}

/// The user dismissed the native store purchase/restore sheet without
/// completing it — not an error, mirrors [SignInCancelledException] (#138).
class PurchaseCancelledException extends AppException {
  const PurchaseCancelledException({
    super.message = 'Purchase was cancelled.',
  });
}

class DatabaseException extends AppException {
  const DatabaseException({required super.message});
}

class PermissionException extends DatabaseException {
  const PermissionException({required super.message});
}

class NotFoundException extends DatabaseException {
  const NotFoundException({required super.message});
}

/// The free-tier memory cap (TRV01) or photo-per-memory cap (TRV02) was
/// rejected server-side (#139) — maps to [FreeTierLimitFailure]/
/// [PhotoLimitFailure] rather than a generic [DatabaseException] so the UI
/// can point at the paywall instead of a dead-end error. The 2,000/memory
/// hard ceiling (TRV03) deliberately does NOT get its own exception type —
/// it falls through to the generic [DatabaseException] mapping, since it's
/// never framed as an upsell and the DB's own message is already the right
/// generic copy to show as-is.
class MemoryLimitException extends DatabaseException {
  const MemoryLimitException({required super.message});
}

class PhotoLimitException extends DatabaseException {
  const PhotoLimitException({required super.message});
}

class StorageServerException extends AppException {
  const StorageServerException({required super.message});
}

/// An edge function ran but the underlying operation it performs failed
/// (e.g. `generate_wrap_up`'s Anthropic call failing after its retry) —
/// distinct from auth/permission/not-found, which map to their own
/// exceptions. Maps to [ServerFailure].
class ServerException extends AppException {
  const ServerException({required super.message});
}

class NetworkException extends AppException {
  const NetworkException({
    super.message = 'Network connection failed. Check your internet.',
  });
}

class UnknownException extends AppException {
  const UnknownException({super.message = 'An unknown error occurred.'});
}
