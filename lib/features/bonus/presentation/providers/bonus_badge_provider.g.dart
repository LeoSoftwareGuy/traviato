// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bonus_badge_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Open (incomplete) task count for a trip's stars badge dot — Home's
/// "available-count dot when tray has open tasks" (issue #64 AC). Runs the
/// same ensure-tray orchestration the tray screen does, so the dot is
/// accurate the moment Home loads rather than only after Bonus has been
/// opened once.

@ProviderFor(bonusOpenCountForTrip)
final bonusOpenCountForTripProvider = BonusOpenCountForTripFamily._();

/// Open (incomplete) task count for a trip's stars badge dot — Home's
/// "available-count dot when tray has open tasks" (issue #64 AC). Runs the
/// same ensure-tray orchestration the tray screen does, so the dot is
/// accurate the moment Home loads rather than only after Bonus has been
/// opened once.

final class BonusOpenCountForTripProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Open (incomplete) task count for a trip's stars badge dot — Home's
  /// "available-count dot when tray has open tasks" (issue #64 AC). Runs the
  /// same ensure-tray orchestration the tray screen does, so the dot is
  /// accurate the moment Home loads rather than only after Bonus has been
  /// opened once.
  BonusOpenCountForTripProvider._({
    required BonusOpenCountForTripFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'bonusOpenCountForTripProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$bonusOpenCountForTripHash();

  @override
  String toString() {
    return r'bonusOpenCountForTripProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    final argument = this.argument as String;
    return bonusOpenCountForTrip(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BonusOpenCountForTripProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$bonusOpenCountForTripHash() =>
    r'a5e8d2d587f377a84228406788f86d88ca2dcc33';

/// Open (incomplete) task count for a trip's stars badge dot — Home's
/// "available-count dot when tray has open tasks" (issue #64 AC). Runs the
/// same ensure-tray orchestration the tray screen does, so the dot is
/// accurate the moment Home loads rather than only after Bonus has been
/// opened once.

final class BonusOpenCountForTripFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<int>, String> {
  BonusOpenCountForTripFamily._()
    : super(
        retry: null,
        name: r'bonusOpenCountForTripProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Open (incomplete) task count for a trip's stars badge dot — Home's
  /// "available-count dot when tray has open tasks" (issue #64 AC). Runs the
  /// same ensure-tray orchestration the tray screen does, so the dot is
  /// accurate the moment Home loads rather than only after Bonus has been
  /// opened once.

  BonusOpenCountForTripProvider call(String tripId) =>
      BonusOpenCountForTripProvider._(argument: tripId, from: this);

  @override
  String toString() => r'bonusOpenCountForTripProvider';
}
