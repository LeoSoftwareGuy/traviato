import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  const UserEntity({required this.id, required this.email, this.username});

  final String id;
  final String email;
  final String? username;

  @override
  List<Object?> get props => [id, email, username];
}
