// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cover_image_url_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Signs a stored cover path (a custom upload, never an `asset:` bundled
/// reference) for display — `trip-photos` is a private bucket. Auto-dispose,
/// cached per path: cheap to re-derive, no need to keep it alive once
/// nothing is watching (issue #81).

@ProviderFor(coverImageUrl)
final coverImageUrlProvider = CoverImageUrlFamily._();

/// Signs a stored cover path (a custom upload, never an `asset:` bundled
/// reference) for display — `trip-photos` is a private bucket. Auto-dispose,
/// cached per path: cheap to re-derive, no need to keep it alive once
/// nothing is watching (issue #81).

final class CoverImageUrlProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// Signs a stored cover path (a custom upload, never an `asset:` bundled
  /// reference) for display — `trip-photos` is a private bucket. Auto-dispose,
  /// cached per path: cheap to re-derive, no need to keep it alive once
  /// nothing is watching (issue #81).
  CoverImageUrlProvider._({
    required CoverImageUrlFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'coverImageUrlProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$coverImageUrlHash();

  @override
  String toString() {
    return r'coverImageUrlProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    final argument = this.argument as String;
    return coverImageUrl(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CoverImageUrlProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$coverImageUrlHash() => r'0d58ced854487003915f52f4d399b88927a1fabe';

/// Signs a stored cover path (a custom upload, never an `asset:` bundled
/// reference) for display — `trip-photos` is a private bucket. Auto-dispose,
/// cached per path: cheap to re-derive, no need to keep it alive once
/// nothing is watching (issue #81).

final class CoverImageUrlFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String>, String> {
  CoverImageUrlFamily._()
    : super(
        retry: null,
        name: r'coverImageUrlProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Signs a stored cover path (a custom upload, never an `asset:` bundled
  /// reference) for display — `trip-photos` is a private bucket. Auto-dispose,
  /// cached per path: cheap to re-derive, no need to keep it alive once
  /// nothing is watching (issue #81).

  CoverImageUrlProvider call(String storagePath) =>
      CoverImageUrlProvider._(argument: storagePath, from: this);

  @override
  String toString() => r'coverImageUrlProvider';
}
