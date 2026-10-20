import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/router/route_constants.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/presentation_failure_exception.dart';
import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/bottom_sheet_chrome.dart';
import '../../../../core/widgets/star_award_toast.dart';
import '../mutations/photo_mutations.dart';
import 'location_permission_prompt.dart';

enum _BatchItemStatus { pending, uploading, success, failed }

class _BatchItem {
  _BatchItem(this.bytes);

  final Uint8List bytes;
  _BatchItemStatus status = _BatchItemStatus.pending;
}

/// Multi-select gallery upload (#116) — each image runs through the same
/// `runAddPhoto` pipeline as the single-photo flow (EXIF → compress →
/// upload → row insert → award), one at a time so progress ("Uploading 2
/// of 5…") is straightforward and only one image is decoded/compressed in
/// memory at once. No caption/place prompt for a batch — see the plan
/// discussion on #116; that stays exclusive to the single-photo flow.
class BatchAddPhotoSheet extends ConsumerStatefulWidget {
  const BatchAddPhotoSheet({
    required this.tripId,
    required this.dayDate,
    required this.images,
    super.key,
  });

  final String tripId;
  final DateTime dayDate;
  final List<Uint8List> images;

  static Future<void> show(
    BuildContext context, {
    required String tripId,
    required DateTime dayDate,
    required List<Uint8List> images,
  }) {
    return showAppBottomSheet<void>(
      context: context,
      builder: (context) => BatchAddPhotoSheet(
        tripId: tripId,
        dayDate: dayDate,
        images: images,
      ),
    );
  }

  @override
  ConsumerState<BatchAddPhotoSheet> createState() => _BatchAddPhotoSheetState();
}

class _BatchAddPhotoSheetState extends ConsumerState<BatchAddPhotoSheet> {
  late final List<_BatchItem> _items = widget.images
      .map(_BatchItem.new)
      .toList();
  var _isRunning = false;

  /// The most recent upload error, shown under the summary so a failed
  /// batch says *why* (#262) instead of only "0 uploaded, N failed".
  Object? _lastError;

  int get _successCount =>
      _items.where((i) => i.status == _BatchItemStatus.success).length;
  int get _failedCount =>
      _items.where((i) => i.status == _BatchItemStatus.failed).length;
  int get _completedCount => _successCount + _failedCount;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() {
      _isRunning = true;
      _lastError = null;
    });
    final locationGranted = await resolveLocationPermission(context);
    if (!mounted) return;

    for (final item in _items) {
      if (item.status == _BatchItemStatus.success) continue;
      setState(() => item.status = _BatchItemStatus.uploading);
      try {
        await runAddPhoto(
          ref: ref,
          tripId: widget.tripId,
          dayDate: widget.dayDate,
          rawBytes: item.bytes,
          locationPermissionGranted: locationGranted,
        );
        if (!mounted) return;
        setState(() => item.status = _BatchItemStatus.success);
      } catch (e) {
        debugPrint('batch photo upload failed: $e');
        if (!mounted) return;
        setState(() {
          item.status = _BatchItemStatus.failed;
          _lastError = e;
        });
        // The photo cap rejects every remaining image the same way — stop
        // instead of uploading (and rejecting) the rest one by one.
        if (_isPhotoLimit(e)) {
          setState(_failRemaining);
          break;
        }
      }
    }
    if (!mounted) return;

    if (_failedCount == 0) {
      _finish();
    } else {
      setState(() => _isRunning = false);
    }
  }

  static bool _isPhotoLimit(Object error) =>
      error is PresentationFailureException &&
      error.failure is PhotoLimitFailure;

  void _failRemaining() {
    for (final item in _items) {
      if (item.status == _BatchItemStatus.pending) {
        item.status = _BatchItemStatus.failed;
      }
    }
  }

  /// Same paywall entry as `showFailureSnackbar` uses for a photo-cap
  /// failure in the single-photo flow (string must match the
  /// `PaywallEntryPoint.photoCap` enum name in paywall_page.dart).
  void _openUpgrade() {
    final router = GoRouter.of(context);
    _finish();
    router.pushNamed(
      RouteNames.subscriptionOfferings,
      queryParameters: {'entry': 'photoCap'},
    );
  }

  Future<void> _retryFailed() async {
    for (final item in _items) {
      if (item.status == _BatchItemStatus.failed) {
        item.status = _BatchItemStatus.pending;
      }
    }
    await _run();
  }

  void _finish() {
    final successCount = _successCount;
    if (successCount > 0) {
      final points = successCount * 2; // photo = ✦2, canonical + flat
      showStarToast(
        context,
        context.l10n.toast_photosLogged(points, successCount),
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: _isRunning ? _buildProgress() : _buildSummary(),
    );
  }

  Widget _buildProgress() {
    final current = (_completedCount + 1).clamp(1, _items.length);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.photo_uploadingTitle,
          style: AppTypography.screenTitle.copyWith(fontSize: 21),
        ),
        const SizedBox(height: AppSpacing.lg),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            key: const Key('batch-photo-progress'),
            value: _completedCount / _items.length,
            minHeight: 6,
            backgroundColor: AppColors.surfaceBorder,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.l10n.photo_uploadingProgress(current, _items.length),
          style: AppTypography.caption,
        ),
      ],
    );
  }

  Widget _buildSummary() {
    final failed = _failedCount;
    final success = _successCount;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.photo_uploadComplete,
          style: AppTypography.screenTitle.copyWith(fontSize: 21),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          context.l10n.photo_uploadSummary(success, failed),
          style: AppTypography.bodyInput,
        ),
        if (_lastError case final error?) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            presentationFailureMessage(error, context.l10n),
            key: const Key('batch-photo-error'),
            style: AppTypography.caption,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        // Retrying can't get past the photo cap, so offer the way out instead.
        if (_lastError case final error? when _isPhotoLimit(error))
          ElevatedButton(
            key: const Key('batch-photo-upgrade'),
            onPressed: _openUpgrade,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(context.l10n.common_upgrade),
          )
        else
          ElevatedButton(
            key: const Key('batch-photo-retry'),
            onPressed: _retryFailed,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(context.l10n.photo_retryFailed(failed)),
          ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          key: const Key('batch-photo-done'),
          onPressed: _finish,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          child: Text(context.l10n.common_done),
        ),
      ],
    );
  }
}
