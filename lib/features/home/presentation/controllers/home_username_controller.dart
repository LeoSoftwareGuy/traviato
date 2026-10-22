import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/events/global_event.dart';
import '../../../../core/events/global_event_bus.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

part 'home_username_controller.g.dart';

/// The name Home greets with (#266): `profiles.username`, the same field
/// the Profile screen edits. The auth user's metadata name only exists for
/// email sign-ups and never changes after, so it's just the fallback when
/// the profile can't be read. Null means no name: Home says "Hello!".
@riverpod
class HomeUsernameController extends _$HomeUsernameController {
  @override
  Future<String?> build() async {
    final sub = ref.watch(globalEventBusProvider).stream.listen(_onEvent);
    ref.onDispose(sub.cancel);

    final metadataName = ref.watch(authControllerProvider).user?.username;
    final result = await ref.watch(profileRepositoryProvider).getProfile();
    return result.fold(
      (failure) {
        debugPrint('home username: profile read failed: ${failure.message}');
        return _nonBlank(metadataName);
      },
      (profile) => _nonBlank(profile.username),
    );
  }

  void _onEvent(GlobalEvent event) {
    switch (event) {
      case ProfileUpdatedDispatched(:final profile):
        state = AsyncData(_nonBlank(profile.username));
      case TripCreatedDispatched():
      case TripDeletedDispatched():
      case TripUpdatedDispatched():
      case StarsAwardedDispatched():
      case WrapUpPublishedDispatched():
      case EntitlementUpdatedDispatched():
      // Not relevant to the greeting.
    }
  }
}

String? _nonBlank(String? name) {
  final trimmed = name?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}
