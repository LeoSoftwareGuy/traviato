// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entitlement_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EntitlementModel _$EntitlementModelFromJson(Map<String, dynamic> json) =>
    EntitlementModel(
      tier: _tierFromJson(json['tier'] as String),
      revenuecatCustomerId: json['revenuecat_customer_id'] as String?,
      expiresAt: json['expires_at'] == null
          ? null
          : DateTime.parse(json['expires_at'] as String),
    );
