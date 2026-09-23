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
    required this.priceAmount,
    required this.currencyCode,
  });

  /// RevenueCat package identifier — opaque to the domain, passed back to
  /// [SubscriptionRepository.purchase] to identify which plan to buy.
  final String identifier;
  final SubscriptionPeriod period;

  /// Store-localized price, e.g. "$44.99" — already formatted by the store.
  final String priceString;

  /// Raw numeric price backing [priceString] — needed to derive the
  /// per-month split shown on the annual plan card without re-parsing a
  /// currency symbol out of the formatted string.
  final double priceAmount;

  /// ISO currency code (e.g. "USD") for formatting [priceAmount] derivations
  /// (`intl`'s `NumberFormat.simpleCurrency`) in the store's own currency.
  final String currencyCode;

  @override
  List<Object?> get props => [
    identifier,
    period,
    priceString,
    priceAmount,
    currencyCode,
  ];
}
