import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// A field card matching the Register/Log in redesign: a mono uppercase
/// label above the value, the whole card bordered, with the border and
/// label turning primary on focus. `docs/design/README.md` § 2.
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    required this.label,
    required this.controller,
    this.hintText,
    this.obscureText = false,
    this.showObscureToggle = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final bool obscureText;

  /// Adds a "Show"/"Hide" affordance that toggles [obscureText] locally.
  final bool showObscureToggle;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  final _focusNode = FocusNode();
  late var _obscured = widget.obscureText;

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
          TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText && _obscured,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            textCapitalization: widget.textCapitalization,
            validator: widget.validator,
            style: AppTypography.bodyInput,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              hintText: widget.hintText,
              hintStyle: AppTypography.bodyInput.copyWith(
                color: AppColors.textTertiary,
              ),
              suffixIcon: widget.showObscureToggle
                  ? _ObscureToggle(
                      obscured: _obscured,
                      onTap: () => setState(() => _obscured = !_obscured),
                    )
                  : null,
              suffixIconConstraints: const BoxConstraints(minWidth: 0),
            ),
          ),
        ],
      ),
    );
  }
}

class _ObscureToggle extends StatelessWidget {
  const _ObscureToggle({required this.obscured, required this.onTap});

  final bool obscured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.sm),
        child: Text(
          obscured ? 'Show' : 'Hide',
          style: AppTypography.chipLabel.copyWith(color: AppColors.primary),
        ),
      ),
    );
  }
}
