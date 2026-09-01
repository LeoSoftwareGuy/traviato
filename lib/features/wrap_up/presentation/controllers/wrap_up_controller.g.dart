// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wrap_up_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(WrapUpController)
final wrapUpControllerProvider = WrapUpControllerFamily._();

final class WrapUpControllerProvider
    extends $AsyncNotifierProvider<WrapUpController, WrapUpState> {
  WrapUpControllerProvider._({
    required WrapUpControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'wrapUpControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$wrapUpControllerHash();

  @override
  String toString() {
    return r'wrapUpControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  WrapUpController create() => WrapUpController();

  @override
  bool operator ==(Object other) {
    return other is WrapUpControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$wrapUpControllerHash() => r'54d489289496a8d682f6e1601af70f9ffe88403e';

final class WrapUpControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          WrapUpController,
          AsyncValue<WrapUpState>,
          WrapUpState,
          FutureOr<WrapUpState>,
          String
        > {
  WrapUpControllerFamily._()
    : super(
        retry: null,
        name: r'wrapUpControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WrapUpControllerProvider call(String tripId) =>
      WrapUpControllerProvider._(argument: tripId, from: this);

  @override
  String toString() => r'wrapUpControllerProvider';
}

abstract class _$WrapUpController extends $AsyncNotifier<WrapUpState> {
  late final _$args = ref.$arg as String;
  String get tripId => _$args;

  FutureOr<WrapUpState> build(String tripId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<WrapUpState>, WrapUpState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<WrapUpState>, WrapUpState>,
              AsyncValue<WrapUpState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
