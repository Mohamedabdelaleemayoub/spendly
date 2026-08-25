import 'package:flutter/foundation.dart';
import '../../core/services/uuid_generator.dart';
import '../../domain/entities/expense_currency.dart';
import '../../domain/entities/weekly_allowance_transaction.dart';
import '../../domain/entities/weekly_work_budget_summary.dart';
import '../../domain/repositories/weekly_allowance_repository.dart';
import '../datasources/local_database.dart';
import '../datasources/weekly_allowance_remote_datasource.dart';
import '../models/weekly_allowance_model.dart';

class WeeklyAllowanceRepositoryImpl implements WeeklyAllowanceRepository {
  WeeklyAllowanceRepositoryImpl({
    required this.remoteDataSource,
    this.localDatabase,
  });

  final WeeklyAllowanceRemoteDataSource remoteDataSource;
  final LocalDatabase? localDatabase;

  @override
  Future<List<WeeklyAllowanceTransaction>> getWeeklyAllowanceTransactions({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final remote = await remoteDataSource.getWeeklyAllowanceTransactions(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );
      if (localDatabase != null && localDatabase!.isInitialized) {
        await localDatabase!.saveAllowanceTransactions(remote);
      }
      return remote;
    } catch (e) {
      debugPrint('⚠️ [WeeklyAllowanceRepositoryImpl] Remote getWeeklyAllowanceTransactions failed ($e), loading offline from local DB.');
      if (localDatabase != null && localDatabase!.isInitialized) {
        return await localDatabase!.getAllowanceTransactions(
          userId: userId,
          startDate: startDate,
          endDate: endDate,
        );
      }
      return [];
    }
  }

  @override
  Future<WeeklyWorkBudgetSummary> getWeeklyWorkBudgetSummary({
    String? userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final summary = await remoteDataSource.getWeeklyWorkBudgetSummary(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );
      return summary;
    } catch (e) {
      debugPrint('⚠️ [WeeklyAllowanceRepositoryImpl] Remote getWeeklyWorkBudgetSummary failed ($e), computing offline from local DB.');
      if (localDatabase != null && localDatabase!.isInitialized) {
        return await _calculateOfflineWeeklyBudget(
          userId: userId,
          startDate: startDate,
          endDate: endDate,
        );
      }
      return WeeklyWorkBudgetSummary(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
        receivedEgp: 0.0,
        spentEgp: 0.0,
        receivedUsd: 0.0,
        spentUsd: 0.0,
      );
    }
  }

  Future<WeeklyWorkBudgetSummary> _calculateOfflineWeeklyBudget({
    String? userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = localDatabase!;
    final allowances = userId != null
        ? await db.getAllowanceTransactions(userId: userId, startDate: startDate, endDate: endDate)
        : await db.getAllAllowanceTransactions();

    final expenses = await db.getExpenses(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );

    double receivedEgp = 0.0;
    double receivedUsd = 0.0;
    for (final all in allowances) {
      if (all.currency == ExpenseCurrency.usd) {
        receivedUsd += all.amount;
      } else {
        receivedEgp += all.amount;
      }
    }

    double spentEgp = 0.0;
    double spentUsd = 0.0;
    for (final exp in expenses) {
      if (exp.currency == ExpenseCurrency.usd) {
        spentUsd += exp.amount;
      } else {
        spentEgp += exp.amount;
      }
    }

    return WeeklyWorkBudgetSummary(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
      receivedEgp: receivedEgp,
      spentEgp: spentEgp,
      receivedUsd: receivedUsd,
      spentUsd: spentUsd,
    );
  }

  @override
  Future<WeeklyAllowanceTransaction> createAllowanceTransaction({
    required String userId,
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    required DateTime transactionDate,
    String? note,
  }) async {
    final clientTxId = UuidGenerator.generate();
    final now = DateTime.now();

    final localModel = WeeklyAllowanceModel(
      id: clientTxId,
      userId: userId,
      amount: amount,
      currency: currency,
      transactionDate: transactionDate,
      note: note,
      createdBy: '',
      createdAt: now,
      updatedAt: now,
    );

    if (localDatabase != null && localDatabase!.isInitialized) {
      await localDatabase!.saveAllowanceTransaction(localModel);
    }

    try {
      final remote = await remoteDataSource.createAllowanceTransaction(
        id: clientTxId,
        userId: userId,
        amount: amount,
        currency: currency,
        transactionDate: transactionDate,
        note: note,
      );
      if (localDatabase != null && localDatabase!.isInitialized) {
        await localDatabase!.saveAllowanceTransaction(remote);
      }
      return remote;
    } catch (e) {
      debugPrint('⚠️ [WeeklyAllowanceRepositoryImpl] Remote create allowance failed ($e), queued locally.');
      if (localDatabase != null && localDatabase!.isInitialized) {
        await localDatabase!.enqueueSyncOperation(
          operationId: UuidGenerator.generate(),
          entityType: 'allowance_transaction',
          entityId: clientTxId,
          operation: 'INSERT',
          payload: {
            'id': clientTxId,
            'user_id': userId,
            'amount': amount,
            'currency': currency.code,
            'transaction_date': transactionDate.toIso8601String().split('T').first,
            if (note != null && note.isNotEmpty) 'note': note,
          },
        );
      }
      return localModel;
    }
  }

  @override
  Future<WeeklyAllowanceTransaction> updateAllowanceTransaction({
    required String id,
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    required DateTime transactionDate,
    String? note,
  }) async {
    String existingUserId = '';
    String existingCreatedBy = '';
    DateTime? existingCreatedAt;
    if (localDatabase != null && localDatabase!.isInitialized) {
      final existingList = await localDatabase!.getAllAllowanceTransactions();
      final existing = existingList.where((item) => item.id == id).firstOrNull;
      if (existing != null) {
        existingUserId = existing.userId;
        existingCreatedBy = existing.createdBy;
        existingCreatedAt = existing.createdAt;
      }
    }

    final localModel = WeeklyAllowanceModel(
      id: id,
      userId: existingUserId,
      amount: amount,
      currency: currency,
      transactionDate: transactionDate,
      note: note,
      createdBy: existingCreatedBy,
      createdAt: existingCreatedAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (localDatabase != null && localDatabase!.isInitialized) {
      await localDatabase!.saveAllowanceTransaction(localModel);
    }

    try {
      final remote = await remoteDataSource.updateAllowanceTransaction(
        id: id,
        amount: amount,
        currency: currency,
        transactionDate: transactionDate,
        note: note,
      );
      if (localDatabase != null && localDatabase!.isInitialized) {
        await localDatabase!.saveAllowanceTransaction(remote);
      }
      return remote;
    } catch (e) {
      debugPrint('⚠️ [WeeklyAllowanceRepositoryImpl] Remote update allowance failed ($e), queued locally.');
      if (localDatabase != null && localDatabase!.isInitialized) {
        await localDatabase!.enqueueSyncOperation(
          operationId: UuidGenerator.generate(),
          entityType: 'allowance_transaction',
          entityId: id,
          operation: 'UPDATE',
          payload: {
            'id': id,
            'amount': amount,
            'currency': currency.code,
            'transaction_date': transactionDate.toIso8601String().split('T').first,
            'note': note,
          },
        );
      }
      return localModel;
    }
  }

  @override
  Future<void> deleteAllowanceTransaction(String id) async {
    if (localDatabase != null && localDatabase!.isInitialized) {
      await localDatabase!.deleteAllowanceTransaction(id);
    }

    try {
      await remoteDataSource.deleteAllowanceTransaction(id);
    } catch (e) {
      debugPrint('⚠️ [WeeklyAllowanceRepositoryImpl] Remote delete allowance failed ($e), enqueued in sync queue.');
      if (localDatabase != null && localDatabase!.isInitialized) {
        await localDatabase!.enqueueSyncOperation(
          operationId: UuidGenerator.generate(),
          entityType: 'allowance_transaction',
          entityId: id,
          operation: 'DELETE',
          payload: {'id': id},
        );
      }
    }
  }
}
