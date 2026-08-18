import '../entities/expense_currency.dart';
import '../entities/weekly_allowance_transaction.dart';
import '../entities/weekly_work_budget_summary.dart';

abstract class WeeklyAllowanceRepository {
  Future<List<WeeklyAllowanceTransaction>> getWeeklyAllowanceTransactions({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<WeeklyWorkBudgetSummary> getWeeklyWorkBudgetSummary({
    String? userId,
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<WeeklyAllowanceTransaction> createAllowanceTransaction({
    required String userId,
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    required DateTime transactionDate,
    String? note,
  });

  Future<WeeklyAllowanceTransaction> updateAllowanceTransaction({
    required String id,
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    required DateTime transactionDate,
    String? note,
  });

  Future<void> deleteAllowanceTransaction(String id);
}
