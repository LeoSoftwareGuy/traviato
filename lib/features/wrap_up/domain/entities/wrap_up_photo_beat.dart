import 'package:equatable/equatable.dart';

/// Chapter two — one full-bleed photo + second-person narrative
/// (docs/design/README.md § 12).
class WrapUpPhotoBeat extends Equatable {
  const WrapUpPhotoBeat({
    required this.photoId,
    this.dayDate,
    required this.narrative,
  });

  final String photoId;
  final DateTime? dayDate;
  final String narrative;

  @override
  List<Object?> get props => [photoId, dayDate, narrative];
}
