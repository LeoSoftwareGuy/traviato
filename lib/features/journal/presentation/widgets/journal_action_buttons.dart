import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// "To Do" — opens the day's quests. (The "View wrap-up" button shown in
/// the Figma frame was a designer miscommunication and isn't part of the
/// Journal screen.)
class JournalActionButtons extends StatelessWidget {
  const JournalActionButtons({required this.onToDoTap, super.key});

  final VoidCallback onToDoTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      key: const Key('journal-to-do-action'),
      onPressed: onToDoTap,
      icon: const Icon(Icons.calendar_today_outlined, size: 16),
      label: const Text('To Do'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: AppColors.textSecondary,
        side: const BorderSide(color: AppColors.surfaceBorder),
      ),
    );
  }
}
