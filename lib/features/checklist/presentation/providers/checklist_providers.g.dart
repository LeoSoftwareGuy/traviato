// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checklist_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(checklistRemoteDataSource)
final checklistRemoteDataSourceProvider = ChecklistRemoteDataSourceProvider._();

final class ChecklistRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          ChecklistRemoteDataSource,
          ChecklistRemoteDataSource,
          ChecklistRemoteDataSource
        >
    with $Provider<ChecklistRemoteDataSource> {
  ChecklistRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'checklistRemoteDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$checklistRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<ChecklistRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ChecklistRemoteDataSource create(Ref ref) {
    return checklistRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChecklistRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChecklistRemoteDataSource>(value),
    );
  }
}

String _$checklistRemoteDataSourceHash() =>
    r'b17c14c4180e708cfb09d1db96b59cec95e338f3';

@ProviderFor(checklistRepository)
final checklistRepositoryProvider = ChecklistRepositoryProvider._();

final class ChecklistRepositoryProvider
    extends
        $FunctionalProvider<
          ChecklistRepository,
          ChecklistRepository,
          ChecklistRepository
        >
    with $Provider<ChecklistRepository> {
  ChecklistRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'checklistRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$checklistRepositoryHash();

  @$internal
  @override
  $ProviderElement<ChecklistRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ChecklistRepository create(Ref ref) {
    return checklistRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChecklistRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChecklistRepository>(value),
    );
  }
}

String _$checklistRepositoryHash() =>
    r'99f967ec0f686abd9579d6cf0c3da9070cd3de5a';

@ProviderFor(ChecklistProgressForTrip)
final checklistProgressForTripProvider = ChecklistProgressForTripFamily._();

final class ChecklistProgressForTripProvider
    extends
        $AsyncNotifierProvider<ChecklistProgressForTrip, ChecklistProgress> {
  ChecklistProgressForTripProvider._({
    required ChecklistProgressForTripFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'checklistProgressForTripProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$checklistProgressForTripHash();

  @override
  String toString() {
    return r'checklistProgressForTripProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ChecklistProgressForTrip create() => ChecklistProgressForTrip();

  @override
  bool operator ==(Object other) {
    return other is ChecklistProgressForTripProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$checklistProgressForTripHash() =>
    r'9d5cf773bfd18f5350c15bc067b9182a9f5a3b0a';

final class ChecklistProgressForTripFamily extends $Family
    with
        $ClassFamilyOverride<
          ChecklistProgressForTrip,
          AsyncValue<ChecklistProgress>,
          ChecklistProgress,
          FutureOr<ChecklistProgress>,
          String
        > {
  ChecklistProgressForTripFamily._()
    : super(
        retry: null,
        name: r'checklistProgressForTripProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ChecklistProgressForTripProvider call(String tripId) =>
      ChecklistProgressForTripProvider._(argument: tripId, from: this);

  @override
  String toString() => r'checklistProgressForTripProvider';
}

abstract class _$ChecklistProgressForTrip
    extends $AsyncNotifier<ChecklistProgress> {
  late final _$args = ref.$arg as String;
  String get tripId => _$args;

  FutureOr<ChecklistProgress> build(String tripId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ChecklistProgress>, ChecklistProgress>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ChecklistProgress>, ChecklistProgress>,
              AsyncValue<ChecklistProgress>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
