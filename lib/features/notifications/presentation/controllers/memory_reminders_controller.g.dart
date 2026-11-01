// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory_reminders_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The You → Settings "Memory reminders" toggle (#307). Stored on the
/// device with the rest of the notification prefs.

@ProviderFor(MemoryRemindersController)
final memoryRemindersControllerProvider = MemoryRemindersControllerProvider._();

/// The You → Settings "Memory reminders" toggle (#307). Stored on the
/// device with the rest of the notification prefs.
final class MemoryRemindersControllerProvider
    extends $AsyncNotifierProvider<MemoryRemindersController, bool> {
  /// The You → Settings "Memory reminders" toggle (#307). Stored on the
  /// device with the rest of the notification prefs.
  MemoryRemindersControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'memoryRemindersControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$memoryRemindersControllerHash();

  @$internal
  @override
  MemoryRemindersController create() => MemoryRemindersController();
}

String _$memoryRemindersControllerHash() =>
    r'606664f1e33675cb346620da60a34a9f1426c2c9';

/// The You → Settings "Memory reminders" toggle (#307). Stored on the
/// device with the rest of the notification prefs.

abstract class _$MemoryRemindersController extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
