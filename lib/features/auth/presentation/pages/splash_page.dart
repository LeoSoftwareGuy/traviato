import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Shown while the router waits for the initial Supabase session to
/// resolve (`AuthStatus.unknown`).
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}
