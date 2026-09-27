import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/supabase_providers.dart';
import '../../data/datasources/entitlements_remote_data_source.dart';
import '../../data/datasources/purchases_remote_data_source.dart';
import '../../data/datasources/revenuecat_purchases_remote_data_source.dart';
import '../../data/datasources/supabase_entitlements_remote_data_source.dart';
import '../../data/repositories/subscription_repository_impl.dart';
import '../../domain/repositories/subscription_repository.dart';

part 'subscription_providers.g.dart';

/// Whether `Purchases.configure` ran this session. `main.dart` overrides this
/// with the real result; the default is the safe answer — never call into an
/// unconfigured RevenueCat SDK (#156).
@Riverpod(keepAlive: true)
bool revenueCatConfigured(Ref ref) => false;

@riverpod
PurchasesRemoteDataSource purchasesRemoteDataSource(Ref ref) =>
    RevenueCatPurchasesRemoteDataSource(
      isConfigured: ref.watch(revenueCatConfiguredProvider),
    );

@riverpod
EntitlementsRemoteDataSource entitlementsRemoteDataSource(Ref ref) =>
    SupabaseEntitlementsRemoteDataSource(
      client: ref.watch(supabaseClientProvider),
    );

@riverpod
SubscriptionRepository subscriptionRepository(Ref ref) =>
    SubscriptionRepositoryImpl(
      purchases: ref.watch(purchasesRemoteDataSourceProvider),
      entitlements: ref.watch(entitlementsRemoteDataSourceProvider),
    );
