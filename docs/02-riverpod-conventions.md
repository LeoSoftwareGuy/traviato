# 02 — Riverpod Conventions (code-gen)

Always use the generator. Every file with providers ends with `part '<name>.g.dart';` and is
built by `dart run build_runner watch -d`.

## Three kinds of providers

### 1. Dependency-injection providers (plain functions)

These construct objects and wire dependencies. They are your DI container. Type the return
as the **domain interface**, return the **data implementation**.

```dart
// features/auth/presentation/providers/auth_providers.dart
part 'auth_providers.g.dart';

// data source: interface <- supabase implementation
@riverpod
AuthRemoteDataSource authRemoteDataSource(Ref ref) =>
    SupabaseAuthRemoteDataSource(client: ref.watch(supabaseClientProvider));

// repository: domain interface <- data implementation
@riverpod
AuthRepository authRepository(Ref ref) =>
    AuthRepositoryImpl(remote: ref.watch(authRemoteDataSourceProvider));
```

Rules:
- One provider per dependency. Compose with `ref.watch(...)`.
- Return type is the **abstraction** (`AuthRepository`), never the concrete class. This is
  what makes the whole app testable — override the provider in tests.
- No state here, just construction.

### 2. Shared singletons — `keepAlive`

Things that must live for the whole app session use `@Riverpod(keepAlive: true)`:

```dart
@Riverpod(keepAlive: true)
SupabaseClient supabaseClient(Ref ref) => Supabase.instance.client;
```

Use `keepAlive` sparingly: the Supabase client, an app-wide realtime connection, an event
bus. Everything else should be auto-disposed (the default) so state resets when no screen
needs it.

### 3. State controllers — `@riverpod class`

Screen/feature state uses a generated Notifier. Sync state returns a plain value; async state
returns a `Future<T>` (generates an `AsyncNotifier`, UI gets `AsyncValue<T>`).

```dart
@riverpod
class AuthController extends _$AuthController {
  @override
  AuthState build() {
    final repo = ref.watch(authRepositoryProvider);
    final sub = repo.onAuthStateChanged.listen((user) {
      state = user == null
          ? const AuthState.unauthenticated()
          : AuthState.authenticated(user);
    });
    ref.onDispose(sub.cancel);        // ALWAYS clean up subscriptions
    return const AuthState.unknown(); // initial state
  }

  // imperative methods mutate `state = ...`
}
```

For data you load once and display:

```dart
@riverpod
class MyProfileController extends _$MyProfileController {
  @override
  Future<UserEntity> build() async {
    final id = ref.watch(authControllerProvider).user?.id;
    if (id == null) throw const AuthenticationFailure(message: 'Not logged in');
    final repo = ref.watch(profileRepositoryProvider);
    return repo.getProfile(id).getOrThrowFailure(); // fold Either -> value/throw
  }
}
```

## `ref.watch` vs `ref.read` vs `ref.listen`

| Use | When |
|-----|------|
| `ref.watch(p)` | Inside `build()` / widget `build` — reactive dependency. Rebuilds on change. |
| `ref.read(p)`  | Inside a callback / imperative method — one-shot read, no subscription. |
| `ref.listen(p, cb)` | Run a side-effect on change (show snackbar, bump router refresh). |

Never call `ref.watch` inside a button handler; never rely on `ref.read` for something that
should rebuild the UI.

## Lifecycle & safety

- **Clean up** every `StreamSubscription`, `ValueNotifier`, `StreamController` in
  `ref.onDispose(...)`.
- **After every `await` in a notifier method, guard with `if (!ref.mounted) return;`** before
  touching `state`. The provider may have been disposed while awaiting.
- Re-read the latest state after an await (`final latest = state.value;`) instead of trusting
  a snapshot captured before the await — other events may have changed it.

## AsyncNotifier state updates (manual, without re-running `build`)

For lists you mutate in place (pagination, optimistic edits) set `state` directly with
`AsyncData` wrapping a `copyWith` of the current value:

```dart
final current = state.value;
if (current == null) return;
state = AsyncData(current.copyWith(posts: [newPost, ...current.posts]));
```

Only call `ref.invalidateSelf()` / return from `build` again when you truly want a full reload.

## Mutations — for one-shot actions (Riverpod 3)

Do **not** model "submit login", "delete post", "toggle like" as watched controller state.
Use a **Mutation**: it gives you `idle / pending / error / success` for a single invocation,
without polluting your screen-state notifier.

```dart
import 'package:flutter_riverpod/experimental/mutation.dart';

final loginMutation = Mutation<void>();

Future<void> runLogin({required WidgetRef ref, required String email, required String pw}) {
  return loginMutation.run(ref, (tsx) async {
    final repo = tsx.get(authRepositoryProvider);          // tsx.get inside a mutation
    (await repo.login(email: email, password: pw)).fold(
      (failure) => throw PresentationFailureException(failure), // throw -> MutationError
      (_) {},                                                   // return -> MutationSuccess
    );
  });
}
```

Key mutation used with a **key** when the action is per-item (per post):

```dart
final toggleLikeMutation = Mutation<void>();
// call: toggleLikeMutation(post.id).run(ref, (tsx) => ...);
```

In the widget, watch the mutation for the button's loading state and `ref.listen` it to show
errors:

```dart
ref.listen<MutationState<void>>(loginMutation, (prev, next) {
  if (next is MutationError) {
    showErrorSnackbar(context, message: presentationFailureMessage(next.error));
  }
});
final isLoading = ref.watch(loginMutation) is MutationPending;
```

See [06](06-presentation-controllers-and-mutations.md) for full page examples.

## Global retry policy

Disable Riverpod's automatic retry unless you want it, at the root:

```dart
runApp(ProviderScope(retry: (_, __) => null, child: const MyApp()));
```

Handle retries explicitly with a Retry button instead of silent background retries.
