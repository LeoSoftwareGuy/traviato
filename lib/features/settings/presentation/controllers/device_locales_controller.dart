import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'device_locales_controller.g.dart';

/// The phone's preferred locales, kept current when the user changes the
/// system language while the app runs (`didChangeLocales`), so "System
/// default" follows along live (#236).
@Riverpod(keepAlive: true)
class DeviceLocalesController extends _$DeviceLocalesController
    with WidgetsBindingObserver {
  @override
  List<Locale> build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() => WidgetsBinding.instance.removeObserver(this));
    return PlatformDispatcher.instance.locales;
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    state = locales ?? PlatformDispatcher.instance.locales;
  }
}
