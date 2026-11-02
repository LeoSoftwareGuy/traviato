// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_share_slug_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The shared memory someone arrived from and hasn't seen signed in yet
/// (#310's deferred deep link). The router sends them to `/m/{slug}` once
/// the splash, sign-up or log-in is done; the preview page clears it once
/// shown signed in. Persisted, so it survives the install → first launch
/// gap and an app restart mid sign-up.

@ProviderFor(PendingShareSlugController)
final pendingShareSlugControllerProvider =
    PendingShareSlugControllerProvider._();

/// The shared memory someone arrived from and hasn't seen signed in yet
/// (#310's deferred deep link). The router sends them to `/m/{slug}` once
/// the splash, sign-up or log-in is done; the preview page clears it once
/// shown signed in. Persisted, so it survives the install → first launch
/// gap and an app restart mid sign-up.
final class PendingShareSlugControllerProvider
    extends $NotifierProvider<PendingShareSlugController, String?> {
  /// The shared memory someone arrived from and hasn't seen signed in yet
  /// (#310's deferred deep link). The router sends them to `/m/{slug}` once
  /// the splash, sign-up or log-in is done; the preview page clears it once
  /// shown signed in. Persisted, so it survives the install → first launch
  /// gap and an app restart mid sign-up.
  PendingShareSlugControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingShareSlugControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingShareSlugControllerHash();

  @$internal
  @override
  PendingShareSlugController create() => PendingShareSlugController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$pendingShareSlugControllerHash() =>
    r'ef2dc5edeaeb5a2f7e2cbfcf3d8a2ac0bc9cc325';

/// The shared memory someone arrived from and hasn't seen signed in yet
/// (#310's deferred deep link). The router sends them to `/m/{slug}` once
/// the splash, sign-up or log-in is done; the preview page clears it once
/// shown signed in. Persisted, so it survives the install → first launch
/// gap and an app restart mid sign-up.

abstract class _$PendingShareSlugController extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
