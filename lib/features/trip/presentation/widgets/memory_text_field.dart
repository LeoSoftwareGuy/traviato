import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Labeled input matching the "Add trip" Figma frame: a small label above a
/// field whose leading icon sits in its own tinted square.
class MemoryTextField extends StatelessWidget {
  const MemoryTextField({
    required this.label,
    required this.controller,
    required this.icon,
    required this.iconTint,
    required this.iconColor,
    this.hintText,
    this.validator,
    this.textInputAction,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final Color iconTint;
  final Color iconColor;
  final String? hintText;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.fieldLabel),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          validator: validator,
          textInputAction: textInputAction,
          style: AppTypography.bodyInput,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Padding(
              padding: const EdgeInsets.all(14),
              child: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconTint,
                  borderRadius: AppRadius.badgeRadius,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
