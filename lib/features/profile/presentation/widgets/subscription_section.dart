import '../../../../core/config/router/route_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/show_error_snackbar.dart';
import '../../../../core/widgets/star_award_toast.dart';
import '../../../subscription/domain/entities/active_subscription_entity.dart';
import '../../../subscription/domain/entities/entitlement_entity.dart';
import '../../../subscription/domain/entities/subscription_offering_entity.dart';
import '../../../subscription/presentation/mutations/subscription_mutations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'tier_pill.dart';

// Mirrors trip_mutations.dart's `_freeTierMemoryLimit` and
// photo_mutations.dart's `_freeTierPhotoLimit` — this section only displays
// the same caps, so it doesn't import those private consts, just repeats
// the same numbers (docs/design/M6_MONETIZATION_SPEC.md §2/§3).
const _memoryCap = 3;
const _photoCap = 40;

/// Profile's subscription card, tier pill, usage meters and actions (#142) —
/// sits between the stats row and Achievements.
class SubscriptionSection extends ConsumerWidget {
  const SubscriptionSection({
    required this.entitlement,
    required this.memoriesKept,
    required this.photosInBusiestMemory,
    required this.activeSubscription,
    required this.offerings,
    super.key,
  });

  final EntitlementEntity entitlement;
  final int memoriesKept;
  final int photosInBusiestMemory;

  /// Pro only — `null` for a free user or a failed live RevenueCat read.
  final ActiveSubscriptionEntity? activeSubscription;

  /// The store's real, localized plans (same data the paywall shows) —
  /// prices both the renewal line and the free-tier trial-terms line so
  /// neither hardcodes a number.
  final List<SubscriptionOfferingEntity> offerings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<MutationState<dynamic>>(restoreMutation, (previous, next) {
      if (next is MutationError) {
        showErrorSnackbar(
          context,
          message: presentationFailureMessage(next.error, context.l10n),
        );
      } else if (next is MutationSuccess) {
        // Same outcome branching as the paywall (#141): RevenueCat's
        // restore never fails just because there was nothing to restore.
        final restored = next.value as EntitlementEntity;
        if (restored.isPro) {
          showStarToast(context, context.l10n.sub_restored);
        } else {
          showAppSnackbar(context, context.l10n.sub_nothingToRestore);
        }
      }
    });

    final isPro = entitlement.isPro;
    final isRestoring = ref.watch(restoreMutation) is MutationPending;
    final periodLabel = switch (activeSubscription?.period) {
      SubscriptionPeriod.annual => context.l10n.sub_periodAnnual.toUpperCase(),
      SubscriptionPeriod.monthly =>
        context.l10n.sub_periodMonthly.toUpperCase(),
      null => null,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.sub_header.toUpperCase(),
          style: AppTypography.mono,
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            color: isPro
                ? AppColors.tint(AppColors.primary, .07)
                : AppColors.surface,
            border: Border.all(
              color: isPro
                  ? AppColors.tint(AppColors.primary, .28)
                  : AppColors.surfaceBorder,
            ),
            borderRadius: AppRadius.cardRadius,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TierPill(isPro: isPro, periodLabel: periodLabel),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          isPro
                              ? context.l10n.sub_proName(AppConstants.appName)
                              : context.l10n.sub_freePlan,
                          style: AppTypography.displaySerif.copyWith(
                            fontSize: 21,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _metaLine(context.l10n, isPro),
                          style: AppTypography.chipLabel.copyWith(
                            fontSize: 11.5,
                            height: 1.55,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _TierTile(isPro: isPro),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _UsageMeter(
                key: const Key('memories-meter'),
                label: context.l10n.sub_memoriesKept,
                value: isPro
                    ? context.l10n.sub_unlimited
                    : context.l10n.sub_ofCap(memoriesKept, _memoryCap),
                fraction: isPro
                    ? 1
                    : (memoriesKept / _memoryCap).clamp(0, 1).toDouble(),
                atCap: !isPro && memoriesKept >= _memoryCap,
              ),
              const SizedBox(height: 13),
              _UsageMeter(
                key: const Key('photos-meter'),
                label: context.l10n.sub_photosInMemory,
                value: isPro
                    ? context.l10n.sub_noLimit(photosInBusiestMemory)
                    : context.l10n.sub_ofCap(photosInBusiestMemory, _photoCap),
                fraction: isPro
                    ? 1
                    : (photosInBusiestMemory / _photoCap)
                          .clamp(0, 1)
                          .toDouble(),
                atCap: !isPro && photosInBusiestMemory >= _photoCap,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (isPro) ...[
                _ManageSubscriptionButton(
                  url: activeSubscription?.managementUrl,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.l10n.sub_manageHint,
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ] else ...[
                _UpgradeButton(
                  onTap: () => context.pushNamed(
                    RouteNames.subscriptionOfferings,
                    queryParameters: const {'entry': 'profile'},
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _trialTerms(context.l10n),
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: TextButton(
            onPressed: isRestoring ? null : () => _restore(ref),
            child: isRestoring
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    context.l10n.sub_restore,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  String? _priceFor(SubscriptionPeriod period) {
    for (final offering in offerings) {
      if (offering.period == period) return offering.priceString;
    }
    return null;
  }

  String _metaLine(AppLocalizations l10n, bool isPro) {
    if (!isPro) return l10n.sub_memoriesKeptMeta(memoriesKept, _memoryCap);
    final expiresAt = entitlement.expiresAt;
    final locale = l10n.localeName;
    final dateLabel = expiresAt != null
        ? (locale == 'en'
                  ? DateFormat('MMM d, y', locale)
                  : DateFormat.yMMMd(locale))
              .format(expiresAt)
        : l10n.sub_renewsSoon;
    final period = activeSubscription?.period;
    final price = period == null ? null : _priceFor(period);
    if (price == null || period == null) return l10n.sub_renews(dateLabel);
    return period == SubscriptionPeriod.annual
        ? l10n.sub_renewsYearly(dateLabel, price)
        : l10n.sub_renewsMonthly(dateLabel, price);
  }

  String _trialTerms(AppLocalizations l10n) {
    final annualPrice = _priceFor(SubscriptionPeriod.annual);
    if (annualPrice == null) return l10n.sub_trialTerms;
    return l10n.sub_trialTermsYearly(annualPrice);
  }

  // The mutation's own error state (surfaced via ref.listen above) already
  // shows the failure as a snackbar (guidelines doc 06).
  Future<void> _restore(WidgetRef ref) async {
    try {
      await runRestore(ref: ref);
    } catch (_) {
      return;
    }
  }
}

class _TierTile extends StatelessWidget {
  const _TierTile({required this.isPro});

  final bool isPro;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isPro
            ? AppColors.tint(AppColors.primary, .14)
            : AppColors.surfaceElevated,
        border: Border.all(
          color: isPro
              ? AppColors.tint(AppColors.primary, .45)
              : AppColors.surfaceBorder,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isPro ? '✦' : '○',
        style: TextStyle(
          color: isPro ? AppColors.primary : AppColors.textTertiary,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _UsageMeter extends StatelessWidget {
  const _UsageMeter({
    required this.label,
    required this.value,
    required this.fraction,
    required this.atCap,
    super.key,
  });

  final String label;
  final String value;
  final double fraction;
  final bool atCap;

  @override
  Widget build(BuildContext context) {
    final barColor = atCap ? AppColors.accentCoral : AppColors.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Flexible: a long label wraps instead of overflowing (#220).
            Flexible(
              child: Text(
                label,
                style: AppTypography.chipLabel.copyWith(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              value.toUpperCase(),
              style: AppTypography.mono.copyWith(fontSize: 10.5),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2.5),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 5,
            backgroundColor: AppColors.tint(AppColors.surfaceBorder, .9),
            valueColor: AlwaysStoppedAnimation(barColor),
          ),
        ),
      ],
    );
  }
}

class _UpgradeButton extends StatelessWidget {
  const _UpgradeButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.badgeRadius,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: const BoxDecoration(gradient: AppGradients.primaryCta),
          child: InkWell(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              height: 48,
              alignment: Alignment.center,
              child: Text(
                context.l10n.sub_upgradeToPro,
                style: AppTypography.buttonLabel.copyWith(
                  color: AppColors.background,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ManageSubscriptionButton extends StatefulWidget {
  const _ManageSubscriptionButton({required this.url});

  final String? url;

  @override
  State<_ManageSubscriptionButton> createState() =>
      _ManageSubscriptionButtonState();
}

class _ManageSubscriptionButtonState extends State<_ManageSubscriptionButton> {
  var _opening = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _opening ? null : _open,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.surfaceBorder),
          backgroundColor: AppColors.surface,
        ),
        child: _opening
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(context.l10n.sub_manage),
      ),
    );
  }

  Future<void> _open() async {
    final url = widget.url;
    if (url == null) {
      _showSnackbar(context.l10n.sub_noSubscription);
      return;
    }
    setState(() => _opening = true);
    final uri = Uri.tryParse(url);
    final launched =
        uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    setState(() => _opening = false);
    if (!launched) _showSnackbar(context.l10n.sub_cantOpenSettings);
  }

  void _showSnackbar(String message) {
    showAppSnackbar(context, message, kind: AppSnackbarKind.error);
  }
}
