import 'dart:io';
import '../../domain/entities/employee_summary.dart';
import '../../domain/entities/profile.dart';

abstract class ProfileRepository {
  Future<Profile?> getProfile(String userId);
  Future<Profile> updateProfile(Profile profile);
  Future<String> uploadAvatar(String userId, File imageFile);
  Future<void> deleteAvatar(String userId);
  Future<Profile> ensureProfileExists({
    required String userId,
    required String name,
    String? email,
  });
  Future<List<Profile>> getEmployees();
  Future<List<EmployeeSummary>> getEmployeesWithStats();

  // Admin User Management
  Future<Profile> createEmployee({
    required String email,
    required String password,
    required String fullName,
    String role = 'employee',
  });
  Future<void> deleteEmployee(String userId);
  Future<void> updateEmployeeRole(String userId, String role);
  Future<void> toggleEmployeeStatus(String userId, String status);
  Future<void> approveUser(String userId);
  Future<void> rejectUser(String userId);
}
