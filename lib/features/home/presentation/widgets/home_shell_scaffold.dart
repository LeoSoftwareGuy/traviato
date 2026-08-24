import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/router/route_constants.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';

/// Persistent bottom nav for the Home/Expenses tabs, with a centered ➕
/// action button that pushes create-memory rather than switching tabs
/// (guidelines doc 07). Chrome lives in [AppBottomNavBar].
class HomeShellScaffold extends StatelessWidget {
  const HomeShellScaffold({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: AppBottomNavBar(
        onFabTap: () => context.pushNamed(RouteNames.createMemory),
        items: [
          AppBottomNavBarItem(
            icon: Icons.home_rounded,
            label: 'Home',
            selected: navigationShell.currentIndex == 0,
            onTap: () => navigationShell.goBranch(0),
          ),
          AppBottomNavBarItem(
            icon: Icons.receipt_long_outlined,
            label: 'Expenses',
            selected: navigationShell.currentIndex == 1,
            onTap: () => navigationShell.goBranch(1),
          ),
        ],
      ),
    );
  }
}
