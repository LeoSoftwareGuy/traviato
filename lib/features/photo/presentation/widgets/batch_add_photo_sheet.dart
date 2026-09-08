import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    setState(() => _isRunning = true);
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
      } catch (_) {
        if (!mounted) return;
        setState(() => item.status = _BatchItemStatus.failed);
      }
    }
    if (!mounted) return;

    if (_failedCount == 0) {
      _finish();
    } else {
      setState(() => _isRunning = false);
    }
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
        '✦ +$points stars · $successCount photo${successCount == 1 ? '' : 's'} logged',
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
          'Uploading photos',
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
          'Uploading $current of ${_items.length}…',
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
          'Upload complete',
          style: AppTypography.screenTitle.copyWith(fontSize: 21),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          '$success uploaded, $failed failed.',
          style: AppTypography.bodyInput,
        ),
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton(
          key: const Key('batch-photo-retry'),
          onPressed: _retryFailed,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          child: Text('Retry failed ($failed)'),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          key: const Key('batch-photo-done'),
          onPressed: _finish,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
