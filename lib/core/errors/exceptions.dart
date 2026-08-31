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

class DatabaseException extends AppException {
  const DatabaseException({required super.message});
}

class PermissionException extends DatabaseException {
  const PermissionException({required super.message});
}

class NotFoundException extends DatabaseException {
  const NotFoundException({required super.message});
}

class StorageServerException extends AppException {
  const StorageServerException({required super.message});
}

class NetworkException extends AppException {
  const NetworkException({
    super.message = 'Network connection failed. Check your internet.',
  });
}

class UnknownException extends AppException {
  const UnknownException({super.message = 'An unknown error occurred.'});
}
