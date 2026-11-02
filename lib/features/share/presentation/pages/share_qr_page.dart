import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/show_error_snackbar.dart';
import '../../../../core/widgets/star_award_toast.dart';
import '../../domain/entities/share_link.dart';
import '../providers/share_memory_provider.dart';
import '../providers/share_providers.dart';
import '../widgets/share_memory_labels.dart';
import '../widgets/share_qr_code.dart';

/// Full-screen QR for the share link (#311, design 1c). The screen goes to
/// full brightness while it's open so another phone can scan it.
class ShareQrPage extends ConsumerStatefulWidget {
  const ShareQrPage({required this.tripId, required this.link, super.key});

  final String tripId;
  final ShareLink link;

  static Future<void> show(
    BuildContext context, {
    required String tripId,
    required ShareLink link,
  }) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => ShareQrPage(tripId: tripId, link: link),
    ),
  );

  @override
  ConsumerState<ShareQrPage> createState() => _ShareQrPageState();
}

class _ShareQrPageState extends ConsumerState<ShareQrPage> {
  final _cardKey = GlobalKey();
  late final _outlets = ref.read(shareOutletsProvider);
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    unawaited(_brightness(_outlets.maxBrightness));
  }

  @override
  void dispose() {
    unawaited(_brightness(_outlets.restoreBrightness));
    super.dispose();
  }

  /// Brightness is a nicety — no plugin (tests, desktop) is fine.
  Future<void> _brightness(Future<void> Function() change) async {
    try {
      await change();
    } catch (_) {}
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    setState(() => _isSaving = true);
    try {
      final png = await captureBoundaryPng(_cardKey, pixelRatio: 3);
      await _outlets.saveToPhotos(png);
      if (mounted) showStarToast(context, l10n.story_toastSaved);
    } catch (_) {
      if (mounted) showErrorSnackbar(context, message: l10n.share_saveFailed);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _copy() async {
    final message = context.l10n.share_toastCopied;
    await Clipboard.setData(ClipboardData(text: widget.link.url));
    await HapticFeedback.lightImpact();
    if (mounted) showStarToast(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final trip = ref.watch(shareMemoryProvider(widget.tripId)).value?.trip;
    final locale = Localizations.localeOf(context).languageCode;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.screenGroundRadial(
            AppGradients.groundTopJournal,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: l10n.common_back,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppColors.textPrimary),
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: RepaintBoundary(
                      key: _cardKey,
                      child: _QrCard(
                        title: trip?.name ?? '',
                        meta: trip?.placeAndDates(locale) ?? '',
                        url: widget.link.url,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, AppSpacing.base),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : _save,
                        child: Text(l10n.qr_save),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _copy,
                        child: Text(l10n.qr_copyLink),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Eyebrow, title, meta, the QR on cream, and the URL — what Save image
/// captures, on the app's own background.
class _QrCard extends StatelessWidget {
  const _QrCard({required this.title, required this.meta, required this.url});

  final String title;
  final String meta;
  final String url;

  @override
  Widget build(BuildContext context) {
    // Solid so the saved PNG reads on any gallery background.
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.hairlineSoft),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.qr_eyebrow.toUpperCase(),
            style: AppTypography.mono.copyWith(color: AppColors.primaryLight),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.serif(
              fontSize: 30,
              height: 1.15,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            meta.toUpperCase(),
            textAlign: TextAlign.center,
            style: AppTypography.mono.copyWith(fontSize: 10),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.textPrimary,
              borderRadius: BorderRadius.circular(28),
            ),
            child: ShareQrCode(url: url, size: 230),
          ),
          const SizedBox(height: AppSpacing.base),
          Text(
            url.replaceFirst('https://', ''),
            style: AppTypography.mono.copyWith(
              fontSize: 12,
              letterSpacing: 0,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
