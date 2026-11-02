// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share_link_intake_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Where shared-memory links come into the app (#310):
/// - universal / app links (`https://storyni.app/m/{slug}`) and the web
///   page's `com.leo.storyni://m/{slug}` fallback, through `app_links`
///   (Flutter deep linking is off — supabase_flutter owns auth links);
/// - on Android's first launch, the Play install referrer the web page's
///   store button set.
/// Each one becomes the pending slug and opens `/m/{slug}`; the router's
/// redirect holds it through the splash and sign-up. `keepAlive`,
/// instantiated from `main.dart`.

@ProviderFor(ShareLinkIntakeController)
final shareLinkIntakeControllerProvider = ShareLinkIntakeControllerProvider._();

/// Where shared-memory links come into the app (#310):
/// - universal / app links (`https://storyni.app/m/{slug}`) and the web
///   page's `com.leo.storyni://m/{slug}` fallback, through `app_links`
///   (Flutter deep linking is off — supabase_flutter owns auth links);
/// - on Android's first launch, the Play install referrer the web page's
///   store button set.
/// Each one becomes the pending slug and opens `/m/{slug}`; the router's
/// redirect holds it through the splash and sign-up. `keepAlive`,
/// instantiated from `main.dart`.
final class ShareLinkIntakeControllerProvider
    extends $NotifierProvider<ShareLinkIntakeController, void> {
  /// Where shared-memory links come into the app (#310):
  /// - universal / app links (`https://storyni.app/m/{slug}`) and the web
  ///   page's `com.leo.storyni://m/{slug}` fallback, through `app_links`
  ///   (Flutter deep linking is off — supabase_flutter owns auth links);
  /// - on Android's first launch, the Play install referrer the web page's
  ///   store button set.
  /// Each one becomes the pending slug and opens `/m/{slug}`; the router's
  /// redirect holds it through the splash and sign-up. `keepAlive`,
  /// instantiated from `main.dart`.
  ShareLinkIntakeControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shareLinkIntakeControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shareLinkIntakeControllerHash();

  @$internal
  @override
  ShareLinkIntakeController create() => ShareLinkIntakeController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$shareLinkIntakeControllerHash() =>
    r'34d6b8c8952da0b1bba682f074129eac1dcac868';

/// Where shared-memory links come into the app (#310):
/// - universal / app links (`https://storyni.app/m/{slug}`) and the web
///   page's `com.leo.storyni://m/{slug}` fallback, through `app_links`
///   (Flutter deep linking is off — supabase_flutter owns auth links);
/// - on Android's first launch, the Play install referrer the web page's
///   store button set.
/// Each one becomes the pending slug and opens `/m/{slug}`; the router's
/// redirect holds it through the splash and sign-up. `keepAlive`,
/// instantiated from `main.dart`.

abstract class _$ShareLinkIntakeController extends $Notifier<void> {
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
