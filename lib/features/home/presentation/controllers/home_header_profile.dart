import 'package:equatable/equatable.dart';

/// Who Home's header greets and shows (#266, #283): the profile's name and
/// avatar, the same fields the Profile screen edits.
class HomeHeaderProfile extends Equatable {
  const HomeHeaderProfile({this.username, this.avatarUrl});

  /// Null when the profile has no name — Home says "Hello!".
  final String? username;

  /// An OAuth picture URL or this app's `avatars` storage path; null shows
  /// the initial.
  final String? avatarUrl;

  @override
  List<Object?> get props => [username, avatarUrl];
}
