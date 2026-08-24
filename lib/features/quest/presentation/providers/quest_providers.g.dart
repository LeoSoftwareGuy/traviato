// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quest_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(questRemoteDataSource)
final questRemoteDataSourceProvider = QuestRemoteDataSourceProvider._();

final class QuestRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          QuestRemoteDataSource,
          QuestRemoteDataSource,
          QuestRemoteDataSource
        >
    with $Provider<QuestRemoteDataSource> {
  QuestRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'questRemoteDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$questRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<QuestRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  QuestRemoteDataSource create(Ref ref) {
    return questRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(QuestRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<QuestRemoteDataSource>(value),
    );
  }
}

String _$questRemoteDataSourceHash() =>
    r'e655afc24f97b6c8de968bb03cfe6463ae4194aa';

@ProviderFor(questRepository)
final questRepositoryProvider = QuestRepositoryProvider._();

final class QuestRepositoryProvider
    extends
        $FunctionalProvider<QuestRepository, QuestRepository, QuestRepository>
    with $Provider<QuestRepository> {
  QuestRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'questRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$questRepositoryHash();

  @$internal
  @override
  $ProviderElement<QuestRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  QuestRepository create(Ref ref) {
    return questRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(QuestRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<QuestRepository>(value),
    );
  }
}

String _$questRepositoryHash() => r'6b6e6cc678c148e2550ebd4a367eefed56d3ad42';

/// Planned-quest count for a trip — used by Home's Coming-up planning-state
/// line. `trip_card_view` doesn't carry this, so it's derived here rather
/// than adding a column.

@ProviderFor(questCountForTrip)
final questCountForTripProvider = QuestCountForTripFamily._();

/// Planned-quest count for a trip — used by Home's Coming-up planning-state
/// line. `trip_card_view` doesn't carry this, so it's derived here rather
/// than adding a column.

final class QuestCountForTripProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Planned-quest count for a trip — used by Home's Coming-up planning-state
  /// line. `trip_card_view` doesn't carry this, so it's derived here rather
  /// than adding a column.
  QuestCountForTripProvider._({
    required QuestCountForTripFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'questCountForTripProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$questCountForTripHash();

  @override
  String toString() {
    return r'questCountForTripProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    final argument = this.argument as String;
    return questCountForTrip(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is QuestCountForTripProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$questCountForTripHash() => r'e5c5c367ae55b647b37b0432ea6a4ac565f3249d';

/// Planned-quest count for a trip — used by Home's Coming-up planning-state
/// line. `trip_card_view` doesn't carry this, so it's derived here rather
/// than adding a column.

final class QuestCountForTripFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<int>, String> {
  QuestCountForTripFamily._()
    : super(
        retry: null,
        name: r'questCountForTripProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Planned-quest count for a trip — used by Home's Coming-up planning-state
  /// line. `trip_card_view` doesn't carry this, so it's derived here rather
  /// than adding a column.

  QuestCountForTripProvider call(String tripId) =>
      QuestCountForTripProvider._(argument: tripId, from: this);

  @override
  String toString() => r'questCountForTripProvider';
}
