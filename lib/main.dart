import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/notifications/presentation/controllers/bonus_notifications_lifecycle_controller.dart';
import 'features/subscription/presentation/controllers/subscription_identity_lifecycle_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_PUBLISHABLE_KEY']!,
  );
  await _configureRevenueCat();
  // Disable Riverpod's silent auto-retry; retries are handled explicitly with
  // Retry buttons (guidelines doc 02).
  runApp(ProviderScope(retry: (_, _) => null, child: const TraviatoApp()));
}

/// RevenueCat is configured anonymously here; `SubscriptionIdentityLifecycleController`
/// calls `Purchases.logIn`/`logOut` once the Supabase auth state is known
/// (issue #138). Missing keys degrade to a debug log rather than a crash —
/// the app is still usable free-tier without a configured store.
Future<void> _configureRevenueCat() async {
  final apiKey = defaultTargetPlatform == TargetPlatform.iOS
      ? dotenv.env['REVENUECAT_IOS_API_KEY']
      : dotenv.env['REVENUECAT_ANDROID_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    debugPrint(
      'RevenueCat not configured (REVENUECAT_IOS_API_KEY/'
      'REVENUECAT_ANDROID_API_KEY missing from .env) — Pro purchases are '
      'unavailable this session.',
    );
    return;
  }
  await Purchases.configure(PurchasesConfiguration(apiKey));
}

class TraviatoApp extends ConsumerWidget {
  const TraviatoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // keepAlive — instantiates the bonus-notification lifecycle loop once
    // at launch (issue #65); it self-manages from here on.
    ref.watch(bonusNotificationsLifecycleControllerProvider);
    // keepAlive — keeps RevenueCat's identified user in step with the
    // signed-in Supabase account for the whole session (issue #138).
    ref.watch(subscriptionIdentityLifecycleControllerProvider);
    return MaterialApp.router(
      title: 'Traviato',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
