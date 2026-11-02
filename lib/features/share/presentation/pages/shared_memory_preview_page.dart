import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/router/route_constants.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/async_error_retry_scaffold.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/controllers/auth_state.dart';
import '../../domain/entities/shared_memory_preview.dart';
import '../controllers/pending_share_slug_controller.dart';
import '../providers/shared_memory_view_provider.dart';
import '../widgets/shared_memory_teaser.dart';
import '../widgets/shared_memory_unavailable_view.dart';

/// `/m/{slug}` in the app (#310, design 2c / 2d): the shared memory's
/// teaser for anyone but its owner, who goes straight to their Kept Memory
/// page. Signed out, it asks for an account; the link stays pending, so
/// sign-up / log-in comes back here.
class SharedMemoryPreviewPage extends ConsumerWidget {
  const SharedMemoryPreviewPage({required this.slug, super.key});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(sharedMemoryViewProvider(slug));

    ref.listen(sharedMemoryViewProvider(slug), (_, next) {
      final value = next.value;
      final pending = ref.read(pendingShareSlugControllerProvider.notifier);
      if (value is SharedMemoryOwn) {
        pending.clear();
        context.goNamed(
          RouteNames.keptMemory,
          pathParameters: {'tripId': value.tripId},
        );
      } else if (value is SharedMemoryUnavailable ||
          (value is SharedMemoryTeaser && value.signedIn)) {
        // Seen signed in, or nothing to come back to after sign-up.
        pending.clear();
      } else if (value is SharedMemoryTeaser) {
        // Signed out: sign-up / log-in comes back here.
        pending.set(slug);
      }
    });

    void close() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(
          _isSignedIn(ref) ? RoutePaths.home : RoutePaths.guestLanding,
        );
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.screenGroundRadial(
            AppGradients.groundTopLandingAuth,
          ),
        ),
        child: view.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (error, _) => AsyncErrorRetryScaffold(
            message: presentationFailureMessage(error, context.l10n),
            onRetry: () => ref.invalidate(sharedMemoryViewProvider(slug)),
          ),
          data: (view) => switch (view) {
            SharedMemoryOwn() => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            SharedMemoryUnavailable() => SharedMemoryUnavailableView(
              onClose: close,
              onStartOwn: () => _startOwn(context, ref),
            ),
            SharedMemoryTeaser(:final preview, :final signedIn) => _TeaserBody(
              preview: preview,
              signedIn: signedIn,
              onClose: close,
              onStartOwn: () => _startOwn(context, ref),
            ),
          },
        ),
      ),
    );
  }

  bool _isSignedIn(WidgetRef ref) =>
      ref.read(authControllerProvider).status == AuthStatus.authenticated;

  /// Signed in: a new memory. Signed out: an account first.
  void _startOwn(BuildContext context, WidgetRef ref) {
    if (_isSignedIn(ref)) {
      context.go(RoutePaths.home);
      context.pushNamed(RouteNames.createMemory);
    } else {
      context.go(RoutePaths.signup);
    }
  }
}

class _TeaserBody extends StatelessWidget {
  const _TeaserBody({
    required this.preview,
    required this.signedIn,
    required this.onClose,
    required this.onStartOwn,
  });

  final SharedMemoryPreview preview;
  final bool signedIn;
  final VoidCallback onClose;
  final VoidCallback onStartOwn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SharedMemoryHero(preview: preview, onClose: onClose),
                if (preview.photoUrls.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SharedMemoryStrip(photoUrls: preview.photoUrls),
                ],
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
            child: signedIn
                ? ElevatedButton(
                    key: const Key('shared-memory-start-own'),
                    onPressed: onStartOwn,
                    child: Text(context.l10n.share_startOwn),
                  )
                : _SignUpBlock(ownerName: preview.ownerName),
          ),
        ),
      ],
    );
  }
}

class _SignUpBlock extends StatelessWidget {
  const _SignUpBlock({this.ownerName});

  final String? ownerName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final headline = AppTypography.serif(
      fontSize: 21,
      height: 1.3,
      color: AppColors.textPrimary,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            text: l10n.share_inapp_headline(ownerName ?? l10n.share_someone),
            children: [
              const TextSpan(text: ' '),
              TextSpan(
                text: l10n.share_inapp_headlineEmphasis,
                style: headline.copyWith(
                  fontStyle: FontStyle.italic,
                  color: AppColors.primaryLight,
                ),
              ),
            ],
          ),
          style: headline,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.share_inapp_body,
          style: AppTypography.caption.copyWith(
            fontSize: 12.5,
            height: 1.5,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          key: const Key('shared-memory-create-account'),
          onPressed: () => context.go(RoutePaths.signup),
          child: Text(l10n.share_createAccount),
        ),
        TextButton(
          key: const Key('shared-memory-log-in'),
          onPressed: () => context.go(RoutePaths.login),
          child: Text(
            l10n.share_login,
            style: AppTypography.bodyEmphasis.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
