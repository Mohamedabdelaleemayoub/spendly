import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/errors/app_failure.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/profile_repository.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required this.profileRepository,
    required this.authRepository,
  }) : super(const ProfileInitial());

  final ProfileRepository profileRepository;
  final AuthRepository authRepository;

  @override
  void emit(ProfileState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }

  Future<void> loadProfile() async {
    final user = authRepository.currentUser;
    if (user == null) {
      emit(const ProfileError('المستخدم غير مسجل'));
      return;
    }

    emit(const ProfileLoading());
    try {
      var profile = await profileRepository.getProfile(user.id);
      profile ??= await profileRepository.ensureProfileExists(
        userId: user.id,
        name: user.userMetadata?['name'] as String? ??
            user.email?.split('@').first ??
            'مستخدم',
        email: user.email,
      );
      emit(ProfileLoaded(profile));
    } on Failure catch (e) {
      emit(ProfileError(e.message));
    } catch (e) {
      emit(ProfileError('فشل تحميل الملف الشخصي: $e'));
    }
  }

  Future<void> updateName(String newName) async {
    final current = state;
    if (current is! ProfileLoaded) return;

    emit(ProfileUpdating(current.profile));
    try {
      final updated = await profileRepository.updateProfile(
        current.profile.copyWith(name: newName.trim()),
      );
      emit(ProfileUpdated(updated));
      emit(ProfileLoaded(updated));
    } on Failure catch (e) {
      emit(ProfileError(e.message));
      emit(ProfileLoaded(current.profile));
    } catch (e) {
      emit(ProfileError('فشل تعديل الاسم: $e'));
      emit(ProfileLoaded(current.profile));
    }
  }

  Future<void> uploadAvatar(File imageFile) async {
    final current = state;
    if (current is! ProfileLoaded) return;

    emit(ProfileUpdating(current.profile));
    try {
      final newUrl = await profileRepository.uploadAvatar(current.profile.id, imageFile);
      final updated = current.profile.copyWith(avatarUrl: newUrl);
      emit(ProfileUpdated(updated));
      emit(ProfileLoaded(updated));
    } on Failure catch (e) {
      emit(ProfileError(e.message));
      emit(ProfileLoaded(current.profile));
    } catch (e) {
      emit(ProfileError('فشل رفع الصورة: $e'));
      emit(ProfileLoaded(current.profile));
    }
  }

  Future<void> removeAvatar() async {
    final current = state;
    if (current is! ProfileLoaded) return;

    emit(ProfileUpdating(current.profile));
    try {
      await profileRepository.deleteAvatar(current.profile.id);
      final updated = current.profile.copyWith(avatarUrl: '');
      emit(ProfileUpdated(updated));
      emit(ProfileLoaded(updated));
    } on Failure catch (e) {
      emit(ProfileError(e.message));
      emit(ProfileLoaded(current.profile));
    } catch (e) {
      emit(ProfileError('فشل حذف الصورة: $e'));
      emit(ProfileLoaded(current.profile));
    }
  }
}
