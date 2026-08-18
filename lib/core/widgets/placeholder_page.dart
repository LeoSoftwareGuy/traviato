import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Generic "coming soon" screen for routes whose real feature hasn't landed
/// yet. Swap for the real page once its issue ships.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({required this.title, this.message, super.key});

  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            message ?? '$title is on its way.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyInput.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
