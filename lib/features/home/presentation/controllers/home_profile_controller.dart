import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/events/global_event.dart';
import '../../../../core/events/global_event_bus.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../profile/domain/entities/profile_entity.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import 'home_header_profile.dart';

part 'home_profile_controller.g.dart';

/// The name Home greets with (#266) and the avatar beside it (#283) —
/// `profiles.username` and `profiles.avatar_url`, the fields the Profile
/// screen edits. The auth user's metadata name only exists for email
/// sign-ups and never changes after, so it's just the fallback name when
/// the profile can't be read (with no avatar).
@riverpod
class HomeProfileController extends _$HomeProfileController {
  @override
  Future<HomeHeaderProfile> build() async {
    final sub = ref.watch(globalEventBusProvider).stream.listen(_onEvent);
    ref.onDispose(sub.cancel);

    final metadataName = ref.watch(authControllerProvider).user?.username;
    final result = await ref.watch(profileRepositoryProvider).getProfile();
    return result.fold((failure) {
      debugPrint('home profile: profile read failed: ${failure.message}');
      return HomeHeaderProfile(username: _nonBlank(metadataName));
    }, _fromProfile);
  }

  void _onEvent(GlobalEvent event) {
    switch (event) {
      // Fired by both a profile edit and an avatar upload.
      case ProfileUpdatedDispatched(:final profile):
        state = AsyncData(_fromProfile(profile));
      case TripCreatedDispatched():
      case TripDeletedDispatched():
      case TripUpdatedDispatched():
      case StarsAwardedDispatched():
      case WrapUpPublishedDispatched():
      case EntitlementUpdatedDispatched():
      // Not relevant to the header.
    }
  }
}

HomeHeaderProfile _fromProfile(ProfileEntity profile) => HomeHeaderProfile(
  username: _nonBlank(profile.username),
  avatarUrl: _nonBlank(profile.avatarUrl),
);

String? _nonBlank(String? value) {
  final trimmed = value?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}
