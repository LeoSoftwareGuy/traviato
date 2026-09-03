import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/profile_entity.dart';
import 'profile_avatar.dart';

final _joinedFormat = DateFormat('MMMM yyyy');

/// Centred avatar + stars pill, name/@handle, bio, joined date, and the Edit
/// entry point (`docs/design/README.md` § 11). `username` is the app's only
/// identity field — rendered once plain as the name, once `@`-prefixed as
/// the handle (issue #96's plan comment; the mockup's separate name/handle
/// fields don't exist in the schema).
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    required this.profile,
    required this.stars,
    required this.onEdit,
    super.key,
  });

  final ProfileEntity profile;
  final int stars;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final username = profile.username;
    final hasUsername = username != null && username.isNotEmpty;
    final bio = profile.bio;

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onEdit,
            child: const Text('Edit'),
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            ProfileAvatar(avatarUrl: profile.avatarUrl, username: username),
            Positioned(
              right: -8,
              bottom: -6,
              child: _StarsPill(stars: stars),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          hasUsername ? username : 'Traveler',
          style: AppTypography.screenTitle.copyWith(fontSize: 25),
        ),
        if (hasUsername) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            '@$username',
            style: AppTypography.mono.copyWith(color: AppColors.primary),
          ),
        ],
        if (bio != null && bio.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 270),
            child: Text(
              bio,
              textAlign: TextAlign.center,
              style: AppTypography.chipLabel,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Text(
          'JOINED ${_joinedFormat.format(profile.createdAt).toUpperCase()}',
          style: AppTypography.mono,
        ),
      ],
    );
  }
}

class _StarsPill extends StatelessWidget {
  const _StarsPill({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppRadius.pillRadius,
      ),
      child: Text(
        '✦ $stars',
        style: AppTypography.caption.copyWith(
          color: AppColors.background,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
