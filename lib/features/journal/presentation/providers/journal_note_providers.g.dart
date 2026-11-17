// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journal_note_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(journalNoteRemoteDataSource)
final journalNoteRemoteDataSourceProvider =
    JournalNoteRemoteDataSourceProvider._();

final class JournalNoteRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          JournalNoteRemoteDataSource,
          JournalNoteRemoteDataSource,
          JournalNoteRemoteDataSource
        >
    with $Provider<JournalNoteRemoteDataSource> {
  JournalNoteRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'journalNoteRemoteDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$journalNoteRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<JournalNoteRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  JournalNoteRemoteDataSource create(Ref ref) {
    return journalNoteRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(JournalNoteRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<JournalNoteRemoteDataSource>(value),
    );
  }
}

String _$journalNoteRemoteDataSourceHash() =>
    r'e301df2b77f2651ea47e67ddb4c3ad4bbcb1165a';

@ProviderFor(journalNoteRepository)
final journalNoteRepositoryProvider = JournalNoteRepositoryProvider._();

final class JournalNoteRepositoryProvider
    extends
        $FunctionalProvider<
          JournalNoteRepository,
          JournalNoteRepository,
          JournalNoteRepository
        >
    with $Provider<JournalNoteRepository> {
  JournalNoteRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'journalNoteRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$journalNoteRepositoryHash();

  @$internal
  @override
  $ProviderElement<JournalNoteRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  JournalNoteRepository create(Ref ref) {
    return journalNoteRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(JournalNoteRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<JournalNoteRepository>(value),
    );
  }
}

String _$journalNoteRepositoryHash() =>
    r'916beb1be8042499852d612f8ab3fc67185e37b0';
