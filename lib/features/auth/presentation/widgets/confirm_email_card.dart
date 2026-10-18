import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_message.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/show_error_snackbar.dart';
import '../mutations/auth_mutations.dart';
import '../../../../core/l10n/context_l10n.dart';

/// The auth screen's "Check your inbox" state after a signup that still
/// needs email confirmation (#162). Deliberately calm — surface card,
/// success-tinted icon, no snackbar — so it can't be mistaken for an error.
///
/// Opening the link on this device signs the user in (#157) and the router
/// moves them on, so this card never has to listen for confirmation itself.
class ConfirmEmailCard extends ConsumerStatefulWidget {
  const ConfirmEmailCard({
    required this.email,
    required this.onBackToLogin,
    required this.onUseDifferentEmail,
    super.key,
  });

  final String email;
  final VoidCallback onBackToLogin;
  final VoidCallback onUseDifferentEmail;

  /// Matches Supabase's per-address email limit, so the resend link never
  /// offers an attempt that is bound to be rate-limited. Counted from the
  /// signup itself too — that already sent one email.
  static const resendCooldown = Duration(seconds: 60);

  @override
  ConsumerState<ConfirmEmailCard> createState() => _ConfirmEmailCardState();
}

class _ConfirmEmailCardState extends ConsumerState<ConfirmEmailCard> {
  Timer? _ticker;
  var _secondsLeft = 0;
  var _sentAgain = false;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // Callers wrap this in setState (or run it from initState).
  void _startCooldown() {
    _ticker?.cancel();
    _secondsLeft = ConfirmEmailCard.resendCooldown.inSeconds;
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) timer.cancel();
    });
  }

  Future<void> _resend() async {
    setState(() => _sentAgain = false);
    // The mutation's error state (ref.listen in build) shows the snackbar;
    // this catch only keeps the rethrow from reaching the zone (#155).
    try {
      await runResendConfirmation(ref: ref, email: widget.email);
    } catch (_) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _sentAgain = true;
      _startCooldown();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<MutationState<void>>(resendConfirmationMutation, (_, next) {
      if (next is MutationError) {
        showErrorSnackbar(
          context,
          message: presentationFailureMessage(next.error, context.l10n),
        );
      }
    });
    final isSending = ref.watch(resendConfirmationMutation) is MutationPending;
    final canResend = _secondsLeft <= 0 && !isSending;

    return Container(
      key: const Key('confirm-email-card'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.tint(AppColors.success, .15),
              borderRadius: AppRadius.badgeRadius,
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              size: 22,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          Text('Check your inbox', style: AppTypography.headlineSerif),
          const SizedBox(height: AppSpacing.sm),
          Text.rich(
            TextSpan(
              style: AppTypography.chipLabel.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              children: [
                const TextSpan(text: 'We sent a confirmation link to '),
                TextSpan(
                  text: widget.email,
                  style: AppTypography.chipLabel.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
                const TextSpan(
                  text:
                      ". Open it on this phone and you'll be signed straight "
                      'in, or confirm anywhere and log in here.',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onBackToLogin,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Back to log in'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              TextButton(
                onPressed: canResend ? _resend : null,
                child: Text(
                  _secondsLeft > 0
                      ? 'Resend in ${_secondsLeft}s'
                      : 'Resend email',
                ),
              ),
              if (_sentAgain)
                Text(
                  'Sent again ✓',
                  style: AppTypography.chipLabel.copyWith(
                    color: AppColors.success,
                  ),
                ),
            ],
          ),
          TextButton(
            onPressed: widget.onUseDifferentEmail,
            child: const Text('Use a different email'),
          ),
        ],
      ),
    );
  }
}
