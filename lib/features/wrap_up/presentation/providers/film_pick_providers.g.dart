// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'film_pick_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Photos of the memory's completed bonus tasks, in completion order — the
/// film badges the first 3 (#294). A garnish for the "Film chose this one"
/// hint: on failure it's empty rather than an error.

@ProviderFor(filmBonusPhotoIds)
final filmBonusPhotoIdsProvider = FilmBonusPhotoIdsFamily._();

/// Photos of the memory's completed bonus tasks, in completion order — the
/// film badges the first 3 (#294). A garnish for the "Film chose this one"
/// hint: on failure it's empty rather than an error.

final class FilmBonusPhotoIdsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>
        >
    with $FutureModifier<List<String>>, $FutureProvider<List<String>> {
  /// Photos of the memory's completed bonus tasks, in completion order — the
  /// film badges the first 3 (#294). A garnish for the "Film chose this one"
  /// hint: on failure it's empty rather than an error.
  FilmBonusPhotoIdsProvider._({
    required FilmBonusPhotoIdsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'filmBonusPhotoIdsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$filmBonusPhotoIdsHash();

  @override
  String toString() {
    return r'filmBonusPhotoIdsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<String>> create(Ref ref) {
    final argument = this.argument as String;
    return filmBonusPhotoIds(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FilmBonusPhotoIdsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$filmBonusPhotoIdsHash() => r'431fac795802dd5af0b61da109bda98b01c5979c';

/// Photos of the memory's completed bonus tasks, in completion order — the
/// film badges the first 3 (#294). A garnish for the "Film chose this one"
/// hint: on failure it's empty rather than an error.

final class FilmBonusPhotoIdsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<String>>, String> {
  FilmBonusPhotoIdsFamily._()
    : super(
        retry: null,
        name: r'filmBonusPhotoIdsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Photos of the memory's completed bonus tasks, in completion order — the
  /// film badges the first 3 (#294). A garnish for the "Film chose this one"
  /// hint: on failure it's empty rather than an error.

  FilmBonusPhotoIdsProvider call(String tripId) =>
      FilmBonusPhotoIdsProvider._(argument: tripId, from: this);

  @override
  String toString() => r'filmBonusPhotoIdsProvider';
}

/// The Journal's photos the film gives a main moment to, with the current
/// picks (#294) — computed locally, never a network or AI call. Follows
/// every optimistic pick change in the Journal at once.

@ProviderFor(filmMomentIds)
final filmMomentIdsProvider = FilmMomentIdsFamily._();

/// The Journal's photos the film gives a main moment to, with the current
/// picks (#294) — computed locally, never a network or AI call. Follows
/// every optimistic pick change in the Journal at once.

final class FilmMomentIdsProvider
    extends $FunctionalProvider<Set<String>, Set<String>, Set<String>>
    with $Provider<Set<String>> {
  /// The Journal's photos the film gives a main moment to, with the current
  /// picks (#294) — computed locally, never a network or AI call. Follows
  /// every optimistic pick change in the Journal at once.
  FilmMomentIdsProvider._({
    required FilmMomentIdsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'filmMomentIdsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$filmMomentIdsHash();

  @override
  String toString() {
    return r'filmMomentIdsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<Set<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Set<String> create(Ref ref) {
    final argument = this.argument as String;
    return filmMomentIds(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FilmMomentIdsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$filmMomentIdsHash() => r'67e1c2a6aa339fafff21b983eb84b8f8ecc29fe9';

/// The Journal's photos the film gives a main moment to, with the current
/// picks (#294) — computed locally, never a network or AI call. Follows
/// every optimistic pick change in the Journal at once.

final class FilmMomentIdsFamily extends $Family
    with $FunctionalFamilyOverride<Set<String>, String> {
  FilmMomentIdsFamily._()
    : super(
        retry: null,
        name: r'filmMomentIdsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The Journal's photos the film gives a main moment to, with the current
  /// picks (#294) — computed locally, never a network or AI call. Follows
  /// every optimistic pick change in the Journal at once.

  FilmMomentIdsProvider call(String tripId) =>
      FilmMomentIdsProvider._(argument: tripId, from: this);

  @override
  String toString() => r'filmMomentIdsProvider';
}
