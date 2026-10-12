// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_link_failure_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The latest email confirmation link that failed to sign the user in
/// (#157), or `null` once it has been shown. `keepAlive` and watched from
/// the app root so a failure on a cold start — handled by supabase_flutter
/// before the first frame — is still there when the UI can show it.

@ProviderFor(AuthLinkFailureController)
final authLinkFailureControllerProvider = AuthLinkFailureControllerProvider._();

/// The latest email confirmation link that failed to sign the user in
/// (#157), or `null` once it has been shown. `keepAlive` and watched from
/// the app root so a failure on a cold start — handled by supabase_flutter
/// before the first frame — is still there when the UI can show it.
final class AuthLinkFailureControllerProvider
    extends $NotifierProvider<AuthLinkFailureController, AuthLinkFailure?> {
  /// The latest email confirmation link that failed to sign the user in
  /// (#157), or `null` once it has been shown. `keepAlive` and watched from
  /// the app root so a failure on a cold start — handled by supabase_flutter
  /// before the first frame — is still there when the UI can show it.
  AuthLinkFailureControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authLinkFailureControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authLinkFailureControllerHash();

  @$internal
  @override
  AuthLinkFailureController create() => AuthLinkFailureController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthLinkFailure? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthLinkFailure?>(value),
    );
  }
}

String _$authLinkFailureControllerHash() =>
    r'f6b81c6060ac13a05eb7de3257f72d84814abe70';

/// The latest email confirmation link that failed to sign the user in
/// (#157), or `null` once it has been shown. `keepAlive` and watched from
/// the app root so a failure on a cold start — handled by supabase_flutter
/// before the first frame — is still there when the UI can show it.

abstract class _$AuthLinkFailureController extends $Notifier<AuthLinkFailure?> {
  AuthLinkFailure? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AuthLinkFailure?, AuthLinkFailure?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AuthLinkFailure?, AuthLinkFailure?>,
              AuthLinkFailure?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
