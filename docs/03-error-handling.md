# 03 — Error Handling

Errors flow through three named stages. Each layer only knows its own type.

```
Supabase / SDK error
      │  (data source catches, maps, throws)
      ▼
AppException  ── exceptions.dart ──  data layer currency
      │  (repository catches, maps, returns)
      ▼
Either<Failure, T>  ── failures.dart ── domain boundary currency
      │  (controller/mutation folds)
      ▼
String message  ──  UI (snackbar / retry widget)
```

## Layer 1 — Exceptions (data layer throws these)

Defined in `core/errors/exceptions.dart`. A base `AppException` plus specific subtypes.

```dart
class AppException implements Exception {
  const AppException({required this.message});
  final String message;
  @override
  String toString() => '$runtimeType: $message';
}

class AuthenticationException extends AppException { const AuthenticationException({required super.message}); }
class DatabaseException     extends AppException { const DatabaseException({required super.message}); }
class PermissionException   extends DatabaseException { const PermissionException({required super.message}); }
class NotFoundException     extends DatabaseException { const NotFoundException({required super.message}); }
class StorageServerException extends AppException { const StorageServerException({required super.message}); }
class NetworkException      extends AppException {
  const NetworkException({super.message = 'Network connection failed. Check your internet.'});
}
class UnknownException      extends AppException { const UnknownException({super.message = 'An unknown error occurred.'}); }
```

**Data sources** wrap every remote call in `try/on/catch` and translate SDK errors into these
(see [04](04-data-layer-supabase.md) for the canonical Supabase mapping).

## Layer 2 — Failures (domain returns these)

Defined in `core/errors/failures.dart`. `Failure extends Equatable` with a `message`.

```dart
abstract class Failure extends Equatable {
  const Failure({required this.message});
  final String message;
  @override
  List<Object> get props => [message];
  @override
  String toString() => '$runtimeType: $message';
}

class ServerFailure         extends Failure { const ServerFailure({required super.message}); }
class NetworkFailure        extends Failure { const NetworkFailure({super.message = 'Please check your connection.'}); }
class AuthenticationFailure extends Failure { const AuthenticationFailure({required super.message}); }
class PermissionFailure     extends Failure { const PermissionFailure({super.message = 'You do not have permission.'}); }
class NotFoundFailure       extends Failure { const NotFoundFailure({super.message = 'The requested data was not found.'}); }
class UnknownFailure        extends Failure { const UnknownFailure({super.message = 'An unknown error occurred. Try again later.'}); }
```

**Repositories** catch `AppException`s and return `Left(Failure)` / `Right(value)`:

```dart
@override
Future<Either<Failure, void>> login({required String email, required String password}) async {
  try {
    await _remote.login(email: email, password: password);
    return const Right(null);
  } on AuthenticationException catch (e) {
    return Left(AuthenticationFailure(message: e.message));
  } on NetworkException {
    return const Left(NetworkFailure());
  } on AppException catch (e) {
    return Left(UnknownFailure(message: e.message));
  }
}
```

> Return type is **always** `Future<Either<Failure, T>>` for repository methods that can fail.
> Streams that can fail use `Stream<Either<Failure, T>>` **or** emit a safe fallback and log
> (the auth stream in the reference emits `null` on error rather than an `Either`).

## Layer 3 — Presentation

The domain speaks `Either`. The UI needs a `String`. Bridge with a small exception type so
`Either` failures can travel through `throw` inside Mutations/AsyncNotifiers:

```dart
// core/errors/presentation_failure_exception.dart
class PresentationFailureException implements Exception {
  PresentationFailureException(this.failure);
  final Failure failure;
  @override
  String toString() => failure.message;
}

String presentationFailureMessage(Object error) {
  if (error is PresentationFailureException) return error.failure.message;
  if (error is Failure) return error.message;
  return error.toString();
}
```

Pattern in a controller/mutation — fold the `Either`, throw on `Left`:

```dart
final result = await repo.getProfile(id);
return result.fold(
  (failure) => throw PresentationFailureException(failure), // -> AsyncError / MutationError
  (profile) => profile,
);
```

Pattern in the widget — turn the error into a message:

```dart
ref.listen(loginMutation, (prev, next) {
  if (next is MutationError) {
    showErrorSnackbar(context, message: presentationFailureMessage(next.error));
  }
});
```

## Transient vs blocking failures

Distinguish two UX cases:

- **Blocking failure** — the screen has no data to show (initial load failed). Render a
  full-screen error + Retry (`AsyncError` on the notifier, or a `failure` field on state).
- **Transient failure** — the screen already shows data and a *secondary* action failed
  (pagination page 3 failed, a like toggle failed). Keep the data on screen, surface the
  error as a one-shot snackbar. Model it as a nullable `transientFailure` field on state that
  the UI shows once then clears via `consumeTransientFailure()`.

## Unexpected errors

For truly unexpected `catch (e, st)` blocks, log and degrade — never crash the notifier:

```dart
Failure logUnexpectedFailure(Object error, StackTrace st) {
  debugPrint('Unexpected error: $error\n$st');
  return kDebugMode ? UnknownFailure(message: '$error') : const UnknownFailure();
}
```

Show the raw message only in debug; a generic message in release.

## Rules

- Never `print`/swallow an error silently; either map it to a `Failure` or log it.
- Never let a `PostgrestException`, `AuthException`, `StorageException`, or `SocketException`
  escape the data layer.
- Never show `error.toString()` of an unknown object directly to users in release builds.
- One `on SocketException` → `NetworkException`/`NetworkFailure` mapping everywhere, so
  offline handling is uniform.
