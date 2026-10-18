import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/async_error_retry_scaffold.dart';
import '../../../../core/widgets/show_error_snackbar.dart';
import '../../../../core/widgets/star_award_toast.dart';
import '../../../../core/widgets/twinkle_dot.dart';
import '../../domain/entities/entitlement_entity.dart';
import '../../domain/entities/subscription_offering_entity.dart';
import '../controllers/offerings_controller.dart';
import '../mutations/subscription_mutations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Which flow sent the user to the paywall — picks the contextual sub-copy
/// under the headline (docs/design/M6_MONETIZATION_SPEC.md §4). An
/// unrecognized/missing `entry` query param falls back to [profile].
enum PaywallEntryPoint {
  profile,
  memoryCap,
  photoCap;

  static PaywallEntryPoint fromQueryParam(String? value) =>
      PaywallEntryPoint.values.firstWhere(
        (e) => e.name == value,
        orElse: () => PaywallEntryPoint.profile,
      );

  String subCopy(AppLocalizations l10n) => switch (this) {
    PaywallEntryPoint.memoryCap => l10n.paywall_subMemoryCap,
    PaywallEntryPoint.photoCap => l10n.paywall_subPhotoCap,
    PaywallEntryPoint.profile => l10n.paywall_subProfile,
  };
}

/// Full-screen paywall (issue #141) — reached from Profile's "Upgrade to
/// Pro", or automatically when a free-tier write hits the memory/photo cap
/// (`show_failure_snackbar.dart`, #139). Sits on the same
/// [purchaseMutation]/[restoreMutation] the plain picker (#138) used; this
/// screen only redoes the visuals and adds the entry-point copy.
class PaywallPage extends ConsumerStatefulWidget {
  const PaywallPage({required this.entryPoint, super.key});

  final PaywallEntryPoint entryPoint;

  @override
  ConsumerState<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends ConsumerState<PaywallPage> {
  String? _selectedIdentifier;

  @override
  Widget build(BuildContext context) {
    ref.listen<MutationState<dynamic>>(purchaseMutation, (previous, next) {
      if (next is MutationError) {
        showErrorSnackbar(
          context,
          message: presentationFailureMessage(next.error, context.l10n),
        );
      } else if (next is MutationSuccess && next.value != null) {
        showStarToast(context, context.l10n.paywall_trialStarted);
        Navigator.of(context).maybePop();
      }
    });
    ref.listen<MutationState<dynamic>>(restoreMutation, (previous, next) {
      if (next is MutationError) {
        showErrorSnackbar(
          context,
          message: presentationFailureMessage(next.error, context.l10n),
        );
      } else if (next is MutationSuccess) {
        // RevenueCat's restore never fails just because there was nothing to
        // restore — it resolves successfully with whatever entitlement the
        // account actually has. A still-free result after restoring *is*
        // the "nothing to restore" outcome, not an error.
        final entitlement = next.value as EntitlementEntity;
        if (entitlement.isPro) {
          showStarToast(context, context.l10n.sub_restored);
        } else {
          showAppSnackbar(context, context.l10n.sub_nothingToRestore);
        }
      }
    });

    final offeringsAsync = ref.watch(offeringsControllerProvider);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.screenGroundRadial(
            AppGradients.groundTopBonusProfile,
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: _PaywallStarSpecks()),
            SafeArea(
              child: Column(
                children: [
                  const _TopBar(),
                  Expanded(
                    child: offeringsAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) => AsyncErrorRetryScaffold(
                        message: presentationFailureMessage(
                          error,
                          context.l10n,
                        ),
                        onRetry: () =>
                            ref.invalidate(offeringsControllerProvider),
                      ),
                      data: (offerings) {
                        _selectedIdentifier ??=
                            _firstOrNull(
                              offerings.where(
                                (o) => o.period == SubscriptionPeriod.annual,
                              ),
                            )?.identifier ??
                            _firstOrNull(offerings)?.identifier;
                        return _PaywallBody(
                          entryPoint: widget.entryPoint,
                          offerings: offerings,
                          selectedIdentifier: _selectedIdentifier,
                          onSelect: (id) =>
                              setState(() => _selectedIdentifier = id),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

T? _firstOrNull<T>(Iterable<T> items) => items.isEmpty ? null : items.first;

class _TopBar extends ConsumerWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRestoring = ref.watch(restoreMutation) is MutationPending;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Row(
        children: [
          _CloseButton(onTap: () => Navigator.of(context).maybePop()),
          const Spacer(),
          TextButton(
            onPressed: isRestoring ? null : () => _restore(ref),
            child: isRestoring
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    context.l10n.sub_restore,
                    style: AppTypography.chipLabel.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // The mutation's own error state (surfaced via ref.listen on PaywallPage)
  // already shows the failure as a snackbar (guidelines doc 06).
  Future<void> _restore(WidgetRef ref) async {
    try {
      await runRestore(ref: ref);
    } catch (_) {
      return;
    }
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: const Icon(
            Icons.close,
            size: 16,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _PaywallStarSpecks extends StatelessWidget {
  const _PaywallStarSpecks();

  static const _specks = [
    _Speck(top: 36, left: 44, size: 3, color: AppColors.primary, delayMs: 0),
    _Speck(top: 84, left: 300, size: 2, color: Colors.white, delayMs: 1100),
    _Speck(
      top: 150,
      left: 64,
      size: 2.5,
      color: Color(0xFFF6C77A),
      delayMs: 2000,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          for (final speck in _specks)
            Positioned(
              top: speck.top,
              left: speck.left,
              child: TwinkleDot(
                size: speck.size,
                color: speck.color,
                delayMs: speck.delayMs,
              ),
            ),
        ],
      ),
    );
  }
}

class _Speck {
  const _Speck({
    required this.top,
    required this.left,
    required this.size,
    required this.color,
    required this.delayMs,
  });

  final double top;
  final double left;
  final double size;
  final Color color;
  final int delayMs;
}

class _PaywallBody extends StatelessWidget {
  const _PaywallBody({
    required this.entryPoint,
    required this.offerings,
    required this.selectedIdentifier,
    required this.onSelect,
  });

  final PaywallEntryPoint entryPoint;
  final List<SubscriptionOfferingEntity> offerings;
  final String? selectedIdentifier;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final selected = _firstOrNull(
      offerings.where((o) => o.identifier == selectedIdentifier),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.base,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      children: [
        _Header(entryPoint: entryPoint),
        const SizedBox(height: AppSpacing.xl),
        const _PerkList(),
        const SizedBox(height: AppSpacing.xl),
        for (final offering in offerings)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _PlanCard(
              offering: offering,
              selected: offering.identifier == selectedIdentifier,
              onTap: () => onSelect(offering.identifier),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        _CtaBlock(selected: selected),
        const SizedBox(height: AppSpacing.lg),
        const _ReassuranceCard(),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.entryPoint});

  final PaywallEntryPoint entryPoint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 25,
              height: 25,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppGradients.primaryCta,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Text(
                '✦',
                style: TextStyle(color: AppColors.background, fontSize: 13),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              context.l10n
                  .paywall_brandEyebrow(AppConstants.appName)
                  .toUpperCase(),
              style: AppTypography.mono.copyWith(
                fontSize: 9.5,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.base),
        Text(
          context.l10n.paywall_titleLead,
          style: AppTypography.heroHeadline.copyWith(fontSize: 34),
        ),
        Text(
          context.l10n.paywall_titleEmphasis,
          style: AppTypography.heroHeadline.copyWith(
            fontSize: 34,
            fontStyle: FontStyle.italic,
            color: AppColors.primaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 296),
          child: Text(
            entryPoint.subCopy(context.l10n),
            style: AppTypography.bodyInput.copyWith(
              fontSize: 13,
              height: 1.65,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _Perk {
  const _Perk({
    required this.glyph,
    required this.title,
    required this.detail,
    required this.shipped,
  });

  final String glyph;
  final String Function(AppLocalizations l10n) title;
  final String Function(AppLocalizations l10n) detail;
  final bool shipped;
}

String _perkMemories(AppLocalizations l) => l.paywall_perkMemories;
String _perkMemoriesDetail(AppLocalizations l) => l.paywall_perkMemoriesDetail;
String _perkPhotos(AppLocalizations l) => l.paywall_perkPhotos;
String _perkPhotosDetail(AppLocalizations l) => l.paywall_perkPhotosDetail;
String _perkExport(AppLocalizations l) => l.paywall_perkExport;
String _perkExportDetail(AppLocalizations l) => l.paywall_perkExportDetail;
String _perkPriority(AppLocalizations l) => l.paywall_perkPriority;
String _perkPriorityDetail(AppLocalizations l) => l.paywall_perkPriorityDetail;

const _perks = [
  _Perk(
    glyph: '∞',
    title: _perkMemories,
    detail: _perkMemoriesDetail,
    shipped: true,
  ),
  _Perk(
    glyph: '▣',
    title: _perkPhotos,
    detail: _perkPhotosDetail,
    shipped: true,
  ),
  _Perk(
    glyph: '▸',
    title: _perkExport,
    detail: _perkExportDetail,
    shipped: false,
  ),
  _Perk(
    glyph: '↯',
    title: _perkPriority,
    detail: _perkPriorityDetail,
    shipped: false,
  ),
];

class _PerkList extends StatelessWidget {
  const _PerkList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final perk in _perks) ...[
          _PerkRow(perk: perk),
          if (perk != _perks.last) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _PerkRow extends StatelessWidget {
  const _PerkRow({required this.perk});

  final _Perk perk;

  @override
  Widget build(BuildContext context) {
    final tint = perk.shipped ? AppColors.primary : AppColors.accentPurple;
    final glyphColor = perk.shipped
        ? AppColors.primary
        : AppColors.accentPurpleLight;
    final titleColor = perk.shipped
        ? AppColors.textPrimary
        : AppColors.textSecondary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.tint(tint, perk.shipped ? .15 : .16),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(perk.glyph, style: TextStyle(color: glyphColor)),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                perk.title(context.l10n),
                style: AppTypography.bodyEmphasis.copyWith(color: titleColor),
              ),
              const SizedBox(height: 2),
              Text(
                perk.detail(context.l10n),
                style: AppTypography.caption.copyWith(
                  fontSize: 11.5,
                  height: 1.5,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.offering,
    required this.selected,
    required this.onTap,
  });

  final SubscriptionOfferingEntity offering;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isAnnual = offering.period == SubscriptionPeriod.annual;
    final l10n = context.l10n;
    final label = isAnnual ? l10n.paywall_planAnnual : l10n.paywall_planMonthly;
    final unit = isAnnual ? l10n.paywall_perYear : l10n.paywall_perMonth;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.cardRadius,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.tint(AppColors.primary, .1)
              : AppColors.surface,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(
            color: selected
                ? AppColors.tint(AppColors.primary, .6)
                : AppColors.surfaceBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            _RadioRing(selected: selected),
            const SizedBox(width: AppSpacing.md),
            // Wrap: a longer plan name + the save pill move the pill to a
            // second line instead of overflowing into the price (#220).
            Expanded(
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(label, style: AppTypography.bodyEmphasis),
                  if (isAnnual) const _SavePill(),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  offering.priceString,
                  style: AppTypography.bigNumber.copyWith(
                    fontSize: 20,
                    color: selected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                Text(
                  isAnnual
                      ? _monthlyEquivalent(l10n, offering)
                      : unit.toUpperCase(),
                  style: AppTypography.mono.copyWith(fontSize: 9),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _monthlyEquivalent(
    AppLocalizations l10n,
    SubscriptionOfferingEntity offering,
  ) {
    final perMonth = NumberFormat.simpleCurrency(
      locale: l10n.localeName,
      name: offering.currencyCode,
    ).format(offering.priceAmount / 12);
    return l10n.paywall_perMonthEquivalent(perMonth).toUpperCase();
  }
}

class _RadioRing extends StatelessWidget {
  const _RadioRing({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.primary : Colors.transparent,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.textTertiary,
          width: 1.5,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, size: 12, color: AppColors.background)
          : null,
    );
  }
}

class _SavePill extends StatelessWidget {
  const _SavePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.tint(AppColors.primary, .18),
        border: Border.all(color: AppColors.tint(AppColors.primary, .45)),
        borderRadius: AppRadius.pillRadius,
      ),
      child: Text(
        context.l10n.paywall_savePercent(63).toUpperCase(),
        style: AppTypography.mono.copyWith(
          fontSize: 8.5,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _CtaBlock extends ConsumerWidget {
  const _CtaBlock({required this.selected});

  final SubscriptionOfferingEntity? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPurchasing = ref.watch(purchaseMutation) is MutationPending;

    return Column(
      children: [
        _PulsingCta(
          enabled: selected != null && !isPurchasing,
          isPurchasing: isPurchasing,
          onTap: selected == null ? null : () => _purchase(ref, selected!),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (selected != null)
          Text(
            _trialTerms(context.l10n, selected!),
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              fontSize: 11,
              height: 1.6,
              color: AppColors.textTertiary,
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        Text(
          context.l10n.paywall_termsPrivacy,
          textAlign: TextAlign.center,
          style: AppTypography.caption.copyWith(
            fontSize: 10.5,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  String _trialTerms(
    AppLocalizations l10n,
    SubscriptionOfferingEntity offering,
  ) => offering.period == SubscriptionPeriod.annual
      ? l10n.paywall_trialTermsYearly(offering.priceString)
      : l10n.paywall_trialTermsMonthly(offering.priceString);

  // The mutation's own error state (surfaced via ref.listen on PaywallPage)
  // already shows the failure as a snackbar (guidelines doc 06).
  Future<void> _purchase(
    WidgetRef ref,
    SubscriptionOfferingEntity offering,
  ) async {
    try {
      await runPurchase(ref: ref, offeringIdentifier: offering.identifier);
    } catch (_) {
      return;
    }
  }
}

class _PulsingCta extends StatefulWidget {
  const _PulsingCta({
    required this.enabled,
    required this.isPurchasing,
    required this.onTap,
  });

  final bool enabled;
  final bool isPurchasing;
  final VoidCallback? onTap;

  @override
  State<_PulsingCta> createState() => _PulsingCtaState();
}

class _PulsingCtaState extends State<_PulsingCta>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: AppMotion.pulseGlowDuration,
  );
  late final _glow = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.pulseGlowCurve,
  );

  // Reduce motion (#198) rests the glow at 0 — no halo, the button as-is.
  // Re-checked on every dependency change so flipping the OS setting while
  // the screen is open takes effect either way.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, child) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          boxShadow: [
            BoxShadow(
              color: AppColors.tint(AppColors.primary, .32 * _glow.value),
              blurRadius: 14 * _glow.value,
              spreadRadius: 2 * _glow.value,
            ),
          ],
        ),
        child: child,
      ),
      child: SizedBox(
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppGradients.primaryCta,
            borderRadius: BorderRadius.circular(17),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(17),
            child: InkWell(
              onTap: widget.enabled ? widget.onTap : null,
              borderRadius: BorderRadius.circular(17),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 17),
                child: Center(
                  child: widget.isPurchasing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.background,
                          ),
                        )
                      : Text(
                          context.l10n.paywall_startTrial,
                          style: AppTypography.buttonLabel.copyWith(
                            fontSize: 15,
                            color: AppColors.background,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReassuranceCard extends StatelessWidget {
  const _ReassuranceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.tint(AppColors.surface, .55),
        border: Border.all(color: AppColors.surfaceBorder),
        borderRadius: AppRadius.cardRadius,
      ),
      child: Text(
        context.l10n.paywall_reassurance,
        style: AppTypography.pullQuote.copyWith(
          fontSize: 12.5,
          height: 1.6,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
