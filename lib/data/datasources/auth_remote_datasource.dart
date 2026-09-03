import 'package:flutter/foundation.dart';
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
    final cleanEmail = email.trim();
    debugPrint('🔐 [AuthRemoteDataSource] Attempting signInWithPassword for: $cleanEmail');
    try {
      final response = await client.auth.signInWithPassword(
        email: cleanEmail,
        password: password,
      );
      debugPrint('✅ [AuthRemoteDataSource] signInWithPassword succeeded for user: ${response.user?.id}, email: ${response.user?.email}');
      return response;
    } catch (e) {
      debugPrint('❌ [AuthRemoteDataSource] signInWithPassword failed for $cleanEmail: $e');
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    final cleanEmail = email.trim();
    debugPrint('📝 [AuthRemoteDataSource] Attempting signUp for: $cleanEmail');
    try {
      final response = await client.auth.signUp(
        email: cleanEmail,
        password: password,
        data: name != null ? {'name': name.trim()} : null,
      );
      debugPrint('✅ [AuthRemoteDataSource] signUp succeeded for user: ${response.user?.id}');
      return response;
    } catch (e) {
      debugPrint('❌ [AuthRemoteDataSource] signUp failed for $cleanEmail: $e');
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
