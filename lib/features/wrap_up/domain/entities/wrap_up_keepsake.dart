import 'package:equatable/equatable.dart';

/// The closing Keepsake frame (#125 `keepsake`) — the trip name split across
/// two display lines, plus an AI-written closing line.
class WrapUpKeepsake extends Equatable {
  const WrapUpKeepsake({
    required this.titleLine1,
    required this.titleLine2,
    required this.closingQuote,
  });

  final String titleLine1;
  final String titleLine2;
  final String closingQuote;

  @override
  List<Object?> get props => [titleLine1, titleLine2, closingQuote];
}
