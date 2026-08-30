import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
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

  Future<bool> signInWithGoogle({String? redirectTo});

  Future<UserResponse> updatePassword(String newPassword);

  Future<void> signOut();
}
