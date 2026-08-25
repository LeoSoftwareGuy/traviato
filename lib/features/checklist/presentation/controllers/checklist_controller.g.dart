// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checklist_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ChecklistController)
final checklistControllerProvider = ChecklistControllerFamily._();

final class ChecklistControllerProvider
    extends $AsyncNotifierProvider<ChecklistController, ChecklistState> {
  ChecklistControllerProvider._({
    required ChecklistControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'checklistControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$checklistControllerHash();

  @override
  String toString() {
    return r'checklistControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ChecklistController create() => ChecklistController();

  @override
  bool operator ==(Object other) {
    return other is ChecklistControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$checklistControllerHash() =>
    r'536b7ae939b13838031d1b467e9e53f755797996';

final class ChecklistControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ChecklistController,
          AsyncValue<ChecklistState>,
          ChecklistState,
          FutureOr<ChecklistState>,
          String
        > {
  ChecklistControllerFamily._()
    : super(
        retry: null,
        name: r'checklistControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ChecklistControllerProvider call(String tripId) =>
      ChecklistControllerProvider._(argument: tripId, from: this);

  @override
  String toString() => r'checklistControllerProvider';
}

abstract class _$ChecklistController extends $AsyncNotifier<ChecklistState> {
  late final _$args = ref.$arg as String;
  String get tripId => _$args;

  FutureOr<ChecklistState> build(String tripId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ChecklistState>, ChecklistState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ChecklistState>, ChecklistState>,
              AsyncValue<ChecklistState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
