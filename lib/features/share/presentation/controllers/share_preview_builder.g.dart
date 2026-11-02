// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share_preview_builder.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Builds share links' public preview images in the background (#309) —
/// nothing waits on it; the web page shows a title-only teaser until it's
/// done. Runs when the share sheet opens on a link that isn't built, and a
/// minute after the memory's photos, film picks, name or cover change while
/// it has an active link. `keepAlive` and instantiated from `main.dart`, so
/// a build outlives the sheet that started it.

@ProviderFor(SharePreviewBuilder)
final sharePreviewBuilderProvider = SharePreviewBuilderProvider._();

/// Builds share links' public preview images in the background (#309) —
/// nothing waits on it; the web page shows a title-only teaser until it's
/// done. Runs when the share sheet opens on a link that isn't built, and a
/// minute after the memory's photos, film picks, name or cover change while
/// it has an active link. `keepAlive` and instantiated from `main.dart`, so
/// a build outlives the sheet that started it.
final class SharePreviewBuilderProvider
    extends $NotifierProvider<SharePreviewBuilder, void> {
  /// Builds share links' public preview images in the background (#309) —
  /// nothing waits on it; the web page shows a title-only teaser until it's
  /// done. Runs when the share sheet opens on a link that isn't built, and a
  /// minute after the memory's photos, film picks, name or cover change while
  /// it has an active link. `keepAlive` and instantiated from `main.dart`, so
  /// a build outlives the sheet that started it.
  SharePreviewBuilderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharePreviewBuilderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharePreviewBuilderHash();

  @$internal
  @override
  SharePreviewBuilder create() => SharePreviewBuilder();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$sharePreviewBuilderHash() =>
    r'3f6ac04ff79143cf7b4beb01b40e77999a1f2ee0';

/// Builds share links' public preview images in the background (#309) —
/// nothing waits on it; the web page shows a title-only teaser until it's
/// done. Runs when the share sheet opens on a link that isn't built, and a
/// minute after the memory's photos, film picks, name or cover change while
/// it has an active link. `keepAlive` and instantiated from `main.dart`, so
/// a build outlives the sheet that started it.

abstract class _$SharePreviewBuilder extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
