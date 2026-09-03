import 'package:equatable/equatable.dart';
import 'expense_currency.dart';
import 'profile.dart';
import 'salary_payment.dart';

enum PayrollPaymentStatus {
  paid,
  partiallyPaid,
  unpaid,
  overpaid,
}

class PayrollSummary extends Equatable {
  const PayrollSummary({
    required this.profile,
    required this.salaryPeriodStart,
    required this.salaryPeriodEnd,
    required this.totalPeriodDays,
    required this.salaryAmount,
    required this.salaryCurrency,
    required this.totalPaidInPeriod,
    required this.remainingSalary,
    required this.overpaidAmount,
    required this.paidDays,
    required this.remainingDays,
    required this.nextExpectedPaymentDate,
    required this.daysUntilPayment,
    required this.status,
    this.lastPaymentAmount,
    this.lastPaymentDate,
    this.periodPayments = const [],
  });

  final Profile profile;
  final DateTime salaryPeriodStart;
  final DateTime salaryPeriodEnd;
  final int totalPeriodDays;
  final double salaryAmount;
  final ExpenseCurrency salaryCurrency;
  final double totalPaidInPeriod;
  final double remainingSalary;
  final double overpaidAmount;
  final double paidDays;
  final double remainingDays;
  final DateTime nextExpectedPaymentDate;
  final int daysUntilPayment;
  final PayrollPaymentStatus status;
  final double? lastPaymentAmount;
  final DateTime? lastPaymentDate;
  final List<SalaryPayment> periodPayments;

  bool get isDueToday => daysUntilPayment == 0 && remainingSalary > 0;
  bool get isDueSoon => daysUntilPayment > 0 && daysUntilPayment <= 3 && remainingSalary > 0;
  bool get isOverdue => daysUntilPayment < 0 && remainingSalary > 0;
  bool get isFullyPaid => remainingSalary <= 0 && salaryAmount > 0;

  double get paidPercentage {
    if (salaryAmount <= 0) return 0.0;
    return (totalPaidInPeriod / salaryAmount).clamp(0.0, 1.0);
  }

  @override
  List<Object?> get props => [
        profile,
        salaryPeriodStart,
        salaryPeriodEnd,
        totalPeriodDays,
        salaryAmount,
        salaryCurrency,
        totalPaidInPeriod,
        remainingSalary,
        overpaidAmount,
        paidDays,
        remainingDays,
        nextExpectedPaymentDate,
        daysUntilPayment,
        status,
        lastPaymentAmount,
        lastPaymentDate,
        periodPayments,
      ];
}
