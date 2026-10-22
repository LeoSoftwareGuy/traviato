import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/profile_providers.dart';

/// The profile avatar — either an external OAuth picture URL, this app's
/// own `avatars`-bucket upload (signed for display, a private bucket), or
/// initials over a plain fill when neither is set. `docs/design/README.md`
/// § 11. Also Home's header avatar (#283), smaller and with Home's own ring
/// and initial styling.
class ProfileAvatar extends ConsumerWidget {
  const ProfileAvatar({
    required this.avatarUrl,
    required this.username,
    this.size = 86,
    this.borderWidth = 2,
    this.borderColor,
    this.initialsStyle,
    super.key,
  });

  final String? avatarUrl;
  final String? username;
  final double size;
  final double borderWidth;

  /// Defaults to primary at 55%.
  final Color? borderColor;

  /// Defaults to the Profile screen's big primary serif initial.
  final TextStyle? initialsStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
        border: Border.all(
          color: borderColor ?? AppColors.tint(AppColors.primary, .55),
          width: borderWidth,
        ),
      ),
      child: _image(ref),
    );
  }

  Widget _image(WidgetRef ref) {
    final url = avatarUrl;
    if (url == null || url.isEmpty) {
      return _Initials(username: username, style: initialsStyle);
    }

    // An OAuth provider's picture is already a full external URL — the
    // avatars bucket is private, so anything else is our own storage path
    // and needs signing (issue #96's plan comment).
    if (url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (context, url) => const ColoredBox(
          color: AppColors.surface,
        ),
        errorWidget: (context, url, error) =>
            _Initials(username: username, style: initialsStyle),
      );
    }

    final signedUrl = ref.watch(avatarImageUrlProvider(url));
    return signedUrl.when(
      loading: () => const ColoredBox(color: AppColors.surface),
      error: (_, _) => _Initials(username: username, style: initialsStyle),
      data: (resolvedUrl) => CachedNetworkImage(
        imageUrl: resolvedUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => const ColoredBox(
          color: AppColors.surface,
        ),
        errorWidget: (context, url, error) =>
            _Initials(username: username, style: initialsStyle),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.username, this.style});

  final String? username;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final name = username;
    final initial = (name == null || name.isEmpty)
        ? '?'
        : name[0].toUpperCase();
    return ColoredBox(
      color: AppColors.surface,
      child: Center(
        child: Text(
          initial,
          style:
              style ??
              AppTypography.bigNumber.copyWith(color: AppColors.primary),
        ),
      ),
    );
  }
}
