import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/router/route_constants.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/dashed_rrect_border.dart';
import '../../../../core/widgets/show_error_snackbar.dart';
import '../mutations/auth_mutations.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/password_strength_meter.dart';

enum AuthMode { login, signup }

/// Single auth screen with a segmented Create account / Log in toggle,
/// replacing the old separate LoginPage/RegisterPage.
/// `docs/design/README.md` § 2.
class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({required this.initialMode, super.key});

  final AuthMode initialMode;

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  var _autovalidate = AutovalidateMode.disabled;
  late var _mode = widget.initialMode;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  bool get _isSignup => _mode == AuthMode.signup;

  String? _validateName(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Enter your name.';
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email.';
    if (!email.contains('@')) return 'Enter a valid email.';
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return _isSignup ? 'Enter a password.' : 'Enter your password.';
    }
    if (password.length < 6) return 'At least 6 characters.';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (!_isSignup) return null;
    if (value != _password.text) return 'Passwords do not match.';
    return null;
  }

  Future<void> _submit() async {
    setState(() => _autovalidate = AutovalidateMode.always);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isSignup) {
      await runSignup(
        ref: ref,
        email: _email.text.trim(),
        password: _password.text,
        username: _name.text.trim(),
      );
    } else {
      await runLogin(
        ref: ref,
        email: _email.text.trim(),
        password: _password.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mutation = _isSignup ? signupMutation : loginMutation;
    ref.listen<MutationState<void>>(mutation, (previous, next) {
      if (next is MutationError) {
        showErrorSnackbar(
          context,
          message: presentationFailureMessage(next.error),
        );
      }
    });
    final isLoading = ref.watch(mutation) is MutationPending;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.sm),
              _BackLink(
                onTap: () => context.goNamed(RouteNames.guestLanding),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Begin your',
                style: AppTypography.screenTitle.copyWith(
                  fontSize: 32,
                  height: 1.15,
                ),
              ),
              Text(
                'collection.',
                style: AppTypography.screenTitle.copyWith(
                  fontSize: 32,
                  height: 1.15,
                  fontStyle: FontStyle.italic,
                  color: AppColors.primaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _ModeToggle(
                mode: _mode,
                onChanged: (mode) => setState(() => _mode = mode),
              ),
              const SizedBox(height: AppSpacing.lg),
              Form(
                key: _formKey,
                autovalidateMode: _autovalidate,
                child: Column(
                  children: [
                    if (_isSignup) ...[
                      AuthTextField(
                        label: 'Name',
                        controller: _name,
                        hintText: 'Ada Wong',
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: _validateName,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    AuthTextField(
                      label: 'Email',
                      controller: _email,
                      hintText: 'ada@wanderlog.app',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AuthTextField(
                      label: 'Password',
                      controller: _password,
                      obscureText: true,
                      showObscureToggle: true,
                      textInputAction: _isSignup
                          ? TextInputAction.next
                          : TextInputAction.done,
                      validator: _validatePassword,
                    ),
                    if (_isSignup)
                      ListenableBuilder(
                        listenable: _password,
                        builder: (context, _) =>
                            PasswordStrengthMeter(password: _password.text),
                      ),
                    if (_isSignup) ...[
                      const SizedBox(height: AppSpacing.md),
                      AuthTextField(
                        label: 'Confirm password',
                        controller: _confirmPassword,
                        obscureText: true,
                        showObscureToggle: true,
                        textInputAction: TextInputAction.done,
                        validator: _validateConfirmPassword,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _isSignup ? 'Create my account' : 'Log in',
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.base),
              Center(
                child: Text(
                  'Your memories stay yours — nothing is ever published.',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(letterSpacing: 0),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const _RewardTeaseCard(),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackLink extends StatelessWidget {
  const _BackLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.badgeRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.arrow_back,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text('Back', style: AppTypography.chipLabel),
          ],
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final AuthMode mode;
  final ValueChanged<AuthMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.pillRadius,
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeSegment(
              label: 'Create account',
              selected: mode == AuthMode.signup,
              onTap: () => onChanged(AuthMode.signup),
            ),
          ),
          Expanded(
            child: _ModeSegment(
              label: 'Log in',
              selected: mode == AuthMode.login,
              onTap: () => onChanged(AuthMode.login),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSegment extends StatelessWidget {
  const _ModeSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const _segmentRadius = BorderRadius.all(Radius.circular(10));

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: _segmentRadius,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: _segmentRadius,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.buttonLabel.copyWith(
            fontSize: 13,
            color: selected ? AppColors.background : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _RewardTeaseCard extends StatelessWidget {
  const _RewardTeaseCard();

  @override
  Widget build(BuildContext context) {
    return DashedRRectBorder(
      color: AppColors.tint(AppColors.textPrimary, .28),
      borderRadius: AppRadius.cardRadius,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: AppRadius.badgeRadius,
              ),
              child: Text(
                '✦',
                style: AppTypography.bodyInput.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: AppTypography.chipLabel.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  children: [
                    const TextSpan(text: 'Your first memory earns '),
                    TextSpan(
                      text: '10 stars',
                      style: AppTypography.chipLabel.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(
                      text:
                          ' — and the Storyteller badge is only three notes '
                          'away.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
