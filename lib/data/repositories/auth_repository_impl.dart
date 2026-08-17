import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this.remoteDataSource});

  final AuthRemoteDataSource remoteDataSource;

  @override
  User? get currentUser => remoteDataSource.currentUser;

  @override
  Session? get currentSession => remoteDataSource.currentSession;

  @override
  Stream<AuthState> get authStateChanges => remoteDataSource.authStateChanges;

  @override
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return remoteDataSource.signInWithPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? name,
  }) {
    return remoteDataSource.signUp(
      email: email,
      password: password,
      name: name,
    );
  }

  @override
  Future<UserResponse> updatePassword(String newPassword) {
    return remoteDataSource.updatePassword(newPassword);
  }

  @override
  Future<void> signOut() {
    return remoteDataSource.signOut();
  }
}
