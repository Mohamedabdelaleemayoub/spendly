import '../entities/expense_currency.dart';
import '../entities/salary_advance.dart';

abstract class SalaryAdvanceRepository {
  Future<List<SalaryAdvance>> getSalaryAdvances(String userId);
  Future<List<SalaryAdvance>> getAllSalaryAdvances();
  Future<SalaryAdvance> createSalaryAdvance({
    required String userId,
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    required DateTime advanceDate,
    String? note,
  });
  Future<SalaryAdvance> updateSalaryAdvance({
    required String id,
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    required DateTime advanceDate,
    String? note,
  });
  Future<void> deleteSalaryAdvance(String id);
  Future<void> updateEmployeeSalary({
    required String userId,
    required double salaryAmount,
    ExpenseCurrency salaryCurrency = ExpenseCurrency.egp,
  });
}
