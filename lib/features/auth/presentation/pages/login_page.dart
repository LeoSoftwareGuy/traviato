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

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _autovalidate = AutovalidateMode.disabled;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email.';
    if (!email.contains('@')) return 'Enter a valid email.';
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Enter your password.';
    if (password.length < 6) return 'At least 6 characters.';
    return null;
  }

  Future<void> _submit() async {
    setState(() => _autovalidate = AutovalidateMode.always);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await runLogin(
      ref: ref,
      email: _email.text.trim(),
      password: _password.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<MutationState<void>>(loginMutation, (previous, next) {
      if (next is MutationError) {
        showErrorSnackbar(
          context,
          message: presentationFailureMessage(next.error),
        );
      }
    });
    final isLoading = ref.watch(loginMutation) is MutationPending;

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
                    color: AppColors.primaryTint,
                    borderRadius: AppRadius.cardRadius,
                    border: Border.all(color: AppColors.primaryTint),
                  ),
                  child: const Icon(
                    Icons.explore_outlined,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Welcome back',
                textAlign: TextAlign.center,
                style: AppTypography.displaySerif,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Log in to continue your journey',
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
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      validator: _validatePassword,
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
                          : const Text('Log in'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Center(
                child: TextButton(
                  onPressed: () => context.goNamed(RouteNames.signup),
                  child: RichText(
                    text: TextSpan(
                      style: AppTypography.chipLabel,
                      children: [
                        const TextSpan(text: "Don't have an account? "),
                        TextSpan(
                          text: 'Sign up',
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
