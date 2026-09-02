import 'dart:typed_data';

import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/presentation_failure_exception.dart';
import '../../domain/entities/profile_entity.dart';
import '../controllers/profile_controller.dart';
import '../providers/profile_providers.dart';

final updateProfileMutation = Mutation<ProfileEntity>();
final uploadAvatarMutation = Mutation<ProfileEntity>();

/// The edit sheet's username/bio save — pass only the field being changed.
Future<ProfileEntity> runUpdateProfile({
  required WidgetRef ref,
  String? username,
  String? bio,
}) {
  return updateProfileMutation.run(ref, (tsx) async {
    final repo = tsx.get(profileRepositoryProvider);
    final result = await repo.updateProfile(username: username, bio: bio);
    return result.fold(
      (failure) => throw PresentationFailureException(failure),
      (
        profile,
      ) {
        tsx
            .get(profileControllerProvider.notifier)
            .applyProfileUpdated(profile);
        return profile;
      },
    );
  });
}

/// Uploads the picked/compressed avatar, then persists its storage path —
/// mirrors the trip cover's upload-then-updateTrip two-step (issue #96).
Future<ProfileEntity> runUploadAvatar({
  required WidgetRef ref,
  required Uint8List bytes,
}) {
  return uploadAvatarMutation.run(ref, (tsx) async {
    final repo = tsx.get(profileRepositoryProvider);

    final uploaded = await repo.uploadAvatar(bytes);
    final path = uploaded.fold(
      (failure) => throw PresentationFailureException(failure),
      (p) => p,
    );

    final result = await repo.updateProfile(avatarUrl: path);
    return result.fold(
      (failure) => throw PresentationFailureException(failure),
      (
        profile,
      ) {
        tsx
            .get(profileControllerProvider.notifier)
            .applyProfileUpdated(profile);
        return profile;
      },
    );
  });
}
