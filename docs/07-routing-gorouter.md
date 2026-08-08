# 07 — Routing (go_router)

One router for the whole app, exposed as a `@riverpod GoRouter` so it can react to auth
state. Route paths and names live in a constants file — never inline string literals.

## Route constants

```dart
// core/config/router/route_constants.dart
abstract class RoutePaths {
  static const splash = '/splash';
  static const login  = '/login';
  static const signup = '/signup';
  static const post    = '/post';
  static const search  = '/search';
  static const profile = '/profile';

  static const postCreate = '/create';
  static const userDetail = '/user/:userId';          // path param
  static const postDetail = '/post-detail/:postId';
  static const postEdit   = 'edit';                   // sub-route (relative, no leading /)
  static const profileEdit = 'edit';
}

abstract class RouteNames {
  static const splash = 'splash';
  static const login  = 'login';
  static const post = 'post';
  static const postDetail = 'postDetail';
  static const postEdit   = 'postEdit';
  static const userDetail = 'userDetail';
  // ... one name per route
}
```

Navigate by **name**, not path: `context.goNamed(RouteNames.signup)`,
`context.pushNamed(RouteNames.postDetail, pathParameters: {'postId': id})`.

## The router provider + auth redirect

The router watches the auth controller and redirects based on `AuthStatus`. Because
`redirect` isn't automatically re-run when a provider changes, bridge Riverpod → go_router
with a `refreshListenable` that bumps on auth changes.

```dart
@riverpod
GoRouter router(Ref ref) {
  final authRefresh = ValueNotifier<int>(0);
  ref.onDispose(authRefresh.dispose);

  // bump the listenable whenever auth state changes -> go_router re-evaluates redirect
  ref.listen<AuthState>(authControllerProvider, (_, __) => authRefresh.value++);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final status = ref.read(authControllerProvider).status;
      final loc = state.matchedLocation;
      final isSplash = loc == RoutePaths.splash;
      final isAuthRoute = loc == RoutePaths.login || loc == RoutePaths.signup;

      if (status == AuthStatus.unknown) {
        return isSplash ? null : RoutePaths.splash;      // wait on splash until known
      }
      if (status == AuthStatus.authenticated) {
        if (isSplash || isAuthRoute) return RoutePaths.post;   // bounce away from auth screens
        return null;
      }
      // unauthenticated
      return isAuthRoute ? null : RoutePaths.login;
    },
    routes: [ /* ... */ ],
    errorBuilder: (context, state) => ErrorPage(error: state.error),
  );
}
```

Wire it into `MaterialApp.router`:

```dart
MaterialApp.router(routerConfig: ref.watch(routerProvider), /* ... */);
```

### The three-state auth pattern

`AuthStatus` has **three** values, and the third is what makes redirects correct:

- `unknown` — app just launched, still resolving the session → show splash, redirect nothing
  else here.
- `authenticated` — keep users out of login/signup/splash.
- `unauthenticated` — force everything to `/login`.

Without `unknown` you get a login-screen flash before the session resolves. The auth
controller starts in `unknown` and updates from the Supabase auth stream (see
[02](02-riverpod-conventions.md)).

## Shell routes for bottom-nav

Use `StatefulShellRoute.indexedStack` for a persistent bottom navigation bar where each tab
keeps its own navigation stack:

```dart
StatefulShellRoute.indexedStack(
  builder: (context, state, navShell) => ScaffoldWithNavBar(navigationShell: navShell),
  branches: [
    StatefulShellBranch(routes: [GoRoute(path: RoutePaths.post,    name: RouteNames.post,    builder: ...)]),
    StatefulShellBranch(routes: [GoRoute(path: RoutePaths.search,  name: RouteNames.search,  builder: ...)]),
    StatefulShellBranch(routes: [
      GoRoute(path: RoutePaths.profile, name: RouteNames.profile, builder: ...,
        routes: [ GoRoute(path: RoutePaths.profileEdit, name: RouteNames.profileEdit, builder: ...) ],
      ),
    ]),
  ],
)
```

The `ScaffoldWithNavBar` uses `navigationShell.currentIndex` and
`navigationShell.goBranch(index)` to switch tabs.

## Reading path params

```dart
GoRoute(
  path: RoutePaths.postDetail,                 // '/post-detail/:postId'
  name: RouteNames.postDetail,
  builder: (context, state) => PostDetailPage(postId: state.pathParameters['postId']!),
  routes: [
    GoRoute(
      path: RoutePaths.postEdit,               // relative 'edit' -> /post-detail/:postId/edit
      name: RouteNames.postEdit,
      builder: (context, state) => PostFormPage(postId: state.pathParameters['postId']),
    ),
  ],
)
```

## Rules

- Exactly one `GoRouter`, provided via `@riverpod`. No second router.
- Auth gating lives **only** in `redirect` — don't scatter "if not logged in" checks in pages.
- Navigate by name + `pathParameters`; never concatenate URL strings by hand.
- Every route has both a `path` and a `name`; both come from the constants classes.
- Provide an `errorBuilder` so unknown routes render a proper error page.
