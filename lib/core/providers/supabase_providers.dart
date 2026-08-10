import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'supabase_providers.g.dart';

/// The app-wide Supabase client. `Supabase.initialize` must have run in `main`
/// before this is read. Kept alive for the whole session — it is the single
/// entry point the data layer injects into every remote data source.
@Riverpod(keepAlive: true)
SupabaseClient supabaseClient(Ref ref) => Supabase.instance.client;
