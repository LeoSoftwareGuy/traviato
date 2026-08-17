import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_PUBLISHABLE_KEY']!,
  );
  // Disable Riverpod's silent auto-retry; retries are handled explicitly with
  // Retry buttons (guidelines doc 02).
  runApp(ProviderScope(retry: (_, _) => null, child: const TraviatoApp()));
}

class TraviatoApp extends ConsumerWidget {
  const TraviatoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO(#5): switch to MaterialApp.router with routerProvider once the
    // auth-aware GoRouter and splash land.
    return MaterialApp(
      title: 'Traviato',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const BootstrapPage(),
    );
  }
}

/// Placeholder home for the bootstrap milestone — proves the app builds and runs
/// against an initialized Supabase client. Replaced by the router + real screens
/// in later issues.
class BootstrapPage extends StatelessWidget {
  const BootstrapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Traviato',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
