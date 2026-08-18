import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../../core/errors/app_failure.dart';
import '../../../domain/entities/profile.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/profile_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required this.authRepository,
    required this.profileRepository,
  }) : super(const AuthInitial()) {
    _init();
  }

  final AuthRepository authRepository;
  final ProfileRepository profileRepository;
  StreamSubscription? _authSubscription;

  @override
  void emit(AuthState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }

  void _init() async {
    final session = authRepository.currentSession;
    final user = authRepository.currentUser;

    if (session != null && user != null) {
      await _processUserSession(user, session);
    } else {
      emit(const Unauthenticated());
    }

    _authSubscription = authRepository.authStateChanges.listen((data) async {
      final session = data.session;
      final user = session?.user;

      if (user != null) {
        await _processUserSession(user, session);
      } else {
        emit(const Unauthenticated());
      }
    });
  }

  Future<void> _processUserSession(User user, Session? session) async {
    Profile? profile;
    try {
      profile = await profileRepository.getProfile(user.id);
    } catch (_) {}

    if (profile == null) {
      // Fallback: Ensure profile is created
      try {
        profile = await profileRepository.ensureProfileExists(
          userId: user.id,
          name: user.email?.split('@').first ?? 'مستخدم',
          email: user.email,
        );
      } catch (_) {}
    }

    if (profile != null) {
      if (profile.isInactive) {
        await authRepository.signOut();
        emit(const AuthError('هذا الحساب غير مفعل. يرجى التواصل مع المسؤول.'));
        return;
      }

      if (profile.isPending) {
        emit(AuthPendingApproval(user: user, profile: profile, session: session));
        return;
      }

      if (profile.isRejected) {
        emit(AuthRejected(user: user, profile: profile, session: session));
        return;
      }
    }

    emit(Authenticated(user: user, profile: profile, session: session));
  }

  Future<void> reloadProfile() async {
    final user = authRepository.currentUser;
    final session = authRepository.currentSession;
    if (user != null) {
      try {
        final profile = await profileRepository.getProfile(user.id);
        if (profile != null) {
          if (profile.isInactive) {
            await authRepository.signOut();
            emit(const AuthError('هذا الحساب غير مفعل. يرجى التواصل مع المسؤول.'));
            return;
          }
          if (profile.isPending) {
            emit(AuthPendingApproval(user: user, profile: profile, session: session));
            return;
          }
          if (profile.isRejected) {
            emit(AuthRejected(user: user, profile: profile, session: session));
            return;
          }
          emit(Authenticated(user: user, profile: profile, session: session));
        }
      } catch (_) {}
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());
    try {
      final response = await authRepository.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user != null) {
        await _processUserSession(user, response.session);
      } else {
        emit(const Unauthenticated());
      }
    } on Failure catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError('فشل تسجيل الدخول: $e'));
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    emit(const AuthLoading());
    try {
      final response = await authRepository.signUp(
        email: email,
        password: password,
        name: name,
      );

      final user = response.user;
      if (user != null) {
        // Ensure profile exists in profiles table
        Profile? profile;
        try {
          profile = await profileRepository.ensureProfileExists(
            userId: user.id,
            name: name ?? user.email?.split('@').first ?? 'مستخدم',
            email: user.email,
          );
        } catch (_) {}

        final isConfirmed = response.session != null;
        final isPending = profile?.isPending ?? false;

        emit(AuthSignUpSuccess(
          user: user,
          isConfirmed: isConfirmed,
          isPending: isPending,
        ));

        if (isConfirmed) {
          await _processUserSession(user, response.session);
        }
      } else {
        emit(const Unauthenticated());
      }
    } on Failure catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError('فشل إنشاء الحساب: $e'));
    }
  }

  /// Securely re-authenticates the current user and updates the password via Supabase Auth.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = authRepository.currentUser;
    if (user == null || user.email == null) {
      throw const AuthFailure('جلسة المستخدم غير صالحة، يرجى إعادة تسجيل الدخول.');
    }

    // Step 1: Re-authenticate to verify current password
    try {
      await authRepository.signInWithPassword(
        email: user.email!,
        password: currentPassword,
      );
    } catch (e) {
      throw const AuthFailure('كلمة المرور الحالية غير صحيحة.');
    }

    // Step 2: Update user with new password
    try {
      await authRepository.updatePassword(newPassword);
    } on Failure {
      rethrow;
    } catch (e) {
      throw AuthFailure('فشل تحديث كلمة المرور: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await authRepository.signOut();
      emit(const Unauthenticated());
    } on Failure catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError('فشل تسجيل الخروج: $e'));
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
