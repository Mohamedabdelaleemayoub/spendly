import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_failure.dart';
import '../../core/errors/exception_mapper.dart';
import '../../domain/entities/employee_summary.dart';
import '../models/profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<ProfileModel?> getProfile(String userId);
  Future<ProfileModel> updateProfile(ProfileModel profile);
  Future<String> uploadAvatar(String userId, File imageFile);
  Future<ProfileModel> updateAvatarUrl(String userId, String? avatarUrl);
  Future<void> deleteAvatar(String userId);
  Future<ProfileModel> ensureProfileExists({
    required String userId,
    required String name,
    String? email,
  });
  Future<List<ProfileModel>> getEmployees();
  Future<List<EmployeeSummary>> getEmployeesWithStats();

  // Admin User Management
  Future<ProfileModel> createEmployee({
    required String email,
    required String password,
    required String fullName,
    String role = 'employee',
  });
  Future<void> deleteEmployee(String userId);
  Future<void> updateEmployeeRole(String userId, String role);
  Future<void> toggleEmployeeStatus(String userId, String status);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  ProfileRemoteDataSourceImpl({required this.client});

  final SupabaseClient client;

  @override
  Future<ProfileModel?> getProfile(String userId) async {
    try {
      final response = await client
          .from(AppConstants.profilesTable)
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      return ProfileModel.fromJson(response);
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<ProfileModel> updateProfile(ProfileModel profile) async {
    try {
      final response = await client
          .from(AppConstants.profilesTable)
          .update({
            'full_name': profile.name,
            if (profile.avatarUrl != null) 'avatar_url': profile.avatarUrl,
          })
          .eq('id', profile.id)
          .select()
          .single();

      return ProfileModel.fromJson(response);
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<String> uploadAvatar(String userId, File imageFile) async {
    try {
      final ext = imageFile.path.split('.').last.toLowerCase();
      final path = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';

      await client.storage.from(AppConstants.profileImagesBucket).upload(
            path,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl =
          client.storage.from(AppConstants.profileImagesBucket).getPublicUrl(path);

      await updateAvatarUrl(userId, publicUrl);
      return publicUrl;
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<ProfileModel> updateAvatarUrl(String userId, String? avatarUrl) async {
    try {
      final response = await client
          .from(AppConstants.profilesTable)
          .update({'avatar_url': avatarUrl})
          .eq('id', userId)
          .select()
          .single();

      return ProfileModel.fromJson(response);
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<void> deleteAvatar(String userId) async {
    try {
      await updateAvatarUrl(userId, null);
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<ProfileModel> ensureProfileExists({
    required String userId,
    required String name,
    String? email,
  }) async {
    try {
      final existing = await getProfile(userId);
      if (existing != null) return existing;

      final insertData = <String, dynamic>{
        'id': userId,
        'full_name': name,
        'role': AppConstants.roleEmployee,
        'status': 'active',
      };
      if (email != null) insertData['email'] = email;

      try {
        final response = await client
            .from(AppConstants.profilesTable)
            .upsert(insertData)
            .select()
            .single();

        return ProfileModel.fromJson(response);
      } catch (e) {
        // Fallback without status if DB column does not exist yet
        insertData.remove('status');
        final response = await client
            .from(AppConstants.profilesTable)
            .upsert(insertData)
            .select()
            .single();

        return ProfileModel.fromJson(response);
      }
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<List<ProfileModel>> getEmployees() async {
    try {
      final response = await client
          .from(AppConstants.profilesTable)
          .select()
          .order('full_name', ascending: true);

      return (response as List<dynamic>)
          .map((json) => ProfileModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<List<EmployeeSummary>> getEmployeesWithStats() async {
    try {
      // 1. Fetch all profiles (allowed by Admin RLS)
      final profilesResponse = await client
          .from(AppConstants.profilesTable)
          .select()
          .order('full_name', ascending: true);

      final profiles = (profilesResponse as List<dynamic>)
          .map((json) => ProfileModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // 2. Fetch all expenses in bulk to aggregate
      final expensesResponse = await client
          .from(AppConstants.expensesTable)
          .select('user_id, amount, expense_date');

      final userTotals = <String, double>{};
      final userCounts = <String, int>{};
      final userLastDate = <String, DateTime>{};

      for (final item in (expensesResponse as List<dynamic>)) {
        final userId = item['user_id'] as String?;
        if (userId == null) continue;

        final rawAmount = item['amount'];
        final amount = rawAmount is num
            ? rawAmount.toDouble()
            : double.tryParse(rawAmount?.toString() ?? '0') ?? 0.0;

        userTotals[userId] = (userTotals[userId] ?? 0.0) + amount;
        userCounts[userId] = (userCounts[userId] ?? 0) + 1;

        final dateStr = item['expense_date'] as String?;
        if (dateStr != null) {
          final parsedDate = DateTime.tryParse(dateStr);
          if (parsedDate != null) {
            final currentLast = userLastDate[userId];
            if (currentLast == null || parsedDate.isAfter(currentLast)) {
              userLastDate[userId] = parsedDate;
            }
          }
        }
      }

      return profiles.map((profile) {
        return EmployeeSummary(
          profile: profile,
          totalExpenses: userTotals[profile.id] ?? 0.0,
          expensesCount: userCounts[profile.id] ?? 0,
          lastExpenseDate: userLastDate[profile.id],
        );
      }).toList();
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  // ── Admin User Management ────────────────────────────────────────────────

  @override
  Future<ProfileModel> createEmployee({
    required String email,
    required String password,
    required String fullName,
    String role = 'employee',
  }) async {
    try {
      final res = await client.functions.invoke(
        'admin-create-user',
        body: {
          'email': email,
          'password': password,
          'full_name': fullName,
          'role': role,
        },
      );

      final data = res.data;
      if (res.status != 200) {
        final errMsg = data is Map ? data['error'] : 'Failed to create user';
        throw ServerFailure(errMsg?.toString() ?? 'Failed to create user');
      }

      if (data is Map && data['user'] != null) {
        return ProfileModel.fromJson(data['user'] as Map<String, dynamic>);
      }

      // Fallback reload
      final profile = await getProfile(data['id'] ?? '');
      if (profile != null) return profile;
      throw const ServerFailure('User created but failed to load profile');
    } catch (e) {
      if (e is Failure) rethrow;
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<void> deleteEmployee(String userId) async {
    try {
      final res = await client.functions.invoke(
        'admin-delete-user',
        body: {'user_id': userId},
      );

      if (res.status != 200) {
        final data = res.data;
        final errMsg = data is Map ? data['error'] : 'Failed to delete user';
        throw ServerFailure(errMsg?.toString() ?? 'Failed to delete user');
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<void> updateEmployeeRole(String userId, String role) async {
    try {
      // First attempt Edge Function
      final res = await client.functions.invoke(
        'admin-update-user-role',
        body: {'user_id': userId, 'role': role},
      );

      if (res.status != 200) {
        // Fallback to direct client update protected by RLS trigger
        await client
            .from(AppConstants.profilesTable)
            .update({'role': role})
            .eq('id', userId);
      }
    } catch (_) {
      // Fallback to direct client update protected by protect_profile_role() trigger
      try {
        await client
            .from(AppConstants.profilesTable)
            .update({'role': role})
            .eq('id', userId);
      } catch (e) {
        throw mapExceptionToFailure(e);
      }
    }
  }

  @override
  Future<void> toggleEmployeeStatus(String userId, String status) async {
    try {
      // First attempt Edge Function
      final res = await client.functions.invoke(
        'admin-toggle-user-status',
        body: {'user_id': userId, 'status': status},
      );

      if (res.status != 200) {
        // Fallback to direct update protected by RLS trigger
        await client
            .from(AppConstants.profilesTable)
            .update({'status': status})
            .eq('id', userId);
      }
    } catch (_) {
      try {
        await client
            .from(AppConstants.profilesTable)
            .update({'status': status})
            .eq('id', userId);
      } catch (e) {
        throw mapExceptionToFailure(e);
      }
    }
  }
}
