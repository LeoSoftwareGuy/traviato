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
import '../../../../core/widgets/show_error_snackbar.dart';
import '../mutations/auth_mutations.dart';
import '../widgets/auth_text_field.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  var _autovalidate = AutovalidateMode.disabled;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

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
    if (password.isEmpty) return 'Enter a password.';
    if (password.length < 6) return 'At least 6 characters.';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _password.text) return 'Passwords do not match.';
    return null;
  }

  Future<void> _submit() async {
    setState(() => _autovalidate = AutovalidateMode.always);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await runSignup(
      ref: ref,
      email: _email.text.trim(),
      password: _password.text,
      username: _name.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<MutationState<void>>(signupMutation, (previous, next) {
      if (next is MutationError) {
        showErrorSnackbar(
          context,
          message: presentationFailureMessage(next.error),
        );
      }
    });
    final isLoading = ref.watch(signupMutation) is MutationPending;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.sm),
              IconButton(
                onPressed: () => context.goNamed(RouteNames.guestLanding),
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.accentCoralTint,
                    borderRadius: AppRadius.cardRadius,
                    border: Border.all(color: AppColors.accentCoralTint),
                  ),
                  child: const Icon(
                    Icons.rocket_launch_outlined,
                    color: AppColors.accentCoral,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Start your journey',
                textAlign: TextAlign.center,
                style: AppTypography.displaySerif,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Create an account to track your adventures',
                textAlign: TextAlign.center,
                style: AppTypography.chipLabel,
              ),
              const SizedBox(height: AppSpacing.xxl),
              Form(
                key: _formKey,
                autovalidateMode: _autovalidate,
                child: Column(
                  children: [
                    AuthTextField(
                      label: 'Name',
                      controller: _name,
                      icon: Icons.person_outline,
                      hintText: 'Ada Wong',
                      textInputAction: TextInputAction.next,
                      validator: _validateName,
                    ),
                    const SizedBox(height: AppSpacing.base),
                    AuthTextField(
                      label: 'Email',
                      controller: _email,
                      icon: Icons.mail_outline,
                      hintText: 'ada@wanderlog.app',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: AppSpacing.base),
                    AuthTextField(
                      label: 'Password',
                      controller: _password,
                      icon: Icons.lock_outline,
                      hintText: 'At least 6 characters',
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: AppSpacing.base),
                    AuthTextField(
                      label: 'Confirm password',
                      controller: _confirmPassword,
                      icon: Icons.verified_user_outlined,
                      hintText: 'Repeat your password',
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      validator: _validateConfirmPassword,
                    ),
                    const SizedBox(height: AppSpacing.base),
                    ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create account'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Center(
                child: TextButton(
                  onPressed: () => context.goNamed(RouteNames.login),
                  child: RichText(
                    text: TextSpan(
                      style: AppTypography.chipLabel,
                      children: [
                        const TextSpan(text: 'Already have an account? '),
                        TextSpan(
                          text: 'Log in',
                          style: AppTypography.chipLabel.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
