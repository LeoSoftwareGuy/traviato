import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/router/route_constants.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/async_error_retry_scaffold.dart';
import '../../../../core/widgets/show_error_snackbar.dart';
import '../controllers/wrap_up_controller.dart';
import '../controllers/wrap_up_state.dart';
import '../mutations/wrap_up_mutations.dart';
import '../widgets/wrap_up_achievement_moment_card.dart';
import '../widgets/wrap_up_close_section.dart';
import '../widgets/wrap_up_generating_view.dart';
import '../widgets/wrap_up_hero_section.dart';
import '../widgets/wrap_up_photo_beat_section.dart';
import '../widgets/wrap_up_route_chapter_section.dart';
import '../widgets/wrap_up_stat_chapter_section.dart';

class WrapUpPage extends ConsumerWidget {
  const WrapUpPage({required this.tripId, super.key});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<MutationState<void>>(publishWrapUpMutation, (previous, next) {
      if (next is MutationError) {
        showErrorSnackbar(
          context,
          message: presentationFailureMessage(next.error),
        );
      }
    });

    final wrapUpAsync = ref.watch(wrapUpControllerProvider(tripId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: wrapUpAsync.when(
        loading: () => const WrapUpGeneratingView(),
        error: (error, _) => AsyncErrorRetryScaffold(
          message: presentationFailureMessage(error),
          onRetry: () => ref.invalidate(wrapUpControllerProvider(tripId)),
        ),
        data: (state) => _WrapUpContent(tripId: tripId, state: state),
      ),
    );
  }
}

class _WrapUpContent extends StatelessWidget {
  const _WrapUpContent({required this.tripId, required this.state});

  final String tripId;
  final WrapUpState state;

  @override
  Widget build(BuildContext context) {
    final wrapUp = state.wrapUp;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (wrapUp.hero != null)
          WrapUpHeroSection(
            hero: wrapUp.hero!,
            coverImageUrl: state.imageUrlForPhoto(wrapUp.hero!.coverPhotoId),
            tripStartDate: state.trip.startDate,
            onClose: () => context.goNamed(RouteNames.home),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (wrapUp.routeChapter != null) ...[
                WrapUpRouteChapterSection(chapter: wrapUp.routeChapter!),
                const SizedBox(height: AppSpacing.xxl),
              ],
              WrapUpPhotoBeatSection(
                beats: wrapUp.photoBeats,
                imageUrlForPhoto: state.imageUrlForPhoto,
              ),
              if (wrapUp.photoBeats.isNotEmpty)
                const SizedBox(height: AppSpacing.xxl),
              if (wrapUp.statChapter != null) ...[
                WrapUpStatChapterSection(chapter: wrapUp.statChapter!),
                const SizedBox(height: AppSpacing.xxl),
              ],
              if (wrapUp.achievementMoment != null) ...[
                WrapUpAchievementMomentCard(moment: wrapUp.achievementMoment!),
                const SizedBox(height: AppSpacing.xxl),
              ],
              if (wrapUp.close != null)
                WrapUpCloseSection(
                  close: wrapUp.close!,
                  tripId: tripId,
                  isPublished: wrapUp.isPublished,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
