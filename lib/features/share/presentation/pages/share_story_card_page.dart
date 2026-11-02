import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/show_error_snackbar.dart';
import '../../../../core/widgets/star_award_toast.dart';
import '../../../trip/presentation/widgets/trip_cover_image.dart';
import '../../domain/entities/share_link.dart';
import '../providers/share_memory_provider.dart';
import '../providers/share_providers.dart';
import '../widgets/share_memory_labels.dart';
import '../widgets/share_qr_code.dart';
import '../widgets/share_story_card.dart';

/// The Instagram story card (#311, design 1d): a 1080×1920 card with the
/// memory's cover, title and the link's QR, a cover picker from the
/// link's teaser photos, then Instagram Stories or Save to Photos.
class ShareStoryCardPage extends ConsumerStatefulWidget {
  const ShareStoryCardPage({
    required this.tripId,
    required this.link,
    super.key,
  });

  final String tripId;
  final ShareLink link;

  static Future<void> show(
    BuildContext context, {
    required String tripId,
    required ShareLink link,
  }) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => ShareStoryCardPage(tripId: tripId, link: link),
    ),
  );

  @override
  ConsumerState<ShareStoryCardPage> createState() => _ShareStoryCardPageState();
}

class _ShareStoryCardPageState extends ConsumerState<ShareStoryCardPage> {
  final _cardKey = GlobalKey();

  /// Null = the link's cover (the first teaser photo).
  String? _coverPath;
  var _isBusy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _isBusy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _instagram() => _run(() async {
    final message = context.l10n.error_unknown;
    try {
      final png = await captureBoundaryPng(_cardKey);
      await ref
          .read(shareOutletsProvider)
          .shareStoryCard(png: png, url: widget.link.url);
    } catch (_) {
      if (mounted) showErrorSnackbar(context, message: message);
    }
  });

  Future<void> _save() => _run(() async {
    final l10n = context.l10n;
    try {
      final png = await captureBoundaryPng(_cardKey);
      await ref.read(shareOutletsProvider).saveToPhotos(png);
      if (mounted) showStarToast(context, l10n.story_toastSaved);
    } catch (_) {
      if (mounted) showErrorSnackbar(context, message: l10n.share_saveFailed);
    }
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final memory = ref.watch(shareMemoryProvider(widget.tripId)).value;
    final trip = memory?.trip;
    final photos = memory?.teaserPhotos ?? const [];
    final cover =
        _coverPath ?? photos.firstOrNull?.storagePath ?? trip?.coverImagePath;
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: AppColors.viewerBackground,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(eyebrow: l10n.story_eyebrow),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: ShareStoryCard.width / ShareStoryCard.height,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: FittedBox(
                        child: RepaintBoundary(
                          key: _cardKey,
                          child: ShareStoryCard(
                            title: trip?.name ?? '',
                            eyebrow: trip?.placeAndDays(l10n) ?? '',
                            dates: trip?.dates(locale)?.toUpperCase(),
                            coverPath: cover,
                            url: widget.link.url,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (photos.length > 1)
              _CoverPicker(
                paths: [for (final p in photos) p.storagePath],
                selected: cover,
                onSelect: (path) => setState(() => _coverPath = path),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, AppSpacing.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: _isBusy || trip == null ? null : _instagram,
                    child: Text(l10n.story_instagram),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton(
                    onPressed: _isBusy || trip == null ? null : _save,
                    child: Text(l10n.story_save),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.eyebrow});

  final String eyebrow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: context.l10n.common_back,
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: AppColors.textPrimary),
            ),
          ),
          Text(
            eyebrow.toUpperCase(),
            style: AppTypography.mono.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// The teaser photos as 42px thumbs; the chosen one has a primary ring.
class _CoverPicker extends StatelessWidget {
  const _CoverPicker({
    required this.paths,
    required this.selected,
    required this.onSelect,
  });

  final List<String> paths;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Wrap(
        spacing: AppSpacing.sm,
        children: [
          for (final path in paths)
            GestureDetector(
              key: ValueKey('story-cover-$path'),
              onTap: () => onSelect(path),
              child: Container(
                width: 46,
                height: 46,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    width: 2,
                    color: path == selected
                        ? AppColors.primary
                        : Colors.transparent,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: TripCoverImage(imagePath: path),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
