import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_message.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/async_error_retry_scaffold.dart';
import '../../../../core/widgets/show_error_snackbar.dart';
import '../../domain/entities/subscription_offering_entity.dart';
import '../controllers/offerings_controller.dart';
import '../mutations/subscription_mutations.dart';

/// A plain, undesigned plan picker (issue #138) — fetches offerings, lets
/// the user purchase or restore. M6-5 replaces this screen's visuals with
/// the real paywall on top of the same [purchaseMutation]/[restoreMutation];
/// nothing here anticipates that design.
class SubscriptionOfferingsPage extends ConsumerStatefulWidget {
  const SubscriptionOfferingsPage({super.key});

  @override
  ConsumerState<SubscriptionOfferingsPage> createState() =>
      _SubscriptionOfferingsPageState();
}

class _SubscriptionOfferingsPageState
    extends ConsumerState<SubscriptionOfferingsPage> {
  String? _selectedIdentifier;

  @override
  Widget build(BuildContext context) {
    ref.listen<MutationState<dynamic>>(purchaseMutation, (previous, next) {
      if (next is MutationError) {
        showErrorSnackbar(
          context,
          message: presentationFailureMessage(next.error),
        );
      } else if (next is MutationSuccess && next.value != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Trial started · 7 days free')),
          );
        Navigator.of(context).maybePop();
      }
    });
    ref.listen<MutationState<dynamic>>(restoreMutation, (previous, next) {
      if (next is MutationError) {
        showErrorSnackbar(
          context,
          message: presentationFailureMessage(next.error),
        );
      } else if (next is MutationSuccess) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Purchases restored')));
      }
    });

    final offeringsAsync = ref.watch(offeringsControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Upgrade to Pro'),
      ),
      body: offeringsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AsyncErrorRetryScaffold(
          message: presentationFailureMessage(error),
          onRetry: () => ref.invalidate(offeringsControllerProvider),
        ),
        data: (offerings) {
          _selectedIdentifier ??= _firstOrNull(
            offerings.where((o) => o.period == SubscriptionPeriod.annual),
          )?.identifier;
          return _OfferingsBody(
            offerings: offerings,
            selectedIdentifier: _selectedIdentifier,
            onSelect: (id) => setState(() => _selectedIdentifier = id),
          );
        },
      ),
    );
  }
}

T? _firstOrNull<T>(Iterable<T> items) => items.isEmpty ? null : items.first;

class _OfferingsBody extends ConsumerWidget {
  const _OfferingsBody({
    required this.offerings,
    required this.selectedIdentifier,
    required this.onSelect,
  });

  final List<SubscriptionOfferingEntity> offerings;
  final String? selectedIdentifier;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPurchasing = ref.watch(purchaseMutation) is MutationPending;
    final isRestoring = ref.watch(restoreMutation) is MutationPending;
    final hasSelection = offerings.any(
      (o) => o.identifier == selectedIdentifier,
    );

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Text('Traviato Pro', style: AppTypography.screenTitle),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Unlimited memories and photos, with room for every trip you take.',
          style: AppTypography.bodyInput.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        for (final offering in offerings)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _OfferingTile(
              offering: offering,
              selected: offering.identifier == selectedIdentifier,
              onTap: () => onSelect(offering.identifier),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: !hasSelection || isPurchasing
                ? null
                : () => _purchase(ref, selectedIdentifier!),
            child: isPurchasing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Start 7-day free trial'),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: TextButton(
            onPressed: isRestoring ? null : () => _restore(ref),
            child: isRestoring
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Restore purchases'),
          ),
        ),
      ],
    );
  }

  // The mutation's own MutationError state (surfaced via ref.listen on the
  // page) already shows the failure as a snackbar — this just stops it from
  // also reaching the zone as an unhandled Future error (guidelines doc 06).
  Future<void> _purchase(WidgetRef ref, String offeringIdentifier) async {
    try {
      await runPurchase(ref: ref, offeringIdentifier: offeringIdentifier);
    } catch (_) {
      return;
    }
  }

  Future<void> _restore(WidgetRef ref) async {
    try {
      await runRestore(ref: ref);
    } catch (_) {
      return;
    }
  }
}

class _OfferingTile extends StatelessWidget {
  const _OfferingTile({
    required this.offering,
    required this.selected,
    required this.onTap,
  });

  final SubscriptionOfferingEntity offering;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = switch (offering.period) {
      SubscriptionPeriod.monthly => 'Monthly',
      SubscriptionPeriod.annual => 'Annual',
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryTint : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.surfaceBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primary : AppColors.textTertiary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(label, style: AppTypography.bodyEmphasis)),
            Text(
              offering.priceString,
              style: AppTypography.bodyEmphasis.copyWith(
                color: selected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
