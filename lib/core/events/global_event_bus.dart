import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'global_event.dart';

part 'global_event_bus.g.dart';

class GlobalEventBus {
  final _controller = StreamController<GlobalEvent>.broadcast();

  Stream<GlobalEvent> get stream => _controller.stream;

  void add(GlobalEvent event) => _controller.add(event);

  void dispose() => _controller.close();
}

@Riverpod(keepAlive: true)
GlobalEventBus globalEventBus(Ref ref) {
  final bus = GlobalEventBus();
  ref.onDispose(bus.dispose);
  return bus;
}
