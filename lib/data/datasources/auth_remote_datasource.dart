import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/exception_mapper.dart';

abstract class AuthRemoteDataSource {
  User? get currentUser;
  Session? get currentSession;
  Stream<AuthState> get authStateChanges;

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  });

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? name,
  });

  Future<UserResponse> updatePassword(String newPassword);

  Future<void> signOut();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({required this.client});

  final SupabaseClient client;

  @override
  User? get currentUser => client.auth.currentUser;

  @override
  Session? get currentSession => client.auth.currentSession;

  @override
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  @override
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return response;
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      final response = await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: name != null ? {'name': name.trim()} : null,
      );
      return response;
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<UserResponse> updatePassword(String newPassword) async {
    try {
      final response = await client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return response;
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }
}
