// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supabase_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app-wide Supabase client. `Supabase.initialize` must have run in `main`
/// before this is read. Kept alive for the whole session — it is the single
/// entry point the data layer injects into every remote data source.

@ProviderFor(supabaseClient)
final supabaseClientProvider = SupabaseClientProvider._();

/// The app-wide Supabase client. `Supabase.initialize` must have run in `main`
/// before this is read. Kept alive for the whole session — it is the single
/// entry point the data layer injects into every remote data source.

final class SupabaseClientProvider
    extends $FunctionalProvider<SupabaseClient, SupabaseClient, SupabaseClient>
    with $Provider<SupabaseClient> {
  /// The app-wide Supabase client. `Supabase.initialize` must have run in `main`
  /// before this is read. Kept alive for the whole session — it is the single
  /// entry point the data layer injects into every remote data source.
  SupabaseClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supabaseClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supabaseClientHash();

  @$internal
  @override
  $ProviderElement<SupabaseClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SupabaseClient create(Ref ref) {
    return supabaseClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SupabaseClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SupabaseClient>(value),
    );
  }
}

String _$supabaseClientHash() => r'3db2a4c212c7f24cea9810e376225aa1a6cab012';
