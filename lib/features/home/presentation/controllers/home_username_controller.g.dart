// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_username_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The name Home greets with (#266): `profiles.username`, the same field
/// the Profile screen edits. The auth user's metadata name only exists for
/// email sign-ups and never changes after, so it's just the fallback when
/// the profile can't be read. Null means no name: Home says "Hello!".

@ProviderFor(HomeUsernameController)
final homeUsernameControllerProvider = HomeUsernameControllerProvider._();

/// The name Home greets with (#266): `profiles.username`, the same field
/// the Profile screen edits. The auth user's metadata name only exists for
/// email sign-ups and never changes after, so it's just the fallback when
/// the profile can't be read. Null means no name: Home says "Hello!".
final class HomeUsernameControllerProvider
    extends $AsyncNotifierProvider<HomeUsernameController, String?> {
  /// The name Home greets with (#266): `profiles.username`, the same field
  /// the Profile screen edits. The auth user's metadata name only exists for
  /// email sign-ups and never changes after, so it's just the fallback when
  /// the profile can't be read. Null means no name: Home says "Hello!".
  HomeUsernameControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeUsernameControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeUsernameControllerHash();

  @$internal
  @override
  HomeUsernameController create() => HomeUsernameController();
}

String _$homeUsernameControllerHash() =>
    r'f4e3aa98a810d2dd3992927e7da29fa272dd4ee4';

/// The name Home greets with (#266): `profiles.username`, the same field
/// the Profile screen edits. The auth user's metadata name only exists for
/// email sign-ups and never changes after, so it's just the fallback when
/// the profile can't be read. Null means no name: Home says "Hello!".

abstract class _$HomeUsernameController extends $AsyncNotifier<String?> {
  FutureOr<String?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<String?>, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<String?>, String?>,
              AsyncValue<String?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
