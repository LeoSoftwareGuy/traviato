import 'package:equatable/equatable.dart';

/// The Invitation frame's two lines — [line1] is computed from the trip's
/// day count, [line2] is AI-written (#125's `invitation` field).
class WrapUpInvitation extends Equatable {
  const WrapUpInvitation({required this.line1, required this.line2});

  final String line1;
  final String line2;

  @override
  List<Object?> get props => [line1, line2];
}
