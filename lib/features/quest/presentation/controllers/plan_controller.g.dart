// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PlanController)
final planControllerProvider = PlanControllerFamily._();

final class PlanControllerProvider
    extends $AsyncNotifierProvider<PlanController, PlanState> {
  PlanControllerProvider._({
    required PlanControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'planControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$planControllerHash();

  @override
  String toString() {
    return r'planControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PlanController create() => PlanController();

  @override
  bool operator ==(Object other) {
    return other is PlanControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$planControllerHash() => r'7434dc72e543b49b4bce2958d5f552709e39df2d';

final class PlanControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          PlanController,
          AsyncValue<PlanState>,
          PlanState,
          FutureOr<PlanState>,
          String
        > {
  PlanControllerFamily._()
    : super(
        retry: null,
        name: r'planControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PlanControllerProvider call(String tripId) =>
      PlanControllerProvider._(argument: tripId, from: this);

  @override
  String toString() => r'planControllerProvider';
}

abstract class _$PlanController extends $AsyncNotifier<PlanState> {
  late final _$args = ref.$arg as String;
  String get tripId => _$args;

  FutureOr<PlanState> build(String tripId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<PlanState>, PlanState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PlanState>, PlanState>,
              AsyncValue<PlanState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
