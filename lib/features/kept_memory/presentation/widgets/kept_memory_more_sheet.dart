import 'package:flutter/material.dart';

import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/bottom_sheet_chrome.dart';

/// What the Kept Memory hero's ⋯ offers.
enum KeptMemoryMoreAction { share, delete }

/// The hero ⋯ menu: Share memory (#311) first, then Delete.
class KeptMemoryMoreSheet extends StatelessWidget {
  const KeptMemoryMoreSheet({super.key});

  static Future<KeptMemoryMoreAction?> show(BuildContext context) =>
      showAppBottomSheet<KeptMemoryMoreAction>(
        context: context,
        builder: (_) => const KeptMemoryMoreSheet(),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        0,
        AppSpacing.sm,
        AppSpacing.base,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Item(
            key: const ValueKey('kept-memory-share'),
            icon: Icons.ios_share,
            label: l10n.share_entry,
            color: AppColors.textPrimary,
            action: KeptMemoryMoreAction.share,
          ),
          _Item(
            key: const ValueKey('kept-memory-delete'),
            icon: Icons.delete_outline,
            label: l10n.trip_deleteTitle,
            color: AppColors.accentCoral,
            action: KeptMemoryMoreAction.delete,
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.icon,
    required this.label,
    required this.color,
    required this.action,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color color;
  final KeptMemoryMoreAction action;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color, size: 20),
      title: Text(
        label,
        style: AppTypography.bodyEmphasis.copyWith(fontSize: 15, color: color),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
      onTap: () => Navigator.of(context).pop(action),
    );
  }
}
