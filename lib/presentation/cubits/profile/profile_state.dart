import 'package:equatable/equatable.dart';
import '../../../domain/entities/profile.dart';

sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  const ProfileLoaded(this.profile);

  final Profile profile;

  @override
  List<Object?> get props => [profile];
}

class ProfileUpdating extends ProfileState {
  const ProfileUpdating(this.currentProfile);

  final Profile currentProfile;

  @override
  List<Object?> get props => [currentProfile];
}

class ProfileUpdated extends ProfileState {
  const ProfileUpdated(this.profile);

  final Profile profile;

  @override
  List<Object?> get props => [profile];
}

class ProfileError extends ProfileState {
  const ProfileError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
