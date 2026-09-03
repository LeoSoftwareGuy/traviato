import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/bottom_sheet_chrome.dart';
import '../../../../core/widgets/show_error_snackbar.dart';
import '../../../trip/presentation/widgets/create_memory_field.dart';
import '../controllers/profile_controller.dart';
import '../mutations/profile_mutations.dart';
import 'avatar_upload_tile.dart';

/// Username + bio + avatar (`docs/design/README.md` § 11's "Edit" entry
/// point). No editing UI beyond these three fields — matches the sheet's
/// scope in issue #96.
class ProfileEditSheet extends ConsumerStatefulWidget {
  const ProfileEditSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showAppBottomSheet<void>(
      context: context,
      builder: (context) => const ProfileEditSheet(),
    );
  }

  @override
  ConsumerState<ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends ConsumerState<ProfileEditSheet> {
  late final TextEditingController _username;
  late final TextEditingController _bio;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileControllerProvider).value?.profile;
    _username = TextEditingController(text: profile?.username ?? '');
    _bio = TextEditingController(text: profile?.bio ?? '');
  }

  @override
  void dispose() {
    _username.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _saveUsername() async {
    final value = _username.text.trim();
    if (value.isEmpty) return;
    try {
      await runUpdateProfile(ref: ref, username: value);
    } catch (_) {
      // Surfaced via the mutation error listener below.
    }
  }

  Future<void> _saveBio() async {
    try {
      await runUpdateProfile(ref: ref, bio: _bio.text.trim());
    } catch (_) {
      // Surfaced via the mutation error listener below.
    }
  }

  Future<void> _uploadAvatar(Uint8List bytes) async {
    try {
      await runUploadAvatar(ref: ref, bytes: bytes);
    } catch (_) {
      // Surfaced via the mutation error listener below.
    }
  }

  @override
  Widget build(BuildContext context) {
    for (final mutation in [updateProfileMutation, uploadAvatarMutation]) {
      ref.listen<MutationState<dynamic>>(mutation, (previous, next) {
        if (next is MutationError) {
          showErrorSnackbar(
            context,
            message: presentationFailureMessage(next.error),
          );
        }
      });
    }

    final profile = ref.watch(profileControllerProvider).value?.profile;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Edit your profile',
                  style: AppTypography.screenTitle.copyWith(fontSize: 21),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: AvatarUploadTile(
              avatarUrl: profile?.avatarUrl,
              username: profile?.username,
              onPicked: _uploadAvatar,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          CreateMemoryField(
            label: 'Name',
            controller: _username,
            trailing: TextButton(
              onPressed: _saveUsername,
              child: const Text('Save'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          CreateMemoryField(
            label: 'Bio',
            controller: _bio,
            maxLines: 3,
            hintText: 'A line about your travels',
            trailing: TextButton(
              onPressed: _saveBio,
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
