// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared_memory_view_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sharedMemoryView)
final sharedMemoryViewProvider = SharedMemoryViewFamily._();

final class SharedMemoryViewProvider
    extends
        $FunctionalProvider<
          AsyncValue<SharedMemoryView>,
          SharedMemoryView,
          FutureOr<SharedMemoryView>
        >
    with $FutureModifier<SharedMemoryView>, $FutureProvider<SharedMemoryView> {
  SharedMemoryViewProvider._({
    required SharedMemoryViewFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'sharedMemoryViewProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sharedMemoryViewHash();

  @override
  String toString() {
    return r'sharedMemoryViewProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<SharedMemoryView> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SharedMemoryView> create(Ref ref) {
    final argument = this.argument as String;
    return sharedMemoryView(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SharedMemoryViewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sharedMemoryViewHash() => r'940f4389dfb839a705a1cbad7feb03b4b45d1faa';

final class SharedMemoryViewFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<SharedMemoryView>, String> {
  SharedMemoryViewFamily._()
    : super(
        retry: null,
        name: r'sharedMemoryViewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SharedMemoryViewProvider call(String slug) =>
      SharedMemoryViewProvider._(argument: slug, from: this);

  @override
  String toString() => r'sharedMemoryViewProvider';
}
