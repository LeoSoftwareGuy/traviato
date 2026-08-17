import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';
import 'auth_remote_data_source.dart';

class SupabaseAuthRemoteDataSource implements AuthRemoteDataSource {
  SupabaseAuthRemoteDataSource({required SupabaseClient client})
    : _client = client;

  final SupabaseClient _client;

  @override
  Stream<UserModel?> get onAuthStateChanged => _client.auth.onAuthStateChange
      .map((data) => data.session?.user)
      .map((user) => user == null ? null : UserModel.fromSupabaseUser(user));

  @override
  UserModel? get currentUser {
    final user = _client.auth.currentUser;
    return user == null ? null : UserModel.fromSupabaseUser(user);
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = res.user;
      if (user == null) {
        throw const AuthenticationException(
          message: 'Login succeeded but no user returned.',
        );
      }
      return UserModel.fromSupabaseUser(user);
    } on AuthenticationException {
      rethrow;
    } on AuthException catch (e) {
      throw AuthenticationException(message: e.message);
    } on PostgrestException catch (e) {
      if (e.code == PostgresErrors.insufficientPrivilege) {
        throw PermissionException(message: e.message);
      }
      if (e.code == PostgresErrors.moreThanOneOrNoItemsReturned) {
        throw NotFoundException(message: e.message);
      }
      throw DatabaseException(message: e.message);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  @override
  Future<UserModel> signup({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final res = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );
      final user = res.user;
      if (user == null) {
        throw const AuthenticationException(
          message: 'Signup succeeded but no user returned.',
        );
      }
      return UserModel.fromSupabaseUser(user);
    } on AuthenticationException {
      rethrow;
    } on AuthException catch (e) {
      throw AuthenticationException(message: e.message);
    } on PostgrestException catch (e) {
      if (e.code == PostgresErrors.insufficientPrivilege) {
        throw PermissionException(message: e.message);
      }
      if (e.code == PostgresErrors.moreThanOneOrNoItemsReturned) {
        throw NotFoundException(message: e.message);
      }
      throw DatabaseException(message: e.message);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  @override
  Future<void> logout() async {
    if (_client.auth.currentUser == null) {
      throw const AuthenticationException(
        message: 'User is not authenticated',
      );
    }
    try {
      await _client.auth.signOut();
    } on AuthenticationException {
      rethrow;
    } on AuthException catch (e) {
      throw AuthenticationException(message: e.message);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }
}
