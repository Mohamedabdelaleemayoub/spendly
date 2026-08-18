import '../../domain/entities/expense_currency.dart';
import '../../domain/entities/salary_advance.dart';
import '../../domain/repositories/salary_advance_repository.dart';
import '../datasources/salary_advance_remote_datasource.dart';

class SalaryAdvanceRepositoryImpl implements SalaryAdvanceRepository {
  SalaryAdvanceRepositoryImpl({required this.remoteDataSource});

  final SalaryAdvanceRemoteDataSource remoteDataSource;

  @override
  Future<List<SalaryAdvance>> getSalaryAdvances(String userId) async {
    return await remoteDataSource.getSalaryAdvances(userId);
  }

  @override
  Future<List<SalaryAdvance>> getAllSalaryAdvances() async {
    return await remoteDataSource.getAllSalaryAdvances();
  }

  @override
  Future<SalaryAdvance> createSalaryAdvance({
    required String userId,
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    required DateTime advanceDate,
    String? note,
  }) async {
    return await remoteDataSource.createSalaryAdvance(
      userId: userId,
      amount: amount,
      currency: currency,
      advanceDate: advanceDate,
      note: note,
    );
  }

  @override
  Future<SalaryAdvance> updateSalaryAdvance({
    required String id,
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    required DateTime advanceDate,
    String? note,
  }) async {
    return await remoteDataSource.updateSalaryAdvance(
      id: id,
      amount: amount,
      currency: currency,
      advanceDate: advanceDate,
      note: note,
    );
  }

  @override
  Future<void> deleteSalaryAdvance(String id) async {
    await remoteDataSource.deleteSalaryAdvance(id);
  }

  @override
  Future<void> updateEmployeeSalary({
    required String userId,
    required double salaryAmount,
    ExpenseCurrency salaryCurrency = ExpenseCurrency.egp,
  }) async {
    await remoteDataSource.updateEmployeeSalary(
      userId: userId,
      salaryAmount: salaryAmount,
      salaryCurrency: salaryCurrency,
    );
  }
}
