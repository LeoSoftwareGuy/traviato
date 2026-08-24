import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The three gradient recipes used across the redesign — screen ground,
/// photo scrim, and the primary→coral CTA fill. See
/// `docs/design/README.md` § Gradients. Nothing else is a gradient.
abstract class AppGradients {
  // Screen-ground top colors, per screen group.
  static const Color groundTopHome = Color(0xFF1E1B45);
  static const Color groundTopLandingAuth = Color(0xFF241C4E);
  static const Color groundTopBonusProfile = Color(0xFF2A1E52);
  static const Color groundTopPlanChecklistExpenses = Color(0xFF141238);
  static const Color groundTopJournal = Color(0xFF181541);

  /// Radial screen-ground gradient (Home / Landing / Auth / Bonus / Profile):
  /// navy [topColor] fading to [AppColors.background] from the top centre.
  static RadialGradient screenGroundRadial(Color topColor) => RadialGradient(
    center: const Alignment(0, -1.1),
    radius: 1.2,
    colors: [topColor, const Color(0xFF111436), AppColors.background],
    stops: const [0, .44, 1],
  );

  /// Simple vertical screen-ground gradient (Plan / Checklist / Expenses use
  /// [groundTopPlanChecklistExpenses] at [stop] .34–.38; Journal uses
  /// [groundTopJournal] at .40).
  static LinearGradient screenGroundVertical({
    required Color topColor,
    double stop = 0.36,
  }) => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [topColor, AppColors.background],
    stops: [stop, 1],
  );

  /// Vertical scrim for text over imagery. [warm] adds the Home-hero warm
  /// lift at the top stop.
  static LinearGradient photoScrim({bool warm = false}) => LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [
      AppColors.background.withValues(alpha: .9),
      AppColors.background.withValues(alpha: .1),
      warm ? const Color(0x28FFC88C) : Colors.transparent,
    ],
  );

  /// Primary CTA / star-bar gradient — FAB, packing-progress bar, "View
  /// wrap-up" button. The plain primary button stays flat [AppColors.primary].
  static const LinearGradient primaryCta = LinearGradient(
    begin: Alignment(-0.71, -0.71),
    end: Alignment(0.71, 0.71),
    colors: [AppColors.primary, AppColors.accentCoral],
  );
}
