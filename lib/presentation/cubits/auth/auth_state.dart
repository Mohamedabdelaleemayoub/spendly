import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../domain/entities/profile.dart';
import '../../../domain/entities/user_role.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  const Authenticated({
    required this.user,
    this.profile,
    this.session,
  });

  final User user;
  final Profile? profile;
  final Session? session;

  UserRole get role => profile?.userRole ?? UserRole.employee;
  bool get isAdmin => role.isAdmin;
  bool get isEmployee => role.isEmployee;

  Authenticated copyWith({
    User? user,
    Profile? profile,
    Session? session,
  }) {
    return Authenticated(
      user: user ?? this.user,
      profile: profile ?? this.profile,
      session: session ?? this.session,
    );
  }

  @override
  List<Object?> get props => [user.id, profile, session?.accessToken];
}

class AuthPendingApproval extends AuthState {
  const AuthPendingApproval({
    required this.user,
    required this.profile,
    this.session,
  });

  final User user;
  final Profile profile;
  final Session? session;

  @override
  List<Object?> get props => [user.id, profile, session?.accessToken];
}

class AuthRejected extends AuthState {
  const AuthRejected({
    required this.user,
    required this.profile,
    this.session,
  });

  final User user;
  final Profile profile;
  final Session? session;

  @override
  List<Object?> get props => [user.id, profile, session?.accessToken];
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class AuthError extends AuthState {
  const AuthError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class AuthSignUpSuccess extends AuthState {
  const AuthSignUpSuccess({
    required this.user,
    required this.isConfirmed,
    this.isPending = false,
  });

  final User user;
  final bool isConfirmed;
  final bool isPending;

  @override
  List<Object?> get props => [user.id, isConfirmed, isPending];
}
