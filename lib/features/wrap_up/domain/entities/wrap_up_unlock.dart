import 'package:equatable/equatable.dart';

/// The achievement earned by/during this trip, if any (#125 `unlock`).
/// `null` means the Unlock frame has nothing to show — the player skips it.
class WrapUpUnlock extends Equatable {
  const WrapUpUnlock({
    required this.code,
    required this.name,
    required this.reason,
  });

  final String code;
  final String name;
  final String reason;

  @override
  List<Object?> get props => [code, name, reason];
}
