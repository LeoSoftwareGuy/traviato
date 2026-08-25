// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_list_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ExpenseListController)
final expenseListControllerProvider = ExpenseListControllerProvider._();

final class ExpenseListControllerProvider
    extends $AsyncNotifierProvider<ExpenseListController, ExpenseListState> {
  ExpenseListControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'expenseListControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$expenseListControllerHash();

  @$internal
  @override
  ExpenseListController create() => ExpenseListController();
}

String _$expenseListControllerHash() =>
    r'7f7f4d5a8c26e379a87cf75613946a01c554262e';

abstract class _$ExpenseListController
    extends $AsyncNotifier<ExpenseListState> {
  FutureOr<ExpenseListState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ExpenseListState>, ExpenseListState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ExpenseListState>, ExpenseListState>,
              AsyncValue<ExpenseListState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
