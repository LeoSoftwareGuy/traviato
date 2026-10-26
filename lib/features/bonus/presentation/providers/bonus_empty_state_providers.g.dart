// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bonus_empty_state_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(starBreakdownRemoteDataSource)
final starBreakdownRemoteDataSourceProvider =
    StarBreakdownRemoteDataSourceProvider._();

final class StarBreakdownRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          StarBreakdownRemoteDataSource,
          StarBreakdownRemoteDataSource,
          StarBreakdownRemoteDataSource
        >
    with $Provider<StarBreakdownRemoteDataSource> {
  StarBreakdownRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'starBreakdownRemoteDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$starBreakdownRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<StarBreakdownRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  StarBreakdownRemoteDataSource create(Ref ref) {
    return starBreakdownRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StarBreakdownRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StarBreakdownRemoteDataSource>(
        value,
      ),
    );
  }
}

String _$starBreakdownRemoteDataSourceHash() =>
    r'75f5effce863ba0eeb62e270ba6daabe2e6f9f25';

@ProviderFor(starBreakdownRepository)
final starBreakdownRepositoryProvider = StarBreakdownRepositoryProvider._();

final class StarBreakdownRepositoryProvider
    extends
        $FunctionalProvider<
          StarBreakdownRepository,
          StarBreakdownRepository,
          StarBreakdownRepository
        >
    with $Provider<StarBreakdownRepository> {
  StarBreakdownRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'starBreakdownRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$starBreakdownRepositoryHash();

  @$internal
  @override
  $ProviderElement<StarBreakdownRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  StarBreakdownRepository create(Ref ref) {
    return starBreakdownRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StarBreakdownRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StarBreakdownRepository>(value),
    );
  }
}

String _$starBreakdownRepositoryHash() =>
    r'59a8ccfc0f64ed39eebbc63dccc0c97ba0c65cad';

/// "Now" for the Bonus page's state choice — overridden in tests so the
/// days-until math can be pinned to a date (#219).

@ProviderFor(bonusClock)
final bonusClockProvider = BonusClockProvider._();

/// "Now" for the Bonus page's state choice — overridden in tests so the
/// days-until math can be pinned to a date (#219).

final class BonusClockProvider
    extends
        $FunctionalProvider<
          DateTime Function(),
          DateTime Function(),
          DateTime Function()
        >
    with $Provider<DateTime Function()> {
  /// "Now" for the Bonus page's state choice — overridden in tests so the
  /// days-until math can be pinned to a date (#219).
  BonusClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bonusClockProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bonusClockHash();

  @$internal
  @override
  $ProviderElement<DateTime Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DateTime Function() create(Ref ref) {
    return bonusClock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime Function()>(value),
    );
  }
}

String _$bonusClockHash() => r'ce66abb829b38e1c526fdbf42de8c3a5166414f6';

/// The user's memories, refetched whenever one is created, changed or
/// deleted, or stars move.

@ProviderFor(bonusTripCards)
final bonusTripCardsProvider = BonusTripCardsProvider._();

/// The user's memories, refetched whenever one is created, changed or
/// deleted, or stars move.

final class BonusTripCardsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TripCardEntity>>,
          List<TripCardEntity>,
          FutureOr<List<TripCardEntity>>
        >
    with
        $FutureModifier<List<TripCardEntity>>,
        $FutureProvider<List<TripCardEntity>> {
  /// The user's memories, refetched whenever one is created, changed or
  /// deleted, or stars move.
  BonusTripCardsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bonusTripCardsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bonusTripCardsHash();

  @$internal
  @override
  $FutureProviderElement<List<TripCardEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TripCardEntity>> create(Ref ref) {
    return bonusTripCards(ref);
  }
}

String _$bonusTripCardsHash() => r'59ee1ec26b13ec34ef499ab76ada5df11020f89b';

/// Stars by type and by memory (frames 1a/1b, and the All memories list).

@ProviderFor(starSummary)
final starSummaryProvider = StarSummaryProvider._();

/// Stars by type and by memory (frames 1a/1b, and the All memories list).

final class StarSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<StarSummary>,
          StarSummary,
          FutureOr<StarSummary>
        >
    with $FutureModifier<StarSummary>, $FutureProvider<StarSummary> {
  /// Stars by type and by memory (frames 1a/1b, and the All memories list).
  StarSummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'starSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$starSummaryHash();

  @$internal
  @override
  $FutureProviderElement<StarSummary> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<StarSummary> create(Ref ref) {
    return starSummary(ref);
  }
}

String _$starSummaryHash() => r'711e084a2b43aed0180b6502c8af2c18b548bde2';

@ProviderFor(bonusEmptyState)
final bonusEmptyStateProvider = BonusEmptyStateProvider._();

final class BonusEmptyStateProvider
    extends
        $FunctionalProvider<
          AsyncValue<BonusEmptyState>,
          BonusEmptyState,
          FutureOr<BonusEmptyState>
        >
    with $FutureModifier<BonusEmptyState>, $FutureProvider<BonusEmptyState> {
  BonusEmptyStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bonusEmptyStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bonusEmptyStateHash();

  @$internal
  @override
  $FutureProviderElement<BonusEmptyState> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<BonusEmptyState> create(Ref ref) {
    return bonusEmptyState(ref);
  }
}

String _$bonusEmptyStateHash() => r'8b10c33eef8974174d2bcc165042fe39c54adff2';
