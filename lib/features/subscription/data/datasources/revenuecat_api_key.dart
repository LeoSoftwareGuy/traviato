import 'package:flutter/foundation.dart';

/// The RevenueCat public API key for [platform] from the loaded `.env`, or
/// `null` when it's missing/empty — in which case RevenueCat must not be
/// configured, and nothing may call into its SDK this session (#156).
String? revenueCatApiKey({
  required TargetPlatform platform,
  required Map<String, String> env,
}) {
  final key = platform == TargetPlatform.iOS
      ? env['REVENUECAT_IOS_API_KEY']
      : env['REVENUECAT_ANDROID_API_KEY'];
  return (key == null || key.isEmpty) ? null : key;
}
