// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share_sheet_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Opening the sheet makes (or reuses) the memory's link. A link whose
/// public preview isn't built yet starts the background build (#309) —
/// nothing waits on it.

@ProviderFor(ShareSheetController)
final shareSheetControllerProvider = ShareSheetControllerFamily._();

/// Opening the sheet makes (or reuses) the memory's link. A link whose
/// public preview isn't built yet starts the background build (#309) —
/// nothing waits on it.
final class ShareSheetControllerProvider
    extends $AsyncNotifierProvider<ShareSheetController, ShareSheetState> {
  /// Opening the sheet makes (or reuses) the memory's link. A link whose
  /// public preview isn't built yet starts the background build (#309) —
  /// nothing waits on it.
  ShareSheetControllerProvider._({
    required ShareSheetControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'shareSheetControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$shareSheetControllerHash();

  @override
  String toString() {
    return r'shareSheetControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ShareSheetController create() => ShareSheetController();

  @override
  bool operator ==(Object other) {
    return other is ShareSheetControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$shareSheetControllerHash() =>
    r'775cc7831faf1de76135c56ff495cff03fa5be6c';

/// Opening the sheet makes (or reuses) the memory's link. A link whose
/// public preview isn't built yet starts the background build (#309) —
/// nothing waits on it.

final class ShareSheetControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ShareSheetController,
          AsyncValue<ShareSheetState>,
          ShareSheetState,
          FutureOr<ShareSheetState>,
          String
        > {
  ShareSheetControllerFamily._()
    : super(
        retry: null,
        name: r'shareSheetControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Opening the sheet makes (or reuses) the memory's link. A link whose
  /// public preview isn't built yet starts the background build (#309) —
  /// nothing waits on it.

  ShareSheetControllerProvider call(String tripId) =>
      ShareSheetControllerProvider._(argument: tripId, from: this);

  @override
  String toString() => r'shareSheetControllerProvider';
}

/// Opening the sheet makes (or reuses) the memory's link. A link whose
/// public preview isn't built yet starts the background build (#309) —
/// nothing waits on it.

abstract class _$ShareSheetController extends $AsyncNotifier<ShareSheetState> {
  late final _$args = ref.$arg as String;
  String get tripId => _$args;

  FutureOr<ShareSheetState> build(String tripId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ShareSheetState>, ShareSheetState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ShareSheetState>, ShareSheetState>,
              AsyncValue<ShareSheetState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
