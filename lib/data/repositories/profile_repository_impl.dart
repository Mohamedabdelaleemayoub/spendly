import 'dart:io';
import '../../domain/entities/employee_summary.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';
import '../models/profile_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({required this.remoteDataSource});

  final ProfileRemoteDataSource remoteDataSource;

  @override
  Future<Profile?> getProfile(String userId) {
    return remoteDataSource.getProfile(userId);
  }

  @override
  Future<Profile> updateProfile(Profile profile) {
    return remoteDataSource.updateProfile(ProfileModel.fromEntity(profile));
  }

  @override
  Future<String> uploadAvatar(String userId, File imageFile) {
    return remoteDataSource.uploadAvatar(userId, imageFile);
  }

  @override
  Future<void> deleteAvatar(String userId) {
    return remoteDataSource.deleteAvatar(userId);
  }

  @override
  Future<Profile> ensureProfileExists({
    required String userId,
    required String name,
    String? email,
  }) {
    return remoteDataSource.ensureProfileExists(
      userId: userId,
      name: name,
      email: email,
    );
  }

  @override
  Future<List<Profile>> getEmployees() {
    return remoteDataSource.getEmployees();
  }

  @override
  Future<List<EmployeeSummary>> getEmployeesWithStats() {
    return remoteDataSource.getEmployeesWithStats();
  }

  @override
  Future<Profile> createEmployee({
    required String email,
    required String password,
    required String fullName,
    String role = 'employee',
  }) {
    return remoteDataSource.createEmployee(
      email: email,
      password: password,
      fullName: fullName,
      role: role,
    );
  }

  @override
  Future<void> deleteEmployee(String userId) {
    return remoteDataSource.deleteEmployee(userId);
  }

  @override
  Future<void> updateEmployeeRole(String userId, String role) {
    return remoteDataSource.updateEmployeeRole(userId, role);
  }

  @override
  Future<void> toggleEmployeeStatus(String userId, String status) {
    return remoteDataSource.toggleEmployeeStatus(userId, status);
  }
}
