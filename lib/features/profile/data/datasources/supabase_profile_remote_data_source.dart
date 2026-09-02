import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/achievement_template_model.dart';
import '../models/profile_model.dart';
import 'profile_remote_data_source.dart';

/// Signed URLs are valid for an hour — matches the trip-cover convention
/// (`supabase_trip_remote_data_source.dart`).
const _signedUrlTtlSeconds = 3600;

String _avatarStoragePath(String userId) => '$userId/avatar.jpg';

class SupabaseProfileRemoteDataSource implements ProfileRemoteDataSource {
  SupabaseProfileRemoteDataSource({required SupabaseClient client})
    : _client = client;

  final SupabaseClient _client;

  String _requireUserId() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthenticationException(
        message: 'User is not authenticated',
      );
    }
    return user.id;
  }

  @override
  Future<ProfileModel> getProfile() async {
    final userId = _requireUserId();
    try {
      final row = await _client
          .from(Tables.profiles)
          .select()
          .eq('id', userId)
          .single();
      return ProfileModel.fromJson(row);
    } on AuthenticationException {
      rethrow;
    } on PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  @override
  Future<ProfileModel> updateProfile({
    String? username,
    String? bio,
    String? avatarUrl,
  }) async {
    final userId = _requireUserId();
    try {
      final row = await _client
          .from(Tables.profiles)
          .update({
            'username': ?username,
            'bio': ?bio,
            'avatar_url': ?avatarUrl,
          })
          .eq('id', userId)
          .select()
          .single();
      return ProfileModel.fromJson(row);
    } on AuthenticationException {
      rethrow;
    } on PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  @override
  Future<List<AchievementTemplateModel>> getAchievementTemplates() async {
    _requireUserId();
    try {
      final rows = await _client
          .from(Tables.achievementTemplates)
          .select()
          .order('position');
      return rows
          .map((row) => AchievementTemplateModel.fromJson(row))
          .toList(growable: false);
    } on AuthenticationException {
      rethrow;
    } on PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  @override
  Future<Map<int, DateTime>> getEarnedAchievements() async {
    final userId = _requireUserId();
    try {
      final rows = await _client
          .from(Tables.userAchievements)
          .select('template_id, earned_at')
          .eq('user_id', userId);
      return {
        for (final row in rows)
          (row['template_id'] as num).toInt(): DateTime.parse(
            row['earned_at'] as String,
          ),
      };
    } on AuthenticationException {
      rethrow;
    } on PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  @override
  Future<String> uploadAvatar(Uint8List bytes) async {
    final userId = _requireUserId();
    final path = _avatarStoragePath(userId);
    try {
      // Best-effort: nothing there yet on a first upload, or a transient
      // hiccup — the upload below is what actually matters. This bucket
      // has no update policy, so a replace is delete-then-insert rather
      // than an upsert (matches the trip-cover convention).
      await _client.storage.from(Storage.avatars).remove([path]);
    } catch (_) {
      // Ignored — see above.
    }
    try {
      await _client.storage.from(Storage.avatars).uploadBinary(path, bytes);
      return path;
    } on StorageException catch (e) {
      throw StorageServerException(message: e.message);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  @override
  Future<String> getAvatarUrl(String storagePath) async {
    _requireUserId();
    try {
      return await _client.storage
          .from(Storage.avatars)
          .createSignedUrl(storagePath, _signedUrlTtlSeconds);
    } on StorageException catch (e) {
      throw StorageServerException(message: e.message);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }
}

AppException _mapPostgrestException(PostgrestException e) {
  if (e.code == PostgresErrors.insufficientPrivilege) {
    return PermissionException(message: e.message);
  }
  if (e.code == PostgresErrors.moreThanOneOrNoItemsReturned) {
    return NotFoundException(message: e.message);
  }
  return DatabaseException(message: e.message);
}
