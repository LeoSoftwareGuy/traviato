import 'package:equatable/equatable.dart';

/// Domain-boundary error currency.
///
/// Repositories catch [AppException]s and return `Either<Failure, T>`. The
/// presentation layer converts a [Failure] into a user-facing string (see
/// `failure_message.dart`).
abstract class Failure extends Equatable {
  const Failure({required this.message});

  final String message;

  @override
  List<Object> get props => [message];

  @override
  String toString() => '$runtimeType: $message';
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message});
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'Please check your connection.'});
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure({required super.message});
}

class PermissionFailure extends Failure {
  const PermissionFailure({super.message = 'You do not have permission.'});
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({
    super.message = 'The requested data was not found.',
  });
}

class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'An unknown error occurred. Try again later.',
  });
}

class FreeTierLimitFailure extends Failure {
  const FreeTierLimitFailure({
    super.message =
        'Free plan is limited to 3 memories. Upgrade to Pro for unlimited '
        'memories.',
  });
}

/// Server-side counterpart is TRV02 (#139) — a free user at the 40-photo
/// cap for one memory. Deliberately distinct from [FreeTierLimitFailure] so
/// the UI can tell which cap was hit even though both point at the same
/// upgrade prompt.
class PhotoLimitFailure extends Failure {
  const PhotoLimitFailure({
    super.message =
        'Free plan is limited to 40 photos per memory. Upgrade to Pro for '
        'unlimited photos.',
  });
}
