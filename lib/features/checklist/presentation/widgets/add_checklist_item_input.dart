import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/dashed_rrect_border.dart';

/// Dashed "+ Add something of your own..." row pinned under a category's
/// item list. `docs/design/README.md` § 6.
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
    return DashedRRectBorder(
      color: AppColors.surfaceBorder,
      borderRadius: AppRadius.cardRadius,
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.base),
          Text(
            '+',
            style: AppTypography.bodyInput.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: _controller,
              style: AppTypography.bodyInput,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: 'Add something of your own...',
                hintStyle: AppTypography.bodyInput.copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                ),
              ),
            ),
          ),
          InkWell(
            key: const Key('checklist-add-item-submit'),
            onTap: _submit,
            borderRadius: BorderRadius.circular(14),
            child: const Padding(
              padding: EdgeInsets.all(AppSpacing.sm),
              child: Icon(
                Icons.arrow_upward_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
    );
  }
}
