import 'package:supabase_flutter/supabase_flutter.dart' show User;

import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({required super.id, required super.email, super.username});

  factory UserModel.fromSupabaseUser(User user) {
    final meta = user.userMetadata ?? {};
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      username: meta['username'] as String?,
    );
  }
}
