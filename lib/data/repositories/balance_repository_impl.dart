import 'package:flutter/foundation.dart';
import '../../core/services/uuid_generator.dart';
import '../../domain/entities/balance_transaction.dart';
import '../../domain/entities/employee_balance_summary.dart';
import '../../domain/entities/expense_currency.dart';
import '../../domain/entities/financial_history_item.dart';
import '../../domain/repositories/balance_repository.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/balance_remote_datasource.dart';
import '../datasources/local_database.dart';
import '../datasources/local_expense_datasource.dart';
import '../models/balance_transaction_model.dart';

class BalanceRepositoryImpl implements BalanceRepository {
  BalanceRepositoryImpl({
    required this.remoteDataSource,
    required this.localExpenseDataSource,
    required this.expenseRepository,
    this.localDatabase,
  });

  final BalanceRemoteDataSource remoteDataSource;
  final LocalExpenseDataSource localExpenseDataSource;
  final ExpenseRepository expenseRepository;
  final LocalDatabase? localDatabase;

  @override
  Future<BalanceTransaction> addBalance({
    required String userId,
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    DateTime? transactionDate,
    String? note,
  }) async {
    final clientTxId = UuidGenerator.generate();
    final date = transactionDate ?? DateTime.now();

    final localModel = BalanceTransactionModel(
      id: clientTxId,
      userId: userId,
      amount: amount,
      currency: currency,
      type: BalanceTransactionType.credit,
      transactionDate: date,
      note: note,
      createdAt: DateTime.now(),
    );

    if (localDatabase != null && localDatabase!.isInitialized) {
      await localDatabase!.saveBalanceTransaction(localModel);
    }

    try {
      final remote = await remoteDataSource.addBalance(
        userId: userId,
        amount: amount,
        currency: currency,
        transactionDate: transactionDate,
        note: note,
      );
      if (localDatabase != null && localDatabase!.isInitialized) {
        await localDatabase!.saveBalanceTransaction(remote);
      }
      return remote;
    } catch (e) {
      debugPrint('⚠️ [BalanceRepositoryImpl] Remote addBalance failed ($e), queued locally.');
      if (localDatabase != null && localDatabase!.isInitialized) {
        await localDatabase!.enqueueSyncOperation(
          operationId: UuidGenerator.generate(),
          entityType: 'balance_transaction',
          entityId: clientTxId,
          operation: 'INSERT',
          payload: {
            'id': clientTxId,
            'user_id': userId,
            'amount': amount,
            'currency': currency.toDbString(),
            'type': BalanceTransactionType.credit.toDbString(),
            'transaction_date': date.toIso8601String().split('T').first,
            if (note != null && note.isNotEmpty) 'note': note,
          },
        );
      }
      return localModel;
    }
  }

  @override
  Future<EmployeeBalanceSummary> getEmployeeBalanceSummary(String userId) async {
    try {
      final summary = await remoteDataSource.getEmployeeBalanceSummary(userId);
      final pendingOffline = await localExpenseDataSource.getPendingExpenses(userId: userId);
      double egpPending = 0.0;
      double usdPending = 0.0;
      for (final exp in pendingOffline) {
        if (exp.currency == ExpenseCurrency.usd) {
          usdPending += exp.amount;
        } else {
          egpPending += exp.amount;
        }
      }

      return summary.copyWith(
        availableBalanceEgp: summary.availableBalanceEgp - egpPending,
        totalSpentEgp: summary.totalSpentEgp + egpPending,
        availableBalanceUsd: summary.availableBalanceUsd - usdPending,
        totalSpentUsd: summary.totalSpentUsd + usdPending,
      );
    } catch (e) {
      debugPrint('⚠️ [BalanceRepositoryImpl] Error in getEmployeeBalanceSummary ($e), calculating offline from local DB.');
      if (localDatabase != null && localDatabase!.isInitialized) {
        return await _calculateOfflineBalanceSummary(userId);
      }

      final localAll = await localExpenseDataSource.getExpenses(userId: userId);
      double egpSpent = 0.0;
      double usdSpent = 0.0;
      for (final exp in localAll) {
        if (exp.currency == ExpenseCurrency.usd) {
          usdSpent += exp.amount;
        } else {
          egpSpent += exp.amount;
        }
      }
      return EmployeeBalanceSummary(
        userId: userId,
        name: 'موظف',
        totalReceivedEgp: 0.0,
        totalSpentEgp: egpSpent,
        availableBalanceEgp: -egpSpent,
        totalReceivedUsd: 0.0,
        totalSpentUsd: usdSpent,
        availableBalanceUsd: -usdSpent,
      );
    }
  }

  Future<EmployeeBalanceSummary> _calculateOfflineBalanceSummary(String userId) async {
    final db = localDatabase!;
    final profile = await db.getProfile(userId);
    final balanceTxs = await db.getBalanceTransactions(userId);
    final expenses = await db.getExpenses(userId: userId);

    double egpReceived = 0.0;
    double egpAdjustSub = 0.0;
    double usdReceived = 0.0;
    double usdAdjustSub = 0.0;

    for (final tx in balanceTxs) {
      if (tx.currency == ExpenseCurrency.usd) {
        if (tx.type == BalanceTransactionType.adjustmentSub) {
          usdAdjustSub += tx.amount;
        } else {
          usdReceived += tx.amount;
        }
      } else {
        if (tx.type == BalanceTransactionType.adjustmentSub) {
          egpAdjustSub += tx.amount;
        } else {
          egpReceived += tx.amount;
        }
      }
    }

    double egpSpent = 0.0;
    double usdSpent = 0.0;
    for (final exp in expenses) {
      if (exp.currency == ExpenseCurrency.usd) {
        usdSpent += exp.amount;
      } else {
        egpSpent += exp.amount;
      }
    }

    return EmployeeBalanceSummary(
      userId: userId,
      name: profile?.name ?? 'موظف',
      email: profile?.email,
      role: profile?.role ?? 'employee',
      status: profile?.status ?? 'active',
      avatarUrl: profile?.avatarUrl,
      totalReceivedEgp: egpReceived,
      totalSpentEgp: egpSpent,
      availableBalanceEgp: egpReceived - egpAdjustSub - egpSpent,
      totalReceivedUsd: usdReceived,
      totalSpentUsd: usdSpent,
      availableBalanceUsd: usdReceived - usdAdjustSub - usdSpent,
    );
  }

  @override
  Future<List<EmployeeBalanceSummary>> getAllEmployeeBalances() async {
    try {
      final remote = await remoteDataSource.getAllEmployeeBalances();
      return remote;
    } catch (e) {
      debugPrint('⚠️ [BalanceRepositoryImpl] Remote getAllEmployeeBalances failed ($e), calculating offline.');
      if (localDatabase != null && localDatabase!.isInitialized) {
        final profiles = await localDatabase!.getProfiles();
        final List<EmployeeBalanceSummary> summaries = [];
        for (final p in profiles) {
          final summary = await _calculateOfflineBalanceSummary(p.id);
          summaries.add(summary);
        }
        return summaries;
      }
      return [];
    }
  }

  @override
  Future<List<BalanceTransaction>> getBalanceTransactions(String userId) async {
    try {
      final remote = await remoteDataSource.getBalanceTransactions(userId);
      if (localDatabase != null && localDatabase!.isInitialized) {
        await localDatabase!.saveBalanceTransactions(remote);
      }
      return remote;
    } catch (e) {
      debugPrint('⚠️ [BalanceRepositoryImpl] Remote getBalanceTransactions failed ($e), loading from local DB.');
      if (localDatabase != null && localDatabase!.isInitialized) {
        return await localDatabase!.getBalanceTransactions(userId);
      }
      return [];
    }
  }

  @override
  Future<List<FinancialHistoryItem>> getFinancialHistory(String userId) async {
    try {
      final balanceTxs = await getBalanceTransactions(userId);
      final expenses = await expenseRepository.getExpenses(
        userId: userId,
        pageSize: 300,
      );

      final List<FinancialHistoryItem> items = [];

      for (final tx in balanceTxs) {
        items.add(FinancialHistoryItem.fromBalanceTransaction(tx));
      }

      for (final exp in expenses) {
        items.add(FinancialHistoryItem.fromExpense(exp));
      }

      items.sort((a, b) => b.date.compareTo(a.date));
      return items;
    } catch (e) {
      debugPrint('❌ [BalanceRepositoryImpl] Error fetching financial history: $e');
      return [];
    }
  }
}
