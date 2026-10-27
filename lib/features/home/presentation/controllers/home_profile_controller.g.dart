// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_profile_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The name Home greets with (#266) and the avatar beside it (#283) —
/// `profiles.username` and `profiles.avatar_url`, the fields the Profile
/// screen edits. The auth user's metadata name only exists for email
/// sign-ups and never changes after, so it's just the fallback name when
/// the profile can't be read (with no avatar).

@ProviderFor(HomeProfileController)
final homeProfileControllerProvider = HomeProfileControllerProvider._();

/// The name Home greets with (#266) and the avatar beside it (#283) —
/// `profiles.username` and `profiles.avatar_url`, the fields the Profile
/// screen edits. The auth user's metadata name only exists for email
/// sign-ups and never changes after, so it's just the fallback name when
/// the profile can't be read (with no avatar).
final class HomeProfileControllerProvider
    extends $AsyncNotifierProvider<HomeProfileController, HomeHeaderProfile> {
  /// The name Home greets with (#266) and the avatar beside it (#283) —
  /// `profiles.username` and `profiles.avatar_url`, the fields the Profile
  /// screen edits. The auth user's metadata name only exists for email
  /// sign-ups and never changes after, so it's just the fallback name when
  /// the profile can't be read (with no avatar).
  HomeProfileControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeProfileControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeProfileControllerHash();

  @$internal
  @override
  HomeProfileController create() => HomeProfileController();
}

String _$homeProfileControllerHash() =>
    r'1be8bbfc0b9a9bc50a07779dc7d6b4aa26513382';

/// The name Home greets with (#266) and the avatar beside it (#283) —
/// `profiles.username` and `profiles.avatar_url`, the fields the Profile
/// screen edits. The auth user's metadata name only exists for email
/// sign-ups and never changes after, so it's just the fallback name when
/// the profile can't be read (with no avatar).

abstract class _$HomeProfileController
    extends $AsyncNotifier<HomeHeaderProfile> {
  FutureOr<HomeHeaderProfile> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<HomeHeaderProfile>, HomeHeaderProfile>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<HomeHeaderProfile>, HomeHeaderProfile>,
              AsyncValue<HomeHeaderProfile>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
