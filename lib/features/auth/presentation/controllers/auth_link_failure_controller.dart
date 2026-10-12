import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/failures.dart';
import '../providers/auth_providers.dart';

part 'auth_link_failure_controller.g.dart';

/// The latest email confirmation link that failed to sign the user in
/// (#157), or `null` once it has been shown. `keepAlive` and watched from
/// the app root so a failure on a cold start — handled by supabase_flutter
/// before the first frame — is still there when the UI can show it.
@Riverpod(keepAlive: true)
class AuthLinkFailureController extends _$AuthLinkFailureController {
  @override
  AuthLinkFailure? build() {
    final sub = ref
        .watch(authRepositoryProvider)
        .onAuthLinkFailure
        .listen((failure) => state = failure);
    ref.onDispose(sub.cancel);
    return null;
  }

  /// Marks the current failure as shown, so the same failure arriving again
  /// (the user re-taps the stale link) still notifies listeners.
  void clear() => state = null;
}
