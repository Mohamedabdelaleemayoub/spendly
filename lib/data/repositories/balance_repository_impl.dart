import 'package:flutter/foundation.dart';
import '../../domain/entities/balance_transaction.dart';
import '../../domain/entities/employee_balance_summary.dart';
import '../../domain/entities/financial_history_item.dart';
import '../../domain/repositories/balance_repository.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/balance_remote_datasource.dart';
import '../datasources/local_expense_datasource.dart';

class BalanceRepositoryImpl implements BalanceRepository {
  BalanceRepositoryImpl({
    required this.remoteDataSource,
    required this.localExpenseDataSource,
    required this.expenseRepository,
  });

  final BalanceRemoteDataSource remoteDataSource;
  final LocalExpenseDataSource localExpenseDataSource;
  final ExpenseRepository expenseRepository;

  @override
  Future<BalanceTransaction> addBalance({
    required String userId,
    required double amount,
    DateTime? transactionDate,
    String? note,
  }) async {
    return remoteDataSource.addBalance(
      userId: userId,
      amount: amount,
      transactionDate: transactionDate,
      note: note,
    );
  }

  @override
  Future<EmployeeBalanceSummary> getEmployeeBalanceSummary(String userId) async {
    try {
      final summary = await remoteDataSource.getEmployeeBalanceSummary(userId);
      // Incorporate pending offline expenses that haven't synced yet
      final pendingOffline = await localExpenseDataSource.getPendingExpenses(userId: userId);
      double pendingTotal = 0.0;
      for (final exp in pendingOffline) {
        pendingTotal += exp.amount;
      }

      final adjustedAvailable = summary.availableBalance - pendingTotal;
      return summary.copyWith(
        availableBalance: adjustedAvailable,
        totalSpent: summary.totalSpent + pendingTotal,
      );
    } catch (e) {
      debugPrint('⚠️ [BalanceRepositoryImpl] Error in getEmployeeBalanceSummary ($e), calculating offline.');
      final localAll = await localExpenseDataSource.getExpenses(userId: userId);
      double totalSpent = 0.0;
      for (final exp in localAll) {
        totalSpent += exp.amount;
      }
      return EmployeeBalanceSummary(
        userId: userId,
        name: 'موظف',
        totalReceived: 0.0,
        totalSpent: totalSpent,
        availableBalance: -totalSpent,
      );
    }
  }

  @override
  Future<List<EmployeeBalanceSummary>> getAllEmployeeBalances() async {
    return remoteDataSource.getAllEmployeeBalances();
  }

  @override
  Future<List<BalanceTransaction>> getBalanceTransactions(String userId) async {
    return remoteDataSource.getBalanceTransactions(userId);
  }

  @override
  Future<List<FinancialHistoryItem>> getFinancialHistory(String userId) async {
    try {
      // 1. Fetch balance transactions (Credits / Adjustments)
      final balanceTxs = await remoteDataSource.getBalanceTransactions(userId);

      // 2. Fetch expenses
      final expenses = await expenseRepository.getExpenses(
        userId: userId,
        pageSize: 300,
      );

      // 3. Map both to FinancialHistoryItem
      final List<FinancialHistoryItem> items = [];

      for (final tx in balanceTxs) {
        items.add(FinancialHistoryItem.fromBalanceTransaction(tx));
      }

      for (final exp in expenses) {
        items.add(FinancialHistoryItem.fromExpense(exp));
      }

      // 4. Sort chronologically descending
      items.sort((a, b) => b.date.compareTo(a.date));

      return items;
    } catch (e) {
      debugPrint('❌ [BalanceRepositoryImpl] Error fetching financial history: $e');
      return [];
    }
  }
}
