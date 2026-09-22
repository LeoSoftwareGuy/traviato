import 'package:equatable/equatable.dart';

enum SubscriptionPeriod { monthly, annual }

/// One purchasable plan (RevenueCat "package"), decoupled from the
/// `purchases_flutter` SDK types so the domain layer stays SDK-free
/// (guidelines doc 01/05).
class SubscriptionOfferingEntity extends Equatable {
  const SubscriptionOfferingEntity({
    required this.identifier,
    required this.period,
    required this.priceString,
  });

  /// RevenueCat package identifier — opaque to the domain, passed back to
  /// [SubscriptionRepository.purchase] to identify which plan to buy.
  final String identifier;
  final SubscriptionPeriod period;

  /// Store-localized price, e.g. "$44.99" — already formatted by the store.
  final String priceString;

  @override
  List<Object?> get props => [identifier, period, priceString];
}
