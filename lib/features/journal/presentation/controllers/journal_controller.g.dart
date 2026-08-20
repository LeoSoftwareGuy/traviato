// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journal_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(JournalController)
final journalControllerProvider = JournalControllerFamily._();

final class JournalControllerProvider
    extends $AsyncNotifierProvider<JournalController, JournalState> {
  JournalControllerProvider._({
    required JournalControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'journalControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$journalControllerHash();

  @override
  String toString() {
    return r'journalControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  JournalController create() => JournalController();

  @override
  bool operator ==(Object other) {
    return other is JournalControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$journalControllerHash() => r'f202c6a847e50508cb87fe3a8ca10081ee00c3a2';

final class JournalControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          JournalController,
          AsyncValue<JournalState>,
          JournalState,
          FutureOr<JournalState>,
          String
        > {
  JournalControllerFamily._()
    : super(
        retry: null,
        name: r'journalControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  JournalControllerProvider call(String tripId) =>
      JournalControllerProvider._(argument: tripId, from: this);

  @override
  String toString() => r'journalControllerProvider';
}

abstract class _$JournalController extends $AsyncNotifier<JournalState> {
  late final _$args = ref.$arg as String;
  String get tripId => _$args;

  FutureOr<JournalState> build(String tripId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<JournalState>, JournalState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<JournalState>, JournalState>,
              AsyncValue<JournalState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
