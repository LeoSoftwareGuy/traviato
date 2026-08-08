# 09 — Naming & Style Cheatsheet

## File naming (snake_case, role suffix)

| Kind | Pattern | Example |
|------|---------|---------|
| Entity | `<name>_entity.dart` | `user_entity.dart` |
| Model | `<name>_model.dart` | `post_display_model.dart` |
| Repository interface | `<name>_repository.dart` | `auth_repository.dart` |
| Repository impl | `<name>_repository_impl.dart` | `auth_repository_impl.dart` |
| Data source interface | `<name>_remote_data_source.dart` | `post_remote_data_source.dart` |
| Data source impl | `supabase_<name>_remote_data_source.dart` | `supabase_post_remote_data_source.dart` |
| Controller | `<name>_controller.dart` | `post_list_controller.dart` |
| Controller state | `<name>_state.dart` | `post_list_state.dart` |
| Mutations | `<feature>_mutations.dart` | `post_mutations.dart` |
| DI providers | `<feature>_providers.dart` | `post_providers.dart` |
| Page | `<name>_page.dart` | `login_page.dart` |
| Use case (if used) | `<verb>_<noun>_usecase.dart` | `update_post_usecase.dart` |

## Type / member naming

| Thing | Convention | Example |
|-------|-----------|---------|
| Classes / enums | `UpperCamelCase` | `PostListController`, `AuthStatus` |
| Generated DI provider | `camelCase` + `Provider` | `authRepositoryProvider` (from `authRepository`) |
| Mutation object | `<action>Mutation` | `loginMutation`, `toggleLikeMutation` |
| Mutation runner fn | `run<Action>` | `runLogin`, `runCreatePost` |
| Event classes | `<Subject><PastVerb>Dispatched` | `PostCreatedDispatched` |
| Private fields | leading `_` | `_client`, `_formKey` |
| Constants holders | `abstract class` of `static const` | `Tables`, `RoutePaths` |
| Page-size / tuning consts | private top-level `_camelCase` | `const _pageSize = 20;` |

## Constructor conventions

- Named required params for anything with 2+ arguments:
  `SupabaseAuthRemoteDataSource({required SupabaseClient client})`.
- Store the injected abstraction into a private final via initializer list:
  `: _client = client`.
- `const` constructors on all entities/state/DTO classes.

## Barrels / exports

In a **single-package** app you generally don't need barrel files — import the specific file.
Only add a barrel (`<feature>.dart` re-exporting its public surface) if a feature's public API
is imported from many places and you want a stable import path. Don't build the
`src/` + barrel machinery the reference packages use; that's a pub-package concern.

## Formatting & lints

- `flutter_lints` on. Fix all analyzer warnings before committing.
- Run `dart format .`; keep the default 80-col trailing-comma style (trailing commas so the
  formatter lays out widget trees vertically).
- Keep `const` everywhere the analyzer allows (`prefer_const_constructors`).

## Quick do / don't

| ✅ Do | ❌ Don't |
|------|---------|
| Import `supabase_flutter` only in `data/` | Touch Supabase from a widget or controller |
| Return `Either<Failure, T>` from repos | Let exceptions escape the data layer |
| `Model extends Entity` with `@JsonKey` | Put `fromJson` on entities |
| `ref.watch` in `build`, `ref.read` in callbacks | `ref.watch` inside a button handler |
| Guard `if (!ref.mounted) return;` after awaits | Mutate `state` after an await unguarded |
| One-shot actions → `Mutation` | Cram submit/delete into watched controller state |
| Skip pass-through use cases | One use-case class per repo method by default |
| Navigate by `RouteNames` + params | Concatenate route path strings |
| Table/RPC/bucket names in constants classes | Hard-code `'posts'`, `'post_display_view'` inline |
| `sealed` event base + exhaustive `switch` | `if (event is X)` chains without a sealed type |
| `copyWith(String? Function()? field)` for clearable nullables | Lose the ability to set a field back to `null` |
| Clean up subs/notifiers in `ref.onDispose` | Leak subscriptions from `keepAlive` providers |
| Feature-first folders in one package | Split every layer into its own pub package |

## Env & secrets

- Supabase URL + publishable key come from `.env` via `flutter_dotenv`; load in `main`:
  ```dart
  await dotenv.load(fileName: '.env');
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_PUBLISHABLE_KEY']!,
  );
  ```
- `.env` is git-ignored and listed under `flutter/assets:` in `pubspec.yaml`.
- Never commit keys; never put the service-role key in the app.

## `main.dart` skeleton

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_PUBLISHABLE_KEY']!,
  );
  runApp(ProviderScope(retry: (_, __) => null, child: const MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
    routerConfig: ref.watch(routerProvider),
  );
}
```
