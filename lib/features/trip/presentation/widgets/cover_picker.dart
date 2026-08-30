import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/dashed_rrect_border.dart';
import '../../../../core/widgets/photo_scrim.dart';
import 'cover_options.dart';
import 'cover_upload_tile.dart';

/// The New memory cover picker: a 150px slot (empty/chosen state) above an
/// 8-thumbnail strip. `docs/design/README.md` § 4.
class CoverPicker extends StatelessWidget {
  const CoverPicker({
    required this.selectedCoverId,
    required this.selectedVibes,
    required this.onSelect,
    this.customCoverBytes,
    this.onUploadCustom,
    super.key,
  });

  final String? selectedCoverId;
  final Set<String> selectedVibes;
  final ValueChanged<String> onSelect;

  /// Locally-picked bytes pending upload (issue #81) — takes priority over
  /// [selectedCoverId] for the preview slot when set.
  final Uint8List? customCoverBytes;
  final Future<void> Function(Uint8List bytes)? onUploadCustom;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CoverSlot(
          selectedCoverId: selectedCoverId,
          selectedVibes: selectedVibes,
          customCoverBytes: customCoverBytes,
        ),
        const SizedBox(height: AppSpacing.sm),
        CoverThumbnailStrip(
          selectedCoverId: selectedCoverId,
          onSelect: onSelect,
          onUploadCustom: onUploadCustom,
        ),
      ],
    );
  }
}

/// The 8-thumbnail strip on its own — reused by the manage-memory sheet's
/// cover-change section, which doesn't need the empty/chosen slot above it.
class CoverThumbnailStrip extends StatelessWidget {
  const CoverThumbnailStrip({
    required this.selectedCoverId,
    required this.onSelect,
    this.onUploadCustom,
    super.key,
  });

  final String? selectedCoverId;
  final ValueChanged<String> onSelect;

  /// When given, a leading "Upload photo" tile opens a camera/gallery
  /// picker and hands the compressed bytes here (issue #81).
  final Future<void> Function(Uint8List bytes)? onUploadCustom;

  @override
  Widget build(BuildContext context) {
    final onUpload = onUploadCustom;
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kCoverOptions.length + (onUpload == null ? 0 : 1),
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (onUpload != null && index == 0) {
            return CoverUploadTile(onPicked: onUpload);
          }
          final option = kCoverOptions[index - (onUpload == null ? 0 : 1)];
          return _Thumbnail(
            option: option,
            selected: option.id == selectedCoverId,
            onTap: () => onSelect(option.id),
          );
        },
      ),
    );
  }
}

class _CoverSlot extends StatelessWidget {
  const _CoverSlot({
    required this.selectedCoverId,
    required this.selectedVibes,
    this.customCoverBytes,
  });

  final String? selectedCoverId;
  final Set<String> selectedVibes;
  final Uint8List? customCoverBytes;

  @override
  Widget build(BuildContext context) {
    final customBytes = customCoverBytes;
    final coverId = selectedCoverId;
    if (customBytes != null || coverId != null) {
      final image = customBytes != null
          ? Image.memory(customBytes, fit: BoxFit.cover)
          : Image.asset(
              kCoverOptions.firstWhere((o) => o.id == coverId).assetPath,
              fit: BoxFit.cover,
            );
      return Container(
        height: 150,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: AppRadius.mediaRadius,
          border: Border.all(color: AppColors.tint(AppColors.primary, .4)),
        ),
        child: PhotoScrim(
          image: image,
          child: const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: _MonoTag('YOUR COVER'),
            ),
          ),
        ),
      );
    }

    final suggestion = selectedVibes.isEmpty
        ? null
        : suggestedCover(selectedVibes);

    return Container(
      height: 150,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-1, -0.6),
          end: const Alignment(1, 0.6),
          colors: [
            AppColors.tint(AppColors.primary, .14),
            AppColors.tint(AppColors.accentPurple, .14),
          ],
        ),
        borderRadius: AppRadius.mediaRadius,
      ),
      child: DashedRRectBorder(
        color: AppColors.tint(AppColors.textSecondary, .28),
        borderRadius: AppRadius.mediaRadius,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _FloatingStar(),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Choose a cover',
                      style: AppTypography.screenTitle.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "or we'll pick one that suits the vibe",
                      style: AppTypography.chipLabel.copyWith(
                        fontSize: 10.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (suggestion != null)
                Positioned(
                  left: 0,
                  bottom: 0,
                  child: _MonoTag(
                    'SUGGESTED: ${suggestion.vibe.toUpperCase()}',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final CoverOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: Key('cover-thumbnail-${option.id}'),
      onTap: onTap,
      borderRadius: AppRadius.badgeRadius,
      child: Container(
        width: 60,
        height: 46,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: AppRadius.badgeRadius,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.surfaceBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(option.assetPath, fit: BoxFit.cover),
            if (selected)
              Container(
                color: AppColors.tint(AppColors.primary, .28),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MonoTag extends StatelessWidget {
  const _MonoTag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.tint(AppColors.background, .62),
        borderRadius: AppRadius.pillRadius,
      ),
      child: Text(
        text,
        style: AppTypography.mono.copyWith(color: AppColors.primaryLight),
      ),
    );
  }
}

class _FloatingStar extends StatefulWidget {
  const _FloatingStar();

  @override
  State<_FloatingStar> createState() => _FloatingStarState();
}

class _FloatingStarState extends State<_FloatingStar>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: AppMotion.floatYMinDuration,
  );
  late final _translateY = Tween<double>(
    begin: 0,
    end: -7,
  ).animate(CurvedAnimation(parent: _controller, curve: AppMotion.floatYCurve));
  Timer? _startTimer;

  @override
  void initState() {
    super.initState();
    // One-shot, not repeat(): this slot is on-screen the whole time the
    // Create memory form is open, and a repeating animation would never
    // let a pumpAndSettle() in this page's own tests (needed for the
    // async create-mutation flow) settle.
    _startTimer = Timer(Duration.zero, () => _controller.forward());
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _translateY.value),
        child: child,
      ),
      child: Text(
        '✦',
        style: AppTypography.bigNumber.copyWith(
          fontSize: 22,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
