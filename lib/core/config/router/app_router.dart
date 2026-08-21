import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../../features/auth/presentation/controllers/auth_state.dart';
import '../../../features/auth/presentation/pages/guest_landing_page.dart';
import '../../../features/auth/presentation/pages/login_page.dart';
import '../../../features/auth/presentation/pages/register_page.dart';
import '../../../features/auth/presentation/pages/splash_page.dart';
import '../../../features/checklist/presentation/pages/checklist_page.dart';
import '../../../features/expense/presentation/pages/expenses_page.dart';
import '../../../features/home/presentation/pages/home_page.dart';
import '../../../features/home/presentation/widgets/home_shell_scaffold.dart';
import '../../../features/journal/presentation/pages/journal_page.dart';
import '../../../features/quest/presentation/pages/plan_page.dart';
import '../../../features/trip/presentation/pages/create_memory_page.dart';
import '../../widgets/placeholder_page.dart';
import 'route_constants.dart';

part 'app_router.g.dart';

@riverpod
GoRouter router(Ref ref) {
  final authRefresh = ValueNotifier<int>(0);
  ref.onDispose(authRefresh.dispose);

  ref.listen<AuthState>(authControllerProvider, (_, _) => authRefresh.value++);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final status = ref.read(authControllerProvider).status;
      final loc = state.matchedLocation;
      final isSplash = loc == RoutePaths.splash;
      final isAuthRoute = loc == RoutePaths.login || loc == RoutePaths.signup;
      final isGuestLanding = loc == RoutePaths.guestLanding;

      if (status == AuthStatus.unknown) {
        return isSplash ? null : RoutePaths.splash;
      }
      if (status == AuthStatus.authenticated) {
        if (isSplash || isAuthRoute || isGuestLanding) return RoutePaths.home;
        return null;
      }
      // unauthenticated
      if (isGuestLanding || isAuthRoute) return null;
      return RoutePaths.guestLanding;
    },
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: RoutePaths.guestLanding,
        name: RouteNames.guestLanding,
        builder: (context, state) => const GuestLandingPage(),
      ),
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RoutePaths.signup,
        name: RouteNames.signup,
        builder: (context, state) => const RegisterPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navShell) =>
            HomeShellScaffold(navigationShell: navShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.home,
                name: RouteNames.home,
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.expenses,
                name: RouteNames.expenses,
                builder: (context, state) => const ExpensesPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.profile,
        name: RouteNames.profile,
        builder: (context, state) => const PlaceholderPage(title: 'Profile'),
      ),
      GoRoute(
        path: RoutePaths.createMemory,
        name: RouteNames.createMemory,
        builder: (context, state) => const CreateMemoryPage(),
      ),
      GoRoute(
        path: RoutePaths.tripPlan,
        name: RouteNames.tripPlan,
        builder: (context, state) =>
            PlanPage(tripId: state.pathParameters['tripId']!),
      ),
      GoRoute(
        path: RoutePaths.tripChecklist,
        name: RouteNames.tripChecklist,
        builder: (context, state) =>
            ChecklistPage(tripId: state.pathParameters['tripId']!),
      ),
      GoRoute(
        path: RoutePaths.tripJournal,
        name: RouteNames.tripJournal,
        builder: (context, state) =>
            JournalPage(tripId: state.pathParameters['tripId']!),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('${state.error}'))),
  );
}
