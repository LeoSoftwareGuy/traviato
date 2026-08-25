// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_compare_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ExpenseCompareController)
final expenseCompareControllerProvider = ExpenseCompareControllerProvider._();

final class ExpenseCompareControllerProvider
    extends
        $AsyncNotifierProvider<ExpenseCompareController, ExpenseCompareState> {
  ExpenseCompareControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'expenseCompareControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$expenseCompareControllerHash();

  @$internal
  @override
  ExpenseCompareController create() => ExpenseCompareController();
}

String _$expenseCompareControllerHash() =>
    r'f31928c059d3a77a40f13a1d8279384673d38722';

abstract class _$ExpenseCompareController
    extends $AsyncNotifier<ExpenseCompareState> {
  FutureOr<ExpenseCompareState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ExpenseCompareState>, ExpenseCompareState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ExpenseCompareState>, ExpenseCompareState>,
              AsyncValue<ExpenseCompareState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
