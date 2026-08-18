import '../entities/balance_transaction.dart';
import '../entities/employee_balance_summary.dart';
import '../entities/expense_currency.dart';
import '../entities/financial_history_item.dart';

abstract class BalanceRepository {
  Future<BalanceTransaction> addBalance({
    required String userId,
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    DateTime? transactionDate,
    String? note,
  });

  Future<EmployeeBalanceSummary> getEmployeeBalanceSummary(String userId);

  Future<List<EmployeeBalanceSummary>> getAllEmployeeBalances();

  Future<List<BalanceTransaction>> getBalanceTransactions(String userId);

  Future<List<FinancialHistoryItem>> getFinancialHistory(String userId);
}
