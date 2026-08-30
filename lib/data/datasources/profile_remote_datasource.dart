import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  Future<void> approveUser(String userId);
  Future<void> rejectUser(String userId);
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

      // 2. Fetch all expenses in bulk to aggregate lifetime and weekly stats
      dynamic expensesResponse;
      try {
        expensesResponse = await client
            .from(AppConstants.expensesTable)
            .select('user_id, amount, currency, expense_date');
      } catch (_) {
        // Fallback if currency column doesn't exist yet
        try {
          expensesResponse = await client
              .from(AppConstants.expensesTable)
              .select('user_id, amount, expense_date');
        } catch (_) {
          expensesResponse = [];
        }
      }

      final userTotals = <String, double>{};
      final userCounts = <String, int>{};
      final userLastDate = <String, DateTime>{};
      final userWeeklySpentEgp = <String, double>{};
      final userWeeklySpentUsd = <String, double>{};

      // Determine this week range (Monday to Sunday)
      final now = DateTime.now();
      final monday = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - DateTime.monday));
      final sunday = monday.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

      for (final item in (expensesResponse as List<dynamic>)) {
        final userId = item['user_id'] as String?;
        if (userId == null) continue;

        final rawAmount = item['amount'];
        final amount = rawAmount is num
            ? rawAmount.toDouble()
            : double.tryParse(rawAmount?.toString() ?? '0') ?? 0.0;
        final curr = item['currency'] as String? ?? 'EGP';

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

            final expDay = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
            final mDay = DateTime(monday.year, monday.month, monday.day);
            final sDay = DateTime(sunday.year, sunday.month, sunday.day);
            if (!expDay.isBefore(mDay) && !expDay.isAfter(sDay)) {
              if (curr == 'USD') {
                userWeeklySpentUsd[userId] = (userWeeklySpentUsd[userId] ?? 0.0) + amount;
              } else {
                userWeeklySpentEgp[userId] = (userWeeklySpentEgp[userId] ?? 0.0) + amount;
              }
            }
          }
        }
      }

      // 3. Fetch all salary advances to aggregate advances per employee
      final userAdvances = <String, double>{};
      try {
        final advancesResponse = await client
            .from(AppConstants.salaryAdvancesTable)
            .select('user_id, amount');

        for (final item in (advancesResponse as List<dynamic>)) {
          final userId = item['user_id'] as String?;
          if (userId == null) continue;

          final rawAmount = item['amount'];
          final amount = rawAmount is num
              ? rawAmount.toDouble()
              : double.tryParse(rawAmount?.toString() ?? '0') ?? 0.0;

          userAdvances[userId] = (userAdvances[userId] ?? 0.0) + amount;
        }
      } catch (_) {
        // Table might not exist yet during migration tests
      }

      // 4. Fetch this week allowance transactions to aggregate weekly received
      final userWeeklyReceivedEgp = <String, double>{};
      final userWeeklyReceivedUsd = <String, double>{};
      try {
        final monStr =
            '${monday.year.toString().padLeft(4, '0')}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
        final sunStr =
            '${sunday.year.toString().padLeft(4, '0')}-${sunday.month.toString().padLeft(2, '0')}-${sunday.day.toString().padLeft(2, '0')}';

        final allowanceResponse = await client
            .from(AppConstants.allowanceTransactionsTable)
            .select('user_id, amount, currency, transaction_date')
            .gte('transaction_date', monStr)
            .lte('transaction_date', sunStr);

        for (final item in (allowanceResponse as List<dynamic>)) {
          final userId = item['user_id'] as String?;
          if (userId == null) continue;

          final rawAmount = item['amount'];
          final amount = rawAmount is num
              ? rawAmount.toDouble()
              : double.tryParse(rawAmount?.toString() ?? '0') ?? 0.0;
          final curr = item['currency'] as String? ?? 'EGP';

          if (curr == 'USD') {
            userWeeklyReceivedUsd[userId] = (userWeeklyReceivedUsd[userId] ?? 0.0) + amount;
          } else {
            userWeeklyReceivedEgp[userId] = (userWeeklyReceivedEgp[userId] ?? 0.0) + amount;
          }
        }
      } catch (_) {
        // Table might not exist yet
      }

      return profiles.map((profile) {
        return EmployeeSummary(
          profile: profile,
          totalExpenses: userTotals[profile.id] ?? 0.0,
          expensesCount: userCounts[profile.id] ?? 0,
          lastExpenseDate: userLastDate[profile.id],
          totalAdvances: userAdvances[profile.id] ?? 0.0,
          weeklyReceivedEgp: userWeeklyReceivedEgp[profile.id] ?? 0.0,
          weeklySpentEgp: userWeeklySpentEgp[profile.id] ?? 0.0,
          weeklyReceivedUsd: userWeeklyReceivedUsd[profile.id] ?? 0.0,
          weeklySpentUsd: userWeeklySpentUsd[profile.id] ?? 0.0,
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
      if (res.status == 200) {
        if (data is Map && data['user'] != null) {
          return ProfileModel.fromJson(data['user'] as Map<String, dynamic>);
        }
        if (data is Map && data['id'] != null) {
          final profile = await getProfile(data['id'].toString());
          if (profile != null) return profile;
        }
      }
    } catch (e) {
      debugPrint('ℹ️ [ProfileRemoteDataSource] admin-create-user edge function failed ($e), using isolated auth fallback.');
    }

    // Direct Auth Sign-Up Fallback (isolated SupabaseClient preserving Admin session)
    try {
      final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
      final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
      final isolatedAuthClient = SupabaseClient(supabaseUrl, supabaseAnonKey);

      final authResponse = await isolatedAuthClient.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
          'role': role,
        },
      );

      final createdUser = authResponse.user;
      if (createdUser == null) {
        throw const ServerFailure('فشل إنشاء حساب المستخدم في خادم المصادقة');
      }

      // Activate and ensure role & full_name in profiles table
      try {
        await client.from(AppConstants.profilesTable).upsert({
          'id': createdUser.id,
          'email': email.trim(),
          'full_name': fullName.trim(),
          'role': role,
          'status': 'active',
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (upsertErr) {
        debugPrint('⚠️ [ProfileRemoteDataSource] Upsert profile after signup: $upsertErr');
      }

      final profile = await getProfile(createdUser.id);
      if (profile != null) return profile;

      return ProfileModel(
        id: createdUser.id,
        email: email.trim(),
        name: fullName.trim(),
        role: role,
        status: 'active',
        createdAt: DateTime.now(),
      );
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
        try {
          await client.from(AppConstants.profilesTable).delete().eq('id', userId);
        } catch (_) {
          await client.from(AppConstants.profilesTable).update({'status': 'inactive'}).eq('id', userId);
        }
      }
    } catch (e) {
      try {
        await client.from(AppConstants.profilesTable).delete().eq('id', userId);
      } catch (_) {
        try {
          await client.from(AppConstants.profilesTable).update({'status': 'inactive'}).eq('id', userId);
        } catch (inner) {
          throw mapExceptionToFailure(inner);
        }
      }
    }
  }

  @override
  Future<void> updateEmployeeRole(String userId, String role) async {
    try {
      final res = await client.functions.invoke(
        'admin-update-user-role',
        body: {'user_id': userId, 'role': role},
      );

      if (res.status != 200) {
        await client
            .from(AppConstants.profilesTable)
            .update({'role': role})
            .eq('id', userId);
      }
    } catch (_) {
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
      final res = await client.functions.invoke(
        'admin-toggle-user-status',
        body: {'user_id': userId, 'status': status},
      );

      if (res.status != 200) {
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

  @override
  Future<void> approveUser(String userId) async {
    await toggleEmployeeStatus(userId, 'active');
  }

  @override
  Future<void> rejectUser(String userId) async {
    await toggleEmployeeStatus(userId, 'rejected');
  }
}
