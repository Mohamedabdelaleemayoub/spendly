import 'package:flutter/foundation.dart';
import '../../core/services/uuid_generator.dart';
import '../../domain/entities/expense_currency.dart';
import '../../domain/entities/salary_advance.dart';
import '../../domain/repositories/salary_advance_repository.dart';
import '../datasources/local_database.dart';
import '../datasources/salary_advance_remote_datasource.dart';
import '../models/profile_model.dart';
import '../models/salary_advance_model.dart';

class SalaryAdvanceRepositoryImpl implements SalaryAdvanceRepository {
  SalaryAdvanceRepositoryImpl({
    required this.remoteDataSource,
    this.localDatabase,
  });

  final SalaryAdvanceRemoteDataSource remoteDataSource;
  final LocalDatabase? localDatabase;

  @override
  Future<List<SalaryAdvance>> getSalaryAdvances(String userId) async {
    try {
      final remote = await remoteDataSource.getSalaryAdvances(userId);
      if (localDatabase != null && localDatabase!.isInitialized) {
        await localDatabase!.saveSalaryAdvances(remote);
      }
      return remote;
    } catch (e) {
      debugPrint('⚠️ [SalaryAdvanceRepositoryImpl] Remote getSalaryAdvances failed ($e), loading from local DB.');
      if (localDatabase != null && localDatabase!.isInitialized) {
        return await localDatabase!.getSalaryAdvances(userId);
      }
      return [];
    }
  }

  @override
  Future<List<SalaryAdvance>> getAllSalaryAdvances() async {
    try {
      final remote = await remoteDataSource.getAllSalaryAdvances();
      if (localDatabase != null && localDatabase!.isInitialized) {
        await localDatabase!.saveSalaryAdvances(remote);
      }
      return remote;
    } catch (e) {
      debugPrint('⚠️ [SalaryAdvanceRepositoryImpl] Remote getAllSalaryAdvances failed ($e), loading from local DB.');
      if (localDatabase != null && localDatabase!.isInitialized) {
        return await localDatabase!.getAllSalaryAdvances();
      }
      return [];
    }
  }

  @override
  Future<SalaryAdvance> createSalaryAdvance({
    required String userId,
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    required DateTime advanceDate,
    String? note,
  }) async {
    final clientAdvanceId = UuidGenerator.generate();
    final now = DateTime.now();

    final localModel = SalaryAdvanceModel(
      id: clientAdvanceId,
      userId: userId,
      amount: amount,
      currency: currency,
      advanceDate: advanceDate,
      note: note,
      createdBy: '',
      createdAt: now,
      updatedAt: now,
    );

    if (localDatabase != null && localDatabase!.isInitialized) {
      await localDatabase!.saveSalaryAdvance(localModel);
    }

    try {
      final remote = await remoteDataSource.createSalaryAdvance(
        id: clientAdvanceId,
        userId: userId,
        amount: amount,
        currency: currency,
        advanceDate: advanceDate,
        note: note,
      );
      if (localDatabase != null && localDatabase!.isInitialized) {
        await localDatabase!.saveSalaryAdvance(remote);
      }
      return remote;
    } catch (e) {
      debugPrint('⚠️ [SalaryAdvanceRepositoryImpl] Remote createSalaryAdvance failed ($e), queued locally.');
      if (localDatabase != null && localDatabase!.isInitialized) {
        await localDatabase!.enqueueSyncOperation(
          operationId: UuidGenerator.generate(),
          entityType: 'salary_advance',
          entityId: clientAdvanceId,
          operation: 'INSERT',
          payload: {
            'id': clientAdvanceId,
            'user_id': userId,
            'amount': amount,
            'currency': currency.code,
            'advance_date': advanceDate.toIso8601String().split('T').first,
            if (note != null && note.isNotEmpty) 'note': note,
          },
        );
      }
      return localModel;
    }
  }

  @override
  Future<SalaryAdvance> updateSalaryAdvance({
    required String id,
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    required DateTime advanceDate,
    String? note,
  }) async {
    String existingUserId = '';
    String existingCreatedBy = '';
    DateTime? existingCreatedAt;
    if (localDatabase != null && localDatabase!.isInitialized) {
      final existingList = await localDatabase!.getAllSalaryAdvances();
      final existing = existingList.where((item) => item.id == id).firstOrNull;
      if (existing != null) {
        existingUserId = existing.userId;
        existingCreatedBy = existing.createdBy;
        existingCreatedAt = existing.createdAt;
      }
    }

    final localModel = SalaryAdvanceModel(
      id: id,
      userId: existingUserId,
      amount: amount,
      currency: currency,
      advanceDate: advanceDate,
      note: note,
      createdBy: existingCreatedBy,
      createdAt: existingCreatedAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (localDatabase != null && localDatabase!.isInitialized) {
      await localDatabase!.saveSalaryAdvance(localModel);
    }

    try {
      final remote = await remoteDataSource.updateSalaryAdvance(
        id: id,
        amount: amount,
        currency: currency,
        advanceDate: advanceDate,
        note: note,
      );
      if (localDatabase != null && localDatabase!.isInitialized) {
        await localDatabase!.saveSalaryAdvance(remote);
      }
      return remote;
    } catch (e) {
      debugPrint('⚠️ [SalaryAdvanceRepositoryImpl] Remote updateSalaryAdvance failed ($e), queued locally.');
      if (localDatabase != null && localDatabase!.isInitialized) {
        await localDatabase!.enqueueSyncOperation(
          operationId: UuidGenerator.generate(),
          entityType: 'salary_advance',
          entityId: id,
          operation: 'UPDATE',
          payload: {
            'id': id,
            'amount': amount,
            'currency': currency.code,
            'advance_date': advanceDate.toIso8601String().split('T').first,
            'note': note,
          },
        );
      }
      return localModel;
    }
  }

  @override
  Future<void> deleteSalaryAdvance(String id) async {
    if (localDatabase != null && localDatabase!.isInitialized) {
      await localDatabase!.deleteSalaryAdvance(id);
    }

    try {
      await remoteDataSource.deleteSalaryAdvance(id);
    } catch (e) {
      debugPrint('⚠️ [SalaryAdvanceRepositoryImpl] Remote deleteSalaryAdvance failed ($e), enqueued in sync queue.');
      if (localDatabase != null && localDatabase!.isInitialized) {
        await localDatabase!.enqueueSyncOperation(
          operationId: UuidGenerator.generate(),
          entityType: 'salary_advance',
          entityId: id,
          operation: 'DELETE',
          payload: {'id': id},
        );
      }
    }
  }

  @override
  Future<void> updateEmployeeSalary({
    required String userId,
    required double salaryAmount,
    ExpenseCurrency salaryCurrency = ExpenseCurrency.egp,
  }) async {
    if (localDatabase != null && localDatabase!.isInitialized) {
      final prof = await localDatabase!.getProfile(userId);
      if (prof != null) {
        await localDatabase!.saveProfile(ProfileModel.fromEntity(prof.copyWith(
          salaryAmount: salaryAmount,
          salaryCurrency: salaryCurrency,
        )));
      }
    }

    try {
      await remoteDataSource.updateEmployeeSalary(
        userId: userId,
        salaryAmount: salaryAmount,
        salaryCurrency: salaryCurrency,
      );
    } catch (e) {
      debugPrint('⚠️ [SalaryAdvanceRepositoryImpl] Remote updateEmployeeSalary failed ($e), updated locally.');
      if (localDatabase != null && localDatabase!.isInitialized) {
        await localDatabase!.enqueueSyncOperation(
          operationId: UuidGenerator.generate(),
          entityType: 'profile',
          entityId: userId,
          operation: 'UPDATE',
          payload: {
            'id': userId,
            'salary_amount': salaryAmount,
            'salary_currency': salaryCurrency.code,
          },
        );
      }
    }
  }
}
