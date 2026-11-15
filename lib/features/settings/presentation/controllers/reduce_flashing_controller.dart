import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../providers/settings_providers.dart';

part 'reduce_flashing_controller.g.dart';

/// The You → Settings "Reduce flashing" switch (#363): films with flashes
/// (Neon Night) play their softer version. Stored on the device.
@Riverpod(keepAlive: true)
class ReduceFlashingController extends _$ReduceFlashingController {
  @override
  bool build() => ref.read(initialReduceFlashingProvider);

  Future<void> setEnabled({required bool enabled}) async {
    state = enabled;
    await ref.read(reduceFlashingPrefsProvider).write(enabled: enabled);
  }
}

/// Whether a film should play its reduced-flashing version: when the
/// phone asks for reduced motion, or the user turned the setting on.
bool watchReduceFlashing(BuildContext context, WidgetRef ref) =>
    MediaQuery.disableAnimationsOf(context) ||
    ref.watch(reduceFlashingControllerProvider);
