// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share_memory_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(shareMemory)
final shareMemoryProvider = ShareMemoryFamily._();

final class ShareMemoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<ShareMemory>,
          ShareMemory,
          FutureOr<ShareMemory>
        >
    with $FutureModifier<ShareMemory>, $FutureProvider<ShareMemory> {
  ShareMemoryProvider._({
    required ShareMemoryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'shareMemoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$shareMemoryHash();

  @override
  String toString() {
    return r'shareMemoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ShareMemory> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ShareMemory> create(Ref ref) {
    final argument = this.argument as String;
    return shareMemory(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ShareMemoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$shareMemoryHash() => r'e179c26629e9d9e8280cbe71f28b6b7cae7c0c29';

final class ShareMemoryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ShareMemory>, String> {
  ShareMemoryFamily._()
    : super(
        retry: null,
        name: r'shareMemoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ShareMemoryProvider call(String tripId) =>
      ShareMemoryProvider._(argument: tripId, from: this);

  @override
  String toString() => r'shareMemoryProvider';
}
