import '../entities/expense_currency.dart';
import '../entities/payroll_summary.dart';
import '../entities/salary_payment.dart';

abstract class SalaryPaymentRepository {
  Future<List<SalaryPayment>> getSalaryPayments(String userId);
  Future<List<SalaryPayment>> getAllSalaryPayments();
  Future<SalaryPayment> createSalaryPayment({
    required String userId,
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    required DateTime paymentDate,
    required DateTime salaryPeriodStart,
    required DateTime salaryPeriodEnd,
    String? note,
  });
  Future<SalaryPayment> updateSalaryPayment({
    required String id,
    required double amount,
    ExpenseCurrency currency = ExpenseCurrency.egp,
    required DateTime paymentDate,
    required DateTime salaryPeriodStart,
    required DateTime salaryPeriodEnd,
    String? note,
  });
  Future<void> deleteSalaryPayment(String id);
  Future<void> updateSalaryCycleConfig({
    required String userId,
    required String cycleType,
    required int cycleDays,
    required int cycleStartDay,
  });
  Future<PayrollSummary?> getEmployeePayrollSummary(String userId, {DateTime? referenceDate});
  Future<List<PayrollSummary>> getAllPayrollSummaries({DateTime? referenceDate});
}
