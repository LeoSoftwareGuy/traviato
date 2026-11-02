import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// The link row (#311, 1a): `storyni.app/m/` + the slug in primary light,
/// and Copy, which reads "Copied ✓" for 1.6s. [slug] null = the link is
/// still being made — a shimmering bar and no Copy.
class ShareLinkField extends StatefulWidget {
  const ShareLinkField({required this.slug, required this.onCopy, super.key});

  final String? slug;
  final VoidCallback onCopy;

  static const copiedFor = Duration(milliseconds: 1600);

  @override
  State<ShareLinkField> createState() => _ShareLinkFieldState();
}

class _ShareLinkFieldState extends State<ShareLinkField> {
  Timer? _copiedTimer;

  bool get _isCopied => _copiedTimer?.isActive ?? false;

  void _copy() {
    widget.onCopy();
    setState(() {
      _copiedTimer?.cancel();
      _copiedTimer = Timer(ShareLinkField.copiedFor, () {
        if (mounted) setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _copiedTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slug = widget.slug;
    final text = AppTypography.mono.copyWith(
      fontSize: 12.5,
      letterSpacing: 0,
      color: AppColors.textPrimary,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: slug == null
                ? const _Shimmer()
                : Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: '${AppConstants.shareHost}/m/'),
                        TextSpan(
                          text: slug,
                          style: const TextStyle(color: AppColors.primaryLight),
                        ),
                      ],
                    ),
                    style: text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
          const SizedBox(width: 8),
          _CopyButton(
            isCopied: _isCopied,
            onPressed: slug == null ? null : _copy,
          ),
        ],
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.isCopied, required this.onPressed});

  final bool isCopied;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 76, minHeight: 36),
      child: TextButton(
        key: const ValueKey('share-copy'),
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: isCopied
              ? AppColors.tint(AppColors.primary, .18)
              : AppColors.primary,
          foregroundColor: isCopied ? AppColors.primary : AppColors.background,
          disabledBackgroundColor: AppColors.surfaceDisabled,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: AppTypography.buttonLabel.copyWith(fontSize: 13),
        ),
        child: Text(isCopied ? l10n.share_copied : l10n.share_copy),
      ),
    );
  }
}

/// A soft pulsing bar where the URL will be.
class _Shimmer extends StatefulWidget {
  const _Shimmer();

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      key: const ValueKey('share-link-shimmer'),
      opacity: Tween<double>(begin: .35, end: .8).animate(_controller),
      child: Container(
        height: 14,
        margin: const EdgeInsets.only(right: 40),
        decoration: BoxDecoration(
          color: AppColors.surfaceBorder,
          borderRadius: BorderRadius.circular(7),
        ),
      ),
    );
  }
}
