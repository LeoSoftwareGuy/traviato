import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// The redesign's field-card style: mono uppercase label above the value,
/// border/label turn primary on focus. Introduced for New memory (§4),
/// reused by the quest add/edit sheet (§5) once it moved onto the R-1
/// sheet chrome — replaced the old `MemoryTextField` in both places, which
/// is why this lives under `trip/`.
class CreateMemoryField extends StatefulWidget {
  const CreateMemoryField({
    required this.label,
    required this.controller,
    this.hintText,
    this.valueStyle,
    this.trailing,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.maxLines = 1,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;

  /// Overrides the value's text style — the name field uses a larger serif
  /// value per spec, other fields use the default.
  final TextStyle? valueStyle;
  final Widget? trailing;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;

  /// A bio-style field passes >1 for a multiline value (issue #96); every
  /// other caller keeps the single-line default.
  final int maxLines;

  @override
  State<CreateMemoryField> createState() => _CreateMemoryFieldState();
}

class _CreateMemoryFieldState extends State<CreateMemoryField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() => setState(() {});

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focusNode.hasFocus;
    final accentColor = focused ? AppColors.primary : AppColors.surfaceBorder;
    final labelColor = focused ? AppColors.primary : AppColors.textTertiary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: accentColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label.toUpperCase(),
            style: AppTypography.mono.copyWith(color: labelColor),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  validator: widget.validator,
                  maxLines: widget.maxLines,
                  cursorColor: AppColors.primary,
                  style: widget.valueStyle ?? AppTypography.bodyInput,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    hintText: widget.hintText,
                    hintStyle: (widget.valueStyle ?? AppTypography.bodyInput)
                        .copyWith(color: AppColors.textTertiary),
                  ),
                ),
              ),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
        ],
      ),
    );
  }
}
