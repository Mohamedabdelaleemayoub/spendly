import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../core/services/uuid_generator.dart';
import '../../domain/entities/employee_summary.dart';
import '../../domain/entities/expense_currency.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/local_database.dart';
import '../datasources/profile_remote_datasource.dart';
import '../models/profile_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({
    required this.remoteDataSource,
    this.localDatabase,
  });

  final ProfileRemoteDataSource remoteDataSource;
  final LocalDatabase? localDatabase;

  @override
  Future<Profile?> getProfile(String userId) async {
    try {
      final remote = await remoteDataSource.getProfile(userId);
      if (remote != null && localDatabase != null && localDatabase!.isInitialized) {
        await localDatabase!.saveProfile(remote);
      }
      if (remote != null) return remote;
    } catch (e) {
      debugPrint('⚠️ [ProfileRepositoryImpl] Remote getProfile failed ($e), falling back to local DB.');
    }

    if (localDatabase != null && localDatabase!.isInitialized) {
      return await localDatabase!.getProfile(userId);
    }
    return null;
  }

  @override
  Future<Profile> updateProfile(Profile profile) async {
    final model = ProfileModel.fromEntity(profile);
    if (localDatabase != null && localDatabase!.isInitialized) {
      await localDatabase!.saveProfile(model);
    }

    try {
      final updated = await remoteDataSource.updateProfile(model);
      if (localDatabase != null && localDatabase!.isInitialized) {
        await localDatabase!.saveProfile(updated);
      }
      return updated;
    } catch (e) {
      debugPrint('⚠️ [ProfileRepositoryImpl] Remote updateProfile failed ($e), saved locally.');
      if (localDatabase != null && localDatabase!.isInitialized) {
        await localDatabase!.enqueueSyncOperation(
          operationId: UuidGenerator.generate(),
          entityType: 'profile',
          entityId: profile.id,
          operation: 'UPDATE',
          payload: {
            'id': profile.id,
            'full_name': profile.name,
            if (profile.avatarUrl != null) 'avatar_url': profile.avatarUrl,
          },
        );
      }
      return profile;
    }
  }

  @override
  Future<String> uploadAvatar(String userId, File imageFile) {
    return remoteDataSource.uploadAvatar(userId, imageFile);
  }

  @override
  Future<void> deleteAvatar(String userId) async {
    try {
      await remoteDataSource.deleteAvatar(userId);
    } catch (e) {
      debugPrint('⚠️ [ProfileRepositoryImpl] Remote deleteAvatar failed ($e).');
    }
  }

  @override
  Future<Profile> ensureProfileExists({
    required String userId,
    required String name,
    String? email,
  }) async {
    try {
      final remote = await remoteDataSource.ensureProfileExists(
        userId: userId,
        name: name,
        email: email,
      );
      if (localDatabase != null && localDatabase!.isInitialized) {
        await localDatabase!.saveProfile(remote);
      }
      return remote;
    } catch (e) {
      debugPrint('⚠️ [ProfileRepositoryImpl] Remote ensureProfileExists failed ($e), using local fallback.');
      final local = localDatabase != null && localDatabase!.isInitialized
          ? await localDatabase!.getProfile(userId)
          : null;

      if (local != null) return local;

      final fallback = ProfileModel(
        id: userId,
        email: email,
        name: name,
        role: 'employee',
        status: 'active',
        salaryAmount: 0.0,
        salaryCurrency: ExpenseCurrency.egp,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (localDatabase != null && localDatabase!.isInitialized) {
        await localDatabase!.saveProfile(fallback);
      }
      return fallback;
    }
  }

  @override
  Future<List<Profile>> getEmployees() async {
    try {
      final remote = await remoteDataSource.getEmployees();
      if (localDatabase != null && localDatabase!.isInitialized) {
        await localDatabase!.saveProfiles(remote);
      }
      return remote;
    } catch (e) {
      debugPrint('⚠️ [ProfileRepositoryImpl] Remote getEmployees failed ($e), falling back to local DB.');
      if (localDatabase != null && localDatabase!.isInitialized) {
        return await localDatabase!.getProfiles();
      }
      return [];
    }
  }

  @override
  Future<List<EmployeeSummary>> getEmployeesWithStats() async {
    try {
      final remote = await remoteDataSource.getEmployeesWithStats();
      if (localDatabase != null && localDatabase!.isInitialized) {
        final models = remote.map((s) => ProfileModel.fromEntity(s.profile)).toList();
        await localDatabase!.saveProfiles(models);
      }
      return remote;
    } catch (e) {
      debugPrint('⚠️ [ProfileRepositoryImpl] Remote getEmployeesWithStats failed ($e), calculating offline from local DB.');
      if (localDatabase != null && localDatabase!.isInitialized) {
        return await _calculateOfflineEmployeeStats();
      }
      return [];
    }
  }

  Future<List<EmployeeSummary>> _calculateOfflineEmployeeStats() async {
    final db = localDatabase!;
    final profiles = await db.getProfiles();
    final expenses = await db.getExpenses();
    final advances = await db.getAllSalaryAdvances();
    final allowances = await db.getAllAllowanceTransactions();

    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - DateTime.monday));
    final sunday = monday.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

    final userTotals = <String, double>{};
    final userCounts = <String, int>{};
    final userLastDate = <String, DateTime>{};
    final userWeeklySpentEgp = <String, double>{};
    final userWeeklySpentUsd = <String, double>{};

    for (final exp in expenses) {
      final userId = exp.userId;
      userTotals[userId] = (userTotals[userId] ?? 0.0) + exp.amount;
      userCounts[userId] = (userCounts[userId] ?? 0) + 1;

      final currentLast = userLastDate[userId];
      if (currentLast == null || exp.expenseDate.isAfter(currentLast)) {
        userLastDate[userId] = exp.expenseDate;
      }

      final expDay = DateTime(exp.expenseDate.year, exp.expenseDate.month, exp.expenseDate.day);
      final mDay = DateTime(monday.year, monday.month, monday.day);
      final sDay = DateTime(sunday.year, sunday.month, sunday.day);
      if (!allDayBefore(expDay, mDay) && !allDayAfter(expDay, sDay)) {
        if (exp.currency == ExpenseCurrency.usd) {
          userWeeklySpentUsd[userId] = (userWeeklySpentUsd[userId] ?? 0.0) + exp.amount;
        } else {
          userWeeklySpentEgp[userId] = (userWeeklySpentEgp[userId] ?? 0.0) + exp.amount;
        }
      }
    }

    final userAdvances = <String, double>{};
    for (final adv in advances) {
      userAdvances[adv.userId] = (userAdvances[adv.userId] ?? 0.0) + adv.amount;
    }

    final userWeeklyReceivedEgp = <String, double>{};
    final userWeeklyReceivedUsd = <String, double>{};
    for (final all in allowances) {
      final allDay = DateTime(all.transactionDate.year, all.transactionDate.month, all.transactionDate.day);
      final mDay = DateTime(monday.year, monday.month, monday.day);
      final sDay = DateTime(sunday.year, sunday.month, sunday.day);
      if (!allDayBefore(allDay, mDay) && !allDayAfter(allDay, sDay)) {
        if (all.currency == ExpenseCurrency.usd) {
          userWeeklyReceivedUsd[all.userId] = (userWeeklyReceivedUsd[all.userId] ?? 0.0) + all.amount;
        } else {
          userWeeklyReceivedEgp[all.userId] = (userWeeklyReceivedEgp[all.userId] ?? 0.0) + all.amount;
        }
      }
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
  }

  bool allDayBefore(DateTime a, DateTime b) => a.isBefore(b);
  bool allDayAfter(DateTime a, DateTime b) => a.isAfter(b);

  @override
  Future<Profile> createEmployee({
    required String email,
    required String password,
    required String fullName,
    String role = 'employee',
  }) async {
    final profile = await remoteDataSource.createEmployee(
      email: email,
      password: password,
      fullName: fullName,
      role: role,
    );
    if (localDatabase != null && localDatabase!.isInitialized) {
      await localDatabase!.saveProfile(profile);
    }
    return profile;
  }

  @override
  Future<void> deleteEmployee(String userId) async {
    await remoteDataSource.deleteEmployee(userId);
    if (localDatabase != null && localDatabase!.isInitialized) {
      await localDatabase!.deleteProfile(userId);
    }
  }

  @override
  Future<void> updateEmployeeRole(String userId, String role) async {
    await remoteDataSource.updateEmployeeRole(userId, role);
    if (localDatabase != null && localDatabase!.isInitialized) {
      final existing = await localDatabase!.getProfile(userId);
      if (existing != null) {
        await localDatabase!.saveProfile(ProfileModel.fromEntity(existing.copyWith(role: role)));
      }
    }
  }

  @override
  Future<void> toggleEmployeeStatus(String userId, String status) async {
    await remoteDataSource.toggleEmployeeStatus(userId, status);
    if (localDatabase != null && localDatabase!.isInitialized) {
      final existing = await localDatabase!.getProfile(userId);
      if (existing != null) {
        await localDatabase!.saveProfile(ProfileModel.fromEntity(existing.copyWith(status: status)));
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
