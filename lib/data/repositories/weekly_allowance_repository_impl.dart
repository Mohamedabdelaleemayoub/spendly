import '../../domain/entities/expense_currency.dart';
import '../../domain/entities/weekly_allowance_transaction.dart';
import '../../domain/entities/weekly_work_budget_summary.dart';
import '../../domain/repositories/weekly_allowance_repository.dart';
import '../datasources/weekly_allowance_remote_datasource.dart';

class WeeklyAllowanceRepositoryImpl implements WeeklyAllowanceRepository {
  WeeklyAllowanceRepositoryImpl({required this.remoteDataSource});

  final WeeklyAllowanceRemoteDataSource remoteDataSource;

  @override
  Future<List<WeeklyAllowanceTransaction>> getWeeklyAllowanceTransactions({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await remoteDataSource.getWeeklyAllowanceTransactions(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<WeeklyWorkBudgetSummary> getWeeklyWorkBudgetSummary({
    String? userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await remoteDataSource.getWeeklyWorkBudgetSummary(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
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
    return await remoteDataSource.createAllowanceTransaction(
      userId: userId,
      amount: amount,
      currency: currency,
      transactionDate: transactionDate,
      note: note,
    );
  }

  @override
  Future<WeeklyAllowanceTransaction> updateAllowanceTransaction({
    required String id,
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    required DateTime transactionDate,
    String? note,
  }) async {
    return await remoteDataSource.updateAllowanceTransaction(
      id: id,
      amount: amount,
      currency: currency,
      transactionDate: transactionDate,
      note: note,
    );
  }

  @override
  Future<void> deleteAllowanceTransaction(String id) async {
    await remoteDataSource.deleteAllowanceTransaction(id);
  }
}
