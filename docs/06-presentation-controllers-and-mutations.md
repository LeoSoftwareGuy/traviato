# 06 — Presentation: Controllers, State, Mutations, Pages

Split the presentation layer by responsibility:

- **controllers/** — Riverpod notifiers holding *displayed* screen state (`+ *_state.dart`
  for the immutable state class when the state is non-trivial).
- **mutations/** — one-shot user actions (submit, delete, like) as Riverpod `Mutation`s.
- **providers/** — DI wiring (data source / repository providers) for the feature.
- **pages/** — full-screen `ConsumerWidget` / `ConsumerStatefulWidget`.
- **widgets/** — feature-local reusable widgets.

## Controllers + state classes

For anything beyond a single value, define a dedicated immutable state class (Equatable +
`copyWith`) and drive it from an `AsyncNotifier`.

```dart
enum PostListStatus { initial, loaded, failure, fetchingNextPage, refreshing }

class PostListState extends Equatable {
  const PostListState({
    this.status = PostListStatus.initial,
    this.posts = const [],
    this.hasReachedMax = false,
    this.failure,             // blocking failure (no data)
    this.transientFailure,    // secondary failure (data still shown)
  });

  final PostListStatus status;
  final List<PostDisplay> posts;
  final bool hasReachedMax;
  final Failure? failure;
  final Failure? transientFailure;

  @override
  List<Object?> get props => [status, posts, hasReachedMax, failure, transientFailure];

  PostListState copyWith({
    PostListStatus? status,
    List<PostDisplay>? posts,
    bool? hasReachedMax,
    Failure? Function()? failure,             // wrapper -> can clear to null
    Failure? Function()? transientFailure,
  }) => PostListState(
    status: status ?? this.status,
    posts: posts ?? this.posts,
    hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    failure: failure != null ? failure() : this.failure,
    transientFailure: transientFailure != null ? transientFailure() : this.transientFailure,
  );
}
```

### The AsyncNotifier controller

```dart
const _pageSize = 20;

@riverpod
class PostListController extends _$PostListController {
  @override
  Future<PostListState> build() async {
    final repo = ref.watch(postRepositoryProvider);
    final result = await repo.getPosts(offset: 0, limit: _pageSize);
    return result.fold(
      (f) => PostListState(status: PostListStatus.failure, failure: f),
      (posts) => PostListState(
        status: PostListStatus.loaded,
        posts: posts,
        hasReachedMax: posts.length < _pageSize,
      ),
    );
  }

  Future<void> fetchNextPage() async {
    final snapshot = state.value;
    if (snapshot == null || state.isLoading) return;
    if (snapshot.hasReachedMax || snapshot.status == PostListStatus.fetchingNextPage) return;

    state = AsyncData(snapshot.copyWith(status: PostListStatus.fetchingNextPage));

    final result = await ref.read(postRepositoryProvider)
        .getPosts(offset: snapshot.posts.length, limit: _pageSize);

    if (!ref.mounted) return;               // guard after await
    final latest = state.value;             // re-read latest, don't trust snapshot
    if (latest == null) return;

    state = AsyncData(result.fold(
      (f) => latest.copyWith(status: PostListStatus.loaded, transientFailure: () => f),
      (newPosts) => latest.copyWith(
        status: PostListStatus.loaded,
        posts: [...latest.posts, ...newPosts],
        hasReachedMax: newPosts.length < _pageSize,
      ),
    ));
  }

  void consumeTransientFailure() {
    final c = state.value;
    if (c == null) return;
    state = AsyncData(c.copyWith(transientFailure: () => null));
  }
}
```

Key notes:
- Initial load failure → a **blocking** `failure` field (full-screen error + retry).
- Pagination/refresh failure → **transient** failure (keep list, snackbar once).
- Always `if (!ref.mounted) return;` after each `await` in a notifier, then re-read `state.value`.
  In `StatefulWidget` async methods (rarely needed with Riverpod), the equivalent is `if (!context.mounted) return;`.
- `_pageSize` is a private top-level const per controller.

## Optimistic updates

Update the UI immediately, call the backend, then reconcile with the authoritative result or
roll back on failure.

```dart
Future<void> toggleLike(PostDisplay post) async {
  final original = post;
  final optimistic = original.copyWith(
    currentUserLiked: !original.currentUserLiked,
    likesCount: original.currentUserLiked ? original.likesCount - 1 : original.likesCount + 1,
  );
  _applyUpdatedPost(optimistic);                       // instant UI

  final result = await ref.read(postRepositoryProvider).toggleLike(original.postId);
  if (!ref.mounted) return;

  result.fold(
    (failure) {
      _applyUpdatedPost(original);                     // rollback
      throw PresentationFailureException(failure);     // surfaced via the mutation
    },
    (likeResult) => _applyUpdatedPost(original.copyWith(
      currentUserLiked: likeResult.liked, likesCount: likeResult.likesCount,
    )),
  );
}
```

## Mutations for one-shot actions

Actions the user triggers (login, create, delete, like) are **Mutations**, defined next to
the controller. They own `pending / error / success` for a single run and keep the
controller's state clean. Multi-step orchestration lives inside the mutation body:

```dart
final createPostMutation = Mutation<PostDisplay>();

Future<PostDisplay> runCreatePost({
  required WidgetRef ref, required String title, required String content, File? imageFile,
}) {
  return createPostMutation.run(ref, (tsx) async {
    final repo = tsx.get(postRepositoryProvider);

    String? postId, imageUrl;
    if (imageFile != null) {
      (await repo.uploadPostImage(image: imageFile)).fold(
        (f) => throw PresentationFailureException(f),
        (r) { postId = r.postId; imageUrl = r.imageUrl; },
      );
    }
    return (await repo.createPost(
      postId: postId, title: title, content: content, imageUrl: imageUrl,
    )).fold(
      (f) => throw PresentationFailureException(f),
      (created) {
        tsx.get(globalEventBusProvider).add(PostCreatedDispatched(post: created)); // notify lists
        return created;
      },
    );
  });
}
```

Use a **keyed** mutation when the action is per-item: `toggleLikeMutation(post.id).run(...)`.

## Pages

- Use `ConsumerWidget` for stateless screens; `ConsumerStatefulWidget` when you need
  `TextEditingController`s, `GlobalKey<FormState>`, local `AutovalidateMode`, etc.
- `ref.listen` mutations for side-effects (snackbars, navigation); `ref.watch` them for the
  submit button's loading/disabled state.
- Dispose every controller you create (`TextEditingController`, `ScrollController`).

```dart
class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  var _autovalidate = AutovalidateMode.disabled;

  @override
  void dispose() { _email.dispose(); super.dispose(); }

  Future<void> _submit() async {
    setState(() => _autovalidate = AutovalidateMode.always);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await runLogin(ref: ref, email: _email.text.trim(), password: /*...*/ '');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<MutationState<void>>(loginMutation, (prev, next) {
      if (next is MutationError) {
        showErrorSnackbar(context, message: presentationFailureMessage(next.error));
      }
    });
    final isLoading = ref.watch(loginMutation) is MutationPending;
    // disable fields/buttons while isLoading; show a small spinner in the button
    // ...
  }
}
```

## Rendering `AsyncValue`

Use `.when` (or pattern matching) and handle all three states. On error, show the shared
retry widget wired to `ref.invalidate(controllerProvider)` or a controller `refresh()`:

```dart
final async = ref.watch(postListControllerProvider);
return async.when(
  loading: () => const Center(child: CircularProgressIndicator()),
  error: (e, _) => AsyncErrorRetryScaffold(
    message: presentationFailureMessage(e),
    onRetry: () => ref.invalidate(postListControllerProvider),
  ),
  data: (state) => /* list UI, react to state.transientFailure via ref.listen */,
);
```

## Rules

- Widgets never call a repository/data source directly — go through a controller or mutation.
- Business/orchestration logic never lives in `build()` of a widget.
- Validation lives in the form (`TextFormField.validator`); set `AutovalidateMode.always`
  only after the first submit attempt.
- Keep pages thin: extract list items, cards, and inputs into `widgets/`.
