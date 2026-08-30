// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bonus_tray_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BonusTrayController)
final bonusTrayControllerProvider = BonusTrayControllerFamily._();

final class BonusTrayControllerProvider
    extends $AsyncNotifierProvider<BonusTrayController, BonusTrayState> {
  BonusTrayControllerProvider._({
    required BonusTrayControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'bonusTrayControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$bonusTrayControllerHash();

  @override
  String toString() {
    return r'bonusTrayControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  BonusTrayController create() => BonusTrayController();

  @override
  bool operator ==(Object other) {
    return other is BonusTrayControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$bonusTrayControllerHash() =>
    r'872aaeb37d66efd2b79571fe99152bfb7c1d73d8';

final class BonusTrayControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          BonusTrayController,
          AsyncValue<BonusTrayState>,
          BonusTrayState,
          FutureOr<BonusTrayState>,
          String
        > {
  BonusTrayControllerFamily._()
    : super(
        retry: null,
        name: r'bonusTrayControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BonusTrayControllerProvider call(String tripId) =>
      BonusTrayControllerProvider._(argument: tripId, from: this);

  @override
  String toString() => r'bonusTrayControllerProvider';
}

abstract class _$BonusTrayController extends $AsyncNotifier<BonusTrayState> {
  late final _$args = ref.$arg as String;
  String get tripId => _$args;

  FutureOr<BonusTrayState> build(String tripId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<BonusTrayState>, BonusTrayState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<BonusTrayState>, BonusTrayState>,
              AsyncValue<BonusTrayState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
