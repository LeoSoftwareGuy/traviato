# 08 — Cross-Feature Communication (Global Event Bus)

## The problem

Independent screens hold their own state. When one screen mutates data, others showing the
same data go stale:

- Create a post on the form page → the feed list should prepend it.
- Toggle a like on the detail page → the feed card should reflect the new count.
- Edit your profile → every post authored by you should show the new username/avatar.

You don't want these controllers to `ref.watch` each other (tight coupling, rebuild storms,
circular deps). Use a lightweight **broadcast event bus**: publishers fire typed events,
interested controllers subscribe and patch their own state.

## The bus

```dart
// core/events/global_event_bus.dart
class GlobalEventBus {
  final _controller = StreamController<GlobalEvent>.broadcast();
  Stream<GlobalEvent> get stream => _controller.stream;
  void add(GlobalEvent event) => _controller.add(event);
  void dispose() => _controller.close();
}
```

Expose it as a **keepAlive** provider so it survives screen disposal:

```dart
@Riverpod(keepAlive: true)
GlobalEventBus globalEventBus(Ref ref) {
  final bus = GlobalEventBus();
  ref.onDispose(bus.dispose);
  return bus;
}
```

## The events — a sealed hierarchy

Model every cross-feature signal as a `final` subclass of a `sealed` base. Sealed → the
`switch` in subscribers is exhaustive and the compiler flags any unhandled new event.

```dart
// core/events/global_event.dart
sealed class GlobalEvent extends Equatable {
  const GlobalEvent();
  @override
  List<Object?> get props => [];
}

final class PostCreatedDispatched extends GlobalEvent {
  const PostCreatedDispatched({required this.post});
  final PostDisplay post;
  @override
  List<Object?> get props => [post];
}

final class PostUpdatedDispatched extends GlobalEvent {
  const PostUpdatedDispatched({required this.post});
  final PostDisplay post;
  @override
  List<Object?> get props => [post];
}

final class PostDeletedDispatched extends GlobalEvent {
  const PostDeletedDispatched({required this.postId});
  final String postId;
  @override
  List<Object?> get props => [postId];
}

final class ProfileUpdatedDispatched extends GlobalEvent {
  const ProfileUpdatedDispatched({required this.profile});
  final UserEntity profile;
  @override
  List<Object?> get props => [profile];
}
```

## Publishing

Fire after a successful mutation (inside the mutation body, using `tsx.get`, or from a
controller with `ref.read`):

```dart
tsx.get(globalEventBusProvider).add(PostCreatedDispatched(post: created));
```

## Subscribing

Subscribe in the controller's `build()` and reduce each event into a local `state` patch.
Cancel the subscription on dispose.

```dart
@override
Future<PostListState> build() async {
  final sub = ref.watch(globalEventBusProvider).stream.listen(_onEvent);
  ref.onDispose(sub.cancel);
  // ... initial load ...
}

void _onEvent(GlobalEvent event) {
  final current = state.value;
  if (current == null) return;
  switch (event) {
    case PostCreatedDispatched(:final post):   _prepend(post);
    case PostUpdatedDispatched(:final post):   _applyUpdated(post);
    case PostDeletedDispatched(:final postId): _remove(postId);
    case ProfileUpdatedDispatched(:final profile): _applyProfileToPosts(profile);
  }
}
```

Use destructuring patterns (`:final post`) to pull payloads out of each event.

## Rules & cautions

- **Events describe facts that already happened** ("PostCreated"), not commands. The
  publisher already did the work and persisted it; subscribers only sync their view.
- **Idempotent handlers.** Guard against duplicates (`if (posts.any((p) => p.id == new.id))
  return;`) — a broadcast stream may reach a controller that already applied the change
  optimistically.
- **Keep payloads as domain entities**, not models/DTOs.
- **Don't defer/lose events during a refresh.** If a controller is mid-refresh when an event
  arrives, either apply it after the refresh completes or re-fetch — decide per controller.
- **Don't overuse it.** The bus is for genuinely independent screens. If one widget simply
  needs another's data, prefer `ref.watch` of a shared provider. Reach for the bus only when
  two features would otherwise have to depend on each other.
- Because the bus is `keepAlive`, subscribers **must** cancel in `onDispose` or you leak.

## Alternative: Supabase Realtime

For data that should update from **other users'** actions (not just this device), subscribe
to Supabase Realtime in a `keepAlive` data source and expose a
`Stream<Either<Failure, T>>` provider that controllers watch. Use the event bus for
*local* echoing (this device's own writes) and Realtime for *remote* changes — they compose.
