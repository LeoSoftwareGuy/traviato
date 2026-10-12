import 'package:equatable/equatable.dart';

import 'user_entity.dart';

/// Outcome of a successful signup call (#162). With email confirmation on,
/// Supabase creates the user but returns no session until the link in the
/// confirmation email is opened — [needsEmailConfirmation] tells the auth
/// screen to show its "Check your inbox" state instead of waiting for the
/// router (which only moves on a session).
class SignupResult extends Equatable {
  const SignupResult({
    required this.user,
    required this.needsEmailConfirmation,
  });

  final UserEntity user;
  final bool needsEmailConfirmation;

  @override
  List<Object?> get props => [user, needsEmailConfirmation];
}
