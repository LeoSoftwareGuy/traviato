import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// "Add an item..." row pinned under a category's item list.
class AddChecklistItemInput extends StatefulWidget {
  const AddChecklistItemInput({required this.onSubmit, super.key});

  final ValueChanged<String> onSubmit;

  @override
  State<AddChecklistItemInput> createState() => _AddChecklistItemInputState();
}

class _AddChecklistItemInputState extends State<AddChecklistItemInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    widget.onSubmit(title);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.surfaceBorder),
              borderRadius: AppRadius.badgeRadius,
            ),
            child: TextField(
              controller: _controller,
              style: AppTypography.bodyInput,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: 'Add an item...',
                hintStyle: AppTypography.bodyInput.copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base,
                  vertical: AppSpacing.md,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        InkWell(
          onTap: _submit,
          borderRadius: AppRadius.badgeRadius,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.surfaceBorder,
              borderRadius: AppRadius.badgeRadius,
            ),
            child: const Icon(
              Icons.add,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}
