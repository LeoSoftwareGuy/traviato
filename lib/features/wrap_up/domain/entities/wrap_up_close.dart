import 'package:equatable/equatable.dart';

/// The closing line + "Open journal" / "Keep forever" CTAs.
class WrapUpClose extends Equatable {
  const WrapUpClose({required this.line});

  final String line;

  @override
  List<Object?> get props => [line];
}
