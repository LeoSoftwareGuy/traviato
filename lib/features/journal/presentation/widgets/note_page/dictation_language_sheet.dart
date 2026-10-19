import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/l10n/context_l10n.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/dashed_rrect_border.dart';
import '../../../../settings/domain/app_language.dart';
import '../../../../settings/presentation/controllers/app_language_controller.dart';
import '../../providers/dictation_providers.dart';
import 'note_dock.dart';

/// "Speak in…" (localization design 2b): picks the dictation language only.
/// Light paper, like the note page. Languages this device can't recognise
/// stay listed but disabled, with the reason — typing in them still works.
class DictationLanguageSheet extends ConsumerWidget {
  const DictationLanguageSheet({super.key});

  /// Opens the sheet; a pick is remembered for the next note.
  static Future<void> show(BuildContext context) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final picked = await showModalBottomSheet<AppLanguage>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DictationLanguageSheet(),
    );
    if (picked == null) return;
    await container
        .read(dictationLanguageControllerProvider.notifier)
        .select(picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final current = ref.watch(dictationLanguageStatusProvider).language;
    final uiCode = ref.watch(resolvedAppLanguageProvider).code!;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        14,
        AppSpacing.lg,
        AppSpacing.xxl + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.tint(AppColors.paperInk, .2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          Text(
            l10n.dictation_title,
            style: AppTypography.headlineSerif.copyWith(
              fontSize: 23,
              color: AppColors.paperInk,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.dictation_sheetSubtitle(uiCode),
            style: AppTypography.chipLabel.copyWith(
              color: AppColors.paperInkMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          for (final language in AppLanguage.dictationLanguages) ...[
            _Row(
              language: language,
              selected: language == current,
              available: ref.watch(
                dictationLanguageSupportedProvider(language),
              ),
            ),
            const SizedBox(height: 7),
          ],
          const SizedBox(height: 7),
          Text(
            l10n.dictation_remember,
            style: AppTypography.caption.copyWith(
              fontSize: 11,
              letterSpacing: 0,
              color: AppColors.paperInkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.language,
    required this.selected,
    required this.available,
  });

  final AppLanguage language;
  final bool selected;
  final bool available;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final code = language.code!;
    final name = l10n.language_name(code);
    final subtitle = available
        ? (name == language.nativeName ? null : name)
        : l10n.dictation_unavailableRow(code, dictationPlatformName());
    final ink = available ? AppColors.paperInk : AppColors.paperInkMuted;

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30,
            child: Text(
              code.toUpperCase(),
              style: AppTypography.mono.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
                color: ink,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  language.nativeName,
                  style: AppTypography.bodyEmphasis.copyWith(
                    fontSize: 14.5,
                    color: ink,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.chipLabel.copyWith(
                      fontSize: 11.5,
                      height: 1.4,
                      color: AppColors.paperInkMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (selected)
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
              child: const Icon(Icons.check, size: 13, color: AppColors.paper),
            ),
        ],
      ),
    );

    if (!available) {
      return Semantics(
        enabled: false,
        child: DashedRRectBorder(
          key: Key('dictation-row-$code'),
          color: AppColors.tint(AppColors.paperInkMuted, .5),
          borderRadius: AppRadius.cardRadius,
          child: content,
        ),
      );
    }
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('dictation-row-$code'),
          onTap: () => Navigator.of(context).pop(language),
          borderRadius: AppRadius.cardRadius,
          child: Ink(
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.tint(AppColors.primary, .12)
                  : AppColors.paperDock,
              border: Border.all(
                color: selected
                    ? AppColors.tint(AppColors.primary, .5)
                    : AppColors.tint(AppColors.paperInk, .12),
              ),
              borderRadius: AppRadius.cardRadius,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
