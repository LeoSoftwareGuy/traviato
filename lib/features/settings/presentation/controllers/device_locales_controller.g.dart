// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_locales_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The phone's preferred locales, kept current when the user changes the
/// system language while the app runs (`didChangeLocales`), so "System
/// default" follows along live (#236).

@ProviderFor(DeviceLocalesController)
final deviceLocalesControllerProvider = DeviceLocalesControllerProvider._();

/// The phone's preferred locales, kept current when the user changes the
/// system language while the app runs (`didChangeLocales`), so "System
/// default" follows along live (#236).
final class DeviceLocalesControllerProvider
    extends $NotifierProvider<DeviceLocalesController, List<Locale>> {
  /// The phone's preferred locales, kept current when the user changes the
  /// system language while the app runs (`didChangeLocales`), so "System
  /// default" follows along live (#236).
  DeviceLocalesControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceLocalesControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceLocalesControllerHash();

  @$internal
  @override
  DeviceLocalesController create() => DeviceLocalesController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Locale> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Locale>>(value),
    );
  }
}

String _$deviceLocalesControllerHash() =>
    r'ea5416aab70ed00a037a58340d2ac088ede1bfa6';

/// The phone's preferred locales, kept current when the user changes the
/// system language while the app runs (`didChangeLocales`), so "System
/// default" follows along live (#236).

abstract class _$DeviceLocalesController extends $Notifier<List<Locale>> {
  List<Locale> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<Locale>, List<Locale>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<Locale>, List<Locale>>,
              List<Locale>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
