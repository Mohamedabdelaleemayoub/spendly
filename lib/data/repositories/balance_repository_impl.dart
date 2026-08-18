import 'package:flutter/foundation.dart';
import '../../domain/entities/balance_transaction.dart';
import '../../domain/entities/employee_balance_summary.dart';
import '../../domain/entities/expense_currency.dart';
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
    ExpenseCurrency currency = ExpenseCurrency.egp,
    DateTime? transactionDate,
    String? note,
  }) async {
    return remoteDataSource.addBalance(
      userId: userId,
      amount: amount,
      currency: currency,
      transactionDate: transactionDate,
      note: note,
    );
  }

  @override
  Future<EmployeeBalanceSummary> getEmployeeBalanceSummary(String userId) async {
    try {
      final summary = await remoteDataSource.getEmployeeBalanceSummary(userId);
      // Incorporate pending offline expenses that haven't synced yet, per currency
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
      debugPrint('⚠️ [BalanceRepositoryImpl] Error in getEmployeeBalanceSummary ($e), calculating offline.');
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
