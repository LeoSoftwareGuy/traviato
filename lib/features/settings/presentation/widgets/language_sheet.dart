import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/bottom_sheet_chrome.dart';
import '../../../../core/widgets/star_award_toast.dart';
import '../../domain/app_language.dart';
import '../controllers/app_language_controller.dart';
import '../controllers/device_locales_controller.dart';
import 'locale_fade.dart';

/// The language picker (localization design 1b), opened from You → Settings
/// and from the guest landing chip.
class LanguageSheet extends ConsumerWidget {
  const LanguageSheet({super.key});

  /// Opens the sheet; picking a row applies it right away (design 1c).
  static Future<void> show(BuildContext context) async {
    final picked = await showAppBottomSheet<AppLanguage>(
      context: context,
      builder: (_) => const LanguageSheet(),
    );
    if (picked == null || !context.mounted) return;
    await applyLanguage(context, picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final choice = ref.watch(appLanguageControllerProvider);
    final systemResolved = resolveAppLanguage(
      AppLanguage.system,
      ref.watch(deviceLocalesControllerProvider),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.settings_language,
            style: AppTypography.headlineSerif.copyWith(fontSize: 23),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.language_sheetSubtitle,
            style: AppTypography.chipLabel.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.base),
          _LanguageRow(
            key: const Key('language-row-system'),
            title: l10n.language_systemDefault,
            subtitle: l10n.language_systemFollows(
              _platformName(),
              systemResolved.code!,
            ),
            selected: choice == AppLanguage.system,
            onTap: () => Navigator.of(context).pop(AppLanguage.system),
          ),
          for (final language in AppLanguage.pinned) ...[
            const SizedBox(height: 7),
            _LanguageRow(
              key: Key('language-row-${language.code}'),
              title: language.nativeName,
              subtitle: _subtitleFor(l10n, language),
              selected: choice == language,
              onTap: () => Navigator.of(context).pop(language),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            l10n.language_footer,
            style: AppTypography.caption.copyWith(
              fontSize: 11,
              height: 1.55,
              letterSpacing: 0,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  /// The language's name in the UI language, or none when that's the same
  /// as its native name (e.g. "English" in an English UI).
  static String? _subtitleFor(AppLocalizations l10n, AppLanguage language) {
    final name = l10n.language_name(language.code!);
    return name == language.nativeName ? null : name;
  }

  static String _platformName() => switch (defaultTargetPlatform) {
    TargetPlatform.iOS => 'ios',
    TargetPlatform.android => 'android',
    _ => 'other',
  };
}

/// Applies [language] (spec 1c): the sheet is already closed; the app
/// fades into the new language, then a toast confirms it — written in the
/// *new* language, since that's the one the user now reads.
Future<void> applyLanguage(BuildContext context, AppLanguage language) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final before = container.read(appLocaleProvider);
  await container.read(appLanguageControllerProvider.notifier).select(language);
  final after = container.read(appLocaleProvider);
  if (!context.mounted) return;
  if (before != after) await Future<void>.delayed(LocaleFade.duration);
  if (!context.mounted) return;
  final l10n = lookupAppLocalizations(after);
  showStarToast(context, l10n.language_toast(l10n.language_selfName));
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.cardRadius,
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.tint(AppColors.primary, .12)
                  : AppColors.surface,
              border: Border.all(
                color: selected
                    ? AppColors.tint(AppColors.primary, .5)
                    : AppColors.surfaceBorder,
              ),
              borderRadius: AppRadius.cardRadius,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.bodyEmphasis.copyWith(
                          fontSize: 14.5,
                        ),
                      ),
                      if (subtitle case final subtitle?) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: AppTypography.chipLabel.copyWith(
                            fontSize: 11.5,
                            color: selected
                                ? AppColors.textSecondary
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                _CheckCircle(selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckCircle extends StatelessWidget {
  const _CheckCircle({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    if (!selected) {
      return Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.tint(AppColors.textSecondary, .35),
            width: 1.5,
          ),
        ),
      );
    }
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary,
      ),
      child: const Icon(Icons.check, size: 13, color: AppColors.background),
    );
  }
}
