import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../core/errors/failure_message.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/show_error_snackbar.dart';
import '../mutations/auth_mutations.dart';

/// "Continue with Apple" / "Continue with Google", under both Create-account
/// and Log-in modes of [AuthPage]. Apple's official button on iOS only —
/// required by App Store review whenever another social provider is offered
/// there; Google shows on every platform. No Figma frame covers this (see
/// the plan comment on issue #84); the Google "G" below is a placeholder
/// monogram, not the licensed brand asset — swap before store submission.
class SocialSignInButtons extends ConsumerWidget {
  const SocialSignInButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<MutationState<void>>(signInWithAppleMutation, (previous, next) {
      if (next is MutationError) {
        showErrorSnackbar(
          context,
          message: presentationFailureMessage(next.error),
        );
      }
    });
    ref.listen<MutationState<void>>(signInWithGoogleMutation, (
      previous,
      next,
    ) {
      if (next is MutationError) {
        showErrorSnackbar(
          context,
          message: presentationFailureMessage(next.error),
        );
      }
    });

    final isAppleLoading =
        ref.watch(signInWithAppleMutation) is MutationPending;
    final isGoogleLoading =
        ref.watch(signInWithGoogleMutation) is MutationPending;
    final isAnyLoading = isAppleLoading || isGoogleLoading;

    return Column(
      children: [
        const _OrDivider(),
        const SizedBox(height: AppSpacing.lg),
        if (defaultTargetPlatform == TargetPlatform.iOS) ...[
          SizedBox(
            key: const Key('apple-sign-in-button'),
            width: double.infinity,
            height: 48,
            child: SignInWithAppleButton(
              borderRadius: AppRadius.cardRadius,
              // Errors surface via the ref.listen above; .ignore() only
              // marks this Future's rejection as handled so it isn't also
              // reported as an unhandled async error.
              onPressed: isAnyLoading
                  ? null
                  : () => runSignInWithApple(ref: ref).ignore(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        _GoogleSignInButton(
          isLoading: isGoogleLoading,
          onTap: isAnyLoading
              ? null
              : () => runSignInWithGoogle(ref: ref).ignore(),
        ),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.surfaceBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text('or', style: AppTypography.caption),
        ),
        const Expanded(child: Divider(color: AppColors.surfaceBorder)),
      ],
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('google-sign-in-button'),
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface,
          side: const BorderSide(color: AppColors.surfaceBorder),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.cardRadius,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _GoogleG(),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Continue with Google',
                    style: AppTypography.buttonLabel,
                  ),
                ],
              ),
      ),
    );
  }
}

// Placeholder monogram, not Google's licensed "G" mark — swap for the real
// asset before store submission (no design source provides one; see the
// class doc above).
class _GoogleG extends StatelessWidget {
  const _GoogleG();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const Text(
        'G',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          height: 1,
          color: Color(0xFF4285F4),
        ),
      ),
    );
  }
}
