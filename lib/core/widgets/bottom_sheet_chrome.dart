import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'rise_in.dart';

/// Sheet background gradient — `docs/design/README.md` § Shared: Add-expense
/// sheet / Manage memory sheet. Distinct from the three ground/photo/CTA
/// recipes in `AppGradients`; scoped here since it is chrome, not a screen
/// treatment.
const _sheetGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFF1A1742), Color(0xFF0F1230)],
);

/// Shared bottom-sheet scaffold: grab handle, radius-26 top corners, the
/// sheet gradient, a primary-tinted top border, and a `riseIn` entrance.
/// Wrap sheet content with this instead of building chrome per-screen.
class BottomSheetChrome extends StatelessWidget {
  const BottomSheetChrome({required this.child, super.key});

  final Widget child;

  static const _topRadius = Radius.circular(26);

  @override
  Widget build(BuildContext context) {
    return RiseIn(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: _sheetGradient,
          borderRadius: const BorderRadius.only(
            topLeft: _topRadius,
            topRight: _topRadius,
          ),
          border: Border(
            top: BorderSide(color: AppColors.tint(AppColors.primary, .35)),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceBorder,
                    borderRadius: AppRadius.pillRadius,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Flexible(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Convenience wrapper around [showModalBottomSheet] that applies
/// [BottomSheetChrome] around [builder]'s content.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    builder: (context) => BottomSheetChrome(child: builder(context)),
  );
}
