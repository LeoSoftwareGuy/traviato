import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Visual-only password strength: three stadium segments + a label. Heuristic
/// is length + character variety, not a real strength estimate — the design
/// only calls for a rough signal (`docs/design/README.md` § 2).
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({required this.password, super.key});

  final String password;

  static ({int filled, String label}) strengthOf(String password) {
    if (password.isEmpty) return (filled: 0, label: '');
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(password);
    final hasDigit = RegExp(r'\d').hasMatch(password);
    final variety = (hasLetter ? 1 : 0) + (hasDigit ? 1 : 0);
    if (password.length >= 10 && variety == 2) {
      return (filled: 3, label: 'Strong');
    }
    if (password.length >= 6) return (filled: 2, label: 'Good');
    return (filled: 1, label: 'Weak');
  }

  @override
  Widget build(BuildContext context) {
    final strength = strengthOf(password);
    if (strength.filled == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: i < strength.filled
                      ? AppColors.primary
                      : AppColors.surfaceBorder,
                  borderRadius: AppRadius.pillRadius,
                ),
              ),
            ),
          ],
          const SizedBox(width: AppSpacing.sm),
          Text(
            strength.label,
            style: AppTypography.caption.copyWith(letterSpacing: 0),
          ),
        ],
      ),
    );
  }
}
